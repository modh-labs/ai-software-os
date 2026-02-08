# Example: Stripe Billing Setup

> Quick start for implementing subscription billing with Stripe, including seat-based pricing and webhook handling.

## What This Covers

- Subscription management (monthly/yearly)
- Seat-based pricing with automatic sync
- Webhook handler architecture (SOLID patterns)
- Idempotent event processing

## Relevant Skills

- `.claude/skills/solid-webhook-patterns/SKILL.md`
- `.claude/skills/webhook-observability/SKILL.md`
- `.claude/skills/security-patterns/SKILL.md`

## Relevant Guides

- `guides/patterns/webhook-patterns.md`
- `guides/patterns/webhook-emission.md`
- `guides/security/overview.md`
- `guides/standards/observability.md`

## Key Patterns

```typescript
// Webhook handler registry pattern
const handlers: Record<string, EventHandler> = {
  "checkout.session.completed": handleCheckoutComplete,
  "customer.subscription.updated": handleSubscriptionUpdate,
  "customer.subscription.deleted": handleSubscriptionDelete,
};

// Each handler is a single-responsibility function
async function handleCheckoutComplete(event: Stripe.Event) {
  const session = event.data.object as Stripe.Checkout.Session;
  // Process checkout...
}
```

## Adaptation Notes

- Replace seat sync logic with your pricing model
- Update webhook event types for your use case
- Configure Stripe webhook endpoint URL
- Set up idempotency keys for retries
