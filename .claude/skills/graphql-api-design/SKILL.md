---
name: graphql-api-design
description: Enforce Shopify graph-first design for your project's Partner API. Use when adding GraphQL types, mutations, REST endpoints, DataLoaders, or working with the API app. Enforces navigable relationships, semantic types, Relay pagination, and repository pattern.
allowed-tools: Read, Grep, Glob
---

# GraphQL API Design Skill

## When This Skill Activates

This skill automatically activates when you:
- Add or modify GraphQL types, queries, or mutations
- Work with REST endpoints in the Partner API
- Create DataLoaders for N+1 prevention
- Discuss API design patterns or schema changes

## Stack

- **Hono**: HTTP framework (REST + GraphQL on same instance)
- **graphql-yoga**: Schema-first GraphQL server
- **DataLoader**: N+1 query prevention
- **Supabase**: PostgreSQL with RLS

## Core Rules (MUST Follow)

### 1. Navigable Relationships, Not IDs

```graphql
# ❌ WRONG - Exposing IDs
type Lead {
  call_ids: [String!]!
}

# ✅ CORRECT - Navigable graph
type Lead {
  calls(first: Int): CallConnection!
}
```

### 2. Semantic Types, Not Primitives

```graphql
# ❌ WRONG
type Lead {
  revenue: Float
  createdAt: String
  email: String
}

# ✅ CORRECT
type Lead {
  totalRevenue: Money!
  createdAt: DateTime!
  email: Email!
}
```

### 3. Hide Internals

Never expose: `organization_id`, `visitor_id`, snake_case fields, join tables, or internal IDs.

### 4. Business Logic Fields

```graphql
# ✅ Provide computed/business fields
type Lead {
  totalRevenue: Money!
  conversionRate: Float!
  hasScheduledCall: Boolean!
}
```

### 5. Relay Pagination (`Connection/Edge` Pattern)

```graphql
type LeadConnection {
  edges: [LeadEdge!]!
  pageInfo: PageInfo!
}

type LeadEdge {
  node: Lead!
  cursor: String!
}
```

### 6. Prefix Mutations by Entity

```graphql
# ❌ WRONG - Generic CRUD
mutation { updateLead(id: ID!, input: LeadInput!): Lead! }

# ✅ CORRECT - Entity-prefixed
mutation { leadUpdate(id: ID!, input: LeadUpdateInput!): LeadUpdatePayload! }
mutation { leadChangeStatus(id: ID!, status: LeadStatus!): LeadChangeStatusPayload! }
```

### 7. Return `userErrors` in Mutations

```graphql
type LeadUpdatePayload {
  lead: Lead
  userErrors: [UserError!]!
}

type UserError {
  field: [String!]
  message: String!
}
```

Never throw exceptions from mutations.

### 8. DataLoader for N+1 Prevention

```typescript
const leadLoader = new DataLoader(async (ids) => {
  const { data } = await supabase.from("leads").select("*").in("id", ids);
  return ids.map((id) => data?.find((lead) => lead.id === id) || null);
});
```

### 9. Repository Pattern (Same as Web App)

```typescript
// ✅ Use @your-org/repositories for ALL database access
import { LeadsRepository } from "@your-org/repositories";
const lead = await LeadsRepository.getById(supabase, orgId, id);

// ❌ Direct Supabase in resolvers
const { data } = await supabase.from("leads").select("id, email")...
```

## Adding New Types (Checklist)

1. **Define type** in `graphql/types.ts`
2. **Create DataLoader** in `graphql/dataloaders.ts`
3. **Implement resolver** in `graphql/resolvers.ts` (transform DB → API)
4. **Add query/mutation** in `graphql/index.ts`
5. **Update schema** in `graphql/schema.graphql`
6. **Wire resolver** in `graphql/yoga-handler.ts`

## File Structure

```
apps/api/src/
├── graphql/
│   ├── index.ts         # Query/Mutation implementations
│   ├── yoga-handler.ts  # graphql-yoga server
│   ├── context.ts       # AsyncLocalStorage Hono context
│   ├── schema.graphql   # Schema (static, schema-first)
│   ├── types.ts         # TypeScript types for GraphQL
│   ├── resolvers.ts     # Field resolvers (transformLead, etc.)
│   └── dataloaders.ts   # N+1 prevention
├── resolvers/           # Business logic
├── routes/              # REST routes
└── middleware/           # Auth, rate limiting
```

## Anti-Patterns

```typescript
// ❌ Exposing database structure (snake_case, join tables)
// ❌ Generic CRUD mutations (updateLead instead of leadUpdate)
// ❌ Returning primitive types for domain concepts
// ❌ Throwing errors from mutations (use userErrors)
// ❌ Direct Supabase in resolvers (use repositories)
// ❌ Missing DataLoader (causes N+1 queries)
```

## Quick Reference

| Pattern | Correct | Wrong |
|---------|---------|-------|
| Relationships | `calls: CallConnection!` | `call_ids: [String!]!` |
| Types | `Money`, `DateTime`, `Email` | `Float`, `String` |
| Mutations | `leadUpdate` | `updateLead` |
| Errors | `userErrors: [UserError!]!` | `throw new Error()` |
| Data access | `@your-org/repositories` | `supabase.from()` |
| Lists | Relay `Connection/Edge` | Plain arrays |

## Reference

- Shopify GraphQL Tutorial: https://github.com/Shopify/graphql-design-tutorial
- graphql-yoga docs: https://the-guild.dev/graphql/yoga-server
- Full API guide: `apps/api/CLAUDE.md`
