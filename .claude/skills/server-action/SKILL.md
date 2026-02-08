---
name: server-action
description: Create server actions following your project's established patterns. Use when writing mutations, form submissions, data operations, or cache invalidation. Enforces repository usage, revalidatePath, structured returns, and route colocation.
allowed-tools: Read, Grep, Glob
---

# Server Action Skill

## When This Skill Activates

This skill automatically activates when you:
- Create or modify server actions (`actions.ts`)
- Write mutation logic (create, update, delete)
- Handle form submissions
- Need to invalidate cache after data changes

## Core Rules (MUST Follow)

### 1. Always Use Repository Functions

**NEVER use direct Supabase queries** in server actions:

```typescript
// ❌ WRONG - Direct Supabase in server action
export async function createCallAction(data: CreateCallInput) {
  const supabase = await createClient();
  const { data: call, error } = await supabase
    .from("calls")
    .insert(data)
    .select("*")
    .single();
  // ...
}

// ✅ CORRECT - Use repository
import { createCall } from "@/app/_shared/repositories/calls.repository";

export async function createCallAction(data: CreateCallInput) {
  const supabase = await createClient();
  const call = await createCall(supabase, data);
  // ...
}
```

**Why**: Repository layer provides consistent query patterns, type safety, and single source of truth.

### 2. Always Call revalidatePath() After Mutations

**EVERY mutation MUST invalidate the cache**:

```typescript
// ❌ WRONG - Missing cache invalidation
export async function updateCallAction(id: string, data: UpdateCallInput) {
  const supabase = await createClient();
  await updateCall(supabase, id, data);
  return { success: true };
  // User sees stale data!
}

// ✅ CORRECT - Invalidate cache
import { revalidatePath } from "next/cache";

export async function updateCallAction(id: string, data: UpdateCallInput) {
  const supabase = await createClient();
  await updateCall(supabase, id, data);

  revalidatePath("/calls");           // Invalidate list
  revalidatePath(`/calls/${id}`);     // Invalidate detail
  revalidatePath("/dashboard");        // Related pages

  return { success: true };
}
```

### 3. Return Structured Response

**ALL server actions MUST return `{ success, data?, error? }`**:

```typescript
// ❌ WRONG - Throwing or returning raw data
export async function getCallAction(id: string) {
  const call = await getCallById(id);
  if (!call) throw new Error("Not found");
  return call;
}

// ✅ CORRECT - Structured response
export async function getCallAction(id: string) {
  try {
    const call = await getCallById(id);
    if (!call) {
      return { success: false, error: "Call not found" };
    }
    return { success: true, data: call };
  } catch (error) {
    logger.error({ error, id }, "Failed to fetch call");
    return { success: false, error: "Failed to fetch call" };
  }
}
```

### 4. Colocate with Route

**Server actions belong in the route's `actions.ts`**, not in shared folders:

```
app/(protected)/calls/
├── page.tsx
├── actions.ts          # ✅ Server actions here
└── components/
    └── CallForm.tsx    # Uses actions from ../actions.ts

# ❌ WRONG - Don't put in shared
app/_shared/actions/calls.ts
```

### 5. Use Module Logger

**NEVER use console.log**:

```typescript
import { createModuleLogger } from "@/app/_shared/lib/logger";
const logger = createModuleLogger("calls-actions");

// ✅ Correct
logger.info({ callId }, "Creating call");
logger.error({ error }, "Failed to create call");

// ❌ Wrong
console.log("Creating call...");
console.error(error);
```

### 6. Add "use server" Directive

**MUST be at the top of file or function**:

```typescript
// ✅ File-level (preferred)
"use server";

import { ... } from "...";

export async function myAction() { ... }

// ✅ Function-level (when mixing with client code)
export async function myAction() {
  "use server";
  // ...
}
```

## Server Action Template

Full CRUD template with client component usage: `references/server-action-template.ts`

## Reference Implementation

See canonical examples at:
- `app/(protected)/calls/actions.ts` - Full server actions implementation
- `app/(protected)/scheduler/actions/` - Multiple action files for complex routes

## Common Mistakes to Avoid

1. **Direct Supabase in actions** - Always use repository
2. **Missing revalidatePath()** - Users see stale data
3. **Throwing errors** - Return structured `{ success, error }`
4. **Wrong location** - Keep in route's actions.ts
5. **Using console.log** - Use Pino logger
6. **Missing "use server"** - Required directive

## Quick Reference

| Pattern | Correct | Wrong |
|---------|---------|-------|
| Data access | Repository functions | `supabase.from()` |
| After mutation | `revalidatePath()` | (nothing) |
| Response | `{ success, data/error }` | throw / raw data |
| Location | `route/actions.ts` | `_shared/actions/` |
| Logging | `logger.info()` | `console.log()` |
| Directive | `"use server"` at top | (missing) |
