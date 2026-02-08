---
description: Run tests and analyze failures with fix suggestions
argument-hint: [optional path or pattern]
allowed-tools: Read, Edit, Bash, Grep, Glob
---

# Test Command

Run tests and analyze any failures.

**Target**: `$ARGUMENTS` (or all tests if not specified)

## Test Commands

```bash
# Run all tests (CI mode - single run)
npm run test:ci

# Run specific file
npm run test -- $ARGUMENTS

# Run tests matching pattern
npm run test -- -t "pattern"

# Run with coverage
npm run test:coverage

# Run E2E tests
npm run test:e2e
```

## Test Analysis Process

### Step 1: Run Tests

```bash
npm run test:ci
```

Or for specific target:
```bash
npm run test -- $ARGUMENTS
```

### Step 2: Parse Results

For each failing test, I'll identify:
- Test file location
- Test name/description
- Error message
- Stack trace

### Step 3: Analyze Root Cause

For each failure, determine if:
1. **Test is wrong** - Test expectations need updating
2. **Source is wrong** - Code has a bug
3. **Mock is wrong** - External dependencies not mocked correctly
4. **Environment issue** - Setup/teardown problem

### Step 4: Suggest Fixes

Provide specific fixes for each failure.

## Common Test Issues

### Mock Not Working

```typescript
// ❌ Wrong - Import before mock
import { myFunction } from "./module";
vi.mock("./dependency");

// ✅ Correct - Mock before import
vi.mock("./dependency");
import { myFunction } from "./module";
```

### Async Test Timeout

```typescript
// Add longer timeout
it("should handle slow operation", async () => {
  // ...
}, 10000);

// Or use fake timers
vi.useFakeTimers();
```

### Missing Supabase Mock

```typescript
const mockSupabase = {
  from: vi.fn(() => ({
    select: vi.fn(() => ({
      eq: vi.fn(() => ({
        single: vi.fn(() => Promise.resolve({ data: mockData, error: null })),
      })),
    })),
  })),
};

vi.mock("@/app/_shared/lib/supabase/server", () => ({
  createClient: vi.fn(() => Promise.resolve(mockSupabase)),
}));
```

### Missing Clerk Mock

```typescript
vi.mock("@clerk/nextjs/server", () => ({
  auth: vi.fn(() => ({ orgId: "test-org", userId: "test-user" })),
  currentUser: vi.fn(() => Promise.resolve({ id: "test-user" })),
}));
```

## Output Format

```markdown
# Test Results

**Command**: `npm run test:ci`
**Status**: ✅ Passing / ❌ X failing

## Passing Tests
- `path/to/test.ts` - 5 tests ✅

## Failing Tests

### 1. path/to/failing.test.ts > describe > test name

**Error**:
```
Expected: X
Received: Y
```

**Root Cause**: [Analysis]

**Fix**:
```typescript
// Code change needed
```

## Summary
- Total: X tests
- Passing: Y
- Failing: Z
- Coverage: XX%
```

## Test File Patterns

Tests should be in `__tests__` directories:

```
app/(protected)/calls/actions/
├── cancel-call.ts
└── __tests__/
    └── cancel-call.test.ts
```

## Quick Test Commands

| Command | Purpose |
|---------|---------|
| `npm run test` | Watch mode |
| `npm run test:ci` | Single run |
| `npm run test -- path` | Specific file |
| `npm run test -- -t "name"` | By name |
| `npm run test:coverage` | With coverage |
| `npm run test:e2e` | E2E tests |
