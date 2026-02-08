---
title: "Performance Patterns: Suspense and Streaming"
description: "Every interaction should feel instant through perceived performance techniques."
tags: ["performance", "nextjs", "react", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# Performance Patterns

## Philosophy

Every interaction should feel **instant**. Users should never wonder "is this working?" The goal is perceived performance through:

1. **Immediate visual feedback** - Show something within 100ms
2. **Progressive loading** - Critical content first, secondary content streams
3. **Optimistic updates** - UI reflects changes before server confirms
4. **Smart prefetching** - Anticipate and preload likely destinations

---

## Pattern 1: Suspense Boundaries for Progressive Loading

### Problem

Pages that fetch all data before rendering anything feel slow, even if the actual fetch is fast.

### Solution

Wrap independent sections in their own `<Suspense>` boundaries so they stream as they become ready.

```tsx
// BEFORE: Single blocking fetch - page waits for ALL data
export default async function DashboardPage() {
  const [analytics, calls, leads] = await Promise.all([
    getAnalytics(),
    getCalls(),
    getLeads(),
  ]);

  return (
    <div>
      <Analytics data={analytics} />
      <Calls data={calls} />
      <Leads data={leads} />
    </div>
  );
}

// AFTER: Progressive streaming - each section loads independently
export default function DashboardPage() {
  return (
    <div>
      <Suspense fallback={<AnalyticsSkeleton />}>
        <AnalyticsSection />
      </Suspense>
      <Suspense fallback={<CallsSkeleton />}>
        <CallsSection />
      </Suspense>
      <Suspense fallback={<LeadsSkeleton />}>
        <LeadsSection />
      </Suspense>
    </div>
  );
}

// Each section is its own async Server Component
async function AnalyticsSection() {
  const analytics = await getAnalytics();
  return <Analytics data={analytics} />;
}
```

### When to Use Nested Suspense

| Scenario | Use Nested Suspense? |
|----------|---------------------|
| Independent data sources | Yes - each can stream separately |
| Parent-child data dependency | No - child depends on parent data |
| Multiple tabs/views | Yes - only active tab needs to load |
| Primary + secondary content | Yes - show primary first |

### Rules

1. Each async Server Component should be wrapped in its own Suspense
2. Skeletons must match the actual content layout (prevent CLS)
3. Group related data that MUST appear together
4. Don't over-granularize - 3-5 boundaries per page is typical

---

## Pattern 2: Optimistic Updates with `useOptimistic`

### Problem

Waiting for server confirmation before updating UI makes interactions feel laggy.

### Solution

Update UI immediately using `useOptimistic`, then reconcile with server response.

```tsx
'use client';
import { useOptimistic, useTransition } from 'react';
import { deleteCallAction } from './actions';

export function CallsList({ calls }: { calls: Call[] }) {
  const [isPending, startTransition] = useTransition();

  // Optimistic state - updates immediately
  const [optimisticCalls, removeCall] = useOptimistic(
    calls,
    (state, deletedId: string) => state.filter(c => c.id !== deletedId)
  );

  const handleDelete = (callId: string) => {
    // 1. Update UI immediately
    removeCall(callId);

    // 2. Then sync with server
    startTransition(async () => {
      const result = await deleteCallAction(callId);
      if (!result.success) {
        // UI will rollback when `calls` prop updates from server
        toast.error('Failed to delete call');
      }
    });
  };

  return (
    <ul>
      {optimisticCalls.map(call => (
        <li key={call.id}>
          {call.title}
          <Button
            onClick={() => handleDelete(call.id)}
            disabled={isPending}
          >
            Delete
          </Button>
        </li>
      ))}
    </ul>
  );
}
```

### Optimistic Update Patterns

#### Delete from List
```tsx
const [optimisticItems, removeItem] = useOptimistic(
  items,
  (state, id: string) => state.filter(item => item.id !== id)
);
```

#### Add to List
```tsx
const [optimisticItems, addItem] = useOptimistic(
  items,
  (state, newItem: Item) => [...state, { ...newItem, id: 'temp-' + Date.now() }]
);
```

#### Update Item Status
```tsx
const [optimisticItems, updateItem] = useOptimistic(
  items,
  (state, { id, status }: { id: string; status: string }) =>
    state.map(item => item.id === id ? { ...item, status } : item)
);
```

#### Toggle Boolean
```tsx
const [optimisticItem, toggleItem] = useOptimistic(
  item,
  (state, _) => ({ ...state, isActive: !state.isActive })
);
```

### Rules

1. Always combine `useOptimistic` with `useTransition`
2. Show toast on server error - UI will auto-rollback
3. Use temporary IDs for optimistic creates
4. Don't use for critical operations (payments, deletions with dependencies)

---

## Pattern 3: Link Prefetching

### Problem

Navigation feels slow because pages load on-demand.

### Solution

Prefetch likely destinations so they're ready when user clicks.

### Automatic Prefetching (Viewport)

```tsx
import Link from 'next/link';

// Prefetches when link enters viewport
<Link href={`/calls/${call.id}`} prefetch={true}>
  View Call
</Link>
```

### Programmatic Prefetching

```tsx
'use client';
import { useRouter } from 'next/navigation';

export function CallRow({ call }: { call: Call }) {
  const router = useRouter();

  // Prefetch on hover
  const handleMouseEnter = () => {
    router.prefetch(`/calls/${call.id}`);
  };

  return (
    <div
      onMouseEnter={handleMouseEnter}
      onClick={() => router.push(`/calls/${call.id}`)}
    >
      {call.title}
    </div>
  );
}
```

### Predictive Prefetching

```tsx
'use client';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

export function CallDetail({ call, nextCallId }: Props) {
  const router = useRouter();

  // Prefetch next likely destination
  useEffect(() => {
    if (nextCallId) {
      router.prefetch(`/calls/${nextCallId}`);
    }
  }, [nextCallId, router]);

  return <div>...</div>;
}
```

### Rules

1. Use `prefetch={true}` on Links in lists/grids
2. Prefetch detail pages on row hover
3. Prefetch "next" items in sequential flows
4. Don't prefetch everything - focus on likely destinations

---

## Pattern 4: Skeleton Components

### Problem

Generic spinners don't communicate what's loading and cause layout shift.

### Solution

Create skeleton components that mirror the actual content layout.

```tsx
import { Skeleton } from '@/components/ui/skeleton';

// Skeleton matches actual CallCard layout
export function CallCardSkeleton() {
  return (
    <div className="flex items-center gap-4 p-4 border rounded-lg">
      {/* Avatar */}
      <Skeleton className="h-10 w-10 rounded-full" />

      {/* Content */}
      <div className="flex-1 space-y-2">
        <Skeleton className="h-4 w-1/3" /> {/* Name */}
        <Skeleton className="h-3 w-1/4" /> {/* Time */}
      </div>

      {/* Actions */}
      <Skeleton className="h-8 w-20" /> {/* Button */}
    </div>
  );
}

// List skeleton repeats card skeleton
export function CallsListSkeleton({ count = 10 }: { count?: number }) {
  return (
    <div className="space-y-4">
      {Array.from({ length: count }).map((_, i) => (
        <CallCardSkeleton key={i} />
      ))}
    </div>
  );
}
```

### Skeleton Guidelines

| Element | Skeleton Representation |
|---------|------------------------|
| Avatar | Circle matching size |
| Text line | Rectangle at typical width |
| Button | Rectangle matching button size |
| Image | Rectangle matching aspect ratio |
| Input | Rectangle matching input height |

### Rules

1. Match exact dimensions to prevent layout shift (CLS)
2. Use consistent animation (pulse is default)
3. Group skeletons that always appear together
4. Show realistic count (10 rows for list, not 3)

---

## Pattern 5: Dialog/Sheet Loading States

### Problem

Dialogs disable buttons during mutations but don't explain why.

### Solution

Show clear loading indication inside dialogs.

```tsx
'use client';
import { useTransition } from 'react';
import { Loader2 } from 'lucide-react';

export function CallOutcomeDialog({ call, onSubmit }: Props) {
  const [isPending, startTransition] = useTransition();

  const handleSubmit = (data: FormData) => {
    startTransition(async () => {
      await onSubmit(data);
    });
  };

  return (
    <DialogContent className="relative">
      {/* Loading overlay */}
      {isPending && (
        <div className="absolute inset-0 bg-background/80 flex items-center justify-center z-50 rounded-lg">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
      )}

      <DialogHeader>
        <DialogTitle>Call Outcome</DialogTitle>
      </DialogHeader>

      <form onSubmit={handleSubmit}>
        {/* Disable all fields during mutation */}
        <fieldset disabled={isPending} className="space-y-4">
          <Input name="outcome" placeholder="Outcome" />
          <Textarea name="notes" placeholder="Notes" />
        </fieldset>

        <DialogFooter className="mt-4">
          <Button type="submit" disabled={isPending}>
            {isPending ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Saving...
              </>
            ) : (
              'Save Outcome'
            )}
          </Button>
        </DialogFooter>
      </form>
    </DialogContent>
  );
}
```

### Sheet with Suspense

```tsx
export function LeadDetailSheet({ leadId, open, onOpenChange }: Props) {
  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent>
        <Suspense fallback={<LeadDetailSkeleton />}>
          <LeadDetailContent leadId={leadId} />
        </Suspense>
      </SheetContent>
    </Sheet>
  );
}
```

### Rules

1. Use `<fieldset disabled>` to disable all form fields
2. Show loading overlay for visual feedback
3. Change button text to indicate action ("Saving...")
4. Wrap sheet content in Suspense with skeleton fallback

---

## Pattern 6: Transition-Wrapped Navigation

### Problem

Navigation without transition doesn't provide loading feedback.

### Solution

Wrap navigation in `startTransition` for smooth UX.

```tsx
'use client';
import { useRouter } from 'next/navigation';
import { useTransition } from 'react';

export function CallRow({ call }: { call: Call }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  const handleClick = () => {
    startTransition(() => {
      router.push(`/calls/${call.id}`);
    });
  };

  return (
    <div
      onClick={handleClick}
      className={cn(
        'cursor-pointer hover:bg-muted/50',
        isPending && 'opacity-50 pointer-events-none'
      )}
    >
      {isPending && <Loader2 className="h-4 w-4 animate-spin mr-2" />}
      {call.title}
    </div>
  );
}
```

---

## Route Templates

### List Page Template

```tsx
// page.tsx
import { Suspense } from 'react';

export default function ItemsPage() {
  return (
    <div>
      <PageHeader title="Items" />
      <Suspense fallback={<ItemsListSkeleton />}>
        <ItemsList />
      </Suspense>
    </div>
  );
}

// components/ItemsList.tsx (async Server Component)
async function ItemsList() {
  const items = await getItems();
  return <ItemsDataGrid items={items} />;
}

// components/ItemsListSkeleton.tsx
function ItemsListSkeleton() {
  return (
    <div className="space-y-2">
      {Array.from({ length: 10 }).map((_, i) => (
        <Skeleton key={i} className="h-16 w-full" />
      ))}
    </div>
  );
}
```

### Detail Page Template

```tsx
// [id]/page.tsx
import { Suspense } from 'react';

export default async function ItemDetailPage({ params }: Props) {
  // Fetch primary data (blocks, but fast)
  const item = await getItem(params.id);

  return (
    <div className="grid grid-cols-2 gap-6">
      {/* Primary content - instant from parent fetch */}
      <ItemDetails item={item} />

      {/* Secondary content - streams separately */}
      <Suspense fallback={<RelatedItemsSkeleton />}>
        <RelatedItems itemId={params.id} />
      </Suspense>
    </div>
  );
}
```

### Master-Detail Template

```tsx
// page.tsx - Master list with detail sheet
export default function ItemsPage() {
  return (
    <div className="flex">
      {/* Master list */}
      <div className="flex-1">
        <Suspense fallback={<ItemsListSkeleton />}>
          <ItemsList />
        </Suspense>
      </div>

      {/* Detail sheet - controlled by URL state */}
      <ItemDetailSheet />
    </div>
  );
}

// components/ItemDetailSheet.tsx
'use client';
export function ItemDetailSheet() {
  const searchParams = useSearchParams();
  const selectedId = searchParams.get('selected');

  return (
    <Sheet open={!!selectedId}>
      <SheetContent>
        {selectedId && (
          <Suspense fallback={<ItemDetailSkeleton />}>
            <ItemDetail itemId={selectedId} />
          </Suspense>
        )}
      </SheetContent>
    </Sheet>
  );
}
```

### Public Page Template (with ISR)

```tsx
// [slug]/page.tsx
export const revalidate = 60; // ISR: revalidate every 60 seconds

export default async function PublicPage({ params }: Props) {
  const data = await getPublicData(params.slug);

  return (
    <div>
      {/* Static content - cached */}
      <Header data={data} />

      {/* Dynamic content - streams */}
      <Suspense fallback={<AvailabilitySkeleton />}>
        <AvailabilitySection slug={params.slug} />
      </Suspense>
    </div>
  );
}
```

---

## Quick Reference

### DO

- Wrap independent sections in `<Suspense>` boundaries
- Use `useOptimistic` for all mutations (creates, updates, deletes)
- Add `prefetch={true}` to Links in lists
- Create skeletons that match actual content layout
- Show loading state inside dialogs/sheets
- Use `useTransition` for navigation clicks

### DON'T

- Block entire page waiting for all data
- Wait for server confirmation before updating UI
- Use generic spinners when skeletons are appropriate
- Disable buttons without visual loading indication
- Over-granularize Suspense boundaries (3-5 per page max)
- Prefetch everything - focus on likely destinations

---

## Performance Metrics

Target metrics per route:

| Metric | Target | Measurement |
|--------|--------|-------------|
| First Contentful Paint (FCP) | <1s | Skeleton/structure visible |
| Largest Contentful Paint (LCP) | <2.5s | Main content loaded |
| Time to Interactive (TTI) | <3s | Page responsive to input |
| Cumulative Layout Shift (CLS) | <0.1 | No unexpected movement |

Use Vercel Analytics to track these metrics.
