---
title: "Real-Time Master-Detail Sync"
description: "Complete data flow pattern for master-detail views with automatic UI synchronization."
tags: ["react", "nextjs", "architecture", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# Master-Detail Views with Real-time Updates: Golden Pathway

## Overview

Complete data flow pattern for master-detail views (datagrid → detail view) with automatic UI synchronization using Next.js 16, React 19, Supabase, and Clerk.

## Repository Integration

**CRITICAL**: This pattern fully leverages your repository layer:

- ✅ **Server Components** → Call repository functions (`getCalls`, `getCallById`)
- ✅ **Server Actions** → Call repository functions (`updateCall`, `createCall`, `deleteCall`)
- ✅ **Repositories** → Create Supabase client internally (RLS enforced)
- ✅ **Type Safety** → Use generated types from `database.types.ts`
- ✅ **No Direct Supabase** → Never use `supabase.from()` outside repositories

**Repository Pattern Benefits:**
- Single source of truth for all database queries
- Consistent query patterns across the app
- Type safety via generated types
- RLS enforcement centralized
- Easy to test and maintain

## Architecture: Three-Layer Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: Server-Side Rendering (Initial Load)                 │
│ - Server Components fetch data via repositories                 │
│ - Data passed as props to Client Components                     │
│ - Fast initial render, SEO-friendly                             │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ Layer 2: Optimistic Updates (User's Own Actions)                │
│ - User sees their changes instantly (local state)               │
│ - Server Action executes in background                           │
│ - Cache invalidation refreshes data                             │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ Layer 3: Real-time Subscriptions (Cross-User Updates)           │
│ - WebSocket subscriptions to INSERT/UPDATE/DELETE events        │
│ - Other users' changes appear automatically                     │
│ - Master and detail views stay in sync                          │
└─────────────────────────────────────────────────────────────────┘
```

## Complete Flow: Master → Detail → Update → Sync

### 1. Initial Page Load (Master View)

**File:** `app/(protected)/calls/page.tsx`

```typescript
// Server Component - Fetches initial data via repository
import { getCalls } from '@/app/_shared/repositories/calls.repository'

export default async function CallsPage() {
  const [upcomingCalls, pastCalls] = await Promise.all([
    getCalls({ filterUpcoming: true }),
    getCalls({ filterPast: true }),
  ]);

  return (
    <CallsList
      initialUpcomingCalls={upcomingCalls}
      initialPastCalls={pastCalls}
    />
  );
}
```

**What happens:**
- Server Component calls repository function (`getCalls`)
- Repository creates Supabase client internally (RLS enforced)
- Data passed as props to client component
- Fast SSR, no loading spinner needed

---

### 2. Master View Component (Datagrid)

**File:** `app/(protected)/calls/components/CallsList.tsx`

```typescript
'use client'
import { useRealtimeCalls } from '../hooks/useRealtimeCalls'
import { useCallsData } from '../hooks/useCallsData'
import { useAuth } from '@clerk/nextjs'

export function CallsList({ initialUpcomingCalls, initialPastCalls }) {
  const { orgId } = useAuth()

  // Local state management with optimistic updates
  const {
    upcomingCalls,
    pastCalls,
    updateCall,      // For optimistic updates
    addCall,         // For real-time inserts
    removeCall       // For real-time deletes
  } = useCallsData(initialUpcomingCalls, initialPastCalls)

  // Real-time subscription for cross-user updates
  useRealtimeCalls({
    organizationId: orgId!,
    onInsert: (newCall) => {
      // Add to appropriate list (upcoming or past)
      if (isUpcoming(newCall)) {
        addCall(newCall, 'upcoming')
      } else {
        addCall(newCall, 'past')
      }
    },
    onUpdate: (updatedCall) => {
      // Update existing call in both lists
      updateCall(updatedCall)
    },
    onDelete: (callId) => {
      // Remove from both lists
      removeCall(callId)
    },
  })

  return (
    <CallsDataGrid
      data={activeTab === 'upcoming' ? upcomingCalls : pastCalls}
      onRowClick={(call) => router.push(`/calls/${call.id}`)}
    />
  )
}
```

**What happens:**
- Initial data from SSR props
- Real-time subscription listens for changes
- Local state updates automatically when events received
- Datagrid re-renders with fresh data

---

### 3. User Clicks Row → Navigate to Detail View

**File:** `app/(protected)/calls/[id]/page.tsx`

```typescript
// Server Component - Fetches single call via repository
import { getCallById } from '@/app/_shared/repositories/calls.repository'

export default async function CallDetailPage({ params }) {
  const { id } = await params
  const call = await getCallById(id)

  if (!call) {
    notFound()
  }

  return <CallDetailView call={call} />
}
```

**What happens:**
- User clicks row in datagrid
- Router navigates to `/calls/[id]`
- Server Component calls repository function (`getCallById`)
- Repository fetches call with full relations (RLS enforced)
- Detail view renders with complete data

---

### 4. Detail View Component (With Real-time)

**File:** `app/(protected)/calls/[id]/components/CallDetailView.tsx`

```typescript
'use client'
import { useRealtimeCall } from '../../hooks/useRealtimeCall'
import { useRouter } from 'next/navigation'

export function CallDetailView({ call: initialCall }) {
  const router = useRouter()
  const [call, setCall] = useState(initialCall)

  // Subscribe to updates for THIS specific call
  useRealtimeCall({
    callId: call.id,
    onUpdate: (updatedCall) => {
      // Update local state when call changes
      setCall(updatedCall)

      // Optionally refresh to get full relations if needed
      // router.refresh()
    },
  })

  return (
    <div>
      <CallDetails call={call} />
      <CallOutcomeDialog
        callId={call.id}
        onOutcomeUpdated={(updatedCall) => {
          // Optimistic update (user sees change instantly)
          setCall(updatedCall)
        }}
      />
    </div>
  )
}
```

**What happens:**
- Detail view subscribes to updates for this specific call
- If another user updates the call, detail view updates automatically
- User's own updates are optimistic (instant feedback)

---

### 5. User Updates Call in Detail View

**File:** `app/(protected)/calls/_actions/update-call-outcome.ts`

```typescript
'use server'
import { updateTag, refresh } from 'next/cache'
import { updateCall, getCallById } from '@/app/_shared/repositories/calls.repository'
import { createModuleLogger } from '@/app/_shared/lib/logger'

const logger = createModuleLogger('update-call-outcome')

export async function updateCallOutcomeAction(input: UpdateCallOutcomeInput) {
  try {
    // 1. Update database via repository (CRITICAL: Always use repositories!)
    await updateCall(input.callId, {
      outcome: input.outcome,
      notes: input.notes,
      updated_at: new Date().toISOString()
    })

    // 2. Invalidate cache (backup/fallback)
    updateTag('calls')
    updateTag(`call-${input.callId}`)
    refresh()

    // 3. Fetch updated call via repository for optimistic update
    const updatedCall = await getCallById(input.callId)

    logger.info({ callId: input.callId }, 'Call outcome updated successfully')

    return { success: true, data: updatedCall }
  } catch (error) {
    logger.error({ error, callId: input.callId }, 'Failed to update call outcome')
    return { success: false, error: 'Failed to update call outcome' }
  }
}
```

**What happens:**
- Server Action calls repository function (`updateCall`) - **NEVER direct Supabase queries**
- Repository creates Supabase client internally (RLS enforced)
- Cache invalidation triggers refresh (backup)
- Real-time subscription broadcasts UPDATE event automatically
- All users see the change automatically

---

### 6. Master View Receives Update

**Back in CallsList component:**

```typescript
useRealtimeCalls({
  organizationId: orgId!,
  onUpdate: (updatedCall) => {
    // This fires when ANY user updates the call
    updateCall(updatedCall)  // Updates local state

    // If user is viewing detail view, navigate back or refresh
    if (router.pathname === `/calls/${updatedCall.id}`) {
      router.refresh()  // Refresh detail view to get full relations
    }
  },
})
```

**What happens:**
- Real-time subscription receives UPDATE event
- Master view updates the call in its local state
- Datagrid row updates automatically
- If detail view is open, it also updates (via its own subscription)

---

## Key Patterns

### Pattern 1: Shared State Hook

**File:** `app/(protected)/calls/hooks/useCallsData.ts`

```typescript
export function useCallsData(initialUpcoming, initialPast) {
  const [upcomingCalls, setUpcomingCalls] = useState(initialUpcoming)
  const [pastCalls, setPastCalls] = useState(initialPast)

  // Sync with SSR props when cache invalidates
  useEffect(() => {
    setUpcomingCalls(initialUpcoming)
  }, [initialUpcoming])

  // Optimistic update (user's own action)
  const updateCall = (updatedCall) => {
    setUpcomingCalls(prev =>
      prev.map(c => c.id === updatedCall.id ? updatedCall : c)
    )
    setPastCalls(prev =>
      prev.map(c => c.id === updatedCall.id ? updatedCall : c)
    )
  }

  // Real-time insert
  const addCall = (newCall, type) => {
    if (type === 'upcoming') {
      setUpcomingCalls(prev => [newCall, ...prev])
    } else {
      setPastCalls(prev => [newCall, ...prev])
    }
  }

  // Real-time delete
  const removeCall = (callId) => {
    setUpcomingCalls(prev => prev.filter(c => c.id !== callId))
    setPastCalls(prev => prev.filter(c => c.id !== callId))
  }

  return { upcomingCalls, pastCalls, updateCall, addCall, removeCall }
}
```

### Pattern 2: Real-time Hook (Master View)

**File:** `app/(protected)/calls/hooks/useRealtimeCalls.ts`

```typescript
export function useRealtimeCalls({ organizationId, onInsert, onUpdate, onDelete }) {
  const supabase = useMemo(() => createClient(), [])

  useEffect(() => {
    const channel = supabase
      .channel(`calls-${organizationId}`)
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'calls',
        filter: `organization_id=eq.${organizationId}`,
      }, (payload) => {
        onInsert?.(payload.new as Call)
      })
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'calls',
        filter: `organization_id=eq.${organizationId}`,
      }, (payload) => {
        onUpdate?.(payload.new as Call)
      })
      .on('postgres_changes', {
        event: 'DELETE',
        schema: 'public',
        table: 'calls',
        filter: `organization_id=eq.${organizationId}`,
      }, (payload) => {
        onDelete?.(payload.old.id as string)
      })
      .subscribe()

    return () => supabase.removeChannel(channel)
  }, [organizationId, supabase, onInsert, onUpdate, onDelete])
}
```

### Pattern 3: Real-time Hook (Detail View)

**File:** `app/(protected)/calls/hooks/useRealtimeCall.ts`

```typescript
export function useRealtimeCall({ callId, onUpdate }) {
  const supabase = useMemo(() => createClient(), [])

  useEffect(() => {
    if (!callId) return

    const channel = supabase
      .channel(`call-${callId}`)
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'calls',
        filter: `id=eq.${callId}`,
      }, (payload) => {
        onUpdate?.(payload.new as Call)
      })
      .subscribe()

    return () => supabase.removeChannel(channel)
  }, [callId, supabase, onUpdate])
}
```

---

## Complete Data Flow Diagram

```
User A Updates Call
│
├─→ [Optimistic] User A sees change instantly (local state)
│
├─→ [Server Action] updateCallOutcomeAction()
│   ├─→ Updates database
│   ├─→ updateTag('calls') + refresh() (backup)
│   └─→ Returns updated call
│
└─→ [Real-time] Supabase broadcasts UPDATE event
    │
    ├─→ User A's Master View (CallsList)
    │   └─→ useRealtimeCalls.onUpdate() → updateCall() → UI updates
    │
    ├─→ User A's Detail View (if open)
    │   └─→ useRealtimeCall.onUpdate() → setCall() → UI updates
    │
    ├─→ User B's Master View
    │   └─→ useRealtimeCalls.onUpdate() → updateCall() → UI updates
    │
    └─→ User B's Detail View (if viewing same call)
        └─→ useRealtimeCall.onUpdate() → setCall() → UI updates
```

---

## Benefits

✅ **Instant Feedback**: User sees their own changes immediately (optimistic)
✅ **Automatic Sync**: Other users see changes automatically (real-time)
✅ **Master-Detail Sync**: Updates in detail view reflect in master view
✅ **Cross-User Collaboration**: Team members see each other's changes instantly
✅ **Backward Compatible**: Cache invalidation still works as fallback
✅ **RLS Enforced**: Real-time respects Row Level Security policies

---

## When to Use Each Layer

| Scenario | Layer Used | Why |
|----------|------------|-----|
| Initial page load | SSR (Layer 1) | Fast, SEO-friendly, no loading state |
| User's own action | Optimistic (Layer 2) | Instant feedback, better UX |
| Other user's action | Real-time (Layer 3) | Automatic updates, no refresh needed |
| WebSocket fails | Cache invalidation | Backup ensures data consistency |
| Background processes | Real-time (Layer 3) | Long-running operations need live updates |

---

## Best Practices

### Repository Pattern (CRITICAL)

1. **ALWAYS use repositories** - NEVER use `supabase.from()` directly in Server Actions
   ```typescript
   // ❌ WRONG - Direct Supabase query
   const { data } = await supabase.from('calls').update(...)

   // ✅ CORRECT - Use repository
   await updateCall(callId, updates)
   ```

2. **Repositories handle Supabase client creation** - Most repositories create client internally
3. **Use generated types** - `Database["public"]["Tables"]["calls"]["Update"]`
4. **Always `select *`** - Repositories use `select *` for type safety

### Real-time Pattern

1. **Always use optimistic updates** for user's own actions
2. **Subscribe to real-time** for cross-user collaboration
3. **Keep cache invalidation** as backup/fallback
4. **Filter by organization_id** in real-time subscriptions (RLS handles it, but filter reduces noise)
5. **Clean up subscriptions** in useEffect cleanup
6. **Handle WebSocket reconnection** (Supabase handles automatically)
7. **Use specific filters** for detail views (`id=eq.${callId}`) vs broad filters for master views (`organization_id=eq.${orgId}`)

### Server Actions Pattern

1. **Call repository functions** - Never direct Supabase queries
2. **Invalidate cache** - Always call `updateTag()` + `refresh()` after mutations
3. **Return structured responses** - `{ success: boolean, data?: T, error?: string }`
4. **Use Pino logger** - Never `console.log()`

---

## Example: Complete Master-Detail Update Flow

**Scenario:** User A updates call outcome in detail view, User B is viewing master view

1. **User A clicks "Mark as Closed"** in detail view
   - Optimistic update: Detail view shows "Closed" instantly
   - Server Action executes: Updates database
   - Real-time event: Supabase broadcasts UPDATE

2. **User A's master view receives update**
   - `useRealtimeCalls.onUpdate()` fires
   - Calls `updateCall(updatedCall)`
   - Datagrid row updates to show "Closed" status

3. **User B's master view receives update**
   - `useRealtimeCalls.onUpdate()` fires
   - Calls `updateCall(updatedCall)`
   - Datagrid row updates automatically (no refresh needed)

4. **If User B opens detail view**
   - Server fetches latest data
   - `useRealtimeCall` subscribes to future updates
   - Detail view shows "Closed" status

**Result:** Both users see the update instantly, master and detail views stay in sync.
