---
name: observability-logging
description: Enforce structured logging, Sentry integration, and distributed tracing patterns. Use when adding logging, error tracking, Sentry tags, custom spans, metrics, or debugging production issues. Prevents console.log usage and ensures trace correlation.
allowed-tools: Read, Grep, Glob
---

# Observability & Logging Skill

## When This Skill Activates

This skill automatically activates when you:
- Add logging to any code (server actions, repositories, webhooks)
- Work with Sentry error tracking or performance monitoring
- Add tracing or custom spans
- Discuss debugging, metrics, or alerting
- Handle errors that need to be captured

## Decision Tree — "What do I use?"

```
Error in webhook handler? → logger.error() + captureWebhookException()
Error in server action?   → logger.error() + domain-specific capture*Exception()
Error in Inngest function? → sentryMiddleware auto-captures + logger.error()
Error in AI agent?        → captureAIException() (or instrumentedAgentGenerate auto-captures)
Need to track duration?   → Sentry.startSpan() or webhook logger lifecycle
Need to filter in Sentry? → setTag() (low cardinality only)
Need debug data?          → setContext() (not searchable)
Need charts?              → Sentry.metrics.distribution() or .count()
Client-side error?        → PageErrorBoundary component
Non-critical info log?    → logger.info() (won't reach Sentry in prod)
```

## Core Rules (MUST Follow)

### 1. ALWAYS Use `createModuleLogger()` — Never `console.log`

```typescript
// WRONG - Raw console
console.log("Processing call", callId);

// CORRECT - Structured logger
import { createModuleLogger } from "@/app/_shared/lib/sentry-logger";
const logger = createModuleLogger("calls-actions");

logger.info("Processing call", { call_id: callId });
logger.error("Payment failed", { error, payment_id: paymentId });
```

Pre-configured loggers: `authLogger`, `apiLogger`, `webhookLogger`, `aiLogger`, `schedulerLogger`, `uiLogger`, `integrationLogger`.

### 2. NEVER Double-Log — `logger.error()` OR `capture*Exception()`, Not Both Internally

`capture*Exception()` functions create **Sentry Issues** (alerts). They do NOT log internally.
The caller decides whether to also log for debugging:

```typescript
// CORRECT — log for debugging, then capture for alerting
logger.error("Booking failed at Nylas API", {
  session_id: sessionId,
  stage: "nylas_api",
});
void captureBookingException(error, { sessionId, organizationId, stage: "nylas_api" });

// WRONG — capture*Exception already handles Sentry, don't add logger.error inside it
// (This was a previous bug that caused 3-5x duplicate events)
```

**Why this matters:**
- `logger.error()` → sends to Sentry Logs + console (Vercel Logs)
- `capture*Exception()` → sends to Sentry Issues (alerts, fingerprinting, grouping)
- If both are inside the capture function AND the caller also logs, you get duplicates

### 3. Use Sentry Built-in OTEL — Never `@vercel/otel`

Sentry SDK v10 has native OpenTelemetry. Adding `@vercel/otel` causes conflicts.

Only add `@opentelemetry/api` (lightweight API package) for `trace.getActiveSpan()`.

### 4. No `consoleLoggingIntegration` — Logger Handles Sentry Directly

We removed `Sentry.consoleLoggingIntegration()` from all configs. Our logger sends to `Sentry.logger.*` directly. Console output is only for Vercel Logs / terminal visibility.

**Do NOT re-add it.** It intercepts `console.warn/error` and re-sends them to Sentry Logs, causing duplicates with what `Sentry.logger` already sent.

### 5. Tags (Searchable) vs Context (Debug) vs Metrics (Charts)

```typescript
import * as Sentry from "@sentry/nextjs";

// Tags: Categorical, filterable in Sentry UI (low cardinality)
Sentry.setTag("ai.verdict", "replace");
Sentry.setTag("webhook.source", "stripe");

// Context: Structured debugging data (NOT searchable)
Sentry.setContext("ai_analysis_result", {
  overallScore: 65,
  verdict: "replace",
  durationMs: 4500,
});

// Metrics: Numeric data for charts
Sentry.metrics.distribution("ai.analysis.duration_ms", 4500, {
  unit: "millisecond",
});
Sentry.metrics.count("webhook.processed", 1, {
  attributes: { provider: "stripe" },
});
```

### 6. PII Auto-Redaction

The logger automatically redacts: `password`, `token`, `secret`, `apikey`, `api_key`, `accesstoken`, `access_token`, `refreshtoken`, `refresh_token`, `bearer`, `authorization`, `creditcard`, `credit_card`, `cardnumber`, `card_number`, `cvv`, `ssn`, `social_security`, `stripe_customer_id`.

### 7. Production Min Level is `info`

| Environment | Sentry Minimum | Console Minimum |
|-------------|---------------|-----------------|
| Production  | `info`        | `info`          |
| Preview     | `debug`       | `debug`         |
| Development | `debug`       | `debug`         |

All `info`, `warn`, and `error` logs appear in Sentry Logs in production — one place to see everything. Only `debug` is filtered out (local dev noise). Use `logger.debug()` for verbose tracing you only need locally.

### 8. Domain-Specific Error Capture

For alertable failures (Sentry Issues, not just logs):

```typescript
import {
  captureBookingException,   // Booking/scheduling failures
  captureMediaException,     // Recording/transcript failures
  capturePaymentException,   // Payment processing failures
  captureWebhookException,   // Webhook handler failures
  captureAIException,        // AI analysis failures
  captureClerkException,     // Auth/user sync failures
  captureEmailException,     // Email delivery failures
  captureOnboardingException,// Onboarding flow failures
  captureDeletionException,  // Entity deletion failures
  captureNoteException,      // Note addition failures
  captureNotetakerException, // Notetaker operation failures
  captureGrantException,     // Nylas grant management failures
} from "@/app/_shared/lib/sentry-logger";
```

These functions: (1) create Sentry Issues with fingerprinting, (2) set domain-specific tags.
They do NOT log internally — the caller handles `logger.error()` separately.

See `references/domain-exceptions.md` for full interfaces and stage enums.

### 9. ALWAYS Propagate `tracingOptions` to Mastra Agents

```typescript
import { getTracingOptionsForMastra } from "@/app/_shared/lib/tracing/otel-context";

const result = await runComprehensiveAnalysis({
  transcript: formattedTranscript,
  tracingOptions: getTracingOptionsForMastra(),
});
```

### 10. Span Naming Conventions

| Pattern | Example | Use For |
|---------|---------|---------|
| `db.*` | `db.calls.list` | Database operations |
| `ai.*` | `ai.comprehensive-analysis` | AI/ML operations |
| `http.*` | `http.external-api` | External HTTP calls |
| `function.*` | `function.process-media` | Business logic |

## Error Handling Patterns

### Server Action / Repository Error

```typescript
try {
  await processPayment(paymentId);
} catch (error) {
  logger.error("Payment processing failed", { payment_id: paymentId, error });
  void capturePaymentException(error, {
    organizationId,
    stage: "payment_storage",
    paymentIntentId,
  });
  return { success: false, error: "Payment failed" };
}
```

### Webhook Error (use webhook logger)

```typescript
import { createWebhookLogger } from "@/app/_shared/lib/webhooks/webhook-logger";

const wLogger = createWebhookLogger({ provider: "stripe", eventType, eventId });
wLogger.start();
try {
  // ... handle webhook
  wLogger.success();
} catch (error) {
  wLogger.failure(error);
  // webhook logger's failure() already calls Sentry.captureException
}
```

### logError() Utility

```typescript
import { logError } from "@/app/_shared/lib/sentry-logger";
logError("Payment processing failed", error, { payment_id: paymentId });
```

## Custom Span Pattern

```typescript
import * as Sentry from "@sentry/nextjs";

const result = await Sentry.startSpan(
  { name: "function.process-media", op: "function" },
  async (span) => {
    const result = await processMedia(input);
    span.setAttributes({ "custom.output_size": result.length });
    return result;
  }
);
```

## Sentry Logs (`Sentry.logger.fmt`)

Use the structured logger for Sentry Logs. Attribute names must be `snake_case`.

```typescript
import * as Sentry from "@sentry/nextjs";

Sentry.logger.fmt("Processing call %s for org %s", [callId, orgId], {
  call_id: callId,
  organization_id: orgId,
  duration_ms: elapsed,
});
```

### `beforeSendLog` Safety Net

All three Sentry configs (`server`, `edge`, `client`) have `beforeSendLog` that:
- Drops `debug`-level logs in production
- Drops health check noise
- Adds `deployment_stage` attribute for environment filtering
- Client additionally: drops `info` in production, filters third-party noise, adds `is_client: true`

## Inngest Observability

`@inngest/middleware-sentry` auto-tags errors with `inngest.function_name`, `inngest.event_name`, `inngest.run_id`.

**Debugging:** Sentry Issue -> `inngest.run_id` tag -> Inngest Dashboard search -> view step execution.

## AI Instrumentation

Use `instrumentedAgentGenerate()` for Mastra agents with automatic Sentry spans and token tracking:

```typescript
import { instrumentedAgentGenerate } from "@/app/_shared/lib/mastra/sentry-instrumentation";

const result = await instrumentedAgentGenerate({
  agent, prompt, operationName: "comprehensive-analysis",
  organizationId, callId,
});
// Auto-emits: ai.tokens.prompt, ai.tokens.completion, ai.duration metrics
```

For simpler tracking: `trackAIOperation()`.

## Error Boundaries

Every route MUST have `error.tsx` using `PageErrorBoundary`:

```typescript
"use client";
import { PageErrorBoundary } from "@/app/_shared/components/PageErrorBoundary";

export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return <PageErrorBoundary error={error} reset={reset} title="Page" loggerModule="route-name" />;
}
```

`global-error.tsx` handles fatal layout errors with `Sentry.captureException` at `level: "fatal"`.

## Performance Thresholds

| Metric | Warning | Error |
|--------|---------|-------|
| DB Query | >1s | >5s |
| Server Action | >3s | >10s |
| API Route | >2s | >8s |
| AI Agent Call | >10s | >30s |

## Anti-Patterns

```
// NEVER console.log or console.error — use logger (even in catch blocks)
// NEVER direct Sentry.captureException — use domain capture*Exception() functions
// NEVER @vercel/otel — use Sentry built-in OTEL
// NEVER consoleLoggingIntegration — removed, causes duplicates
// NEVER logger.error() inside capture*Exception() — caller handles logging
// NEVER both logger.error() AND capture*Exception() for the same error without reason
// NEVER high-cardinality tags (call_id, user_id) — use context instead
// NEVER logger.info() for production alerts — use warn or capture*Exception
// NEVER missing tracingOptions in Mastra calls — traces won't connect
```

## Sentry MCP Debugging Workflow

```
1. search_issues("is:unresolved <keyword>")     -> find the issue
2. get_issue_details(issueId)                    -> view tags, context, stacktrace
3. get_trace_details(traceId)                    -> view span waterfall
```

### Runbook: Production Incident

1. **Alert received** -> `search_issues` with error message or tag
2. **Identify issue** -> `get_issue_details` -> check tags (`ai.verdict`, `inngest.*`, `webhook.source`)
3. **View trace** -> `get_trace_details` -> identify slow/failing span
4. **Check logs** -> Search Sentry Logs by `trace_id` for full context
5. **Inngest jobs** -> Copy `inngest.run_id` -> check Inngest Dashboard for retries/payloads
6. **Fix** -> Deploy -> verify issue resolves in Sentry

## Key Files

| File | Purpose |
|------|---------|
| `app/_shared/lib/sentry-logger.ts` | Logger + all 12 capture*Exception functions |
| `app/_shared/lib/tracing/otel-context.ts` | Trace propagation (`getTracingOptionsForMastra`) |
| `app/_shared/lib/request-context.ts` | AsyncLocalStorage request context |
| `app/_shared/lib/otel/context-enrichment-processor.ts` | Auto-injects user/org into spans |
| `app/_shared/lib/sentry-sampling.ts` | Dynamic trace sampling (critical/important/low-value) |
| `app/_shared/lib/webhooks/webhook-logger.ts` | Webhook logger lifecycle |
| `app/_shared/lib/mastra/sentry-instrumentation.ts` | AI agent instrumentation + token tracking |
| `app/_shared/lib/inngest/client.ts` | Inngest client + Sentry middleware |
| `app/_shared/components/PageErrorBoundary.tsx` | Shared error boundary component |
| `app/global-error.tsx` | Fatal error boundary (root layout) |
| `sentry.server.config.ts` | Server Sentry config + profiling + AI providers |
| `sentry.edge.config.ts` | Edge Sentry config + vercelAIIntegration |
| `instrumentation-client.ts` | Client Sentry config + Session Replay |
| `next.config.mjs` | Sentry webpack plugin (source maps, monitors) |

## Detailed Documentation

- Domain exception functions with full interfaces: `references/domain-exceptions.md`
- Tracing, sampling, context enrichment, AI instrumentation: `references/tracing-patterns.md`
