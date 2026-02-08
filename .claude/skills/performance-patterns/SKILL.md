---
name: performance-patterns
description: Implement performance optimizations following your project's patterns. Use when pages are slow, adding loading states, skeletons, spinners, Suspense boundaries, optimistic updates, or prefetching. Enforces instant UI feedback and progressive loading.
allowed-tools: Read, Grep, Glob, Edit, Write
---

# Performance Patterns Skill

## When This Skill Activates

This skill automatically activates when you:
- Add loading states or skeletons
- Implement optimistic updates
- Work with Suspense boundaries
- Add prefetching to navigation
- Discuss page load performance

## Philosophy

Every interaction should feel **instant**. Users should never wonder "is this working?"

1. **Immediate visual feedback** - Show something within 100ms
2. **Progressive loading** - Critical content first, secondary streams
3. **Optimistic updates** - UI reflects changes before server confirms
4. **Smart prefetching** - Anticipate and preload likely destinations

## Pattern 1: Suspense Boundaries

### Problem
Pages that fetch all data before rendering feel slow.

### Solution
Wrap independent sections in `<Suspense>` boundaries.

```typescript
// ❌ WRONG - Single blocking fetch
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

// ✅ CORRECT - Progressive streaming
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

async function AnalyticsSection() {
  const analytics = await getAnalytics();
  return <Analytics data={analytics} />;
}
```

### Rules
- 3-5 Suspense boundaries per page (typical)
- Skeletons MUST match actual content layout (prevent CLS)
- Group related data that MUST appear together

## Pattern 2: Optimistic Updates

### Problem
Waiting for server confirmation feels slow.

### Solution
Update UI immediately, reconcile when server responds.

```typescript
// ❌ WRONG - Wait for server
async function handleUpdate(data: FormData) {
  setLoading(true);
  await updateLead(data);      // User waits 500ms+
  setLoading(false);
}

// ✅ CORRECT - Optimistic update
function LeadCard({ lead }: { lead: Lead }) {
  const [optimisticLead, setOptimisticLead] = useOptimistic(lead);

  async function handleStatusChange(newStatus: string) {
    // Update UI immediately
    setOptimisticLead({ ...lead, status: newStatus });

    // Server catches up in background
    await updateLeadStatus(lead.id, newStatus);
  }

  return (
    <Card>
      <Badge>{optimisticLead.status}</Badge>
      <StatusSelector onChange={handleStatusChange} />
    </Card>
  );
}
```

### When to Use
| Action | Use Optimistic? |
|--------|-----------------|
| Toggle, status change | ✅ Yes |
| Form submission | ✅ Yes (with validation) |
| Delete | ⚠️ Show confirmation first |
| Complex multi-step | ❌ No - use loading state |

## Pattern 3: Loading Skeletons

### Problem
Generic spinners don't show progress.

### Solution
Skeletons that match final content layout.

```typescript
// ❌ WRONG - Generic spinner
function Loading() {
  return <Spinner />;
}

// ✅ CORRECT - Layout-matched skeleton
function LeadGridSkeleton() {
  return (
    <div className="grid grid-cols-3 gap-4">
      {Array.from({ length: 6 }).map((_, i) => (
        <Card key={i}>
          <Skeleton className="h-4 w-3/4" />      {/* Title */}
          <Skeleton className="h-3 w-1/2 mt-2" />  {/* Subtitle */}
          <Skeleton className="h-8 w-full mt-4" /> {/* Button */}
        </Card>
      ))}
    </div>
  );
}
```

### Rules
1. Match exact dimensions of final content
2. Show content structure (cards, rows, columns)
3. Animate with `animate-pulse` (built into Skeleton)
4. Never use spinners for content areas

## Pattern 4: Prefetching

### Problem
Navigation feels slow when data loads on click.

### Solution
Preload data for likely destinations.

```typescript
// ✅ CORRECT - Prefetch on link render
<Link href="/leads" prefetch={true}>
  View Leads
</Link>

// ✅ CORRECT - Prefetch on hover (for expensive pages)
function NavLink({ href, children }) {
  const router = useRouter();

  return (
    <Link
      href={href}
      onMouseEnter={() => router.prefetch(href)}
      prefetch={false}
    >
      {children}
    </Link>
  );
}
```

### When to Prefetch
| Scenario | Strategy |
|----------|----------|
| Main navigation | `prefetch={true}` (default) |
| Table row links | Prefetch on hover |
| Modals/sheets | No prefetch needed |
| External links | Never prefetch |

## Pattern 5: useTransition for Mutations

### Problem
Buttons feel unresponsive during mutations.

### Solution
Use `useTransition` for non-blocking updates.

```typescript
// ✅ CORRECT - Non-blocking with loading state
function SubmitButton({ onSubmit }: { onSubmit: () => Promise<void> }) {
  const [isPending, startTransition] = useTransition();

  return (
    <Button
      onClick={() => startTransition(onSubmit)}
      disabled={isPending}
    >
      {isPending ? (
        <>
          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
          Saving...
        </>
      ) : (
        'Save'
      )}
    </Button>
  );
}
```

## Thresholds

| Metric | Target | Warning |
|--------|--------|---------|
| Time to First Paint | <100ms | >200ms |
| Time to Interactive | <1s | >2s |
| LCP (Largest Contentful Paint) | <2.5s | >4s |
| CLS (Cumulative Layout Shift) | <0.1 | >0.25 |
| INP (Interaction to Next Paint) | <200ms | >500ms |

## Anti-Patterns

```typescript
// ❌ WRONG - Blocking the entire page
const data = await fetchEverything();

// ❌ WRONG - Generic spinner for content
<Spinner /> // Use skeleton instead

// ❌ WRONG - Disabled button without indicator
<Button disabled={loading}>Save</Button>

// ❌ WRONG - Wait for server before UI update
await saveData();
setData(newData); // Too late!
```

## Reference

For complete documentation: `@docs/patterns/performance-patterns.md`
