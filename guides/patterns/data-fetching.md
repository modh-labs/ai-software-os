---
title: "Data Fetching: Server Components and Suspense"
description: "Server-first data fetching with minimal client-side state management."
tags: ["nextjs", "react", "performance", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# Data Fetching Patterns

## Philosophy

Server-first with minimal client-side state management. Prefer Server Components + Server Actions + cache invalidation over client-side data fetching libraries.

---

## Next.js 16 Caching Strategy

We use Next.js 16's `updateTag()` + `refresh()` pattern for cache invalidation - **NO React Query or SWR**.

**Note:** `cacheComponents: true` is disabled due to Clerk authentication conflicts. The `updateTag()` and `refresh()` APIs work independently and don't require `cacheComponents`.

### Quick Summary

```typescript
// 1. Direct data fetching (no 'use cache' directive)
import { getCalls } from '@/app/_shared/repositories/calls.repository'

export default async function CallsPage() {
  const calls = await getCalls({ filterUpcoming: true })
  return <CallsList initialCalls={calls} />
}

// 2. Server Action with invalidation
import { updateTag, refresh } from 'next/cache'

export async function cancelCall(id: string) {
  'use server'
  await callsRepository.cancel(id)

  updateTag('calls')       // Immediate cache expiration
  updateTag(`call-${id}`)  // Targeted invalidation
  refresh()                // Refresh client router
}

// 3. Client Component with transitions
'use client'
import { useTransition } from 'react'

export function CallsList({ initialCalls }) {
  const [isPending, startTransition] = useTransition()

  async function handleCancel(id: string) {
    startTransition(async () => {
      await cancelCall(id) // Handles cache internally
    })
  }
}
```

### Key APIs

- `updateTag()` - Immediate cache invalidation (Server Actions only) - **Works without cacheComponents**
- `refresh()` - Refresh client router (replaces `router.refresh()`) - **Works without cacheComponents**

**Not Available (cacheComponents disabled):**
- `'use cache'` - Requires `cacheComponents: true`
- `cacheTag()` - Requires `cacheComponents: true`
- `cacheLife()` - Requires `cacheComponents: true`

### Deprecated - DO NOT USE

- React Query (`useMutation`, `useQuery`, `queryClient`)
- SWR (`useSWR`, `mutate`)
- Event emitters for cache coordination
- Manual polling with `setInterval`
- `router.refresh()` from client components
- `revalidatePath()` (use `updateTag` instead for better granularity)

---

## Pattern 1: Server Component + Server Actions (PREFERRED)

Use for most pages - SSR data + client interactions via Server Actions:

```typescript
// Server Component - Fetches data during SSR via repository
// app/(protected)/scheduler/page.tsx
import { createClient } from '@/app/_shared/lib/supabase/server';
import { getBookingLinksWithStats } from '@/app/_shared/repositories/booking-link.repository';

export default async function SchedulerPage() {
  const supabase = await createClient();
  const { orgId } = await auth();

  const configs = await getBookingLinksWithStats(supabase, orgId!, {
    activeOnly: true
  });

  return <SchedulerPageClient configs={configs} />;
}

// Client Component - Handles interactions only
// app/(protected)/scheduler/components/SchedulerPageClient.tsx
'use client';
import { useRouter, useTransition } from 'next/navigation';
import { deleteConfigurationAction } from '../actions/delete-configuration';

export function SchedulerPageClient({ configs }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  async function handleDelete(id: string) {
    startTransition(async () => {
      await deleteConfigurationAction(id);
      router.refresh();
    });
  }

  const filtered = configs.filter(c => c.title.includes(searchQuery));

  return (/* render filtered data */);
}

// Server Action - Mutation with cache invalidation
// app/(protected)/scheduler/actions/delete-configuration.ts
'use server';
import { revalidatePath } from 'next/cache';
import { createClient } from '@/app/_shared/lib/supabase/server';
import { deactivateBookingLink } from '@/app/_shared/repositories/booking-link.repository';

export async function deleteConfigurationAction(id: string) {
  const supabase = await createClient();
  const { orgId } = await auth();

  await deactivateBookingLink(supabase, orgId!, id);
  revalidatePath('/scheduler');
  return { success: true };
}
```

### Benefits

- Zero client-side cache management
- No staleTime/refetchOnWindowFocus complexity
- TypeScript types work seamlessly (no serialization)
- SSR + streaming built-in
- Less JavaScript shipped to client
- All database queries isolated in repositories

---

## Filtering & Search Patterns

### Small datasets (<100 items)

```typescript
// Client-side filtering - instant, no server calls
const filtered = useMemo(() =>
  data.filter(item => item.title.includes(query)),
  [data, query]
);
```

### Large datasets (>100 items)

```typescript
// Server Action with debounce
import { useDebouncedCallback } from 'use-debounce';

const debouncedSearch = useDebouncedCallback(
  async (query: string) => {
    const results = await searchItemsAction(query);
    setResults(results);
  },
  500 // Wait 500ms after typing stops
);

<Input onChange={(e) => debouncedSearch(e.target.value)} />
```

---

## Migration from React Query

1. Remove `useQuery`, `useMutation`, `useQueryClient`
2. Pass SSR data directly to client component
3. Use `useTransition` for loading states
4. Call server actions directly (no HTTP layer)
5. Add `revalidatePath` in server actions
6. Call `router.refresh()` after mutations

```typescript
// BEFORE (React Query)
const { data } = useQuery({ queryKey: ['items'], queryFn: getItems })
const deleteMutation = useMutation({ mutationFn: deleteItem })

// AFTER (Server Actions)
const [isPending, startTransition] = useTransition()
startTransition(async () => {
  await deleteItemAction(id)
  router.refresh()
})
```
