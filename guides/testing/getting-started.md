---
title: "Getting Started with Testing"
description: "This guide will help you write your first tests for your application"
tags: ["testing", "typescript"]
category: "testing"
author: "Imran Gardezi"
publishable: true
---
# Getting Started with Testing

This guide will help you write your first tests for your application.

## Prerequisites

```bash
# Install dependencies
bun install

# Verify test runner works
bun test --run
```

## Writing Your First Test

### 1. Server Action Test

Create a test file colocated with your action:

```
app/(protected)/leads/_actions/
├── update-lead.ts          # Your action
└── __tests__/
    └── update-lead.test.ts  # Your test
```

```typescript
// __tests__/update-lead.test.ts
import { describe, it, expect, vi, beforeEach, Mock } from "vitest";

// Initialize mocks before vi.mock calls
let mockAuthFn: Mock;
let mockGetLeadFn: Mock;
let mockUpdateLeadFn: Mock;

// Mock dependencies using inline factory pattern (Bun compatible)
vi.mock("@clerk/nextjs/server", () => ({
  auth: () => mockAuthFn(),
}));

vi.mock("@your-org/repositories/leads", () => ({
  getLeadById: (...args: unknown[]) => mockGetLeadFn(...args),
  updateLead: (...args: unknown[]) => mockUpdateLeadFn(...args),
}));

vi.mock("@/app/_shared/lib/sentry-logger", () => ({
  createModuleLogger: () => ({
    debug: vi.fn(),
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
  }),
}));

// Import AFTER mocks are set up
import { updateLead } from "../update-lead";

describe("updateLead", () => {
  const TEST_ORG_ID = "org_test_123";
  const TEST_USER_ID = "user_test_123";

  beforeEach(() => {
    vi.clearAllMocks();

    // Initialize mock implementations
    mockAuthFn = vi.fn(() =>
      Promise.resolve({
        userId: TEST_USER_ID,
        orgId: TEST_ORG_ID,
      })
    );

    mockGetLeadFn = vi.fn(() =>
      Promise.resolve({
        id: "lead_123",
        organization_id: TEST_ORG_ID,
        email: "test@example.com",
      })
    );

    mockUpdateLeadFn = vi.fn(() =>
      Promise.resolve({
        id: "lead_123",
        status: "qualified",
      })
    );
  });

  it("returns unauthorized for unauthenticated users", async () => {
    mockAuthFn = vi.fn(() => Promise.resolve({ userId: null, orgId: null }));

    const result = await updateLead({ leadId: "lead_123", status: "qualified" });

    expect(result.success).toBe(false);
    expect(result.error).toBe("Unauthorized");
  });

  it("validates lead belongs to organization", async () => {
    mockGetLeadFn = vi.fn(() =>
      Promise.resolve({
        id: "lead_123",
        organization_id: "different_org", // Different org!
      })
    );

    const result = await updateLead({ leadId: "lead_123", status: "qualified" });

    expect(result.success).toBe(false);
    expect(result.error).toBe("Lead not found");
  });

  it("updates lead successfully", async () => {
    const result = await updateLead({ leadId: "lead_123", status: "qualified" });

    expect(result.success).toBe(true);
    expect(mockUpdateLeadFn).toHaveBeenCalledWith(
      expect.any(Object), // supabase client
      "lead_123",
      { status: "qualified" }
    );
  });
});
```

### 2. Run Your Test

```bash
# Run specific test file
bun test app/\\(protected\\)/leads/_actions/__tests__/update-lead.test.ts

# Watch mode for development
bun test update-lead --watch
```

## Mock Pattern Deep Dive

### Why This Pattern?

Bun's Vitest runner doesn't support `vi.hoisted()` or `vi.mocked()`. The inline factory pattern works reliably:

```typescript
// ❌ Doesn't work in Bun
const mockFn = vi.hoisted(() => vi.fn());

// ❌ Doesn't work in Bun
const mockFn = vi.mocked(someImport.fn);

// ✅ Works in Bun
let mockFn: Mock;
vi.mock("module", () => ({
  fn: (...args: unknown[]) => mockFn(...args),
}));
beforeEach(() => {
  mockFn = vi.fn();
});
```

### Common Mock Patterns

#### Clerk Auth
```typescript
let mockAuthFn: Mock;
vi.mock("@clerk/nextjs/server", () => ({
  auth: () => mockAuthFn(),
}));

beforeEach(() => {
  mockAuthFn = vi.fn(() =>
    Promise.resolve({ userId: "user_123", orgId: "org_123" })
  );
});
```

#### Supabase Client
```typescript
let mockSupabaseFn: Mock;
vi.mock("@/app/_shared/lib/supabase/server", () => ({
  createServiceRoleClient: () => mockSupabaseFn(),
}));

beforeEach(() => {
  mockSupabaseFn = vi.fn(() => Promise.resolve({}));
});
```

#### External APIs (Stripe, Nylas)
```typescript
let mockStripeCreateFn: Mock;
vi.mock("stripe", () => ({
  default: vi.fn().mockImplementation(() => ({
    checkout: {
      sessions: {
        create: (...args: unknown[]) => mockStripeCreateFn(...args),
      },
    },
  })),
}));

beforeEach(() => {
  mockStripeCreateFn = vi.fn(() =>
    Promise.resolve({ id: "cs_123", url: "https://checkout.stripe.com" })
  );
});
```

## Test File Templates

Use templates from `apps/web/test/templates/`:

```bash
# Copy server action template
cp test/templates/server-action.test.ts app/(protected)/my-feature/_actions/__tests__/my-action.test.ts

# Copy repository template
cp test/templates/repository.test.ts app/_shared/repositories/__tests__/my-repo.test.ts
```

## E2E Tests

### Running E2E Tests

```bash
cd apps/web

# Run all E2E tests
bunx playwright test

# Run specific test file
bunx playwright test test/e2e/billing/subscription-flow.spec.ts

# Interactive UI mode
bunx playwright test --ui

# Debug mode
bunx playwright test --debug
```

### Writing E2E Tests

```typescript
// test/e2e/my-feature/my-flow.spec.ts
import { expect, test } from "../fixtures/authenticated-page";

test.describe("My Feature Flow", () => {
  test("user can complete flow", async ({ authenticatedPage }) => {
    await authenticatedPage.goto("/my-feature");

    await authenticatedPage.getByRole("button", { name: /start/i }).click();

    await expect(authenticatedPage).toHaveURL(/\/my-feature\/complete/);
  });
});
```

## Common Gotchas

### 1. Import Order Matters

Always import the module under test AFTER setting up mocks:

```typescript
// ✅ Correct
vi.mock("dependency");
import { myFunction } from "../my-module"; // AFTER mocks

// ❌ Wrong - mocks won't apply
import { myFunction } from "../my-module"; // BEFORE mocks
vi.mock("dependency");
```

### 2. Environment Variables

For tests that need environment variables:

```typescript
// Set before any imports
const originalEnv = { ...process.env };
process.env.MY_VAR = "test_value";

// Restore after all tests
afterAll(() => {
  process.env = originalEnv;
});
```

### 3. Async Mock Setup

If your mock setup is async, use `beforeAll`:

```typescript
let testData: TestData;

beforeAll(async () => {
  testData = await seedTestData();
});

afterAll(async () => {
  await cleanupTestData(testData);
});
```

## Next Steps

- [Test Factories](./factories.md) - Reusable test data generation
- [Mocking Guide](./mocking.md) - Advanced mocking patterns
- [Integration Tests](./integration-tests.md) - Testing with real dependencies
