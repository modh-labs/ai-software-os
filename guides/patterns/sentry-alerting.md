---
title: "Sentry Alerting Configuration"
description: "How to set up Sentry alerts with Slack integration for your application."
tags: ["sentry", "observability", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# Sentry Alerting Configuration

This guide documents how to set up Sentry alerts with Slack integration for your application.

## Slack Channels

Create these Slack channels for alert routing:

| Channel | Purpose | Alert Types |
|---------|---------|-------------|
| `#alerts-critical` | P1 issues requiring immediate attention | Payment failures, auth failures, circuit breakers opening |
| `#alerts-performance` | Performance degradation | Slow queries, slow actions, Web Vitals regressions |
| `#alerts-errors` | Error spike detection | Error rate increases, new error types |

## Alert Rules to Configure

### 1. Critical: Payment Processing Failures

**Trigger:** Any error with tag `domain:payment`

```
Conditions:
- Event tagged with domain = "payment"
- Error level = error

Actions:
- Send Slack notification to #alerts-critical
- Include: error message, user email, amount, Stripe charge ID
```

**Sentry UI Path:** Settings → Alerts → Create Alert → Issue Alert

### 2. Critical: Authentication Failures

**Trigger:** Spike in auth-related errors

```
Conditions:
- Event tagged with domain = "auth"
- Error count > 5 in 5 minutes

Actions:
- Send Slack notification to #alerts-critical
```

### 3. Critical: Circuit Breaker Opened

**Trigger:** Any circuit breaker opens

```
Conditions:
- Message contains "Circuit breaker OPENED"
- Level = warning

Actions:
- Send Slack notification to #alerts-critical
- Include: service name, failure count
```

### 4. Performance: Slow Database Queries

**Trigger:** Very slow queries detected

```
Conditions:
- Message contains "Very slow database query"
- Level = error

Actions:
- Send Slack notification to #alerts-performance
- Include: query name, duration
```

### 5. Performance: Slow Server Actions

**Trigger:** Server actions exceeding thresholds

```
Conditions:
- Message contains "Very slow action"
- Level = error

Actions:
- Send Slack notification to #alerts-performance
```

### 6. Performance: Web Vitals Regression

**Trigger:** Core Web Vitals degrade

```
Conditions:
- Metric: web_vital.lcp.poor > 10 in 1 hour
- OR Metric: web_vital.cls.poor > 10 in 1 hour
- OR Metric: web_vital.inp.poor > 10 in 1 hour

Actions:
- Send Slack notification to #alerts-performance
```

### 7. Errors: Error Rate Spike

**Trigger:** Unusual increase in error volume

```
Conditions:
- Error count increases by 200% compared to previous hour
- Minimum threshold: 10 errors

Actions:
- Send Slack notification to #alerts-errors
```

### 8. Errors: New Issue Type

**Trigger:** First occurrence of a new error

```
Conditions:
- Issue is new (first seen)
- Level = error

Actions:
- Send Slack notification to #alerts-errors
```

## Slack Integration Setup

### Step 1: Install Sentry Slack App

1. Go to Sentry → Settings → Integrations
2. Find "Slack" and click Configure
3. Click "Add Workspace" and authorize

### Step 2: Link Slack Channels

1. In Sentry → Settings → Integrations → Slack
2. Click "Add Channel Mapping"
3. Map each channel to receive alerts

### Step 3: Configure Alert Notifications

For each alert rule:
1. Actions → Send a Slack notification
2. Select the appropriate channel
3. Configure message template (optional)

## Alert Message Templates

### Critical Alert Template
```
:rotating_light: *CRITICAL: {{title}}*

*Environment:* {{environment}}
*First seen:* {{first_seen}}
*Events:* {{count}}

{{culprit}}

<{{link}}|View in Sentry>
```

### Performance Alert Template
```
:warning: *Performance Alert: {{title}}*

*Metric:* {{metric_value}}
*Threshold:* {{threshold}}
*Environment:* {{environment}}

<{{link}}|View Details>
```

## Testing Alerts

### Test Critical Alert
```typescript
// In a test file or console
import { capturePaymentException } from '@/app/_shared/lib/sentry-logger';

capturePaymentException(new Error('Test payment failure'), {
  stripe_charge_id: 'ch_test',
  amount: 10000,
  customer_email: 'test@example.com',
});
```

### Test Performance Alert
```typescript
// Simulate slow query (will trigger if query takes >5s)
import { timedQuery } from '@/app/_shared/lib/query-timing';

await timedQuery('test-slow-query', async () => {
  await new Promise(resolve => setTimeout(resolve, 6000));
  return [];
});
```

## Maintenance

### Weekly Review
- Check #alerts-critical for any patterns
- Review ignored/snoozed alerts
- Adjust thresholds if too noisy or too quiet

### Monthly Review
- Audit alert rules for relevance
- Check Slack channel membership
- Review alert response times

## Escalation Path

1. **L1 - Alert appears in Slack**
   - On-call developer reviews within 15 minutes
   - Acknowledge in thread or resolve

2. **L2 - Not resolved in 30 minutes**
   - Escalate to senior developer
   - Tag in Slack thread

3. **L3 - Production impact > 1 hour**
   - Escalate to engineering lead
   - Consider incident declaration

## Related Documentation

- [Sentry Debugging Guide](./sentry-debugging.md) - Query patterns for investigation
- [Incident Runbook](./incident-runbook.md) - Step-by-step response procedures
- See: `apps/web/app/_shared/lib/circuit-breaker.ts` - Service protection
