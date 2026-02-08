# Tracing Patterns

## Architecture: Sentry's Built-in OpenTelemetry

We use Sentry SDK v10's native OpenTelemetry support. Do NOT add `@vercel/otel`.

Only dependency: `@opentelemetry/api` (lightweight ~50KB API package).

## Trace Context Utilities

```typescript
import {
  getTracingOptionsForMastra,  // For Mastra agent calls
  getCurrentTraceId,           // For manual log correlation
  getCurrentSpanId,            // For span-level correlation
  getSpanContext,              // Full OTEL context (advanced)
} from "@/app/_shared/lib/tracing/otel-context";
```

## Propagating to Mastra Agents

```typescript
const result = await runComprehensiveAnalysis({
  transcript: formattedTranscript,
  tracingOptions: getTracingOptionsForMastra(),
});
```

Expected trace waterfall:
```
[Transaction] inngest.runCallAnalysis
  └── [Span] run-analysis (step)
      └── [Span] ai.comprehensive-analysis
          └── [Span] mastra.agent.generate (from tracingOptions)
              └── [Span] openai.chat.completions
```

## Dynamic Sampling (`sentry-sampling.ts`)

The `tracesSampler` function categorizes operations into tiers:

**Critical paths (100% all environments):**
Patterns: booking, payment, subscription, onboarding, notetaker, checkout, stripe, clerk

**Important operations (50% prod, 100% dev):**
Patterns: server actions, db queries, external APIs, Inngest jobs, ai operations

**Low-value operations (10% prod, 50% preview, 100% dev):**
Patterns: health checks, static assets, metrics endpoints, favicon, robots.txt

**Default:** 10% prod, 50% preview, 100% dev

## Context Enrichment Processor

`ContextEnrichmentProcessor` (`app/_shared/lib/otel/context-enrichment-processor.ts`) auto-injects into every span:
- `user_id`, `organization_id`, `organization_slug` (from AsyncLocalStorage)
- `request_id`, `session_id`
- Redis-backed distributed cache for org slugs (5-minute TTL, 1000-entry in-memory fallback)
- Non-blocking: doesn't delay span creation on cache misses

## Request Context (`request-context.ts`)

Middleware populates `AsyncLocalStorage` with:

```typescript
interface RequestContext {
  requestId: string;
  userId?: string;
  sessionId?: string;
  organizationId?: string;
  organizationRole?: string;
  organizationSlug?: string;
  userAgent?: string;
  ip?: string;
  path?: string;
  method?: string;
  tags: Record<string, string>;
}
```

Access anywhere via:
```typescript
import { getContext, addContextTags } from "@/app/_shared/lib/request-context";
const ctx = getContext(); // auto-injected by middleware
addContextTags({ "custom.tag": "value" }); // adds to current request
```

## AI Instrumentation

### instrumentedAgentGenerate()

```typescript
import { instrumentedAgentGenerate } from "@/app/_shared/lib/mastra/sentry-instrumentation";

const result = await instrumentedAgentGenerate({
  agent,
  prompt,
  operationName: "comprehensive-analysis",
  organizationId,
  callId,
});
```

Auto-captures:
- Sentry span (`ai.chat.completions`) with token counts
- Metrics: `ai.tokens.prompt`, `ai.tokens.completion`, `ai.duration`
- Robust JSON recovery for structured output validation errors
- Error handling with `Sentry.captureException`

### trackAIOperation()

Simpler tracking without full span instrumentation — just metrics.

## Auto-Injected Log Fields

Every log from our logger automatically includes (via `getContextAttributes()`):
`trace_id`, `span_id`, `user_id`, `organization_id`, `organization_slug`, `request_id`, `session_id`

## Sentry Config Integration Points

### Server (`sentry.server.config.ts`)
- `nodeProfilingIntegration()` — flame graphs (10% prod, 100% dev)
- `vercelAIIntegration({ force: true })` — AI provider tracing
- `anthropicAIIntegration()`, `openAIIntegration()`, `googleGenAIIntegration()`
- `ContextEnrichmentProcessor` via `openTelemetrySpanProcessors`

### Edge (`sentry.edge.config.ts`)
- `winterCGFetchIntegration()` — edge-compatible fetch tracing
- `vercelAIIntegration({ force: true })` — `force` required because Vercel bundles break auto-detection

### Client (`instrumentation-client.ts`)
- `replayIntegration()` — session replay with privacy controls
- `browserTracingIntegration()` — client-side performance
- `tracePropagationTargets` — distributed tracing to same-origin + localhost + vercel.app

## Troubleshooting

- **Traces not connected**: Ensure `tracingOptions` is passed to Mastra
- **trace_id missing from logs**: No active span, or using `console.log` instead of logger
- **Logs not in Sentry**: Production filters to `warn` and above
- **Duplicate logs**: Check that `consoleLoggingIntegration` is NOT present in configs
