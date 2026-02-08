---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "!**/*.test.ts"
  - "!**/*.spec.ts"
---

# Observability Standards

> These rules load when working with TypeScript/React files. For complete setup, see `docs/standards/observability.md`.

## Error Tracking

- **Sentry Setup**: See `docs/standards/observability.md` - Required for ALL apps
- **When to capture**: Use `captureXxxException()` for any failure that should alert ops
- **Logging only**: Use `logger.error()` for non-blocking, recoverable failures
- **Rule**: If `logger.error()` is called + the failure impacts the user → add `captureXxxException()`

## Performance Tools

| Tool | Location | Purpose |
|------|----------|---------|
| **Web Vitals** | `_shared/components/web-vitals-reporter.tsx` | LCP, CLS, INP → Sentry |
| **Query Timing** | `_shared/lib/query-timing.ts` | Slow query detection (>1s) |
| **Server Action Tracing** | `_shared/lib/traced-action.ts` | Action performance |
| **Circuit Breaker** | `_shared/lib/circuit-breaker.ts` | External service protection |
| **Rate Limiting** | `_shared/lib/rate-limit.ts` | Distributed rate limits |

## Usage Examples

```typescript
// Wrap database queries for observability
import { timedQuery } from '@/app/_shared/lib/query-timing';
const calls = await timedQuery('getCalls', () => callsRepository.list(supabase));

// Wrap server actions for tracing
import { tracedAction } from '@/app/_shared/lib/traced-action';
export const createCall = tracedAction('calls.create', async (data) => {
  // ... your action logic
});

// Protect external service calls
import { withCircuitBreaker } from '@/app/_shared/lib/circuit-breaker';
const calendar = await withCircuitBreaker('nylas', () => nylasClient.getCalendar());
```

## Thresholds

| Metric | Warning | Error |
|--------|---------|-------|
| DB Query | >1s | >5s |
| Server Action | >3s | >10s |
| Web Vitals LCP | >2.5s | >4s |
| Web Vitals CLS | >0.1 | >0.25 |
| Web Vitals INP | >200ms | >500ms |

## Health Checks

- **Liveness**: `/api/health/live` - Always returns 200 if server running
- **Readiness**: `/api/health/ready` - Checks Supabase, Stripe, Nylas, Redis
