---
name: repository-pattern
description: Ensure all database access follows the your repository pattern. Use when writing database queries, creating repositories, adding CRUD operations, select queries, or data access code. Enforces select *, SupabaseClient parameter, generated types, and RLS reliance.
allowed-tools: Read, Grep, Glob
---

# Repository Pattern Skill

## When This Skill Activates

This skill automatically activates when you:
- Write or modify repository files (`*.repository.ts`)
- Create database queries using Supabase
- Discuss data access patterns
- Need to add CRUD operations for an entity

## Core Rules (MUST Follow)

### 1. Always Use `select *`

**NEVER pick specific columns.** Always use `select *` for the main table and all relations.

```typescript
// ❌ WRONG - Column picking
.select("id, title, scheduled_at")
.select(`
  id, title,
  lead:leads(id, full_name, email)
`)

// ✅ CORRECT - Always select *
.select("*")
.select(`
  *,
  lead:leads!calls_lead_id_fkey(*),
  closer:users!calls_closer_id_fkey(*)
`)
```

**Why**: Types automatically stay in sync with schema. No maintenance burden.

### 2. Accept SupabaseClient as First Parameter

Every repository function MUST accept the Supabase client as its first parameter:

```typescript
// ❌ WRONG - Creating client inside function
export async function getCalls() {
  const supabase = await createClient();
  // ...
}

// ✅ CORRECT - Accept client as parameter
export async function getCalls(
  supabase: Awaited<ReturnType<typeof createClient>>,
  filters?: CallFilters
) {
  // ...
}
```

**Why**: Allows both authenticated and service role clients. Enables testing with mocks.

### 3. Use Generated Types from database.types.ts

**NEVER create custom interfaces** for database entities:

```typescript
// ❌ WRONG - Custom interface
interface Call {
  id: string;
  title: string;
  scheduled_at: string;
  // ...manually defining fields
}

// ✅ CORRECT - Use generated types
import type { Database } from "@/app/_shared/lib/supabase/database.types";
type Call = Database["public"]["Tables"]["calls"]["Row"];
type CallInsert = Database["public"]["Tables"]["calls"]["Insert"];
type CallUpdate = Database["public"]["Tables"]["calls"]["Update"];
```

### 4. Let RLS Handle organization_id

**NEVER pass organization_id** in queries. RLS policies read it from the JWT automatically:

```typescript
// ❌ WRONG - Passing org_id manually
.eq("organization_id", orgId)

// ✅ CORRECT - RLS handles it automatically
// Just query the table, RLS filters by org_id from JWT
const { data } = await supabase.from("calls").select("*");
```

### 5. Use Module Logger

Always use Pino logger, never console.log:

```typescript
import { createModuleLogger } from "@/app/_shared/lib/logger";
const logger = createModuleLogger("calls-repository");

// ✅ Use logger
logger.info({ callId }, "Fetching call details");
logger.error({ error }, "Failed to fetch call");

// ❌ Never use console
console.log("Fetching call...");
```

## Repository File Template

```typescript
"use server";

import type { QueryData } from "@supabase/supabase-js";
import { createModuleLogger } from "@/app/_shared/lib/logger";
import type { Database } from "@/app/_shared/lib/supabase/database.types";
import { createClient } from "@/app/_shared/lib/supabase/server";

const logger = createModuleLogger("entity-repository");

// Type aliases from generated types
type Entity = Database["public"]["Tables"]["entities"]["Row"];
type EntityInsert = Database["public"]["Tables"]["entities"]["Insert"];
type EntityUpdate = Database["public"]["Tables"]["entities"]["Update"];

/**
 * Query builder with standard relations
 */
function buildEntityQueryBuilder(
  supabase: Awaited<ReturnType<typeof createClient>>
) {
  return supabase.from("entities").select(`
    *,
    related:related_table!entities_related_id_fkey(*)
  `);
}

// Type inference from query builder
export type EntityWithRelations = QueryData<
  ReturnType<typeof buildEntityQueryBuilder>
>[number];

/**
 * List all entities (RLS filters by org)
 */
export async function getEntities(
  supabase: Awaited<ReturnType<typeof createClient>>,
  filters?: { status?: string }
): Promise<EntityWithRelations[]> {
  let query = buildEntityQueryBuilder(supabase)
    .order("created_at", { ascending: false });

  if (filters?.status) {
    query = query.eq("status", filters.status);
  }

  const { data, error } = await query;
  if (error) {
    logger.error({ error }, "Failed to fetch entities");
    throw error;
  }
  return data || [];
}

/**
 * Get single entity by ID
 */
export async function getEntityById(
  supabase: Awaited<ReturnType<typeof createClient>>,
  id: string
): Promise<EntityWithRelations | null> {
  const { data, error } = await buildEntityQueryBuilder(supabase)
    .eq("id", id)
    .single();

  if (error) {
    logger.error({ error, id }, "Failed to fetch entity");
    throw error;
  }
  return data;
}

/**
 * Create new entity
 */
export async function createEntity(
  supabase: Awaited<ReturnType<typeof createClient>>,
  input: EntityInsert
): Promise<Entity> {
  const { data, error } = await supabase
    .from("entities")
    .insert(input)
    .select("*")
    .single();

  if (error) {
    logger.error({ error }, "Failed to create entity");
    throw error;
  }
  return data;
}

/**
 * Update existing entity
 */
export async function updateEntity(
  supabase: Awaited<ReturnType<typeof createClient>>,
  id: string,
  updates: EntityUpdate
): Promise<Entity> {
  const { data, error } = await supabase
    .from("entities")
    .update(updates)
    .eq("id", id)
    .select("*")
    .single();

  if (error) {
    logger.error({ error, id }, "Failed to update entity");
    throw error;
  }
  return data;
}

/**
 * Delete entity
 */
export async function deleteEntity(
  supabase: Awaited<ReturnType<typeof createClient>>,
  id: string
): Promise<void> {
  const { error } = await supabase
    .from("entities")
    .delete()
    .eq("id", id);

  if (error) {
    logger.error({ error, id }, "Failed to delete entity");
    throw error;
  }
}
```

## Reference Implementation

See the canonical example at:
- `app/_shared/repositories/calls.repository.ts` - Full repository with query builder
- `app/_shared/repositories/CLAUDE.md` - Complete pattern documentation

## Common Mistakes to Avoid

1. **Column picking** - Always use `select *`
2. **Creating client inside function** - Accept as parameter
3. **Manual type definitions** - Use generated types
4. **Passing organization_id** - Let RLS handle it
5. **Using console.log** - Use Pino logger
6. **Forgetting `"use server"`** - Required at top of file

## Quick Reference

| Pattern | Correct | Wrong |
|---------|---------|-------|
| Select | `select(*)` | `select("id, name")` |
| Client | Parameter | `createClient()` inside |
| Types | `Database["public"]["Tables"]["x"]["Row"]` | `interface X {}` |
| Org ID | (let RLS handle) | `.eq("organization_id", x)` |
| Logging | `logger.info()` | `console.log()` |
