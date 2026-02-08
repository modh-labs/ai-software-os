---
description: Guide through schema-first database migration workflow
argument-hint: [migration_name]
allowed-tools: Read, Edit, Bash, Grep, Glob
---

# Create Migration Command

Guide through the schema-first database migration workflow.

**Migration Name**: `$ARGUMENTS`

## Workflow Overview

```
1. Update domain.sql  →  2. Run db diff  →  3. Review  →  4. Apply  →  5. Generate types
```

## Step 1: Identify the Domain

First, let me check which domain file to update:

```bash
ls supabase/schemas/
```

Domain files:
- `booking.sql` - Booking links, configurations
- `calls.sql` - Calls, outcomes, recordings
- `leads.sql` - Leads, contacts
- `organizations.sql` - Organizations, settings
- `payments.sql` - Stripe payments
- `users.sql` - Users, team members

## Step 2: Describe Your Change

I'll ask what change you want to make:

1. **Add column to existing table** - Which table? What column? Type? Nullable?
2. **Create new table** - What's it called? What columns?
3. **Modify column** - Which column? What change?
4. **Add index** - Which table/column(s)?
5. **Add RLS policy** - Which table? What policy?

## Step 3: Update Domain SQL

I'll update the appropriate `supabase/schemas/*.sql` file with your changes.

### For New Tables

```sql
CREATE TABLE table_name (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id text NOT NULL,
  -- your columns here
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_table_org ON table_name(organization_id);

ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON table_name
  FOR ALL USING (organization_id = (auth.jwt() ->> 'org_id')::text);
```

### For New Columns

```sql
ALTER TABLE existing_table ADD COLUMN column_name type;
```

## Step 4: Generate Migration

```bash
bun run supabase db diff -f $ARGUMENTS --linked
```

## Step 5: Review Generated SQL

```bash
cat supabase/migrations/*_$ARGUMENTS.sql
```

I'll verify:
- [ ] Correct table/column definitions
- [ ] RLS policies included
- [ ] No unintended changes
- [ ] Safe migration patterns

## Step 6: Apply Migration

```bash
bun run supabase db push --linked
```

## Step 7: Generate Types

```bash
npm run db:types
```

## Step 8: Update Repository (if needed)

If you added a new table, you may need to create a repository file:
- Location: `app/_shared/repositories/table-name.repository.ts`
- Follow patterns in `.claude/skills/repository-pattern/SKILL.md`

## Checklist

- [ ] Domain SQL file updated
- [ ] Migration generated with `db diff`
- [ ] Migration reviewed for correctness
- [ ] Migration applied with `db push`
- [ ] Types regenerated with `db:types`
- [ ] Repository created/updated if needed
- [ ] All files committed together

## Common Patterns

### Adding Nullable Column (Safe)
```sql
ALTER TABLE users ADD COLUMN avatar_url text;
```

### Adding Column with Default (Safe)
```sql
ALTER TABLE users ADD COLUMN is_active boolean DEFAULT true;
```

### Adding NOT NULL Column (Multi-Step)
```sql
-- Step 1: Add nullable
ALTER TABLE users ADD COLUMN timezone text;
-- Run migration, backfill data
-- Step 2: Add constraint (separate migration)
ALTER TABLE users ALTER COLUMN timezone SET NOT NULL;
```
