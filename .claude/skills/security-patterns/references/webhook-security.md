# Webhook Security Patterns

## Signature Verification by Provider

### Stripe
```typescript
const body = await req.text(); // MUST use text(), not json()
const signature = req.headers.get("stripe-signature")!;
const event = stripe.webhooks.constructEvent(body, signature, webhookSecret);
```

### Clerk (Svix)
```typescript
const body = await req.text();
const headers = {
  "svix-id": req.headers.get("svix-id")!,
  "svix-timestamp": req.headers.get("svix-timestamp")!,
  "svix-signature": req.headers.get("svix-signature")!,
};
const payload = await svix.verify(body, headers);
```

### Nylas
```typescript
const body = await req.text();
const signature = req.headers.get("x-nylas-signature")!;
const isValid = verifyNylasSignature(body, signature, process.env.NYLAS_WEBHOOK_SECRET!);
```

## Replay Protection

```typescript
const MAX_EVENT_AGE_SECONDS = 300; // 5 minutes

const eventAge = Math.floor(Date.now() / 1000) - event.created;
if (eventAge > MAX_EVENT_AGE_SECONDS) {
  return NextResponse.json({ error: "Event too old" }, { status: 400 });
}
```

## Critical: Raw Body Requirement

**ALWAYS** use `req.text()` for the webhook body. Using `req.json()` parses and re-serializes, which changes whitespace/ordering and breaks cryptographic signatures.

```typescript
// ✅ CORRECT
const body = await req.text();
const parsed = JSON.parse(body); // Parse separately after verification

// ❌ WRONG
const body = await req.json(); // Breaks signature!
```
