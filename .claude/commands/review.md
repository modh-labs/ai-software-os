---
description: Review recent code changes against your project's coding standards and patterns
allowed-tools: Read, Grep, Glob, Bash
---

# Code Review Command

Review recent code changes for pattern compliance and best practices.

## What This Command Does

1. **Identifies changes** - Uses `git diff` to see what's been modified
2. **Checks patterns** - Verifies compliance with codebase standards
3. **Reports issues** - Provides actionable feedback by severity

## Review Process

### Step 1: Get Recent Changes

```bash
git diff --name-only HEAD~5
```

Or if working on a branch:
```bash
git diff --name-only main...HEAD
```

### Step 2: Check Each Modified File

For each changed file, verify compliance with these patterns:

#### Repository Files (`*.repository.ts`)
- [ ] Uses `select(*)` not column picking
- [ ] Accepts `SupabaseClient` as first parameter
- [ ] Uses generated types from `database.types.ts`
- [ ] Does NOT manually filter by `organization_id`
- [ ] Uses Pino logger, not console.log

#### Server Actions (`actions.ts`)
- [ ] Has `"use server"` directive
- [ ] Uses repository functions (no direct Supabase)
- [ ] Calls `revalidatePath()` after mutations
- [ ] Returns `{ success, data/error }` structure
- [ ] Uses Pino logger

#### React Components (`*.tsx`)
- [ ] Uses shadcn/ui components, no raw HTML
- [ ] Uses CSS variables, no hardcoded colors
- [ ] Sheet components use single toggle handler
- [ ] DataGrid uses shadcn themes
- [ ] Has `"use client"` only when needed

#### Database Files (`*.sql`)
- [ ] Tables have `organization_id`
- [ ] RLS is enabled
- [ ] Org isolation policy exists

### Step 3: Report Findings

Organize issues by severity:

## Output Format

```markdown
# Code Review: [date]

## Summary
- Files reviewed: X
- Critical issues: X
- Warnings: X
- Suggestions: X

## Critical Issues (MUST FIX)

### [File: path/to/file.ts]
- **Line XX**: [Issue description]
  - **Pattern violated**: [Which pattern]
  - **Fix**: [How to fix]

## Warnings (SHOULD FIX)

[Similar format]

## Suggestions (CONSIDER)

[Similar format]

## Files Reviewed
- path/to/file1.ts ✅ / ⚠️ / ❌
- path/to/file2.tsx ✅ / ⚠️ / ❌
```

## Quick Pattern Reference

| Pattern | Correct | Wrong |
|---------|---------|-------|
| Select | `select(*)` | `select("id, name")` |
| Supabase in actions | Repository | `supabase.from()` |
| After mutation | `revalidatePath()` | (skip) |
| Colors | `bg-primary` | `bg-blue-500` |
| Button | `<Button>` | `<button>` |
| Sheet toggle | `onOpenChange={toggle}` | separate handlers |

## Reference Documentation

For detailed patterns, see:
- `.claude/skills/repository-pattern/SKILL.md`
- `.claude/skills/server-action/SKILL.md`
- `.claude/skills/component-creation/SKILL.md`
- `CLAUDE.md` in project root
