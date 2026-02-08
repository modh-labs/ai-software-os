---
title: "Observability Standards"
description: "Logging, tracing, and monitoring standards for all apps in the monorepo."
tags: ["observability", "sentry"]
category: "standards"
author: "Imran Gardezi"
publishable: true
---
# Observability Standards

**Applies to:** All apps in the monorepo

## Sentry Setup

**Files needed:**
- `sentry.server.config.ts` - Server config
- `sentry.edge.config.ts` - Edge config
- `next.config.mjs` wrapped with `withSentryConfig()`

**Key settings:**
- DSN: `process.env.NEXT_PUBLIC_SENTRY_DSN`
- Tracing: 10% production, 50% preview, 100% dev/staging
- Integrations: `nodeProfilingIntegration`, `supabaseIntegration`, `consoleLoggingIntegration`
- **DON'T** set Sentry vars manually in Vercel - use Vercel integration

**Vercel integration:** Sentry → Settings → Integrations → Vercel (auto-injects DSN & token)

See existing `apps/web/sentry.*.config.ts` for complete templates.

---

## Structured Logging

Use the `sentry-logger` for all logging. It provides automatic context injection and log-trace correlation.

**Location:** `apps/web/app/_shared/lib/sentry-logger.ts`

### Basic Usage

```typescript
import { logger, createModuleLogger } from "@/app/_shared/lib/sentry-logger";

// Simple logging
logger.info("User logged in");
logger.error("Payment failed", { payment_id: "pay_123" });

// Module-specific logger (adds `module` tag to all logs)
const aiLogger = createModuleLogger("sales-call-analysis");
aiLogger.info("Processing call", { call_id: callId });
```

### Dual API Support (Backward Compatible)

Both Sentry-style and pino-style calls are supported:

```typescript
// Sentry style (preferred)
logger.info("Processing call", { call_id: callId });

// Pino style (backward compatible)
logger.info({ call_id: callId }, "Processing call");
```

### Auto-Injected Context

Every log automatically includes (when available):
- `user_id` - Current user from Clerk
- `organization_id` - Current organization
- `organization_slug` - Organization slug
- `request_id` - Unique request identifier
- `trace_id` - OpenTelemetry trace ID (for log-trace correlation)
- `span_id` - Current span ID

**Search in Sentry:** `organization_id:org_abc user_id:user_xyz trace_id:abc123`

### Pre-configured Module Loggers

```typescript
import {
  authLogger,      // Authentication flows
  apiLogger,       // API endpoints
  webhookLogger,   // Webhook handlers
  aiLogger,        // AI/ML operations
  schedulerLogger, // Background jobs
} from "@/app/_shared/lib/sentry-logger";

webhookLogger.info("Stripe webhook received", { event_type: "payment_intent.succeeded" });
```

### Error Logging with Context

```typescript
import { logError } from "@/app/_shared/lib/sentry-logger";

try {
  await processPayment(paymentId);
} catch (error) {
  logError("Payment processing failed", error, { payment_id: paymentId });
}
```

### Log Level Filtering

| Environment | Sentry Minimum | Console Minimum |
|-------------|---------------|-----------------|
| Production  | `info`        | `info`          |
| Preview     | `debug`       | `debug`         |
| Development | `debug`       | `debug`         |

**Note:** All `info`, `warn`, and `error` logs appear in Sentry Logs in production. Use `logger.debug()` only for verbose local tracing.

---

## PII Redaction

The logger automatically redacts sensitive fields. Any attribute containing these patterns is replaced with `[REDACTED]`:

- `password`, `token`, `secret`, `apikey`, `api_key`
- `accesstoken`, `access_token`, `refreshtoken`, `refresh_token`
- `bearer`, `authorization`
- `creditcard`, `credit_card`, `cardnumber`, `card_number`, `cvv`
- `ssn`, `social_security`
- `stripe_customer_id`

```typescript
// Input
logger.info("Auth attempt", { user: "john", password: "secret123" });

// Logged as
// { user: "john", password: "[REDACTED]" }
```

---

## Trace Propagation to Mastra Agents

AI agent calls should maintain trace continuity for end-to-end visibility. Use `getTracingOptionsForMastra()` to propagate the current trace context.

**Location:** `apps/web/app/_shared/lib/tracing/otel-context.ts`

### Basic Usage

```typescript
import { getTracingOptionsForMastra } from "@/app/_shared/lib/tracing/otel-context";
import { runComprehensiveAnalysis } from "@your-org/agents";

const result = await runComprehensiveAnalysis({
  transcript: formattedTranscript,
  tracingOptions: getTracingOptionsForMastra(), // Propagates current trace
});
```

### Expected Trace Waterfall

When properly configured, Sentry Performance shows connected spans:

```
[Transaction] inngest.runCallAnalysis
  └── [Span] run-analysis (step)
      └── [Span] ai.comprehensive-analysis
          └── [Span] mastra.agent.generate (from tracingOptions)
              └── [Span] openai.chat.completions
```

### Available Utilities

```typescript
import {
  getTracingOptionsForMastra, // For Mastra agent calls
  getCurrentTraceId,          // For manual log correlation
  getCurrentSpanId,           // For span-level correlation
  getSpanContext,             // Full OTEL context (advanced)
} from "@/app/_shared/lib/tracing/otel-context";
```

---

## Log-Trace Correlation

Every log includes `trace_id` and `span_id` automatically. This enables:

### Vercel Logs
Search `trace_id:abc123def456...` to find all logs from a single request/transaction.

### Sentry Logs
Click any log entry → "View Trace" button → See full waterfall with the log in context.

### Manual Correlation

```typescript
const traceId = getCurrentTraceId();
logger.info("Starting analysis", { trace_id: traceId, call_id: callId });
// Later, search Sentry/Vercel for this trace_id to find all related logs
```

---

## Sentry Tags vs Metrics vs Context

Use the right Sentry primitive for each use case:

### Tags (Categorical, Filterable)

Use `Sentry.setTag()` for **categorical data** you want to filter and search by.

```typescript
import * as Sentry from "@sentry/nextjs";

// Good: Categorical values with limited cardinality
Sentry.setTag("ai.verdict", "replace");          // Filter: ai.verdict:replace
Sentry.setTag("ai.outcome", "closed");           // Filter: ai.outcome:closed
Sentry.setTag("inngest.source", "notetaker");    // Filter: inngest.source:notetaker
Sentry.setTag("webhook.source", "stripe");       // Filter: webhook.source:stripe

// Bad: High-cardinality values (use context instead)
// Sentry.setTag("call_id", callId);  // ❌ Too many unique values
```

### Metrics (Numeric, Chartable)

Use `Sentry.metrics` for **numeric data** you want to aggregate and chart.

```typescript
// Distribution: Track ranges (scores, durations)
Sentry.metrics.distribution("ai.analysis.overall_score", 65, {
  unit: "none",
  attributes: { verdict: "replace", source: "notetaker" },
});

Sentry.metrics.distribution("ai.analysis.duration_ms", 4500, {
  unit: "millisecond",
  attributes: { verdict: "replace" },
});

// Count: Track occurrences
Sentry.metrics.count("notetaker.media.completed", 1, {
  attributes: { has_recording: "true", has_transcript: "true" },
});
```

### Context (Structured, Debugging)

Use `Sentry.setContext()` for **structured data** needed for debugging.

```typescript
// Detailed debugging data (not searchable, but visible in issue details)
Sentry.setContext("ai_analysis_result", {
  overallScore: 65,
  verdict: "replace",
  durationMs: 4500,
  modelUsed: "gpt-4o",
  tokenCount: 2500,
});

Sentry.setContext("media_processing", {
  callId,
  notetakerId,
  hasRecording: true,
  hasTranscript: true,
});
```

### Quick Reference

| Use Case | Sentry Primitive | Example |
|----------|-----------------|---------|
| Filter issues by category | `setTag()` | `ai.verdict:replace` |
| Chart numeric distributions | `metrics.distribution()` | Score histograms |
| Count occurrences | `metrics.count()` | Success/failure rates |
| Debug data (not searchable) | `setContext()` | Full result objects |

---

## Critical Error Capture

For **alertable failures** that should trigger Sentry alerts (not just logs), use the domain-specific capture functions:

```typescript
import {
  captureBookingException,  // Booking/scheduling failures
  captureMediaException,    // Recording/transcript failures
  capturePaymentException,  // Payment processing failures
  captureWebhookException,  // Webhook handler failures
  captureAIException,       // AI analysis failures
  captureClerkException,    // Auth/user sync failures
  captureEmailException,    // Email delivery failures
} from "@/app/_shared/lib/sentry-logger";

// Example: AI analysis failure
captureAIException(
  new Error("Call outcome determination failed"),
  {
    callId,
    organizationId,
    stage: "outcome_determination",
    model: "gpt-4o",
    metadata: { transcriptLength: 5000 },
  }
);
```

These functions:
1. Create Sentry Issues (for alerting via Slack/email)
2. Set proper tags and fingerprints (for issue grouping)
3. Do NOT log internally — the caller handles `logger.error()` separately to avoid duplication

---

## Anti-Patterns

```
// NEVER console.log or console.error — use logger (even in catch blocks)
// NEVER direct Sentry.captureException — use domain capture*Exception() functions
// NEVER consoleLoggingIntegration — removed, causes duplicates with Sentry.logger
// NEVER logger.error() inside capture*Exception() — caller handles logging
```

**Recommendation:** Always use `sentry-logger` for new code. Use domain-specific `capture*Exception()` functions for alertable failures. Never use raw `console.error` in catch blocks.

---

## Project Naming

| App | Sentry | Vercel |
|-----|--------|--------|
| `@your-org/web` | `[YOUR_PROJECT]` | `[YOUR_AI_PROJECT]` |
| `@your-org/admin` | `[YOUR_ADMIN_PROJECT]` | `[YOUR_ADMIN_PROJECT]` |
| New apps | `[app]-{name}` | `[app]-{name}` |

---

## Inngest Observability

Background jobs running via Inngest are automatically instrumented with Sentry via `@inngest/middleware-sentry`.

**What it does:**
- Auto-creates Sentry Issues for Inngest function errors
- Tags issues with `inngest.function_name`, `inngest.event_name`, `inngest.run_id`
- Links Sentry error traces to Inngest Dashboard runs

**Configuration:** `apps/web/app/_shared/lib/inngest/client.ts`

```typescript
import { sentryMiddleware } from "@inngest/middleware-sentry";

middleware: [
  sentryMiddleware(),  // Auto-captures errors + adds function metadata tags
  realtimeMiddleware(),
],
```

**Debugging via runID:**
1. Find the Sentry Issue → check `inngest.run_id` tag
2. Open Inngest Dashboard → search by run ID
3. View step-by-step execution, retries, and payloads

---

## Client-Side Sentry Logs

Client errors are captured in Sentry Logs via `Sentry.logger` (used by `uiLogger`).

**Configuration:** `apps/web/instrumentation-client.ts`

- `enableLogs: true` — sends structured logs to Sentry
- `beforeSendLog` filters debug/info in production, adds `is_client: true` attribute
- `disableLogger: false` in `next.config.mjs` preserves `Sentry.logger` in client bundle
- `consoleLoggingIntegration` has been removed — logger sends directly to Sentry

**Filtering client logs in Sentry:** Search `is_client:true` to see only browser-side logs.

---

## Sentry MCP Integration

Use the Sentry MCP tools for production debugging directly from Claude Code:

```
search_issues → get_issue_details → get_trace_details
```

**Common queries:**
- `search_issues("is:unresolved inngest")` — find Inngest failures
- `search_issues("is:unresolved ai.verdict")` — find AI analysis failures
- `get_issue_details(issueId)` → view tags, context, stacktrace
- `get_trace_details(traceId)` → view full span waterfall

---

## Performance Thresholds

| Metric | Warning | Error |
|--------|---------|-------|
| DB Query | >1s | >5s |
| Server Action | >3s | >10s |
| API Route | >2s | >8s |

---

## Related Documentation

- [Tracing and Instrumentation](../patterns/tracing-and-instrumentation.md) - Comprehensive tracing guide
- [Sentry Debugging](../patterns/sentry-debugging.md) - Debugging workflows
- [Sentry Alerting](../patterns/sentry-alerting.md) - Alert configuration
