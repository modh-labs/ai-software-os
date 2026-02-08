---
description: Comprehensive codebase audit for architecture, testing, code quality, and reliability tracking
argument-hint: [path to route, component, or directory]
allowed-tools:
  Read, Grep, Glob, Bash, mcp__posthog__*, AskUserQuestion
---

# Codebase Audit

**Audit Target**: `$ARGUMENTS`

## Overview

This command performs a comprehensive audit of your codebase, covering:

1. **Architecture & Code Quality** - Route colocation, import patterns, type safety
2. **Data Fetching Patterns** - Server Actions, repositories, Server Components
3. **Testing Coverage & Quality** - Unit tests, integration tests, coverage metrics
4. **Reliability & Production Health** - PostHog error tracking, performance metrics
5. **Best Practices Compliance** - Adherence to team standards

## Audit Process

### Phase 1: Scope & Context Gathering

**I'll start by understanding what you want to audit and why.**

#### Step 1: PostHog MCP Connection Check

**Optional but recommended for production insights.**

I'll check if PostHog MCP is connected to provide:
- Error rates and patterns
- Performance metrics
- Feature flag usage
- User journey analytics

**If PostHog MCP is not connected**, you can set it up with:

```bash
npx @posthog/wizard mcp add

# Or manually:
claude mcp add-json posthog -s user '{
  "command": "npx",
  "args": ["-y", "mcp-remote@latest", "https://mcp.posthog.com/sse", "--header", "Authorization:${POSTHOG_AUTH_HEADER}"],
  "env": {"POSTHOG_AUTH_HEADER": "Bearer YOUR_API_KEY"}
}'
```

Get your API key from: https://app.posthog.com/settings/user-api-keys?preset=mcp_server

**I'll continue with the audit regardless of PostHog availability**, but production insights will be limited.

#### Step 2: Audit Scope Clarification

**If you didn't specify a path**, I'll ask:

1. **What do you want to audit?**
   - Specific route (e.g., `app/(protected)/calls`)
   - Specific component (e.g., `CallItem.tsx`)
   - Entire protected routes (`app/(protected)`)
   - Specific feature area (e.g., scheduler, dashboard)

2. **What's the primary goal?**
   - Pre-launch review (comprehensive)
   - Bug investigation (focused on reliability)
   - Code quality improvement (architecture + testing)
   - Performance optimization (PostHog metrics + code patterns)
   - Migration planning (e.g., Apollo → Relay equivalent)

3. **Specific concerns or areas of focus?**
   - Testing gaps
   - Type safety issues
   - Performance problems
   - Error rates in production
   - Server Action patterns
   - Repository usage
   - All of the above

4. **Known context to consider?**
   - Recent production issues
   - Feature flags active
   - Migration status
   - Upcoming launches

---

### Phase 2: Architecture & Code Quality Analysis

#### Section 1: File Structure & Organization

**I'll analyze:**

✅ **Route Colocation Compliance**
- Components in `components/` directory
- Server Actions in `actions.ts` or `actions/`
- Types in `types.ts`
- Hooks in `hooks/`
- No cross-route imports

✅ **No Barrel Files**
- Check for `index.ts` files (anti-pattern)
- Verify direct imports

✅ **Import Organization**
- React/Next.js first
- External dependencies
- Internal (@/ alias)
- Relative imports

**Example findings:**

```markdown
### ❌ Route Colocation Violations

**File**: `app/(protected)/calls/components/CallItem.tsx`
- **Line 5**: Importing from `../../scheduler/components/TimeSlotPicker`
- **Impact**: Creates tight coupling between routes
- **Fix**: Move `TimeSlotPicker` to `app/_shared/components/` or duplicate logic

**File**: `app/(protected)/dashboard/index.ts`
- **Issue**: Barrel file detected
- **Impact**: Slow build times, circular import risk
- **Fix**: Remove barrel file, use direct imports
```

#### Section 2: Type Safety Audit

**I'll check:**

✅ **Supabase-Generated Types Usage**
- NO custom interfaces for database tables
- Use `Database["public"]["Tables"]["table_name"]["Row|Insert|Update"]`
- Check for manual type definitions (anti-pattern)

✅ **TypeScript Strict Mode Compliance**
- No `any` types
- No `@ts-ignore` comments
- Proper null/undefined handling

✅ **Zod Validation**
- Server Actions validate input
- Proper error formatting
- Type inference from schemas

**Example findings:**

```markdown
### ❌ Type Safety Issues

**File**: `app/(protected)/calls/actions.ts`
- **Line 15**: `const data: any = await supabase...`
- **Impact**: No type safety, runtime errors possible
- **Fix**: Use `Call` type from repository or Supabase-generated types

**File**: `app/(protected)/scheduler/types.ts`
- **Lines 10-25**: Custom `BookingLink` interface duplicates database schema
- **Impact**: Type drift from database, maintenance burden
- **Fix**: Remove interface, import from `database.types.ts`

```typescript
// ❌ Current
export interface BookingLink {
  id: string;
  title: string;
  // ... 15 more fields manually defined
}

// ✅ Fix
import type { Database } from "@/app/_shared/lib/supabase/database.types";
export type BookingLink = Database["public"]["Tables"]["call_booking_links"]["Row"];
```
```

#### Section 3: Server Action Patterns

**I'll verify:**

✅ **Required Patterns**
- `"use server"` directive at top
- Structured response type: `{ success, data?, error?, errors? }`
- `revalidatePath()` called after mutations
- Pino logger usage (NOT `console.log`)
- Repository usage (NOT direct `supabase.from()`)
- Zod validation for input

**Example findings:**

```markdown
### ❌ Server Action Anti-Patterns

**File**: `app/(protected)/calls/actions.ts`

**Missing `revalidatePath()`**:
- **Line 45**: `createCallAction` mutates data but doesn't invalidate cache
- **Impact**: UI shows stale data until manual refresh
- **Fix**:
```typescript
export async function createCallAction(input: unknown) {
  // ... validation and mutation logic

  revalidatePath("/calls");        // ✅ Add this
  revalidatePath("/dashboard");    // ✅ Add this

  return { success: true, data: call };
}
```

**Direct Supabase Usage**:
- **Lines 25-30**: Direct `supabase.from("calls").insert()` call
- **Impact**: Bypasses repository layer, duplicates query logic
- **Fix**:
```typescript
// ❌ Current
const { data, error } = await supabase
  .from("calls")
  .insert(callData)
  .select("*")
  .single();

// ✅ Fix
import { createCall } from "@/app/_shared/repositories/calls.repository";
const call = await createCall(supabase, callData);
```

**Missing Logger**:
- **Line 50**: Using `console.error()` instead of Pino
- **Fix**:
```typescript
import { createModuleLogger } from "@/app/_shared/lib/logger";
const logger = createModuleLogger("calls-actions");

logger.error(error, "Failed to create call");
```
```

#### Section 4: Repository Pattern Compliance

**I'll verify:**

✅ **Repository Standards**
- Accept `SupabaseClient` as first parameter
- Use `select *` for full type safety
- Use Supabase-generated `Insert|Update|Row` types
- Export individual functions (not objects)
- Let RLS handle `organization_id` filtering

**Example findings:**

```markdown
### ⚠️ Repository Pattern Violations

**File**: `app/_shared/repositories/calls.repository.ts`

**Not using `select *`**:
- **Line 15**: Selecting specific fields breaks type inference
- **Fix**:
```typescript
// ❌ Current
.select("id, title, scheduled_at")

// ✅ Fix
.select("*")
// TypeScript now infers the full Call type!
```

**Missing Relations**:
- **Query doesn't join related data** (lead, closer, payments)
- **Impact**: Multiple queries needed, N+1 problem
- **Fix**:
```typescript
const selectStr = `
  *,
  lead:leads!calls_lead_id_fkey(*),
  closer:users!calls_closer_id_fkey(*),
  payments!payments_call_id_fkey(*)
`;

return supabase.from("calls").select(selectStr);
```
```

---

### Phase 3: Testing Coverage & Quality

#### Section 1: Test File Coverage

**I'll identify missing tests:**

✅ **Component Tests**
- Every component in `components/` should have a `.test.tsx` file
- Coverage should be > 70% for critical components

✅ **Server Action Tests**
- Every action should test validation, success, and error paths
- Verify `revalidatePath()` is called

✅ **Repository Tests**
- Unit tests for query building and filtering logic
- Mock Supabase client appropriately

**Example findings:**

```markdown
### ❌ Missing Test Coverage

**Components without tests:**
- `app/(protected)/calls/components/CallItem.tsx` (HIGH PRIORITY)
- `app/(protected)/calls/components/CallDetails.tsx` (HIGH PRIORITY)
- `app/(protected)/scheduler/components/BookingLinkCard.tsx` (MEDIUM)

**Server Actions without tests:**
- `app/(protected)/calls/actions.ts` - `cancelCallAction` (HIGH PRIORITY)
- `app/(protected)/scheduler/create/actions.ts` - `createBookingLinkAction` (HIGH PRIORITY)

**Repositories without tests:**
- `app/_shared/repositories/booking-link.repository.ts` (MEDIUM PRIORITY)

**Impact**:
- Cannot safely refactor or modify these files
- Breaking changes go undetected until production
- No confidence in edge case handling
```

#### Section 2: Test Quality Analysis

**I'll review existing tests for:**

✅ **Good Practices**
- No snapshot tests
- Realistic test data (faker.js)
- Factory functions for setup
- Proper mocking (external deps only)
- Arrange-Act-Assert structure
- Descriptive test names

✅ **Coverage Metrics**
- Check `vitest.config.ts` thresholds
- Run coverage report if requested

**Example findings:**

```markdown
### ⚠️ Test Quality Issues

**File**: `app/(protected)/calls/components/__tests__/CallItem.test.tsx`

**Overmocking**:
- **Lines 10-20**: Mocking internal utility functions
- **Impact**: Tests don't validate real behavior
- **Fix**: Only mock external dependencies (SWR, Supabase)

**Hardcoded Test Data**:
- **Line 25**: Using `"John Doe"` instead of `faker.person.fullName()`
- **Impact**: Tests less robust, don't catch edge cases
- **Fix**:
```typescript
import { faker } from "@faker-js/faker";

const mockCall: Call = {
  id: faker.string.uuid(),
  title: faker.lorem.words(3),
  scheduled_at: faker.date.future().toISOString(),
  // ...
};
```

**Missing Edge Cases**:
- No tests for loading states
- No tests for error states
- No tests for empty data
```

---

### Phase 4: Reliability & Production Health (PostHog MCP)

**If PostHog MCP is available**, I'll query production metrics:

✅ **Error Tracking**
- Recent errors related to audited code
- Error frequency and trends
- Stack traces and context

✅ **Performance Metrics**
- Slow queries or Server Actions
- Client-side performance issues
- Time to interactive

✅ **Feature Flags**
- Active flags affecting the code
- Rollout status and user targeting

✅ **User Journeys**
- Drop-off points in flows
- Common user paths
- Session replays for bugs

**Example findings:**

```markdown
### 🚨 Production Issues (PostHog Insights)

**Error Rate Spike**:
- **Route**: `/calls/create`
- **Error**: "Validation failed: scheduled_at is required"
- **Frequency**: 45 errors in the last 7 days
- **Impact**: Users unable to create calls
- **Root Cause**: Client-side validation missing, server-side validation rejecting
- **Fix**: Add client-side Zod validation before Server Action call

**Performance Degradation**:
- **Route**: `/dashboard`
- **Issue**: Time to interactive > 3 seconds (P95)
- **Root Cause**: Loading all 500+ calls without pagination
- **Fix**: Implement server-side pagination in `getCalls` repository function

**Feature Flag Usage**:
- **Flag**: `new-scheduler-ui`
- **Status**: 50% rollout
- **Impact**: Audited code (`scheduler/create/page.tsx`) is behind flag
- **Note**: Ensure tests cover both old and new UI paths
```

---

### Phase 5: Synthesis & Recommendations

**After completing the analysis, I'll provide:**

#### 1. Executive Summary

```markdown
# Audit Summary: `app/(protected)/calls`

## Health Score: 65/100 🟡

### Quick Stats:
- **Files Analyzed**: 15
- **Critical Issues (P0)**: 3
- **High Priority (P1)**: 7
- **Medium Priority (P2)**: 12
- **Low Priority (P3)**: 5
- **Test Coverage**: 35% (Target: 70%+)
- **Type Safety**: 80% (8 `any` types found)

### Top Concerns:
1. ❌ Zero test coverage for `CallItem.tsx` (most complex component)
2. ❌ Missing `revalidatePath()` in 3 Server Actions
3. ❌ Direct Supabase usage in 2 Server Actions (bypass repositories)
4. ⚠️ 45 production errors in `/calls/create` (last 7 days)
```

#### 2. Prioritized Issues (P0/P1/P2/P3)

```markdown
## Critical Issues (P0) - Fix Immediately

### P0-1: Missing Test Coverage for CallItem.tsx
- **File**: `app/(protected)/calls/components/CallItem.tsx`
- **Impact**: Most complex component (200+ lines) with zero tests
- **Risk**: High - any refactor or change could break functionality
- **Effort**: 4-6 hours
- **Action**: Create comprehensive test suite covering:
  - Loading states
  - User interactions (expand/collapse)
  - SWR data fetching
  - Error handling

### P0-2: Missing revalidatePath() in cancelCallAction
- **File**: `app/(protected)/calls/actions.ts:45`
- **Impact**: UI shows stale data after cancellation until manual refresh
- **Risk**: High - user confusion, potential data inconsistency
- **Effort**: 5 minutes
- **Action**:
```typescript
export async function cancelCallAction(callId: string) {
  // ... existing logic

  revalidatePath("/calls");        // ✅ Add this
  revalidatePath("/dashboard");    // ✅ Add this

  return { success: true };
}
```

### P0-3: Production Errors in /calls/create (45 errors/week)
- **File**: `app/(protected)/calls/create/page.tsx`
- **Impact**: Users unable to create calls
- **Root Cause**: Missing client-side validation
- **Effort**: 2 hours
- **Action**: Add Zod validation in form component before Server Action call

## High Priority (P1) - Address This Sprint

[... detailed list of P1 issues ...]

## Medium Priority (P2) - Next 2-3 Sprints

[... detailed list of P2 issues ...]

## Low Priority (P3) - Backlog

[... detailed list of P3 issues ...]
```

#### 3. Immediate Actions (This Week)

```markdown
## Immediate Actions

1. **Add Test Coverage for CallItem.tsx** (P0-1)
   - Create `CallItem.test.tsx`
   - Use factory function pattern from `docs/TESTING-BEST-PRACTICES.md`
   - Aim for 80%+ coverage

2. **Fix revalidatePath() in Server Actions** (P0-2)
   - `calls/actions.ts:45` - `cancelCallAction`
   - `calls/actions.ts:70` - `updateCallAction`
   - `scheduler/create/actions.ts:30` - `createBookingLinkAction`

3. **Add Client-Side Validation** (P0-3)
   - Create Zod schema in `calls/create/schema.ts`
   - Validate in form component before Server Action
   - Show validation errors to user immediately
```

#### 4. Short-Term Improvements (Next 2-3 Sprints)

```markdown
## Short-Term Improvements

1. **Migrate to Repository Pattern** (P1)
   - Remove direct `supabase.from()` calls in Server Actions
   - Use repository functions exclusively
   - Estimated effort: 4-6 hours

2. **Improve Type Safety** (P1)
   - Remove 8 instances of `any` types
   - Replace custom interfaces with Supabase-generated types
   - Estimated effort: 2-3 hours

3. **Add Integration Tests** (P1)
   - Test full call creation flow
   - Test call cancellation flow
   - Estimated effort: 6-8 hours
```

#### 5. Long-Term Considerations (Roadmap)

```markdown
## Long-Term Improvements

1. **Performance Optimization** (P2)
   - Implement pagination for calls list (500+ records)
   - Add virtual scrolling for large datasets
   - Optimize database queries with indexes

2. **Error Boundary Implementation** (P2)
   - Add error boundaries to catch component failures
   - Provide user-friendly error messages
   - Track errors to PostHog

3. **Accessibility Audit** (P3)
   - Ensure keyboard navigation works
   - Add ARIA labels
   - Test with screen readers
```

#### 6. Next Steps

```markdown
## Recommended Next Steps

1. **Prioritize P0 issues** - Fix today
2. **Create tracking tickets** - For P1+ issues (see below)
3. **Schedule team review** - Discuss findings and approach
4. **Update documentation** - Reflect new patterns

### Create Tracking Tickets?

I can help create GitHub issues for the identified gaps. Would you like me to:
- ✅ Create issues for P0 items (3 issues)
- ✅ Create issues for P1 items (7 issues)
- ⏭️ Skip P2/P3 for now
```

---

### Phase 6: Interactive Follow-Up

**After delivering the report, I'll ask:**

#### 1. Deep Dive Options

```
Which area needs deeper investigation?

1. **Architecture** - Drill into specific violations
2. **Testing** - Generate test templates for missing tests
3. **Performance** - Analyze PostHog metrics in detail
4. **Security** - Check for vulnerabilities (exposed secrets, SQL injection)
5. **All of the above**
```

#### 2. Issue Creation Workflow

**IMPORTANT**: I will NEVER create GitHub issues without your explicit confirmation for each issue.

**Step 1: Offer to Create Issues**

```
I've identified 3 P0 gaps and 7 P1 gaps. Would you like me to create GitHub issues to track these?

Options:
- ✅ Yes, show me previews first
- ⏭️ No, I'll create them manually
```

**Step 2: Present Each Issue for Approval**

For each proposed issue, I'll use `AskUserQuestion` to show you:

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Issue Preview [1] of [10]

**Title**: [P0] CallItem.tsx - Zero test coverage

**Labels**: `p0`, `testing`, `frontend`, `calls`

**Body**:
## Problem
The `CallItem` component has no unit tests, integration tests, or Storybook stories, creating high risk of regressions.

## Impact
- Cannot safely refactor or modify component
- No visual regression testing
- Breaking changes go undetected until production

## Files Affected
- `app/(protected)/calls/components/CallItem.tsx` (200 lines, high complexity)

## Action Items
- [ ] Create `CallItem.test.tsx` with factory function pattern
- [ ] Test loading states, user interactions, SWR data fetching
- [ ] Test error handling and edge cases
- [ ] Achieve 80%+ coverage

## References
- Audit Report: `audit-report-calls-2025-01-13.md`
- Testing Guide: `docs/TESTING-BEST-PRACTICES.md`
- Example Test: `app/_shared/modules/kpi/components/__tests__/AnalyticsKPI.test.tsx`

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Create this issue in GitHub?

Options:
- ✅ Yes, create this issue
- ✏️ Edit first (tell me what to change)
- ⏭️ Skip this one
- 🛑 Stop - cancel all remaining
```

**Step 3: Create Issue (Only After Approval)**

If you approve, I'll create the issue and show you:

```
✅ Created: Issue #123 - [P0] Zero test coverage for CallItem.tsx
Link: https://github.com/[YOUR_ORG]/[YOUR_REPO]/issues/123
```

**Step 4: Summary**

```
✅ GitHub Issue Creation Complete

Created 3 issues:
- #123: [P0] Zero test coverage for CallItem.tsx
- #124: [P0] Missing revalidatePath() in cancelCallAction
- #125: [P0] Production errors in /calls/create

Skipped 1 issue:
- [P2] Extract magic numbers to constants (you chose to skip)

All issue links saved in audit report: `audit-report-calls-2025-01-13.md`
```

#### 3. Export Options

```
Would you like me to:

1. **Export audit report** - Save as Markdown file in `docs/audits/`
2. **Generate test templates** - Scaffolded test files for missing coverage
3. **Create migration plan** - Step-by-step guide for fixing issues
4. **Audit related components** - Continue with connected routes/components
5. **All of the above**
```

---

## Documentation References

I will reference these key docs during the audit:

- **Frontend Best Practices**: `docs/FE-BEST-PRACTICES.md`
- **Testing Best Practices**: `docs/TESTING-BEST-PRACTICES.md`
- **Repository Patterns**: `app/_shared/repositories/CLAUDE.md`
- **CLAUDE.md**: Root-level guidance for the entire codebase

---

## Usage Examples

```bash
# Audit a specific route
/audit app/(protected)/calls

# Audit a specific component
/audit app/(protected)/calls/components/CallItem.tsx

# Audit entire protected routes
/audit app/(protected)

# Audit shared repositories
/audit app/_shared/repositories

# Audit specific feature area
/audit app/(protected)/scheduler

# Audit with context (in your message)
/audit app/(protected)/dashboard
# "I'm seeing slow load times and errors in production. Focus on performance and reliability."
```

---

## Principles

1. **Conversational & Adaptive**: I'll ask clarifying questions rather than make assumptions
2. **Read-Only Analysis**: All audit analysis uses read-only operations
3. **Explicit Approval for Actions**: Issue creation requires your approval for EACH item
4. **Context-Aware**: I'll reference team docs and coding standards
5. **Actionable**: Findings include specific recommendations with line numbers and code examples
6. **Prioritized**: Issues are ranked by impact and effort (P0/P1/P2/P3)
7. **Graceful Degradation**: Audit continues even if PostHog MCP isn't available

---

## Safety Guarantees

- ✅ No issues created without your explicit "Yes" approval
- ✅ Full preview shown before any write operation
- ✅ Can edit, skip, or stop at any time
- ✅ All operations logged in audit report for reference
- ✅ Read-only analysis - no code changes during audit

---

## Notes

- Audit analysis is completely **read-only** - no code changes, no commits
- GitHub issue creation is **OPTIONAL** and requires explicit approval for each issue
- PostHog MCP connection is **optional** but provides richer production insights
- The audit adapts based on your responses and available tools
- All findings reference **specific files and line numbers**
- Recommendations align with **team standards and best practices**
- You can **stop issue creation at any time** during the process

---

**Ready to start? I'll begin by checking PostHog MCP and asking about your audit goals.**
