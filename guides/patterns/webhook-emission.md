---
title: "Webhook Emission Architecture"
description: "How to emit webhook events from server actions to notify partner integrations in real-time."
tags: ["webhooks", "architecture", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# Webhook Emission

## Overview

The webhooks system allows partner integrations to receive real-time notifications when events occur in your application. This guide explains how to **emit** webhook events from server actions to notify partners.

> **Note**: For receiving webhooks FROM external services (Stripe, Clerk, Nylas), see [Webhook Patterns](./webhook-patterns.md).

---

## Architecture

```
Server Action (web app)
  ↓
emitWebhook() helper function
  ↓
HTTP POST to /internal/webhooks/emit (API app)
  ↓
WebhookDeliveryService.sendWebhook()
  ↓
Finds all subscriptions for event type
  ↓
Delivers to each subscription URL with HMAC signature
```

---

## Emitting Webhooks from Server Actions

### 1. Import the webhook utilities

```typescript
import {
  emitWebhook,
  transformCallForWebhook
} from "@/app/_shared/lib/webhooks/emit-webhook";
```

### 2. Emit webhook after successful mutation

```typescript
'use server'

export async function createCall(data: CreateCallInput) {
  // Validate and perform mutation
  const call = await callsRepository.create(data);

  // Emit webhook event (non-blocking)
  try {
    await emitWebhook(
      organizationId,
      "call.booked",
      transformCallForWebhook(call),
    );
  } catch (error) {
    // Non-blocking: log but don't fail the action
    console.error("Failed to emit webhook:", error);
  }

  return { success: true, data: call };
}
```

### 3. Use the appropriate transform function

| Event Type | Transform Function |
|------------|-------------------|
| `lead.created`, `lead.updated`, `lead.status_changed` | `transformLeadForWebhook()` |
| `call.booked`, `call.updated`, etc. | `transformCallForWebhook()` |
| `payment.succeeded`, etc. | `transformPaymentForWebhook()` |

---

## Supported Events

### Lead Events

| Event | When It Fires |
|-------|---------------|
| `lead.created` | New lead created |
| `lead.updated` | Lead information updated |
| `lead.status_changed` | Lead status changed (new → contacted → qualified, etc.) |

### Call Events

| Event | When It Fires |
|-------|---------------|
| `call.booked` | New call scheduled |
| `call.updated` | Call details updated |
| `call.started` | Call started (in progress) |
| `call.completed` | Call finished |
| `call.canceled` | Call canceled |
| `call.rescheduled` | Call rescheduled to new time |
| `call.no_show` | Lead didn't attend call |

### Payment Events

| Event | When It Fires |
|-------|---------------|
| `payment.succeeded` | Payment successfully processed |
| `payment.failed` | Payment processing failed |
| `payment.refunded` | Payment refunded |

---

## Integration Examples

### Public Booking (call.booked)

See: `apps/web/app/(public)/[orgSlug]/[linkSlug]/actions/create-booking.ts`

```typescript
// After successful booking creation
const syncResult = await syncBookingToDatabase(params);

try {
  await emitWebhook(
    organizationId,
    "call.booked",
    transformCallForWebhook(syncResult.call),
  );
} catch (error) {
  logger.warn({ error }, "Failed to emit call.booked webhook");
}
```

### Call Outcome Update (call.completed)

See: `apps/web/app/(protected)/calls/_actions/update-call-outcome.ts`

```typescript
// After updating call outcome to "closed"
const updatedCall = await callsRepository.update(orgId, callId, {
  outcome: "closed"
});

if (updatedCall.outcome === "closed") {
  try {
    await emitWebhook(
      organizationId,
      "call.completed",
      transformCallForWebhook(updatedCall),
    );
  } catch (error) {
    logger.warn({ error }, "Failed to emit call.completed webhook");
  }
}
```

### Lead Status Change (lead.status_changed)

See: `apps/web/app/(protected)/opportunities/actions/update-lead-status.ts`

```typescript
// After updating lead status
const updatedLead = await leadsRepository.update(orgId, leadId, {
  status: newStatus
});

try {
  await emitWebhook(
    organizationId,
    "lead.status_changed",
    transformLeadForWebhook(updatedLead),
  );
} catch (error) {
  logger.warn({ error }, "Failed to emit lead.status_changed webhook");
}
```

### Payment Success (payment.succeeded)

See: `apps/web/app/(protected)/calls/_actions/mark-payment-received.ts`

```typescript
// After recording successful payment
const payment = await paymentsRepository.create(orgId, paymentData);

if (payment.status === "succeeded") {
  try {
    await emitWebhook(
      organizationId,
      "payment.succeeded",
      transformPaymentForWebhook(payment),
    );
  } catch (error) {
    logger.warn({ error }, "Failed to emit payment.succeeded webhook");
  }
}
```

---

## Webhook Payload Format

All webhooks follow this structure:

```typescript
{
  "event": "call.booked",
  "created_at": "2026-01-17T08:00:00Z",
  "data": {
    // Event-specific data (e.g., call details)
  },
  "organization_id": "org_xxx"
}
```

---

## Security

### HMAC Signature Verification

All webhook requests include an `X-[APP]-Signature` header with an HMAC-SHA256 signature.

**Partner verification example (Node.js)**:

```javascript
const crypto = require('crypto');

function verifyWebhookSignature(payload, signature, secret) {
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

// In webhook endpoint
app.post('/webhooks/[your-app]', (req, res) => {
  const signature = req.headers['x-[app]-signature'];
  const isValid = verifyWebhookSignature(
    req.body,
    signature,
    process.env.[APP]_WEBHOOK_SECRET
  );

  if (!isValid) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  // Process webhook...
});
```

---

## Retry Logic

Webhooks automatically retry on failure:

| Attempt | Delay |
|---------|-------|
| 1st retry | 1 second |
| 2nd retry | 5 seconds |
| 3rd retry | 15 seconds |

- **Max retries**: 3
- **Timeout**: 10 seconds per request

---

## Best Practices

### 1. Always Use Try-Catch

Webhook failures should never break user actions:

```typescript
// Good - non-blocking
try {
  await emitWebhook(orgId, "lead.created", data);
} catch (error) {
  logger.warn({ error }, "Failed to emit webhook");
}

// Bad - could break user action
await emitWebhook(orgId, "lead.created", data);  // No error handling!
```

### 2. Emit After DB Commit

Only emit webhooks after successful database writes:

```typescript
// Good
const lead = await leadsRepository.create(data);  // DB first
await emitWebhook(orgId, "lead.created", lead);   // Webhook after

// Bad
await emitWebhook(orgId, "lead.created", data);   // Before DB!
const lead = await leadsRepository.create(data);
```

### 3. Use Correct Event Types

Match the semantic meaning of the action:

```typescript
// Good - semantic event
await emitWebhook(orgId, "lead.status_changed", lead);

// Bad - generic event
await emitWebhook(orgId, "lead.updated", lead);  // Less specific
```

### 4. Transform Data

Never emit raw database records:

```typescript
// Good
await emitWebhook(orgId, "call.booked", transformCallForWebhook(call));

// Bad
await emitWebhook(orgId, "call.booked", call);  // Exposes internals!
```

### 5. Log Failures

Use structured logging for debugging:

```typescript
logger.warn({
  error,
  eventType: "lead.created",
  leadId: lead.id
}, "Failed to emit webhook");
```

---

## Environment Variables

Required in web app `.env`:

```bash
# API URL for webhook emission
NEXT_PUBLIC_API_URL=http://localhost:3001

# Service role key for internal API calls
API_SERVICE_ROLE_KEY=your-service-role-key-here
```

---

## Testing Webhooks

### Test webhook endpoint

```bash
curl -X POST https://api.[YOUR_DOMAIN]/v1/webhooks/test \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "subscription_id": "550e8400-e29b-41d4-a716-446655440000"
  }'
```

### Check webhook deliveries

```sql
-- Recent webhook deliveries
SELECT
  ws.event_type,
  ws.target_url,
  COUNT(*) as attempt_count
FROM webhook_subscriptions ws
WHERE ws.organization_id = 'org_xxx'
GROUP BY ws.event_type, ws.target_url;
```

---

## Troubleshooting

### Webhooks Not Being Delivered

1. Check API service role key is set in web app environment
2. Verify internal webhook endpoint is accessible
3. Check API logs for delivery failures
4. Test partner endpoint is publicly accessible over HTTPS

### Invalid Signature Errors

1. Ensure partner is using the correct secret from subscription creation
2. Verify payload is being stringified with `JSON.stringify()` before hashing
3. Check for character encoding issues

### Duplicate Webhook Deliveries

1. Partners should implement idempotency using the `created_at` timestamp
2. Store processed webhook IDs to prevent duplicate processing
3. Consider using database constraints on event IDs
