---
title: "Integration Testing Guide"
description: "Integration tests verify components work together with real dependencies"
tags: ["testing", "database"]
category: "testing"
author: "Imran Gardezi"
publishable: true
---
# Integration Tests

Integration tests verify components work together with real dependencies.

## When to Use Integration Tests

| Scenario | Use Integration Test? |
|----------|----------------------|
| Repository with RLS | ✅ Yes - verify policies |
| Stripe subscription | ✅ Yes - test mode API |
| Nylas calendar sync | ✅ Yes - sandbox API |
| Server action logic | ❌ No - use unit tests |
| Component rendering | ❌ No - use unit tests |

## Environment Setup

### Required Environment Variables

```bash
# .env.test (or set in CI)

# Supabase - Required for database integration tests
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# Stripe - Optional, for payment integration tests
STRIPE_TEST_SECRET_KEY=sk_test_...

# Nylas - Optional, for calendar integration tests
NYLAS_TEST_API_KEY=nyk_test_...
NYLAS_TEST_CLIENT_ID=...
```

### How to Obtain Test Credentials

#### Stripe Test Mode Credentials

1. **Log into Stripe Dashboard**: https://dashboard.stripe.com
2. **Enable Test Mode**: Toggle "Test mode" in the top-right corner
3. **Get API Key**: Go to Developers → API Keys → Reveal test key
4. **Copy the key**: It should start with `sk_test_`

```bash
# Add to .env.local or CI secrets
STRIPE_TEST_SECRET_KEY=sk_test_51ABC123...
```

**Note**: Test mode uses fake money - no real charges occur. Test cards:
- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`

#### Nylas Sandbox Credentials

1. **Log into Nylas Dashboard**: https://dashboard.nylas.com
2. **Create Sandbox Application** (if not exists):
   - Go to Applications → Create Application
   - Name: "Integration Tests"
   - Environment: Sandbox
3. **Get API Key**: Applications → [Your App] → API Keys → Create Key
4. **Get Client ID**: Applications → [Your App] → Application ID

```bash
# Add to .env.local or CI secrets
NYLAS_TEST_API_KEY=nyk_v3_sandbox_...
NYLAS_TEST_CLIENT_ID=abc123...
```

**Sandbox limitations**:
- 50 connected accounts max
- Synthetic calendar data
- No real email sending

#### Supabase Service Role Key

1. **Log into Supabase Dashboard**: https://supabase.com/dashboard
2. **Select Project**: Choose your test/staging project
3. **Get Keys**: Settings → API → `service_role` key (secret)

```bash
# Add to .env.local or CI secrets
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIs...
```

**⚠️ Security Warning**: The service role key bypasses RLS. Never commit it to git or expose in client-side code.

### CI/CD Secret Configuration

For GitHub Actions, add these secrets in Settings → Secrets and variables → Actions:

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `SUPABASE_URL` | Supabase project URL | ✅ Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key | ✅ Yes |
| `STRIPE_TEST_SECRET_KEY` | Stripe test mode key | Optional |
| `NYLAS_TEST_API_KEY` | Nylas sandbox API key | Optional |
| `NYLAS_TEST_CLIENT_ID` | Nylas application ID | Optional |

Tests requiring missing credentials will be automatically skipped.

### Conditional Test Execution

Use `describe.skipIf` to skip tests when credentials aren't available:

```typescript
const STRIPE_KEY = process.env.STRIPE_TEST_SECRET_KEY;
const HAS_STRIPE = !!STRIPE_KEY;

describe.skipIf(!HAS_STRIPE)("Stripe Integration", () => {
  let stripe: Stripe;

  beforeAll(() => {
    stripe = new Stripe(STRIPE_KEY!, {
      apiVersion: "2025-10-29.clover",
    });
  });

  it("creates a checkout session", async () => {
    const session = await stripe.checkout.sessions.create({
      // ...
    });
    expect(session.id).toMatch(/^cs_test_/);
  });
});
```

## Database Integration Tests

### Testing RLS Policies

```typescript
import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { createServiceRoleClient, createClient } from "@/app/_shared/lib/supabase/server";

describe("leads.repository - RLS Integration", () => {
  let serviceClient: SupabaseClient;
  let testOrgA: string;
  let testOrgB: string;

  beforeEach(async () => {
    serviceClient = await createServiceRoleClient();

    // Create test organizations
    testOrgA = `org_test_a_${Date.now()}`;
    testOrgB = `org_test_b_${Date.now()}`;
  });

  afterEach(async () => {
    // Clean up test data
    await serviceClient.from("leads").delete().in("organization_id", [testOrgA, testOrgB]);
  });

  it("prevents cross-org data access", async () => {
    // Create lead in Org A
    const { data: leadA } = await serviceClient
      .from("leads")
      .insert({
        organization_id: testOrgA,
        email: "a@example.com",
        full_name: "User A",
      })
      .select()
      .single();

    // Query from Org B perspective
    const { data: results } = await serviceClient
      .from("leads")
      .select("*")
      .eq("organization_id", testOrgB);

    // Org B should NOT see Org A's lead
    expect(results).toHaveLength(0);
  });

  it("allows same-org data access", async () => {
    // Create lead in Org A
    await serviceClient.from("leads").insert({
      organization_id: testOrgA,
      email: "a@example.com",
      full_name: "User A",
    });

    // Query from same org
    const { data: results } = await serviceClient
      .from("leads")
      .select("*")
      .eq("organization_id", testOrgA);

    expect(results).toHaveLength(1);
    expect(results[0].email).toBe("a@example.com");
  });
});
```

### Testing Cascading Deletes

```typescript
describe("GDPR deletion - Integration", () => {
  it("deletes all associated data", async () => {
    const supabase = await createServiceRoleClient();
    const testOrgId = `org_gdpr_${Date.now()}`;

    // Create lead with associated calls and notes
    const { data: lead } = await supabase
      .from("leads")
      .insert({ organization_id: testOrgId, email: "delete@test.com", full_name: "Delete Me" })
      .select()
      .single();

    await supabase.from("calls").insert({
      organization_id: testOrgId,
      lead_id: lead.id,
      scheduled_at: new Date().toISOString(),
    });

    // Perform deletion
    await deleteLeadData(lead.id, "GDPR request");

    // Verify complete deletion
    const { data: leadCheck } = await supabase
      .from("leads")
      .select()
      .eq("id", lead.id)
      .maybeSingle();
    expect(leadCheck).toBeNull();

    const { data: callsCheck } = await supabase
      .from("calls")
      .select()
      .eq("lead_id", lead.id);
    expect(callsCheck).toHaveLength(0);
  });
});
```

## External API Integration Tests

### Stripe Integration

```typescript
const STRIPE_KEY = process.env.STRIPE_TEST_SECRET_KEY;

describe.skipIf(!STRIPE_KEY)("Stripe Integration", () => {
  let stripe: Stripe;

  beforeAll(() => {
    console.log("🔑 Running Stripe integration tests with test mode credentials");
    stripe = new Stripe(STRIPE_KEY!, { apiVersion: "2025-10-29.clover" });
  });

  describe("Customer Operations", () => {
    it("creates and deletes test customer", async () => {
      // Create
      const customer = await stripe.customers.create({
        email: "integration-test@test.example.com",
        metadata: { test: "true", created_by: "integration_test" },
      });

      expect(customer.id).toMatch(/^cus_/);

      // Cleanup
      const deleted = await stripe.customers.del(customer.id);
      expect(deleted.deleted).toBe(true);
    });
  });

  describe("Error Handling", () => {
    it("handles invalid API key", async () => {
      const invalidStripe = new Stripe("sk_test_invalid", {
        apiVersion: "2025-10-29.clover",
      });

      await expect(invalidStripe.customers.list({ limit: 1 })).rejects.toBeInstanceOf(
        Stripe.errors.StripeAuthenticationError
      );
    });
  });
});
```

### Nylas Integration

```typescript
const NYLAS_KEY = process.env.NYLAS_TEST_API_KEY;

describe.skipIf(!NYLAS_KEY)("Nylas Integration", () => {
  let nylas: Nylas;

  beforeAll(() => {
    console.log("📅 Running Nylas integration tests with sandbox credentials");
    nylas = new Nylas({ apiKey: NYLAS_KEY! });
  });

  describe("Grant Validation", () => {
    it("validates active grant", async () => {
      const grants = await nylas.grants.list({ limit: 1 });

      if (grants.data.length > 0) {
        const grant = grants.data[0];
        expect(grant.id).toBeDefined();
        expect(grant.email).toBeDefined();
      }
    });
  });
});
```

## Best Practices

### 1. Clean Up Test Data

Always clean up after tests to prevent state pollution:

```typescript
afterEach(async () => {
  await supabase.from("test_table").delete().eq("test", true);
});

// Or use unique identifiers
const testOrgId = `org_test_${Date.now()}`;
```

### 2. Use Test-Specific Identifiers

```typescript
const TEST_PREFIX = "integration_test_";

const customer = await stripe.customers.create({
  email: `${TEST_PREFIX}${Date.now()}@test.com`,
  metadata: { test: "true" },
});
```

### 3. Handle Rate Limits

```typescript
beforeAll(async () => {
  // Rate limit buffer
  await new Promise((r) => setTimeout(r, 1000));
});
```

### 4. Log Integration Test Execution

```typescript
beforeAll(() => {
  console.log("🧪 Starting integration tests...");
  console.log(`  📊 Database: ${process.env.SUPABASE_URL}`);
  console.log(`  💳 Stripe: ${STRIPE_KEY ? "configured" : "skipped"}`);
  console.log(`  📅 Nylas: ${NYLAS_KEY ? "configured" : "skipped"}`);
});
```

## CI Configuration

### GitHub Actions

```yaml
# .github/workflows/test.yml
jobs:
  integration:
    runs-on: ubuntu-latest
    env:
      SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
      SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
      STRIPE_TEST_SECRET_KEY: ${{ secrets.STRIPE_TEST_SECRET_KEY }}
      NYLAS_TEST_API_KEY: ${{ secrets.NYLAS_TEST_API_KEY }}

    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v1

      - name: Install dependencies
        run: bun install

      - name: Run integration tests
        run: bun test:integration
```

### Package.json Script

```json
{
  "scripts": {
    "test:integration": "vitest run --config vitest.integration.config.ts"
  }
}
```

## Debugging Integration Tests

### 1. Enable Verbose Logging

```typescript
beforeAll(() => {
  // Enable debug logging for the module under test
  process.env.DEBUG = "[app]:*";
});
```

### 2. Inspect API Responses

```typescript
it("debugs API response", async () => {
  const response = await stripe.customers.list({ limit: 1 });
  console.log("Raw response:", JSON.stringify(response, null, 2));
});
```

### 3. Use Breakpoints

```bash
# Run with Node inspector
NODE_OPTIONS='--inspect-brk' bun test:integration
```
