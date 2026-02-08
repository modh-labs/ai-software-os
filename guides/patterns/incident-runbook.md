---
title: "Incident Runbook: Response and Recovery"
description: "Step-by-step procedures for common production incidents in your application."
tags: ["observability", "architecture", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# Incident Runbook

Step-by-step procedures for common production incidents in your application.

## Quick Links

| Resource | URL |
|----------|-----|
| Sentry Dashboard | https://[YOUR_ORG].sentry.io/projects/[YOUR_PROJECT]/ |
| Vercel Dashboard | https://vercel.com/[YOUR_ORG]/[YOUR_REPO] |
| Supabase Dashboard | https://supabase.com/dashboard/project/[PROJECT_ID] |
| Stripe Dashboard | https://dashboard.stripe.com/ |
| Nylas Dashboard | https://dashboard.nylas.com/ |

---

## Incident Response Framework

### Severity Levels

| Level | Definition | Response Time | Example |
|-------|------------|---------------|---------|
| **P1 - Critical** | Service down, data loss, payment failures | < 15 min | Payment processing broken |
| **P2 - High** | Major feature broken, degraded performance | < 1 hour | Booking scheduler not working |
| **P3 - Medium** | Minor feature broken, workaround exists | < 4 hours | Export feature failing |
| **P4 - Low** | Cosmetic issues, minor bugs | Next business day | UI alignment issue |

### Response Steps

1. **Acknowledge** - Respond in Slack within SLA
2. **Assess** - Determine severity and impact
3. **Communicate** - Update stakeholders if P1/P2
4. **Investigate** - Use Sentry/logs to identify root cause
5. **Mitigate** - Apply fix or workaround
6. **Verify** - Confirm resolution
7. **Document** - Update this runbook if new scenario

---

## Common Incidents

### 1. Payment Processing Failures

**Symptoms:**
- Slack alert in #alerts-critical with "domain:payment"
- Users report payments not going through
- Stripe webhook errors in Sentry

**Investigation:**
```bash
# Check Sentry for payment errors
# Search: domain:payment is:unresolved

# Check Stripe webhook status
# Dashboard → Developers → Webhooks → Recent events
```

**Common Causes & Fixes:**

| Cause | Fix |
|-------|-----|
| Stripe API down | Check [status.stripe.com](https://status.stripe.com), wait for recovery |
| Webhook secret mismatch | Verify `STRIPE_WEBHOOK_SECRET` in Vercel env vars |
| Database connection issue | Check Supabase status, restart if needed |
| Payment amount validation | Check business logic in `stripe-payments/route.ts` |

**Mitigation:**
```typescript
// If webhook is failing, payments still process in Stripe
// Manual reconciliation: Check Stripe dashboard for successful charges
// Run manual sync if needed (future: add manual sync endpoint)
```

---

### 2. Circuit Breaker Opened

**Symptoms:**
- Slack alert: "Circuit breaker OPENED"
- Users see "Service temporarily unavailable" errors
- Feature depending on external service stops working

**Investigation:**
```bash
# Check which service opened
# Sentry search: "Circuit breaker OPENED"

# Check Redis for circuit state
# Use Upstash console to view: circuit-breaker:{service-name}
```

**Services & Recovery:**

| Service | Typical Cause | Recovery |
|---------|---------------|----------|
| `nylas` | Nylas API degradation | Wait for recovery, circuit auto-closes after 60s |
| `stripe` | Stripe API issues | Check status.stripe.com |
| `openai` | Rate limits or outage | Wait 30s, circuit auto-closes |
| `anthropic` | API issues | Wait 30s, circuit auto-closes |

**Manual Reset (if needed):**
```typescript
// In server console or test file
import { resetCircuitBreaker } from '@/app/_shared/lib/circuit-breaker';

await resetCircuitBreaker('nylas');
```

---

### 3. Database Connection Issues

**Symptoms:**
- Multiple errors across features
- "Connection refused" or timeout errors in Sentry
- Supabase health check failing (`/api/health/ready` returns 503)

**Investigation:**
```bash
# Check health endpoint
curl https://your-domain.com/api/health/ready

# Check Supabase status
# https://status.supabase.com/

# Check connection pool in Supabase dashboard
# Database → Reports → Connections
```

**Common Causes & Fixes:**

| Cause | Fix |
|-------|-----|
| Connection pool exhausted | Increase pool size in Supabase settings |
| Supabase outage | Wait for recovery, check status page |
| RLS policy blocking | Check user JWT claims, verify org_id |
| Query timeout | Check slow query logs, optimize query |

---

### 4. Slow Performance / Timeouts

**Symptoms:**
- Slack alerts in #alerts-performance
- Users report slow page loads
- Web Vitals degrading in Sentry

**Investigation:**
```bash
# Check slow queries in Sentry
# Search: "Very slow database query" OR "Very slow action"

# Check Web Vitals
# Sentry → Performance → Web Vitals

# Check N+1 patterns
# Search: "N+1 query pattern detected"
```

**Common Causes & Fixes:**

| Cause | Fix |
|-------|-----|
| N+1 query pattern | Refactor to use joins or batch queries |
| Missing index | Add database index for slow query |
| Large payload | Paginate results, add limits |
| External API slow | Check circuit breaker, add timeout |

**Quick Wins:**
```typescript
// Add query timing to identify slow spots
import { timedQuery } from '@/app/_shared/lib/query-timing';

const data = await timedQuery('identifySlowQuery', () =>
  repository.fetchData(params)
);
```

---

### 5. Authentication Failures

**Symptoms:**
- Users can't sign in
- "Unauthorized" errors spike
- Clerk webhook failures

**Investigation:**
```bash
# Check Clerk status
# https://status.clerk.com/

# Check Sentry for auth errors
# Search: domain:auth is:unresolved

# Check Clerk webhook logs
# Clerk Dashboard → Webhooks → Logs
```

**Common Causes & Fixes:**

| Cause | Fix |
|-------|-----|
| Clerk outage | Wait for recovery |
| Webhook secret mismatch | Verify `CLERK_WEBHOOK_SECRET` |
| JWT expired/invalid | Check Clerk configuration |
| RLS not recognizing user | Verify JWT claims contain org_id |

---

### 6. Booking/Scheduling Failures

**Symptoms:**
- Users can't book appointments
- Calendar not loading
- Nylas errors in Sentry

**Investigation:**
```bash
# Check Nylas status
# https://status.nylas.com/

# Check circuit breaker state
# Sentry search: service:nylas

# Check grant status in Nylas dashboard
```

**Common Causes & Fixes:**

| Cause | Fix |
|-------|-----|
| Nylas API down | Wait for recovery, circuit breaker protects |
| Grant revoked | User needs to re-authenticate calendar |
| Calendar sync failed | Check Nylas dashboard for sync errors |
| Webhook delivery failed | Check Nylas webhook logs |

---

### 7. Email Delivery Failures

**Symptoms:**
- Users not receiving emails
- Resend errors in Sentry
- Email confirmation not working

**Investigation:**
```bash
# Check Resend status
# https://resend.com/status

# Check Sentry for email errors
# Search: "Failed to send email"

# Check Resend dashboard for delivery logs
```

**Common Causes & Fixes:**

| Cause | Fix |
|-------|-----|
| Resend API down | Wait for recovery |
| Rate limit hit | Check usage in Resend dashboard |
| Invalid email address | Validate email format before sending |
| Domain not verified | Check Resend domain settings |

---

### 8. Deployment Failures

**Symptoms:**
- New deploy not live
- Build errors in Vercel
- CI checks failing

**Investigation:**
```bash
# Check Vercel build logs
# Vercel Dashboard → Deployments → [Latest] → Build Logs

# Check for type errors locally
pnpm typecheck

# Check for test failures
pnpm test:ci
```

**Common Causes & Fixes:**

| Cause | Fix |
|-------|-----|
| Type error | Fix TypeScript errors locally first |
| Missing env var | Add to Vercel environment variables |
| Build timeout | Check for slow build steps |
| Dependency issue | Clear cache: `rm -rf .next node_modules && pnpm install` |

**Rollback (if needed):**
```bash
# In Vercel Dashboard
# Deployments → Find last working deploy → ⋮ → Promote to Production
```

---

## Post-Incident

### Checklist

- [ ] Incident resolved and verified
- [ ] Stakeholders notified of resolution
- [ ] Root cause identified
- [ ] Runbook updated if new scenario
- [ ] Preventive measures documented
- [ ] Linear ticket created for follow-up work

### Post-Mortem Template

```markdown
## Incident: [Title]

**Date:** YYYY-MM-DD
**Duration:** X hours
**Severity:** P1/P2/P3/P4
**Impact:** [User impact description]

### Timeline
- HH:MM - Alert received
- HH:MM - Investigation started
- HH:MM - Root cause identified
- HH:MM - Fix deployed
- HH:MM - Verified resolved

### Root Cause
[Description]

### Resolution
[What was done to fix it]

### Prevention
[What we'll do to prevent recurrence]

### Action Items
- [ ] Item 1
- [ ] Item 2
```

---

## Contacts

| Role | Contact |
|------|---------|
| Engineering Lead | [Name] |
| On-call Developer | Check Slack #dev-oncall |
| Stripe Support | support@stripe.com |
| Nylas Support | support@nylas.com |

---

## Related Documentation

- [Sentry Alerting](./sentry-alerting.md) - Alert configuration
- [Sentry Debugging](./sentry-debugging.md) - Query patterns
- [Circuit Breaker](../apps/web/app/_shared/lib/circuit-breaker.ts) - Service protection
- [Health Checks](../apps/web/app/api/health/) - Monitoring endpoints
