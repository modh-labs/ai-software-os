# Development Guide

## Quick Reference

```bash
# Common commands (customize for your project)
dev                      # Development server
build                    # Build for production
fix                      # Auto-fix lint/format issues
test                     # Test in watch mode
test:ci                  # Run tests once (CI)
ci                       # Full check (lint + typecheck + test)
typecheck                # Type check all files
```

---

## AI Engineering System

This project uses a four-layer AI-assisted development system:

| Layer | Location | Purpose |
|-------|----------|---------|
| **Skills** (21) | `.claude/skills/` | Auto-enforced patterns |
| **Agents** (4) | `.claude/agents/` | Specialized task delegation |
| **Commands** (6) | `.claude/commands/` | Workflow shortcuts |
| **Hooks** (1) | `.claude/hooks/` | Deterministic pattern enforcement |

See `.claude/README.md` for full architecture documentation.

---

## Critical Rules

### DO

- Use repositories for ALL database queries (`@your-org/repositories`)
- Use Server Actions for ALL mutations (colocate in route's `actions.ts`)
- Use types from `@your-org/database-types` (never custom interfaces)
- Always `select *` in Supabase queries (never pick columns)
- Call `revalidatePath()` after every mutation
- Use shadcn/ui components — never raw HTML elements
- Colocate components with routes, share only when used by 3+ routes
- Trust RLS for org isolation — don't duplicate permission checks
- Create `error.tsx` for every route
- Create Zod validation schemas before server actions

### DON'T

- Use `supabase.from()` directly in Server Actions/Components
- Create custom interfaces for database types
- Use React Query for Supabase data (use Server Actions + repositories)
- Use `any` types
- Import components from other routes (cross-route imports)
- Skip cache invalidation after mutations

---

## Documentation

- Quick patterns: `guides/patterns/QUICK-REFERENCE.md`
- Repository pattern: `guides/patterns/repository-pattern.md`
- Server actions: `guides/patterns/server-actions.md`
- Testing: `guides/patterns/testing.md`
- Observability: `guides/standards/observability.md`
- Security: `guides/security/overview.md`
- CI/CD: `.github/CLAUDE.md`
