---
name: security-patterns
description: Enforce security standards for your application including RLS policies, webhook signature verification, Zod validation, and environment variable safety. Use when adding tables, webhook handlers, server actions, or working with authentication. Prevents XSS, injection, and data leakage.
allowed-tools: Read, Grep, Glob
---

# Security Patterns Skill

## When This Skill Activates

This skill automatically activates when you:
- Create or modify database tables (RLS policies)
- Write webhook handlers (signature verification)
- Create server actions (input validation)
- Work with environment variables or secrets
- Discuss authentication, authorization, or data protection

## Core Rules (MUST Follow)

### 1. Trust RLS — Don't Duplicate Permission Checks

```typescript
// ❌ WRONG - Redundant with RLS
export async function deleteCall(id: string) {
  const auth = await getAuth();
  const call = await callsRepository.getById(id);
  if (call.organization_id !== auth.orgId) {
    throw new Error("Unauthorized"); // RLS already does this!
  }
  await callsRepository.remove(id);
}

// ✅ CORRECT - Trust RLS
export async function deleteCall(id: string) {
  await callsRepository.remove(id);
  // If RLS rejects, Supabase throws automatically
}
```

### 2. Enable RLS on ALL Tables with User Data

```sql
ALTER TABLE "public"."my_table" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "organization_isolation" ON "public"."my_table"
FOR ALL USING (
  organization_id = (auth.jwt() ->> 'org_id')::text
);
```

### 3. Service Role ONLY in Webhook Handlers

```typescript
// ✅ ONLY in webhook handlers
import { createServiceRoleClient } from "@/app/_shared/lib/supabase/server";

export async function POST(req: Request) {
  const supabase = await createServiceRoleClient();
  // Bypasses RLS - use carefully!
}

// ❌ NEVER in server actions or components
```

### 4. Always Verify Webhook Signatures

```typescript
// Stripe
const event = stripe.webhooks.constructEvent(body, signature, webhookSecret);

// Clerk
const payload = await svix.verify(body, headers);

// Nylas
const isValid = verifyNylasSignature(body, signature, secret);
```

### 5. Always Use `req.text()` for Webhook Body

```typescript
// ✅ CORRECT - Raw body preserves signature
const body = await req.text();
const event = stripe.webhooks.constructEvent(body, signature, secret);

// ❌ WRONG - Parsed JSON breaks signature verification
const body = await req.json();
```

### 6. Zod Validation at Server Action Boundary

```typescript
// ✅ CORRECT - Validate all user input
import { createLeadSchema } from "@/app/_shared/validation/leads.schema";

export async function createLead(data: unknown) {
  const validated = createLeadSchema.parse(data);
  // Now safe to use
}

// ❌ WRONG - Trusting client input
export async function createLead(data: CreateLeadInput) {
  // data could be anything!
  await leadsRepository.create(supabase, data);
}
```

### 7. Never Commit `.env` Files

Lint-staged blocks `.env` commits. Always use Vercel environment variables for secrets.

Client-safe variables use `NEXT_PUBLIC_*` prefix only.

### 8. Reject Stale Webhook Events

```typescript
const MAX_EVENT_AGE_SECONDS = 300; // 5 minutes

const eventAge = Math.floor(Date.now() / 1000) - event.created;
if (eventAge > MAX_EVENT_AGE_SECONDS) {
  return NextResponse.json({ error: "Event too old" }, { status: 400 });
}
```

## HTTP Security Headers

Every `next.config.mjs` MUST include:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Referrer-Policy: origin-when-cross-origin`

Full header config: `references/http-headers.md`

## Sensitive Data

```typescript
// Sentry MUST disable PII
Sentry.init({ sendDefaultPii: false });

// Encrypt credentials at rest
import { encrypt, decrypt } from "@/app/_shared/lib/encryption/credentials";
const encryptedKey = encrypt(apiKey, process.env.INTEGRATION_ENCRYPTION_KEY!);
```

## Anti-Patterns

```typescript
// ❌ Duplicating RLS checks in code
// ❌ Using service role in server actions
// ❌ req.json() for webhook body (breaks signatures)
// ❌ Missing Zod validation on server actions
// ❌ Committing .env files
// ❌ String concatenation in SQL (injection risk)
// ❌ Exposing secrets in NEXT_PUBLIC_* vars
```

## Quick Reference

| Pattern | Correct | Wrong |
|---------|---------|-------|
| Authorization | Trust RLS | Manual org_id checks |
| Webhook body | `req.text()` | `req.json()` |
| Input validation | Zod at boundary | Trust client input |
| Service role | Webhooks only | Server actions |
| Secrets | Vercel env vars | `.env` in repo |
| SQL | Supabase parameterized | String concatenation |

## Detailed Documentation

- HTTP headers config: `references/http-headers.md`
- Webhook signature patterns: `references/webhook-security.md`
- Full security standards: `docs/standards/security.md`

## Checklist for New Apps

- [ ] Security headers in `next.config.mjs`
- [ ] Clerk middleware for protected routes
- [ ] RLS on all tables with user data
- [ ] `sendDefaultPii: false` in Sentry
- [ ] Webhook signature verification
- [ ] Zod schemas for all inputs
- [ ] Rate limiting for public endpoints
