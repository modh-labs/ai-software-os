---
name: route-architecture
description: Guide code organization, folder structure, and route architecture following your project's colocation patterns. Use when creating routes, deciding file placement, organizing imports, or discussing services vs repositories. Enforces 3+ routes threshold, actions folder pattern, and shared infrastructure conventions.
allowed-tools: Read, Grep, Glob, Edit, Write
---

# Route Architecture Skill

## When This Skill Activates

This skill automatically activates when you:
- Create new routes or features
- Decide where to place new code
- Organize components, actions, or types
- Discuss services vs repositories
- Work with `_shared/` directory

## Core Philosophy

**Colocation first, share when necessary.**

Code lives with the route that uses it until it needs to be shared. The threshold for sharing is **3+ routes** or **2 routes with clear expansion potential**.

## Directory Structure

```
app/
├── (protected)/           # Authenticated routes
│   └── [route]/           # Example: calls, leads, dashboard
│       ├── page.tsx       # Server Component (data fetching)
│       ├── actions.ts     # Server actions (1-2 actions)
│       ├── actions/       # Server actions folder (3+ actions)
│       │   ├── create-item.ts
│       │   └── delete-item.ts
│       ├── components/    # Route-specific components
│       ├── loading.tsx    # Skeleton (matches UI layout)
│       ├── error.tsx      # Error boundary with retry
│       └── CLAUDE.md      # Route documentation
│
├── (public)/              # Public routes
│
├── api/webhooks/          # ONLY for external webhooks
│
└── _shared/               # Shared code (3+ routes)
    ├── components/        # Shared UI components
    ├── lib/               # Utilities, clients
    ├── repositories/      # Data access layer
    ├── services/          # Business logic
    ├── types/             # TypeScript types
    └── validation/        # Zod schemas
```

## When to Use What

### Repository vs Service vs Action

| Layer | Purpose | Location | When to Use |
|-------|---------|----------|-------------|
| **Repository** | Database CRUD | `_shared/repositories/` | ALL database operations |
| **Service** | Business logic | `_shared/services/` | Complex multi-step operations |
| **Server Action** | Entry point | Route `actions.ts` | User-triggered mutations |

```
User Click → Server Action → Service (if complex) → Repository → Database
```

### Decision Tree

```
"Where should this code live?"

Is it a database query?
  → _shared/repositories/[entity].repository.ts

Is it complex business logic (multi-step, external services)?
  → _shared/services/[domain].service.ts

Is it a user-triggered mutation or fetch?
  → Route's actions.ts or actions/

Is it a UI component?
  → Used by 1-2 routes? → Route's components/
  → Used by 3+ routes? → _shared/components/

Is it a type definition?
  → Route-specific? → Route's types.ts
  → Shared across routes? → _shared/types/

Is it validation?
  → _shared/validation/[route].schema.ts
```

## Full Pattern Examples

For complete code examples of all patterns (repository, service, action, component, types/validation, anti-patterns), see `references/route-patterns.md`.

## Quick Reference

| What | Where | Rule |
|------|-------|------|
| Database queries | `_shared/repositories/` | Always |
| Complex business logic | `_shared/services/` | 3+ steps or external services |
| User mutations/fetches | Route `actions.ts` or `actions/` | Colocated with route |
| Route components | Route `components/` | Default |
| Shared components | `_shared/components/` | 3+ routes threshold |
| Route-specific types | Route `types.ts` | Single route use |
| Shared types | `_shared/types/` | Multiple route use |
| Validation schemas | `_shared/validation/` | Always |

## Checklist for New Routes

- [ ] `page.tsx` - Server Component for data fetching
- [ ] `actions.ts` or `actions/` - Server actions
- [ ] `components/` - Route-specific components
- [ ] `loading.tsx` - Skeleton matching UI layout
- [ ] `error.tsx` - Error boundary using `PageErrorBoundary` from `@/app/_shared/components/PageErrorBoundary`
- [ ] `CLAUDE.md` - Route documentation
- [ ] Repository in `_shared/repositories/` if new entity
- [ ] Validation schema in `_shared/validation/`

## Reference

For complete audit checklist: `@docs/patterns/route-audit.md`
