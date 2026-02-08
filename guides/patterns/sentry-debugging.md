---
title: "Sentry Debugging Workflows"
description: "Quick reference for finding and debugging issues in Sentry."
tags: ["sentry", "observability", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# Sentry Debugging & Observability Guide

Quick reference for finding and debugging issues in Sentry.

---

## Naming Convention Standard

**All attributes use snake_case for uniform searching across logs, traces, and errors.**

```
organization_id:org_xyz     # One query finds everything
user_id:user_abc            # Works in Issues, Logs, and Performance
```

| Context | Standard Format | Example |
|---------|-----------------|---------|
| Organization | `organization_id` | `organization_id:org_xyz789` |
| User | `user_id` | `user_id:user_abc123` |
| Request | `request_id` | `request_id:req_abc123` |
| Session | `session_id` | `session_id:sess_xyz` |
| Booking prefix | `booking_*` | `booking_organization_id:org_xyz` |
| Webhook prefix | `webhook_*` | `webhook_provider:stripe` |

---

## Auto-Injected Attributes

These are automatically added to every log, error, and trace:

### User & Organization

| Attribute | Values | Use Case | Query Example |
|-----------|--------|----------|---------------|
| `user_id` | `user_abc123` | Find all issues for a user | `user_id:user_abc123` |
| `organization_id` | `org_xyz789` | Filter by org ID | `organization_id:org_xyz789` |
| `organization_slug` | `acme-corp` | Filter by org slug | `organization_slug:acme-corp` |
| `organization_role` | `org:admin`, `org:member` | Find issues by role | `organization_role:org:admin` |

**Set by:** `context-manager.ts`, `sentry-logger.ts`, `context-enrichment-processor.ts`

---

### Request Context

| Attribute | Values | Use Case | Query Example |
|-----------|--------|----------|---------------|
| `request_id` | `req_abc123` | Trace a request end-to-end | `request_id:req_abc123` |
| `request_path` | `/api/webhooks/stripe` | Find errors on routes | `request_path:/api/webhooks/*` |
| `request_method` | `GET`, `POST`, `PUT` | Filter by HTTP method | `request_method:POST` |
| `session_id` | `sess_xyz` | Session tracking | `session_id:sess_xyz` |

**Set by:** `context-manager.ts`, `sentry-logger.ts`

---

## Domain-Specific Attributes

### Webhook Tags

| Attribute | Values | Use Case | Query Example |
|-----------|--------|----------|---------------|
| `webhook_provider` | `nylas`, `stripe`, `clerk` | Find issues by integration | `webhook_provider:stripe` |
| `webhook_event_type` | `booking.created`, `payment_intent.succeeded` | Filter by event | `webhook_event_type:booking.*` |
| `webhook_handler` | Handler function name | Debug specific handler | `webhook_handler:handlePaymentSucceeded` |
| `webhook_organization_id` | Org ID | Webhook issues for org | `webhook_organization_id:org_xyz` |
| `webhook_booking_id` | Booking UUID | Trace booking webhook | `webhook_booking_id:<uuid>` |
| `webhook_call_id` | Call UUID | Trace call webhook | `webhook_call_id:<uuid>` |
| `webhook_payment_id` | Stripe payment ID | Trace payment | `webhook_payment_id:pi_*` |
| `webhook_customer_id` | Stripe customer ID | Customer issues | `webhook_customer_id:cus_*` |

**Set by:** `webhook-logger.ts`

---

### Booking Flow Tags

| Attribute | Values | Use Case | Query Example |
|-----------|--------|----------|---------------|
| `booking_session_id` | UUID | Trace entire booking | `booking_session_id:<uuid>` |
| `booking_organization_id` | Org ID | Booking issues for org | `booking_organization_id:org_xyz` |
| `booking_organization_slug` | Org slug | Issues by slug | `booking_organization_slug:acme` |
| `booking_link_id` | Link UUID | Issues on booking link | `booking_link_id:<uuid>` |
| `booking_link_slug` | Link slug | Issues by link slug | `booking_link_slug:intro-call` |
| `booking_scheduler_timezone` | `America/New_York` | Scheduler timezone | `booking_scheduler_timezone:*` |
| `booking_browser_timezone` | `Europe/London` | User's timezone | `booking_browser_timezone:*` |
| `booking_timezone_offset_hours` | `-5`, `0`, `5.5` | Debug timezone issues | `booking_timezone_offset_hours:!0` |
| `booking_error_stage` | `date_selection`, `form_submit` | Where booking failed | `booking_error_stage:form_submit` |
| `booking_confirmed` | `true`, `false` | Confirmation status | `booking_confirmed:true` |

**Set by:** `booking-tracing.ts`

---

### Logger Module Tags

| Attribute Value | Use Case | Query Example |
|-----------------|----------|---------------|
| `module:auth` | Authentication issues | `module:auth level:error` |
| `module:api` | API handler issues | `module:api level:error` |
| `module:webhooks` | Webhook processing | `module:webhooks level:error` |
| `module:scheduler` | Scheduling logic | `module:scheduler` |
| `module:ai` | AI/LLM operations | `module:ai level:error` |

**Set by:** `sentry-logger.ts` (module loggers)

---

## Quick Queries

### By User/Organization
```
user_id:user_abc123                    # Specific user
organization_id:org_xyz789             # Specific org
organization_slug:acme-corp            # Org by slug
```

### By Error Type
```
is:unresolved                          # All open issues
is:unresolved is:unassigned            # Unassigned issues
level:error                            # Errors only
level:fatal                            # Fatal crashes
handled:no                             # Unhandled exceptions
```

### By Time
```
firstSeen:-24h                         # New in last 24h
lastSeen:-1h                           # Active in last hour
firstSeen:-7d is:unresolved            # New this week, still open
```

### By Location
```
request_path:/api/webhooks/*           # Webhook errors
request_method:POST                    # POST requests
module:webhooks                        # Webhook module logs
```

---

## Traces (Performance Page)

### Find Slow Operations
```
transaction.duration:>5s               # Requests over 5 seconds
transaction.duration:>1s http.method:POST   # Slow mutations
```

### By Organization/User
```
organization_id:org_xyz789             # Org's traces
user_id:user_abc123                    # User's traces
```

### AI Operations
```
ai.pipeline.name:*                     # All AI calls
ai.model.id:claude-*                   # Claude model calls
ai.total_tokens.used:>1000             # Large token usage
```

---

## Logs (Explore -> Logs)

### By Level
```
level:error                            # Errors
level:warn                             # Warnings
level:info                             # Info
```

### By Context (snake_case - same as Issues/Traces!)
```
organization_id:org_xyz789             # Org's logs
user_id:user_abc123                    # User's logs
request_id:req_xyz                     # Request trace
call_id:uuid-here                      # Specific call
```

### By Module
```
module:webhook                         # Webhook logs
module:scheduler                       # Scheduler logs
module:ai                              # AI/LLM logs
```

---

## Debugging Scenarios

### Scenario 1: "User reported a bug"
```bash
# 1. Find their recent errors (Issues page)
user_id:user_abc123 is:unresolved lastSeen:-24h

# 2. Check their logs (Logs page)
user_id:user_abc123 level:error

# 3. Look at session replay (Replays page)
user.id:user_abc123 has:error
```

### Scenario 2: "Webhook failed"
```bash
# 1. Find webhook errors
webhook_provider:stripe level:error

# 2. Check by organization
webhook_organization_id:org_xyz level:error

# 3. Find specific request
request_id:req_xyz
```

### Scenario 3: "Booking flow broken"
```bash
# 1. Find booking errors
booking_organization_id:org_xyz level:error

# 2. Check timezone issues
booking_timezone_offset_hours:!0 level:error

# 3. Find by session
booking_session_id:<uuid>
```

### Scenario 4: "AI call failed"
```bash
# 1. Find AI errors
module:ai level:error

# 2. Check by organization
organization_id:org_xyz module:ai

# 3. Look at token usage
ai.total_tokens.used:>5000
```

---

## Developer Quick Reference

### When to Use Each Capture Function

| Scenario | Function | Example |
|----------|----------|---------|
| Booking API fails | `captureBookingException` | Nylas timeout, validation error |
| Payment processing fails | `capturePaymentException` | Stripe error, match failure |
| Media processing fails | `captureMediaException` | Download timeout, AI failure |
| Calendar/grant fails | `captureGrantException` | Token expired, connection lost |
| Auth sync fails | `captureClerkException` | User/org sync, seat sync |
| Email delivery fails | `captureEmailException` | Resend API error |
| AI analysis fails | `captureAIException` | Outcome determination, scoring |
| Webhook handler fails | `captureWebhookException` | Generic webhook failures |

### Decision Tree

```
Is there a logger.error() call?
  ├── YES → Does the failure impact the user?
  │           ├── YES → Add captureXxxException()
  │           └── NO  → Keep logger.error() only (non-blocking)
  └── NO  → Is it a recoverable transient error?
              ├── YES → logger.warn() only
              └── NO  → Add captureXxxException()
```

### Quick Import Pattern

```typescript
import {
  captureBookingException,
  capturePaymentException,
  captureMediaException,
  captureClerkException,
  captureEmailException,
  captureGrantException,
  captureAIException,
  captureWebhookException,
} from "@/app/_shared/lib/sentry-logger";
```

### Stage Values by Domain

| Domain | Common Stages |
|--------|---------------|
| Booking | `nylas_api`, `nylas_timeout`, `db_sync`, `webhook_sync`, `email`, `cancel`, `reschedule` |
| Payment | `stripe_webhook`, `payment_storage`, `payment_matching`, `lead_status_update` |
| Media | `download`, `storage_upload`, `metadata_fetch`, `all_retries_exhausted` |
| Clerk | `user_created`, `user_updated`, `user_deleted`, `org_created`, `membership_created`, `membership_deleted`, `billing_check` |
| Email | `booking_confirmation`, `booking_cancellation`, `booking_reschedule`, `participant_notification` |
| Grant | `creation`, `validation`, `refresh`, `expiration_cleanup`, `deletion` |
| AI | `outcome_determination`, `sales_scoring`, `translation`, `transcript_summary` |

---

## Attribute Reference by File

| File | Attributes Set |
|------|----------------|
| `context-manager.ts` | `organization_id`, `organization_slug`, `organization_role`, `request_id`, `request_path`, `request_method` |
| `sentry-logger.ts` | `user_id`, `organization_id`, `organization_slug`, `request_id`, `session_id`, `module` |
| `context-enrichment-processor.ts` | `user_id`, `organization_id`, `organization_slug`, `request_id`, `session_id` (on OTEL spans) |
| `booking-tracing.ts` | `booking_*` attributes |
| `webhook-logger.ts` | `webhook_*` attributes |

---

## Pro Tips

1. **One search works everywhere** - `organization_id:org_xyz` finds logs, errors, AND traces

2. **Combine queries** with spaces (AND) or `OR`:
   ```
   is:unresolved user_id:abc OR user_id:xyz
   ```

3. **Negate with `!`**:
   ```
   is:unresolved !environment:development
   ```

4. **Wildcards with `*`**:
   ```
   request_path:/api/webhooks/*
   webhook_event_type:booking.*
   ```

5. **Save frequent searches** - Click "Save Search" in Sentry UI

6. **Create alerts** for critical queries:
   - `level:error organization_id:org_xyz` -> Slack alert
   - `webhook_provider:stripe level:error` -> PagerDuty

---

## Local Development (Spotlight)

```bash
pnpm dev:spotlight          # Start with Spotlight
# Open http://localhost:8969
```

Same queries work in Spotlight with:
- Real-time event streaming
- No sampling (100% of events)
- Click any event -> full trace view

---

## Critical Error Alerting

### Critical Error Tags

your project uses structured tags for critical failures that enable targeted alerting:

| Error Type | Tag | Description |
|------------|-----|-------------|
| Booking Failures | `booking.critical: true` | Calendar booking API failures |
| Media Processing | `media.critical: true` | Recording download/processing failures |
| Payment Processing | `payment.critical: true` | Stripe webhook/storage/matching failures |
| Webhook Failures | `webhook.critical: true` | Nylas/Stripe handler failures |
| AI Analysis | `ai.critical: true` | Transcript analysis/outcome determination |
| **Clerk Auth** | `clerk.critical: true` | User/org sync failures (🚨 SECURITY) |
| **Email Delivery** | `email.critical: true` | Booking confirmation/cancellation emails |
| **Grant Management** | `grant.critical: true` | Calendar connectivity failures |

### Critical Error Queries

```
# All booking failures
is:unresolved tags[booking.critical]:true

# By failure stage
tags[booking.stage]:nylas_api
tags[booking.stage]:nylas_timeout
tags[booking.stage]:db_sync

# Media failures (recording download failed after all retries)
tags[media.critical]:true tags[media.stage]:all_retries_exhausted

# Payment failures (including unmatched payments needing manual reconciliation)
tags[payment.critical]:true
tags[payment.stage]:payment_matching

# AI analysis failures
tags[ai.critical]:true tags[ai.stage]:outcome_determination

# 🚨 SECURITY: Clerk auth sync failures
# User may have been removed from org but still has access!
tags[clerk.critical]:true
tags[clerk.stage]:membership_deleted
tags[clerk.stage]:billing_check

# Email delivery failures (guests won't know about their meetings!)
tags[email.critical]:true
tags[email.type]:booking_confirmation
tags[email.type]:booking_cancellation
tags[email.type]:booking_reschedule

# Grant management failures (calendar connectivity broken)
tags[grant.critical]:true
tags[grant.stage]:expiration_cleanup
```

### Setting Up Slack Alerts (Sentry UI)

#### Step 1: Connect Slack Integration

1. Go to **Settings > Integrations > Slack**
2. Click "Add to Slack" and authorize
3. Create Slack channels:
   - `#booking-alerts` - Booking failures (CRITICAL)
   - `#payment-alerts` - Payment failures (CRITICAL)
   - `#ops-alerts` - Media/AI/webhook failures

#### Step 2: Create Issue Alerts

Go to **Alerts > Create Alert > Issue Alert**

**Booking Critical Failure:**
```yaml
Name: "Booking Critical Failure"
Environment: production
Conditions:
  - An issue's tags match: booking.critical equals true
Actions:
  - Send Slack notification to #booking-alerts
```

**Payment Critical Failure:**
```yaml
Name: "Payment Critical Failure"
Environment: production
Conditions:
  - An issue's tags match: payment.critical equals true
Actions:
  - Send Slack notification to #payment-alerts
```

**Media Processing Failure:**
```yaml
Name: "Media Processing Failure"
Environment: production
Conditions:
  - An issue's tags match: media.critical equals true
Actions:
  - Send Slack notification to #ops-alerts
```

**🚨 Clerk Auth Critical (SECURITY):**
```yaml
Name: "Clerk Auth Critical"
Environment: production
Conditions:
  - An issue's tags match: clerk.critical equals true
Actions:
  - Send Slack notification to #ops-alerts
  - Note: membership_deleted failures = user keeps access after removal!
```

**Email Delivery Critical:**
```yaml
Name: "Email Delivery Critical"
Environment: production
Conditions:
  - An issue's tags match: email.critical equals true
Actions:
  - Send Slack notification to #ops-alerts
```

**Grant Management Critical:**
```yaml
Name: "Grant Management Critical"
Environment: production
Conditions:
  - An issue's tags match: grant.critical equals true
Actions:
  - Send Slack notification to #ops-alerts
```

### Exception Capture Helpers

The codebase provides typed helpers in `sentry-logger.ts`:

```typescript
// Booking failures
import { captureBookingException } from '@/app/_shared/lib/sentry-logger';
captureBookingException(error, {
  sessionId, organizationId, guestEmail, configurationId,
  stage: 'nylas_api', // nylas_api | nylas_timeout | db_sync | email | cancel | reschedule
  metadata: { status: 500 }
});

// Media failures
import { captureMediaException } from '@/app/_shared/lib/sentry-logger';
captureMediaException(error, {
  callId, organizationId,
  stage: 'all_retries_exhausted', // download | storage_upload | metadata_fetch
  metadata: { retry_count: 3 }
});

// Payment failures
import { capturePaymentException } from '@/app/_shared/lib/sentry-logger';
capturePaymentException(error, {
  organizationId,
  stage: 'stripe_webhook', // stripe_webhook | payment_storage | payment_matching
  stripeEventId: event.id,
  stripeEventType: 'charge.succeeded',
  amount: 9900
});

// AI analysis failures
import { captureAIException } from '@/app/_shared/lib/sentry-logger';
captureAIException(error, {
  callId, organizationId,
  stage: 'outcome_determination', // outcome_determination | sales_scoring | translation
  model: 'gpt-4o'
});

// Webhook failures
import { captureWebhookException } from '@/app/_shared/lib/sentry-logger';
captureWebhookException(error, {
  source: 'nylas', // nylas | stripe | clerk | other
  eventType: 'grant.expired',
  organizationId,
  stage: 'grant_cleanup'
});

// 🚨 Clerk auth failures (SECURITY CRITICAL)
import { captureClerkException } from '@/app/_shared/lib/sentry-logger';
captureClerkException(error, {
  clerkUserId, clerkOrgId, eventType: 'organizationMembership.deleted',
  stage: 'membership_deleted', // user_created | user_deleted | membership_deleted | billing_check
  metadata: { security_impact: 'USER_RETAINS_ACCESS' }
});

// Email delivery failures (customer experience)
import { captureEmailException } from '@/app/_shared/lib/sentry-logger';
captureEmailException(error, {
  organizationId, recipientEmail, callId,
  emailType: 'booking_confirmation', // booking_confirmation | booking_cancellation | booking_reschedule
  metadata: { error_message: error.message }
});

// Grant management failures (calendar connectivity)
import { captureGrantException } from '@/app/_shared/lib/sentry-logger';
captureGrantException(error, {
  grantId, organizationId, userId,
  stage: 'expiration_cleanup', // creation | validation | refresh | expiration_cleanup | deletion
  metadata: { provider: 'google' }
});
```

### Error Fingerprinting

Each exception type uses a fingerprint for grouping:

| Type | Fingerprint |
|------|-------------|
| Booking | `["booking-failure", stage, organizationId]` |
| Media | `["media-failure", stage, organizationId]` |
| Payment | `["payment-failure", stage, organizationId]` |
| AI | `["ai-failure", stage, organizationId]` |
| Webhook | `["webhook-failure", source, stage, organizationId]` |
| Clerk | `["clerk-failure", stage, organizationId]` |
| Email | `["email-failure", emailType, organizationId]` |
| Grant | `["grant-failure", stage, organizationId]` |

### Recovery Queries (Supabase)

**Failed Bookings:**
```sql
SELECT session_id, email, phone, full_name, selected_start_time, timezone
FROM booking_intent_tracking
WHERE stage = 'booking_attempted'
  AND call_id IS NULL
  AND organization_id = 'org_xxx'
  AND last_activity_at > NOW() - INTERVAL '24 hours'
ORDER BY last_activity_at DESC;
```

**Failed Media Processing:**
```sql
SELECT id, organization_id, media_processing_status, media_processing_error
FROM calls
WHERE media_processing_status = 'failed'
  AND organization_id = 'org_xxx'
  AND updated_at > NOW() - INTERVAL '24 hours';
```

**Unmatched Payments (Revenue at Risk):**
```sql
SELECT id, stripe_charge_id, customer_email, customer_name, amount, payment_date
FROM payments
WHERE verification_status = 'unverified'
  AND organization_id = 'org_xxx'
  AND payment_date > NOW() - INTERVAL '7 days'
ORDER BY payment_date DESC;
```

**Expired Grants Without Cleanup:**
```sql
SELECT id, user_id, grant_id, provider, connection_status, updated_at
FROM nylas_connections
WHERE connection_status = 'expired'
  AND updated_at > NOW() - INTERVAL '24 hours';
```
