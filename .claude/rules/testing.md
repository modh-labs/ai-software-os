---
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
  - "**/tests/**"
  - "**/__tests__/**"
---

# Testing Standards

> These rules load when working with test files. For complete patterns, see `docs/patterns/testing.md`.

## Test Framework

- **Unit/Integration:** Vitest
- **E2E:** Playwright
- **Coverage:** Vitest built-in

## File Organization

```
app/(protected)/calls/
├── components/
│   ├── CallTable.tsx
│   └── CallTable.test.tsx      # Colocated unit tests
├── actions.ts
├── actions.test.ts              # Action tests
└── page.tsx

tests/
├── e2e/                         # Playwright E2E tests
│   └── calls.spec.ts
└── setup.ts                     # Test setup
```

## Testing Patterns

### Server Actions

```typescript
import { describe, it, expect, vi } from 'vitest';
import { createCall } from './actions';

describe('createCall', () => {
  it('returns success with valid data', async () => {
    const result = await createCall({
      leadId: 'lead-123',
      scheduledAt: new Date(),
    });

    expect(result.success).toBe(true);
    expect(result.data).toBeDefined();
  });

  it('returns error for invalid input', async () => {
    const result = await createCall({
      leadId: '', // Invalid
    });

    expect(result.success).toBe(false);
    expect(result.error).toBeDefined();
  });
});
```

### Repository Functions

```typescript
import { describe, it, expect } from 'vitest';
import { callsRepository } from '@/app/_shared/repositories/calls.repository';
import { createTestClient } from '@/tests/utils';

describe('callsRepository', () => {
  it('lists calls for organization', async () => {
    const supabase = createTestClient();
    const calls = await callsRepository.list(supabase);

    expect(Array.isArray(calls)).toBe(true);
  });
});
```

### Components

```typescript
import { render, screen } from '@testing-library/react';
import { CallTable } from './CallTable';

describe('CallTable', () => {
  it('renders call rows', () => {
    const calls = [
      { id: '1', leadName: 'John', status: 'scheduled' },
    ];

    render(<CallTable calls={calls} />);

    expect(screen.getByText('John')).toBeInTheDocument();
  });

  it('shows empty state when no calls', () => {
    render(<CallTable calls={[]} />);

    expect(screen.getByText(/no calls/i)).toBeInTheDocument();
  });
});
```

## Mocking

### Supabase Client

```typescript
import { vi } from 'vitest';

export function createMockSupabase() {
  return {
    from: vi.fn().mockReturnThis(),
    select: vi.fn().mockReturnThis(),
    eq: vi.fn().mockReturnThis(),
    single: vi.fn().mockResolvedValue({ data: {}, error: null }),
  };
}
```

### Server Actions

```typescript
vi.mock('./actions', () => ({
  createCall: vi.fn().mockResolvedValue({ success: true }),
}));
```

## Commands

```bash
bun test                  # Watch mode
bun test:ci               # Single run (CI)
bun test -- --coverage    # With coverage
bun test -- CallTable     # Run specific tests
```

## Coverage Targets

| Type | Target |
|------|--------|
| Server Actions | 80%+ |
| Repositories | 70%+ |
| Components | 60%+ |
| E2E Critical Paths | 100% |

## Rules

1. **Colocate unit tests** with source files (`*.test.ts` next to `*.ts`)
2. **Test behavior, not implementation** - Test what it does, not how
3. **Mock at boundaries** - Supabase client, external APIs
4. **Use test factories** for consistent test data
5. **Avoid snapshot tests** for components (too brittle)
