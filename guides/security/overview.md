---
title: "Security Architecture Overview"
description: "This is a multi-tenant SaaS application with the following security architecture:"
tags: ["security", "architecture"]
category: "security"
author: "Imran Gardezi"
publishable: true
---
# Security Overview — SOC2 Auditor Reference

## Architecture Summary

This is a multi-tenant SaaS application with the following security architecture:

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Identity** | Clerk | User authentication, MFA, organization management |
| **Authorization** | Clerk JWT → Supabase RLS | Org-scoped access at database level |
| **API Auth** | API Keys (SHA-256 hashed) + Clerk JWT | Partner and first-party app authentication |
| **Encryption** | AES-256-GCM | Integration credentials encrypted at rest |
| **Audit** | Immutable `audit_logs` table | Full lifecycle tracking with actor/IP/changes |
| **Input Validation** | Zod schemas | All server actions and API endpoints validated |
| **Rate Limiting** | Redis + in-memory fallback | Per-key, per-org sliding window limits |
| **Observability** | Sentry + structured logging | Error tracking, tracing, profiling |

## Controls Matrix

### CC6 — Logical and Physical Access Controls

| Control | Implementation | Evidence |
|---------|---------------|----------|
| **CC6.1** Credential lifecycle | API key create/revoke/delete audit logged | `api-keys/actions.ts` → `logAuditAsync()` |
| **CC6.1** Key storage | SHA-256 hashed, plaintext never stored | `api-keys.repository.ts` |
| **CC6.1** Key expiry | Optional expiry, checked on every request | `api-key-auth.ts` middleware |
| **CC6.2** MFA | Clerk-managed (configurable per org) | Clerk dashboard |
| **CC6.3** Role-based access | org:admin, org:member roles via Clerk | `auth()` checks in server actions |
| **CC6.6** Data isolation | RLS on all public tables | `scripts/verify-rls-coverage.sql` |
| **CC6.7** Encryption at rest | AES-256-GCM for integration creds | `encryption/credentials.ts` |
| **CC6.8** Encryption in transit | HSTS preload, TLS enforced | `next.config.mjs` headers |

### CC7 — System Operations & Monitoring

| Control | Implementation | Evidence |
|---------|---------------|----------|
| **CC7.1** Vulnerability scanning | Dependabot + `bun audit` in CI | `.github/dependabot.yml`, `ci.yml` |
| **CC7.2** Monitoring | Sentry errors, rate limit alerts | `sentry.server.config.ts` |
| **CC7.3** Audit trail | Immutable logs, 1-year retention | `audit_logs` table, `data-retention.md` |
| **CC7.4** Incident response | Documented response plan | `incident-response.md` |

### CC8 — Change Management

| Control | Implementation | Evidence |
|---------|---------------|----------|
| **CC8.1** CI/CD quality gate | Lint + typecheck + test on every PR | `.github/workflows/ci.yml` |
| **CC8.1** Pre-commit hooks | Block .env files, run linting | Husky + lint-staged config |
| **CC8.1** Frozen lockfile | `bun install --frozen-lockfile` in CI | `ci.yml` |

## CORS Policy (Partner API)

The Partner API at `api.[YOUR_DOMAIN]` uses `origin: "*"` CORS policy. This is intentional and secure because:

1. **No cookie-based auth:** The API authenticates via `Authorization: Bearer <api_key>` header
2. **No ambient credentials:** Browsers don't auto-attach API keys to cross-origin requests
3. **No CSRF risk:** Without ambient credentials, CORS restrictions provide no security benefit
4. **Industry standard:** Stripe, Twilio, SendGrid, and other API-key-authenticated services use the same pattern

If the API ever adds cookie-based auth (e.g., for a first-party SPA), CORS must be restricted to specific origins.

## Webhook Security

### Signature Verification

| Provider | Verification Method | Implementation |
|----------|-------------------|----------------|
| **Clerk** | Svix signature verification | `svix.verify()` in webhook route |
| **Stripe** | `stripe.webhooks.constructEvent()` | Stripe SDK signature check |
| **Nylas** | HMAC-SHA256 signature | Manual HMAC verification |
| **Dub** | Dub SDK signature verification | `dub.webhooks.verify()` |
| **Mux** | Mux signature header | `Mux.Webhooks.unwrap()` |

### Idempotency Status

| Provider | Idempotency | Mechanism |
|----------|-------------|-----------|
| **Stripe (Billing)** | Yes | `stripe_events` table, `isEventProcessed()` |
| **Stripe (Payments)** | Yes | `createPaymentIdempotent()`, provider_payment_id dedup |
| **Nylas** | Yes | `webhook_events` table upsert on (provider, event_id) |
| **Clerk** | Partial | Database UPSERT on primary key (defensive) |
| **Dub** | No | Needs `webhook_events` integration |
| **Mux** | No | Needs `webhook_events` integration |

## Security Headers

All routes include:
- `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
- `X-Content-Type-Options: nosniff`
- `Content-Security-Policy` (route-specific)
- `Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=(), usb=(), bluetooth=()`
- `Referrer-Policy: origin-when-cross-origin`
- `X-XSS-Protection: 1; mode=block`

### CSP Violation Reporting

To enable CSP violation reporting to Sentry, add the `report-uri` directive using your Sentry DSN:

```
report-uri https://sentry.io/api/{PROJECT_ID}/security/?sentry_key={PUBLIC_KEY}
```

Extract `PROJECT_ID` and `PUBLIC_KEY` from the `NEXT_PUBLIC_SENTRY_DSN` environment variable.

## GraphQL Introspection

- **Development:** Introspection enabled for playground Docs tab
- **Production:** Disabled at two layers:
  1. Hono middleware requires auth for all POST requests (including introspection)
  2. graphql-yoga `useDisableIntrospection()` plugin rejects introspection queries

## PII Handling

Built-in masking utilities (`app/_shared/lib/pii/`) mask:
- Email addresses
- Phone numbers
- Credit card numbers
- API tokens
- URLs with query parameters

Used in logging and error reporting to prevent PII leakage.

## Related Documentation

- [Access Control](./access-control.md) — Auth layers and data flow
- [Incident Response](./incident-response.md) — Security incident procedures
- [Key Rotation](./key-rotation.md) — Credential rotation policy
- [Data Retention](./data-retention.md) — Log retention and archival
