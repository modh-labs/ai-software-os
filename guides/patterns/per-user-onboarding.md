---
title: "Per-User Onboarding Enforcement"
description: "Every user must have their own calendar connection to use the application."
tags: ["architecture", "security", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# Per-User Calendar Connection Enforcement

## Philosophy

Every user must have their own calendar connection to use the application. The onboarding middleware enforces this at the **individual user level**, not the organization level. This prevents the "first user unblocks everyone" bug where one team member's calendar connection would silently onboard all other members of the same org.

---

## The Problem This Solves

This is a multi-tenant application where organizations contain multiple users. When the original onboarding check relied solely on the org-level `onboarding_completed` flag, a race condition emerged:

1. **User A** creates an org and connects their calendar → org flag set to `true`
2. **User B** is invited to the same org → org flag is already `true`
3. **User B** is considered "onboarded" without ever connecting their own calendar
4. **User B** tries to schedule a meeting → fails because they have no Nylas grant

This is a **data-level isolation gap**: the org flag tracks an org milestone, but calendar grants are per-user resources.

---

## Decision Logic

The `checkOnboardingCompletion()` function in `nylas.repository.ts` uses a **most-specific-first** evaluation order:

```
1. Does THIS USER have a nylas_connections record?
   ├── YES → Check provider matches org requirement → ONBOARDED
   └── NO  → Fall through ↓

2. Does the ORG have onboarding_completed = true?
   ├── YES → Is this a demo account?
   │         ├── YES → ONBOARDED (demo bypass)
   │         └── NO  → NOT ONBOARDED (must connect own calendar)
   └── NO  → NOT ONBOARDED
```

### Why This Order Matters

| Check Order | Behavior | Risk |
|-------------|----------|------|
| **User connection first** ✅ | Each user must prove their own grant | None — correct isolation |
| Org flag first ❌ | One user's connection unlocks everyone | Team members skip calendar setup |

---

## Key Concepts

### Per-User Connection = Primary Gate

The user's own `nylas_connections` record with a valid `grant_id` is the **only** way a non-demo user can pass the onboarding check. The org-level `onboarding_completed` flag is necessary but not sufficient.

### Demo Account Bypass

Demo accounts legitimately skip calendar setup — they use synthetic data. The `demo_accounts` table is checked **only when needed**: when a user has no connection but the org flag is `true`. This avoids an extra DB query in the common case.

### Provider Match Validation

If the organization has set a `calendar_provider` (e.g., `google`), the user's connection must match. A Microsoft connection in a Google-only org results in `provider_mismatch` — the user is not considered onboarded.

### Lazy Evaluation

The demo account query is deferred until the specific branch that needs it:

```typescript
// Only runs when: no user connection + org flag is true
// Does NOT run when: user already has a valid connection (common case)
const { data: demoRecord } = await supabase
    .from("demo_accounts")
    .select("id")
    .eq("organization_id", organizationId)
    .maybeSingle();
```

This keeps the happy path (user has a connection) to a single DB query for connections + one for the org record.

---

## Return Contract

`checkOnboardingCompletion()` returns:

| Field | Type | Description |
|-------|------|-------------|
| `isOnboarded` | `boolean` | Whether the user can proceed past onboarding |
| `isDemoAccount` | `boolean` | Whether the org is a demo (bypass was applied) |
| `reason` | `string \| null` | Machine-readable reason for the decision |
| `hasConnection` | `boolean` | Whether the user has any nylas_connections record |
| `hasCalendarProvider` | `boolean` | Whether the org has set a calendar provider |
| `connectionProvider` | `string \| null` | The user's connection provider (google/microsoft) |
| `orgCalendarProvider` | `string \| null` | The org's required provider |

### Reason Values

| Reason | Meaning | Action |
|--------|---------|--------|
| `user_has_matching_connection` | User connected, provider matches org | Allow through |
| `user_has_connection_org_provider_pending` | User connected, org hasn't set provider yet | Allow through |
| `demo_account_bypass` | Demo org, no calendar needed | Allow through |
| `provider_mismatch` | User's provider doesn't match org requirement | Redirect to onboarding |
| `no_user_connection` | User hasn't connected a calendar | Redirect to onboarding |

---

## Where It's Enforced

### Middleware (`proxy.ts`)

The proxy middleware calls `checkOnboardingCompletion()` for every authenticated request to protected routes. If `isOnboarded` is `false`, the user is redirected to `/onboarding`.

```
Request → Auth Check → Gate 1 (Billing) → Gate 2 (Onboarding) → Route
                                             ↑
                                    checkOnboardingCompletion()
```

### Onboarding Client (`onboarding-client.tsx`)

The onboarding page itself detects the user's state and shows the appropriate step (billing, calendar connection, or success). It handles team members correctly — detecting an existing subscription and skipping the billing prompt.

---

## Lifecycle Scenarios

### New Org Creator (Normal Flow)
```
Sign up → Billing → /onboarding (CalendarConnectStep) → Connect → Dashboard
```

### Team Member Joining Existing Org
```
Accept invite → Middleware: org.onboarding_completed=true but no user connection
             → Redirect to /onboarding → Connect own calendar → Dashboard
```

### Demo Account
```
Create demo → org.onboarding_completed=true + demo_accounts record exists
           → Middleware: demo bypass → Dashboard (no calendar needed)
```

### Demo Exit
```
Exit demo → demo_accounts record deleted
         → Next request: no connection + no demo record → Redirect to /onboarding
```

---

## Common Mistakes

| Mistake | Why It's Wrong | Correct Approach |
|---------|---------------|------------------|
| Checking org flag before user connection | One user's connection unlocks everyone | Check user connection first |
| Hardcoding `isDemoAccount: false` | Downstream consumers can't distinguish demo bypass | Query `demo_accounts` when needed |
| Querying `demo_accounts` on every request | Unnecessary DB call when user has a connection | Only query in the no-connection + org-onboarded branch |
| Skipping provider match validation | User with wrong provider can't create events | Compare `connection.provider` to `org.calendar_provider` |

---

## Files

| File | Role |
|------|------|
| `app/_shared/repositories/nylas.repository.ts` | `checkOnboardingCompletion()` — decision logic |
| `proxy.ts` | Middleware that enforces the gate |
| `app/(protected)/onboarding/` | Onboarding UI (handles steps based on state) |
| `app/(protected)/onboarding/actions/complete-onboarding.ts` | Sets org-level `onboarding_completed` flag |
| `app/(protected)/onboarding/actions/exit-demo.ts` | Deletes `demo_accounts` record on exit |

## Related

- [Repository Pattern](./repository-pattern.md) — how DB access is structured
- [Nylas Integration](../../apps/web/app/_shared/lib/nylas/CLAUDE.md) — grant lifecycle and API patterns
