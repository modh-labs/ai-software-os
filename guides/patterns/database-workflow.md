---
title: "Database Workflow: Schema-First Migrations"
description: "Schema-first workflow for database changes with diff-based migrations."
tags: ["database", "supabase", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# Database Workflow

## Quick Reference

```bash
npm run db:types          # Generate TypeScript types from schema
npm run db:studio         # Open Supabase Studio (GUI)
npm run db:push           # Push migrations to remote
npm run db:reset          # Reset local database (destructive)
```

---

## Schema-First Workflow (REQUIRED)

**NEVER manually create migration files.** Always use `supabase db diff`:

### Step-by-Step Process

1. **Modify schema** in `supabase/schemas/` using proper SQL format
2. **Generate migration from schema changes:**
   ```bash
   bun run supabase db diff -f migration_name --linked
   ```
3. **Review the generated migration** in `supabase/migrations/TIMESTAMP_migration_name.sql`
4. **Apply the migration to remote:**
   ```bash
   bun run db:push
   ```
5. **Regenerate types (if schema changed):**
   ```bash
   npm run db:types
   ```

### Example Workflow

```bash
# 1. Edit supabase/schemas/users.sql

# 2. Generate migration automatically
bun run supabase db diff -f add_email_column --linked

# 3. Review the generated migration file
cat supabase/migrations/20251115120000_add_email_column.sql

# 4. Apply it
bun run db:push

# 5. Regenerate types if needed
npm run db:types
```

---

## SQL Format Standards

All SQL in `supabase/schemas/*.sql` MUST follow this format:

### Correct Format

```sql
CREATE TABLE IF NOT EXISTS "public"."users" (
  "id" text NOT NULL PRIMARY KEY,
  "name" text NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS users_created_at_idx ON "public"."users" ("created_at");

ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_read" ON "public"."users"
  FOR SELECT
  TO authenticated
  USING ("id" = auth.uid());
```

### Key Rules

1. **Use UPPERCASE keywords** - `CREATE TABLE`, `NOT NULL`, `PRIMARY KEY`
2. **Quote all identifiers** - `"public"."table_name"` and `"column_name"`
3. **Use `IF NOT EXISTS`** - idempotent schema definitions
4. **Quote schema prefix** - Always: `"public"."table_name"`
5. **Format constraints properly** - `FOREIGN KEY ("column") REFERENCES "public"."other_table"("id")`

### Wrong Format

```sql
-- lowercase, missing quotes, no schema prefix
create table users (
  id text primary key,
  name text
);
alter table users add column email text;  -- inconsistent
```

---

## RLS Policy Patterns

### Organization Isolation (Standard)

```sql
CREATE POLICY "organization_isolation" ON table_name
FOR ALL USING (
  organization_id = (auth.jwt() ->> 'org_id')::text
);
```

### Role-Based Access

```sql
CREATE POLICY "admin_full_access" ON table_name
FOR ALL USING (
  organization_id = (auth.jwt() ->> 'org_id')::text
  AND (auth.jwt() ->> 'org_role') = 'org:admin'
);
```

---

## Adding a Column

1. **Update schema in Supabase Studio** - Add column `cancellation_reason` (text, nullable) to `calls` table
2. **Generate migration:**
   ```bash
   supabase db pull
   # Creates: supabase/migrations/TIMESTAMP_add_cancellation_reason.sql
   ```
3. **Test locally:**
   ```bash
   npm run db:reset
   ```
4. **Regenerate types:**
   ```bash
   npm run db:types
   ```
5. **Commit together:**
   ```bash
   git add supabase/config.toml supabase/migrations/TIMESTAMP_*.sql database.types.ts
   git commit -m "feat(db): add cancellation_reason to calls table"
   ```
6. **Deploy:**
   ```bash
   npm run db:push
   ```

---

## Creating a New Table

1. **Define in Supabase Studio:**
   - Create table `feedback` with columns: `id`, `organization_id`, `call_id`, `content`, `created_at`
   - Enable RLS
   - Add policy: `CREATE POLICY "org_isolation" ON feedback FOR ALL USING (organization_id = (auth.jwt() ->> 'org_id')::text)`

2. **Follow same workflow as adding column**

---

## Safe Migration Patterns

```sql
-- Safe: Add nullable column
ALTER TABLE users ADD COLUMN avatar_url text;

-- Dangerous: Rename column (breaks production)
ALTER TABLE users RENAME COLUMN name TO full_name;

-- Safe: Multi-step rename
-- Migration 1: Add new column
ALTER TABLE users ADD COLUMN full_name text;
-- Migration 2: Backfill + update code
-- Migration 3: Drop old column
```

---

## Critical Rules

### DO

- Always use schema-first workflow
- Generate migrations with `supabase db pull` (not manual SQL)
- Test locally with `npm run db:reset` before deploying
- Regenerate TypeScript types after schema changes
- Commit schema, migrations, and types together
- Use zero-downtime patterns for breaking changes

### DON'T

- Write migrations manually
- Push migrations without updating types
- Forget to update TypeScript types after schema changes
- Push migrations without testing locally first
- Make breaking changes without multi-step migrations
- Skip CI checks with `--no-verify`
