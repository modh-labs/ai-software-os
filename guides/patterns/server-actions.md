---
title: "Server Actions: Mutation Patterns"
description: "Server Actions are the default for all mutations and complex server operations."
tags: ["nextjs", "react", "typescript", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# Server Actions Pattern

## Philosophy

Server Actions are the **default for all mutations and complex server operations**. They're simpler, more type-safe, and faster than API routes.

---

## When to Use Server Actions

- Form submissions and mutations
- Complex business logic that needs server-side access
- Data fetching that should happen server-side
- Anything that currently uses an API route for internal use

## When to Use API Routes Instead

- Webhooks from Clerk, Stripe, Nylas, etc.
- External services that require HTTP endpoints
- **NOT** for internal data mutations
- **NOT** for client fetching

---

## Benefits

- Direct function calls from client - no HTTP serialization
- Full TypeScript end-to-end type safety
- Secrets stay server-side only
- Colocation with the routes that use them
- Easier to test and reason about

---

## Standard Pattern

```typescript
// app/(protected)/calls/actions.ts
'use server'
import { callsRepository } from '@/app/_shared/repositories/calls.repository'
import { revalidatePath } from 'next/cache'

export async function createCall(data: CreateCallInput) {
  try {
    const result = await callsRepository.create(data)
    revalidatePath('/calls')
    return { success: true, data: result }
  } catch (error) {
    return { success: false, error: error.message }
  }
}

export async function updateCallStatus(id: string, status: CallStatus) {
  try {
    const result = await callsRepository.update(id, { status })
    revalidatePath('/calls')
    return { success: true, data: result }
  } catch (error) {
    return { success: false, error: error.message }
  }
}
```

---

## Using from Client Components

```typescript
// app/(protected)/calls/components/CallForm.tsx
'use client'
import { createCall } from '../actions'

export function CallForm() {
  const [loading, setLoading] = useState(false)

  async function handleSubmit(formData: FormData) {
    setLoading(true)
    try {
      const result = await createCall({
        title: formData.get('title'),
        // ...
      })
      if (result.success) {
        // Handle success
      }
    } finally {
      setLoading(false)
    }
  }

  return <form onSubmit={handleSubmit}>{/* ... */}</form>
}
```

---

## Common Mistakes

### Forgetting Cache Invalidation

```typescript
// WRONG - data doesn't update in UI
'use server'
export async function updateCall(id: string, data: UpdateCallInput) {
  await callsRepository.update(id, data)
  // Missing revalidatePath!
}

// RIGHT - invalidate cache after mutation
'use server'
import { revalidatePath } from 'next/cache'

export async function updateCall(id: string, data: UpdateCallInput) {
  await callsRepository.update(id, data)
  revalidatePath('/calls')  // Forces re-render
}
```

### Using API Routes for Internal Mutations

```typescript
// WRONG - creates unnecessary HTTP layer
// app/api/calls/create/route.ts
export async function POST(req: Request) {
  const data = await req.json()
  const result = await callsRepository.create(data)
  return Response.json(result)
}

// RIGHT - use Server Actions instead
// app/(protected)/calls/actions.ts
'use server'
export async function createCall(data: CreateCallInput) {
  return await callsRepository.create(data)
}
```

### Duplicating RLS Permission Checks

```typescript
// WRONG - redundant with RLS
'use server'
export async function deleteCall(id: string) {
  const auth = await getAuth()
  const call = await callsRepository.getById(id)

  // This check is already done by RLS!
  if (call.organization_id !== auth.orgId) {
    throw new Error('Unauthorized')
  }

  await callsRepository.remove(id)
}

// RIGHT - trust RLS, let Supabase enforce it
'use server'
export async function deleteCall(id: string) {
  // If RLS rejects, Supabase throws error automatically
  await callsRepository.remove(id)
}
```

---

## Webhook Pattern (API Routes)

API routes should be limited to external webhooks:

```typescript
// app/api/webhooks/stripe/route.ts
import { createServiceRoleClient } from '@/app/_shared/lib/supabase/server'
import { stripe } from '@/app/_shared/lib/stripe'

export async function POST(req: Request) {
  const signature = req.headers.get('stripe-signature')!
  const body = await req.text()

  // Verify webhook signature
  const event = stripe.webhooks.constructEvent(
    body,
    signature,
    process.env.STRIPE_WEBHOOK_SECRET!
  )

  // Use service role for webhook operations (bypasses RLS)
  const supabase = await createServiceRoleClient()

  switch (event.type) {
    case 'payment_intent.succeeded':
      // Update database
      break
  }

  return Response.json({ received: true })
}
```

**Key Principle:** If it's internal to your app, use Server Actions. If it's a webhook from external service, use API routes.
