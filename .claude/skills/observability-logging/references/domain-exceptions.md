# Domain-Specific Exception Capture

## How It Works (Post-Dedup Fix)

`capture*Exception()` functions **only** create Sentry Issues. They do NOT log internally.

**Caller pattern:**
```typescript
// 1. Log for debugging (goes to Sentry Logs + Vercel Logs)
logger.error("Booking failed at Nylas API", { session_id, stage: "nylas_api" });

// 2. Capture for alerting (goes to Sentry Issues with fingerprinting)
void captureBookingException(error, { sessionId, organizationId, stage: "nylas_api" });
```

**Data flow per call:**
- `logger.error()` → `Sentry.logger.error()` (Sentry Logs) + `console.log(JSON)` (Vercel Logs)
- `capture*Exception()` → `Sentry.captureException()` (Sentry Issues with tags + fingerprint)

**Result:** Exactly 1 Sentry Log entry + 1 Sentry Issue per error. No duplicates.

## All 12 Capture Functions

### captureBookingException

```typescript
type BookingFailureStage =
  | "validation" | "nylas_api" | "nylas_timeout" | "db_sync"
  | "email" | "notetaker" | "cancel" | "reschedule" | "webhook_sync";

interface BookingExceptionContext {
  sessionId?: string;
  organizationId: string;
  guestEmail?: string;
  configurationId?: string;
  stage: BookingFailureStage;
  metadata?: Record<string, unknown>;
}
```
Tags: `booking.critical`, `booking.stage`, `booking.session_id`, `booking.organization_id`, `booking.configuration_id`
Fingerprint: `["booking-failure", stage, organizationId]`

### captureMediaException

```typescript
type MediaFailureStage =
  | "download" | "download_timeout" | "storage_upload" | "metadata_fetch"
  | "transcript_parse" | "transcript_download" | "thumbnail" | "translation"
  | "all_retries_exhausted";

interface MediaExceptionContext {
  callId: string;
  organizationId?: string;
  stage: MediaFailureStage;
  mediaUrl?: string;
  metadata?: Record<string, unknown>;
}
```
Tags: `media.critical`, `media.stage`, `media.call_id`, `media.organization_id`
Fingerprint: `["media-failure", stage, organizationId?]`

### capturePaymentException

```typescript
type PaymentFailureStage =
  | "stripe_webhook" | "webhook_secret_retrieval" | "api_key_retrieval"
  | "payment_storage" | "payment_matching" | "commission_calculation"
  | "subscription_update" | "refund_processing" | "lead_lookup"
  | "lead_status_update" | "auto_close";

interface PaymentExceptionContext {
  organizationId: string;
  stage: PaymentFailureStage;
  stripeEventId?: string;
  stripeEventType?: string;
  paymentIntentId?: string;
  amount?: number;
  metadata?: Record<string, unknown>;
}
```
Tags: `payment.critical`, `payment.stage`, `payment.organization_id`, `payment.event_type`
Fingerprint: `["payment-failure", stage, organizationId]`

### captureWebhookException

```typescript
type WebhookFailureStage =
  | "signature_verification" | "payload_parse" | "handler_execution"
  | "db_sync" | "side_effect" | "grant_cleanup" | "audit_log" | "event_emission";

interface WebhookExceptionContext {
  source: "nylas" | "stripe" | "clerk" | "zapier" | "other";
  eventType: string;
  eventId?: string;
  organizationId?: string;
  stage: WebhookFailureStage;
  metadata?: Record<string, unknown>;
}
```
Tags: `webhook.critical`, `webhook.source`, `webhook.event_type`, `webhook.stage`, `webhook.organization_id`
Fingerprint: `["webhook-failure", source, stage, organizationId]`

### captureAIException

```typescript
type AIFailureStage =
  | "transcript_analysis" | "outcome_determination" | "sales_scoring"
  | "objection_detection" | "language_detection" | "translation"
  | "summary_generation";

interface AIExceptionContext {
  callId: string;
  organizationId: string;
  stage: AIFailureStage;
  model?: string;
  metadata?: Record<string, unknown>;
}
```
Tags: `ai.critical`, `ai.stage`, `ai.call_id`, `ai.organization_id`, `ai.model`
Fingerprint: `["ai-failure", stage, organizationId]`

### captureClerkException

```typescript
type ClerkFailureStage =
  | "user_created" | "user_updated" | "user_deleted"
  | "org_created" | "org_updated" | "org_deleted"
  | "membership_created" | "membership_updated" | "membership_deleted"
  | "invitation_created" | "invitation_accepted"
  | "stripe_seat_sync" | "billing_check";

interface ClerkExceptionContext {
  clerkUserId?: string;
  clerkOrgId?: string;
  eventType: string;
  stage: ClerkFailureStage;
  metadata?: Record<string, unknown>;
}
```
Tags: `clerk.critical`, `clerk.stage`, `clerk.event_type`, `clerk.user_id`, `clerk.org_id`
Fingerprint: `["clerk-failure", stage, clerkOrgId]`

### captureEmailException

```typescript
type EmailFailureStage =
  | "booking_confirmation" | "booking_cancellation" | "booking_reschedule"
  | "participant_notification" | "reminder" | "ics_generation" | "resend_api";

interface EmailExceptionContext {
  organizationId: string;
  recipientEmail?: string;
  emailType: EmailFailureStage;
  callId?: string;
  metadata?: Record<string, unknown>;
}
```
Tags: `email.critical`, `email.type`, `email.organization_id`
Fingerprint: `["email-failure", emailType, organizationId]`

### captureOnboardingException

```typescript
type OnboardingFailureStage =
  | "grant_validation" | "user_upsert" | "connection_save"
  | "invitation_user_upsert" | "invitation_member_creation" | "calendar_connection";

interface OnboardingExceptionContext {
  user_id?: string;
  organization_id?: string;
  stage: OnboardingFailureStage;
  metadata?: Record<string, unknown>;
}
```
Tags: `onboarding.critical`, `onboarding.stage`, `onboarding.user_id`, `onboarding.organization_id`
Fingerprint: `["onboarding-failure", stage, organization_id]`

### captureDeletionException

```typescript
type DeletionFailureStage = "fetch" | "cancel_booking" | "database_delete" | "audit_log";

interface DeletionExceptionContext {
  entity_type: "call" | "lead";
  entity_id: string;
  organization_id: string;
  stage: DeletionFailureStage;
  metadata?: Record<string, unknown>;
}
```
Tags: `deletion.critical`, `deletion.entity_type`, `deletion.stage`, `deletion.organization_id`
Fingerprint: `["deletion-failure", entity_type, stage, organization_id]`

### captureNoteException

```typescript
type NoteFailureStage = "fetch_user" | "fetch_lead" | "create_note" | "update_database" | "audit_log";

interface NoteExceptionContext {
  lead_id: string;
  organization_id: string;
  user_id: string;
  stage: NoteFailureStage;
  metadata?: Record<string, unknown>;
}
```
Tags: `note.critical`, `note.stage`, `note.lead_id`, `note.organization_id`, `note.user_id`
Fingerprint: `["note-failure", stage, organization_id]`

### captureNotetakerException

```typescript
type NotetakerFailureStage =
  | "join_meeting" | "entry_denied" | "no_response" | "bad_meeting_code"
  | "internal_error" | "media_download" | "media_upload";

interface NotetakerExceptionContext {
  call_id: string;
  notetaker_id?: string;
  organization_id: string;
  meeting_state?: string;
  failure_reason?: string;
  stage: NotetakerFailureStage;
  metadata?: Record<string, unknown>;
}
```
Tags: `notetaker.critical`, `notetaker.failure_type`, `notetaker.call_id`, `notetaker.organization_id`, `notetaker.notetaker_id`, `notetaker.meeting_state`
Fingerprint: `["notetaker-failure", meeting_state || stage, organization_id]`

### captureGrantException

```typescript
type GrantFailureStage =
  | "creation" | "validation" | "user_upsert" | "connection_save"
  | "refresh" | "expiration_cleanup" | "deletion";

interface GrantExceptionContext {
  organizationId?: string;
  userId?: string;
  grantId?: string;
  stage: GrantFailureStage;
  metadata?: Record<string, unknown>;
}
```
Tags: `grant.critical`, `grant.stage`, `grant.organization_id`, `grant.user_id`
Fingerprint: `["grant-failure", stage, organizationId]`

## Sentry Metrics Patterns

```typescript
// Distribution: Track ranges
Sentry.metrics.distribution("ai.analysis.overall_score", 65, {
  unit: "none",
  attributes: { verdict: "replace", source: "notetaker" },
});

// Count: Track occurrences
Sentry.metrics.count("notetaker.media.completed", 1, {
  attributes: { has_recording: "true", has_transcript: "true" },
});
```
