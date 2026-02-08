# Example: Supabase + Next.js Setup

> Quick start for using the repository pattern and RLS with Supabase in a Next.js App Router project.

## What This Covers

- Repository pattern for type-safe database access
- Row Level Security (RLS) for multi-tenant isolation
- Server Actions with `revalidatePath()` cache invalidation
- Generated TypeScript types from your schema

## Relevant Skills

- `.claude/skills/repository-pattern/SKILL.md`
- `.claude/skills/server-action/SKILL.md`
- `.claude/skills/database-migration/SKILL.md`

## Relevant Guides

- `guides/patterns/repository-pattern.md`
- `guides/patterns/server-actions.md`
- `guides/patterns/database-workflow.md`
- `guides/standards/database.md`
- `guides/security/access-control.md`

## Quick Setup

1. Install Supabase CLI and create project
2. Copy `.claude/skills/repository-pattern/` into your project
3. Follow the repository pattern guide to create your first repository
4. Set up RLS policies per `guides/security/access-control.md`

## Key Patterns

```typescript
// Repository: always accept client, always select *
export async function getUsers(supabase: SupabaseClient) {
  const { data, error } = await supabase
    .from("users")
    .select("*");
  if (error) throw error;
  return data;
}

// Server Action: use repository, revalidate after mutation
"use server";
export async function createUser(input: UserInsert) {
  const supabase = await createClient();
  const user = await insertUser(supabase, input);
  revalidatePath("/users");
  return { success: true, data: user };
}
```
