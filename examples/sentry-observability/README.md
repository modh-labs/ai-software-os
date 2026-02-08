# Example: Sentry Observability Setup

> Quick start for implementing error tracking, performance monitoring, and distributed tracing with Sentry.

## What This Covers

- Sentry SDK configuration for Next.js
- Structured error capture with domain-specific functions
- Performance monitoring (Web Vitals, query timing)
- Distributed tracing with OpenTelemetry

## Relevant Skills

- `.claude/skills/observability-logging/SKILL.md`
- `.claude/skills/webhook-observability/SKILL.md`

## Relevant Guides

- `guides/standards/observability.md`
- `guides/patterns/tracing-and-instrumentation.md`
- `guides/patterns/sentry-alerting.md`
- `guides/patterns/sentry-debugging.md`

## Key Patterns

```typescript
// Domain-specific error capture
function captureBookingException(error: Error, context: BookingContext) {
  Sentry.captureException(error, {
    tags: {
      domain: "booking",
      action: context.action,
      organization_id: context.orgId,
    },
    extra: context,
  });
}

// Structured logging (not console.log)
import { createModuleLogger } from "@/lib/logger";
const logger = createModuleLogger("booking");
logger.info({ bookingId }, "Booking created");
logger.error({ error, bookingId }, "Booking failed");
```

## Adaptation Notes

- Replace Sentry DSN with your project's DSN
- Configure alert rules per `guides/patterns/sentry-alerting.md`
- Set up source maps upload in CI
- Add Web Vitals reporter component to layout
