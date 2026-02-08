---
title: "Quick Reference: Engineering Patterns Cheat Sheet"
description: "Cheat sheet for common engineering patterns."
tags: ["patterns", "architecture"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# Patterns Quick Reference

## CI Pipeline
- **Fast mode:** `bun run ci` - lint + typecheck + tests (~5s)
- **Full mode:** `bun run ci:build` - above + build verification (~30s)
- **Local:** `bun run ci:local` - interactive mode
- **Optimization:** TypeScript incremental builds + Turbo remote caching
- **Philosophy:** Fast by default, full verification optional (Vercel builds anyway)

See `docs/patterns/ci-optimization.md` for performance tuning and troubleshooting.

---

## Repositories
- **Rule:** ALL DB queries go through repositories (`app/_shared/repositories/`)
- **Never:** `supabase.from()` directly in Server Actions/Components
- **Always:** `select *` for type safety
- **Types:** Use `Database["public"]["Tables"]["name"]["Row"]` (generated types only)
- **Trust:** RLS for org isolation - don't duplicate permission checks

**Standard pattern:**
```typescript
export async function listCalls(supabase: SupabaseClient<Database>) {
  const { data, error } = await supabase
    .from('calls')
    .select('*')
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data || [];
}
```

See `docs/patterns/repository-pattern.md` for full details and examples.

---

## Server Actions
- **Use for:** Mutations, form submissions, complex server logic
- **NOT for:** External webhooks (use API routes instead)
- **Pattern:** Colocate in route's `actions.ts`, use repositories, call `revalidatePath()`
- **Benefits:** Direct function calls, type-safe, secrets stay server-side

**Standard pattern:**
```typescript
'use server'
export async function createCall(data: CreateCallInput) {
  const supabase = await createClient();
  const result = await createCall(supabase, data);
  revalidatePath('/calls');
  return { success: true, data: result };
}
```

See `docs/patterns/server-actions.md` for full details and common mistakes.

---

## UI Components
- **ALWAYS:** Use `@/components/ui/` (shadcn/ui) - NEVER raw HTML
- **Organization:** Route-specific in route dir, shared (3+ routes) in `app/_shared/components/`
- **Styling:** Use semantic tokens (`bg-primary`), not hardcoded colors
- **Detail Views:** Use Sheet with single toggle handler + `useEntityFiltersSync` for URL sync

**Key rule:** If shadcn component exists, use it. Never `<button>`, `<input>`, `<textarea>`.

See `docs/patterns/ui-components.md` for full details and Sheet pattern.

---

## Architecture
```
app/(protected)/[route]/
  ├── components/       # Route-specific only
  ├── actions.ts        # Server mutations (colocated)
  ├── loading.tsx
  ├── error.tsx
  └── page.tsx

app/_shared/           # Shared code (3+ routes)
  ├── components/
  ├── repositories/     # Data access layer
  ├── lib/
  └── validation/       # Zod schemas
```

**Import rules:**
- Within route: relative imports
- Shared: absolute imports from `@/`
- NEVER: cross-route imports

---

## Multi-Tenant
- Clerk handles auth + orgs
- Supabase RLS enforces org isolation at DB level
- Service role (webhooks only) bypasses RLS

---

## Observability
- **Logging:** Use `logger` from `@/app/_shared/lib/sentry-logger`
- **Auto-injected:** `user_id`, `org_id`, `trace_id`, `span_id`
- **AI Agents:** Always pass `tracingOptions: getTracingOptionsForMastra()` for trace continuity
- **Tags:** Categorical data (`setTag`) | **Metrics:** Numeric data (`metrics.distribution`)

**Standard pattern:**
```typescript
import { logger } from "@/app/_shared/lib/sentry-logger";
import { getTracingOptionsForMastra } from "@/app/_shared/lib/tracing/otel-context";

logger.info("Processing call", { call_id: callId });

const result = await runComprehensiveAnalysis({
  transcript,
  tracingOptions: getTracingOptionsForMastra(),
});
```

See `docs/standards/observability.md` and `docs/patterns/tracing-and-instrumentation.md` for full details.

---

For complete documentation:
- Repositories → `docs/patterns/repository-pattern.md`
- Server Actions → `docs/patterns/server-actions.md`
- UI Components → `docs/patterns/ui-components.md`
- Testing → `docs/patterns/testing.md`
- Observability → `docs/standards/observability.md`
- Tracing → `docs/patterns/tracing-and-instrumentation.md`
