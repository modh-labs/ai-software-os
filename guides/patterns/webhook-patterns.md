---
title: "Webhook Architecture and Safety Patterns"
description: "Event-driven integrations that receive data from external services."
tags: ["webhooks", "architecture", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# Webhook Patterns

## Philosophy

Webhooks are **event-driven integrations** that receive data from external services (Stripe, Clerk, Nylas). They require special handling for security, idempotency, and reliability.

---

## When to Use Webhooks

- Receiving events from external services (Stripe payments, Clerk auth, Nylas calendar)
- Real-time data synchronization from third-party APIs
- Event-driven workflows that external services trigger

## When NOT to Use Webhooks

- Internal mutations (use Server Actions)
- Client-initiated data fetching (use Server Components)
- Scheduled tasks (use cron/background jobs)

---

## Directory Structure

```
app/api/webhooks/
├── clerk/                    # Auth events
│   └── route.ts
├── nylas/                    # Calendar events
│   └── route.ts
├── stripe-payments/          # Payment events (per-org)
│   ├── README.md             # Handler documentation
│   └── [org_id]/
│       └── route.ts
└── CLAUDE.md                 # Webhook-specific rules
```

---

## Core Patterns

### 1. Signature Verification

**Always verify webhook signatures before processing:**

```typescript
// Stripe example
const event = stripe.webhooks.constructEvent(
  body,           // Raw body (not parsed JSON)
  signature,      // stripe-signature header
  webhookSecret   // Per-org or global secret
);

// Clerk example
const payload = await svix.verify(body, headers);

// Nylas example
const isValid = verifyNylasSignature(body, signature, secret);
```

**Critical:** Use `request.text()` to get the raw body, not `request.json()`.

---

### 2. Idempotency

**Prevent duplicate processing when webhooks are retried:**

```typescript
// Option A: Database constraint (preferred)
// Uses UNIQUE constraint on provider_payment_id
const { created, payment } = await createPaymentIdempotent(supabase, data);
if (!created) {
  return NextResponse.json({ received: true }); // Already processed
}

// Option B: Check before insert
const existing = await getByProviderId(providerId);
if (existing) {
  return NextResponse.json({ received: true });
}
```

**For reversals (refunds, cancellations), use the reversal's ID:**

```typescript
// Refund has its own ID separate from the original charge
const alreadyProcessed = await isRefundAlreadyProcessed(
  supabase,
  latestRefund.id  // re_xxx, not ch_xxx
);
```

---

### 3. Event Routing

**Use switch statement for clear event handling:**

```typescript
switch (event.type) {
  case "charge.succeeded":
    await handleChargeSucceeded(supabase, orgId, event, requestId);
    break;

  case "charge.refunded":
    await handleChargeRefunded(supabase, orgId, event, requestId);
    break;

  default:
    logger.info({ eventType }, "Unhandled event type - acknowledging");
}
```

**Always return 200 for unhandled events** - returning non-2xx causes retries.

---

### 4. Replay Protection

**Reject stale events to prevent replay attacks:**

```typescript
const MAX_EVENT_AGE_SECONDS = 300; // 5 minutes

const eventAge = Math.floor(Date.now() / 1000) - event.created;
if (eventAge > MAX_EVENT_AGE_SECONDS) {
  return NextResponse.json(
    { error: "Event too old" },
    { status: 400 }
  );
}
```

---

## Reversal Pattern

When handling "undo" events (refunds, cancellations, disputes):

### Don't Delete - Update Status

```typescript
// BAD: Deleting removes audit trail
await supabase.from("payments").delete().eq("id", paymentId);

// GOOD: Update status, preserve record
await supabase.from("payments").update({
  status: "refunded",
  refund_status: "full",
  refunded_at: new Date().toISOString(),
}).eq("id", paymentId);
```

### Find Original by Provider ID

```typescript
// Find the original record to update
const payment = await getPaymentByStripeChargeIdForOrg(
  supabase,
  organizationId,
  charge.id  // Original charge ID from refund event
);

if (!payment) {
  logger.warn({ chargeId }, "Original not found - cannot process reversal");
  return;
}
```

### Cascade Updates Independently

```typescript
// Primary record (always update)
await updatePaymentRefund(supabase, payment.id, refundData);

// Related entity (only if linked)
if (payment.lead_id) {
  await decrementLeadPaymentStats(supabase, payment.lead_id, amount);
}

// Downstream entity (only on specific conditions)
if (isFullRefund && payment.call_id) {
  await unlinkPaymentFromCall(supabase, payment.call_id);
}
```

### Preserve Audit Trail

```typescript
// Keep FK links even when "unlinking"
await supabase.from("calls").update({
  payment_verified: false,
  payment_verified_at: null,
  // linked_payment_id is KEPT for audit trail
}).eq("id", callId);
```

---

## Aggregate Stats Pattern

When webhooks update aggregate fields on related entities:

### Increment on Positive Events

```typescript
async function updateLeadPaymentStats(leadId: string, payment: Payment) {
  const { data: lead } = await supabase
    .from("leads")
    .select("total_paid_cents, payment_count")
    .eq("id", leadId)
    .single();

  const newTotal = (lead.total_paid_cents ?? 0) + amountCents;
  const newCount = (lead.payment_count ?? 0) + 1;

  await supabase.from("leads").update({
    total_paid_cents: newTotal,
    payment_count: newCount,
    payment_status: newTotal > 0 ? "partial" : "pending",
  }).eq("id", leadId);
}
```

### Decrement on Reversals (Never Go Negative)

```typescript
async function decrementLeadPaymentStats(leadId: string, refundCents: number) {
  const { data: lead } = await supabase
    .from("leads")
    .select("total_paid_cents")
    .eq("id", leadId)
    .single();

  // CRITICAL: Never go below zero
  const newTotal = Math.max(0, (lead.total_paid_cents ?? 0) - refundCents);

  // Derive status from aggregate
  const status = newTotal === 0 ? "pending" : "partial";

  await supabase.from("leads").update({
    total_paid_cents: newTotal,
    payment_status: status,
    // DON'T decrement payment_count - it's an audit trail
  }).eq("id", leadId);
}
```

---

## Multi-Tenant Webhooks

For per-organization webhook endpoints:

### URL Structure

```
POST /api/webhooks/stripe-payments/[org_id]
```

### Lookup Per-Org Secrets

```typescript
const webhookSecret = await stripeApiKeysRepository.getWebhookSecret(
  supabase,
  organizationId
);

if (!webhookSecret) {
  return NextResponse.json(
    { error: "Webhook not configured for this organization" },
    { status: 404 }
  );
}
```

### Use Service Role Client

```typescript
// Webhooks need to bypass RLS for cross-table updates
function getSupabaseServiceClient() {
  return createClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );
}
```

---

## Observability

### Structured Logging

```typescript
const requestId = `req_${Date.now()}_${Math.random().toString(36).substring(7)}`;

logger.info({
  requestId,
  organizationId,
  eventType: event.type,
  eventId: event.id,
}, "Webhook received");

// Include requestId in all subsequent logs for tracing
```

### Webhook Logger Helper

```typescript
import { createWebhookLogger } from "@/app/_shared/lib/webhooks";

const webhookLog = createWebhookLogger({
  provider: "stripe",
  handler: `handleOrgPayment_${eventType}`,
  eventType,
  organizationId,
});

webhookLog.start();
// ... process event ...
webhookLog.success({ eventId, duration_ms });
// or
webhookLog.failure(error);
```

---

## Response Codes

| Status | When | Stripe Behavior |
|--------|------|-----------------|
| 200 | Success or already processed | Event marked delivered |
| 400 | Invalid request (bad org_id, stale event) | Event marked failed |
| 401 | Invalid signature | Event marked failed |
| 500 | Processing error | Stripe retries |

**Important:** Return 200 even for business logic failures to prevent infinite retries.

---

## Testing Webhooks

### Local Development with Stripe CLI

```bash
# Forward events to local server
stripe listen --forward-to localhost:3000/api/webhooks/stripe-payments/YOUR_ORG_ID

# Trigger specific events
stripe trigger charge.succeeded
stripe trigger charge.refunded
stripe trigger invoice.paid

# Create real test data
stripe charges create --amount 5000 --currency usd --source tok_visa
stripe refunds create --charge ch_xxx
```

### Testing Checklist

- [ ] Valid signature → 200 OK
- [ ] Invalid signature → 401 Unauthorized
- [ ] Duplicate event → 200 OK, no re-processing
- [ ] Missing config → 400/404 with clear error
- [ ] Stale event → 400 Bad Request
- [ ] Processing error → 500 (logged to Sentry)

---

## Adding New Event Types

1. **Add case to switch statement**
2. **Create handler function** following naming convention: `handle{EventName}`
3. **Check idempotency** using appropriate provider ID
4. **Update related entities** (primary → aggregates → downstream)
5. **Update README** with new event documentation
6. **Configure webhook** in provider dashboard to send new event type

---

## Related Files

| File | Purpose |
|------|---------|
| `app/api/webhooks/*/route.ts` | Webhook handlers |
| `app/api/webhooks/*/README.md` | Handler documentation |
| `app/_shared/lib/webhooks.ts` | Webhook logger utility |
| `app/_shared/repositories/*.repository.ts` | Database operations |

## Related Patterns

- [Server Actions](./server-actions.md) - For internal mutations
- [Repository Pattern](./repository-pattern.md) - For database access
- [Database Workflow](./database-workflow.md) - For schema changes
