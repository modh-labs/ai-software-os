---
title: "Environment Variable Management"
description: "Turborepo-specific environment variable configuration and best practices."
tags: ["architecture", "security"]
category: "standards"
author: "Imran Gardezi"
publishable: true
---
# Environment Variables in Turborepo

> **Standard:** This document covers Turborepo-specific environment variable configuration and best practices.
> For setting up actual environment variable values, see [`docs/internal/guides/ENV_SETUP.md`](../internal/guides/ENV_SETUP.md).

---

## Overview

Turborepo uses environment variables for:
1. **Task hashing** - Changes to env vars should invalidate cache
2. **Runtime availability** - Ensuring tasks have access to needed variables
3. **Cache safety** - Preventing wrong builds from hitting cache

There are three key questions when working with environment variables in Turborepo:

1. Are my environment variables accounted for in the task hash?
2. Which Environment Mode will turbo use?
3. Have I handled my `.env` files?

---

## Configuration Files

### `turbo.json`

**File**: [`turbo.json`](../../turbo.json)

This file configures which environment variables affect task hashing and runtime availability.

```json
{
  "globalPassThroughEnv": ["VERCEL_*", "CI", "NODE_ENV"],
  "globalDependencies": [".env*"],
  "tasks": {
    "build": {
      "env": ["CLERK_*", "SUPABASE_*", "STRIPE_*", "NYLAS_*"]
    }
  }
}
```

---

## Key Configuration Options

### `globalEnv`

**Purpose**: Environment variables that affect **all tasks** and should invalidate cache when changed.

**Use Case**: Rarely needed. Most env vars are task-specific.

**Example**: If you had a global API version that affected everything:

```json
{
  "globalEnv": ["API_VERSION"]
}
```

**Note**: We don't currently use `globalEnv` - our vars are task-specific.

---

### `env` (Task-Specific)

**Purpose**: Environment variables that affect a **specific task** and should invalidate cache when changed.

**Use Case**: Variables used during build/test/etc. that affect output.

**Example**: Build task needs API keys for generating API client:

```json
{
  "tasks": {
    "build": {
      "env": ["CLERK_*", "SUPABASE_*", "STRIPE_*", "NYLAS_*"]
    }
  }
}
```

**Wildcards Supported**: You can use `*` to match prefixes (e.g., `CLERK_*` matches `CLERK_SECRET_KEY`, `CLERK_PUBLISHABLE_KEY`, etc.)

**Current Configuration**:
- Base `build` task: Core service vars (`CLERK_*`, `SUPABASE_*`, `STRIPE_*`, `NYLAS_*`)
- `@your-org/web#build`: Additional web-specific vars (AI keys, Sentry, etc.)
- `@your-org/admin#build`: Admin-specific vars (KV, Sentry, etc.)

---

### `globalPassThroughEnv` / `passThroughEnv`

**Purpose**: Variables available at runtime but **don't affect task hashing**.

**Use Case**: CI/system variables, build metadata, deployment info.

**Example**: Vercel deployment info shouldn't invalidate cache:

```json
{
  "globalPassThroughEnv": ["VERCEL_*", "CI", "NODE_ENV"]
}
```

**Why Use This**:
- CI vendor variables change every build but don't affect output
- Build metadata (`VERCEL_ENV`, `VERCEL_URL`) is runtime-only
- `NODE_ENV` is set by Node/frameworks, not by us

**Current Configuration**:
- `VERCEL_*` - Vercel deployment metadata (auto-injected)
- `CI` - CI environment detection
- `NODE_ENV` - Node environment (development/production)

---

### `globalDependencies`

**Purpose**: Files that affect **all task hashes** when changed.

**Use Case**: Configuration files, lockfiles, `.env` files.

**Example**: Changes to `.env` files should invalidate all caches:

```json
{
  "globalDependencies": ["tsconfig.json", "pnpm-lock.yaml", "biome.json", ".env*"]
}
```

**Why Include `.env*`**:
- When you change `.env.local`, the build output might change
- Without this, Turborepo might serve cached build with old env values
- This ensures cache invalidation when env files change

**Current Configuration**:
- `tsconfig.json` - TypeScript config affects all builds
- `pnpm-lock.yaml` - Dependency changes
- `biome.json` - Linting/formatting config
- `.env*` - **Environment file changes** (added to prevent cache issues)

---

## Framework Inference

Turborepo automatically detects and includes framework-specific environment variables.

### Next.js

**Automatic Prefix**: `NEXT_PUBLIC_*`

**What This Means**: You **don't need** to list `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`, `NEXT_PUBLIC_SUPABASE_URL`, etc. in your `turbo.json`. Turborepo automatically:
1. Includes them in task hashing
2. Makes them available at runtime (in Strict Mode)

**Example**: These are handled automatically:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
NEXT_PUBLIC_SUPABASE_URL=https://...
NEXT_PUBLIC_APP_URL=https://...
```

**How It Works**: Framework inference is **per-package**. Since our apps use Next.js, they get `NEXT_PUBLIC_*` wildcards automatically.

**Opting Out**: If needed (rare), you can disable:

```json
{
  "tasks": {
    "build": {
      "env": ["!NEXT_PUBLIC_*"]
    }
  }
}
```

---

## Environment Modes

### Strict Mode (Default)

**Behavior**: Only variables listed in `env`/`globalEnv`/`passThroughEnv` are available to tasks.

**Benefits**:
- Prevents accidental cache hits with wrong env values
- Forces explicit declaration of all variables
- Catches missing env vars early

**Example**: If you use `MY_API_KEY` in code but don't list it in `turbo.json`:

```bash
# Build fails in Strict Mode:
Error: Environment variable MY_API_KEY is not available
```

**Solution**: Add to `env` array:

```json
{
  "tasks": {
    "build": {
      "env": ["MY_API_KEY"]
    }
  }
}
```

**Current Setup**: We use Strict Mode (default). All required vars are listed in `turbo.json`.

---

### Loose Mode

**Behavior**: All environment variables are available to tasks, even if not listed.

**When to Use**:
- Migration period (temporary)
- Debugging missing variables
- Legacy compatibility

**How to Enable**:

```bash
turbo run build --env-mode=loose
```

**⚠️ Warning**: Loose Mode can lead to cache issues:
- Build with `MY_API_URL=preview` → caches output
- Build with `MY_API_URL=production` → hits cache (wrong!)
- Production build has preview API URLs → **bug in production**

**Best Practice**: Always use Strict Mode. If builds fail, add missing vars to `turbo.json` instead of using Loose Mode.

---

## Handling `.env` Files

### File Placement

**Best Practice**: Place `.env` files in **package directories** (not root).

```
apps/web/.env.local      ✅ Recommended
apps/admin/.env.local    ✅ Recommended
.env.local                ⚠️ Works but not ideal
```

**Why**:
- Each app has its own runtime environment
- Prevents env var leakage between apps
- Matches production deployment patterns

**Current Setup**: We have `.env` files at both root and app levels. Consider migrating to app-level only (future improvement).

---

### Tracking `.env` Files

**Configuration**: Add `.env*` to `globalDependencies` or task `inputs`.

**Current Setup**:

```json
{
  "globalDependencies": [".env*"]
}
```

**Why This Matters**:
- Change to `.env.local` → all task hashes change
- Cache invalidates → fresh build with new env values
- Without this, cached build might have old env values

**What Gets Tracked**:
- `.env` - Base template
- `.env.local` - Local overrides (gitignored)
- `.env.example` - Example template (committed)
- `.env.production` - Production-specific (if used)

---

### Loading `.env` Files

**Important**: Turborepo **does not** load `.env` files into task runtime.

**Who Loads Them**:
- **Next.js**: Automatically loads `.env.local`, `.env.production`, etc.
- **Node.js**: Use `dotenv` package if needed
- **Build tools**: Framework-specific loaders

**What Turborepo Does**:
- Tracks `.env` file changes for hashing (via `globalDependencies`)
- Filters env vars at runtime (via `env`/`passThroughEnv` configs)

**Example**:

```bash
# .env.local
MY_API_KEY=secret123
```

```typescript
// In your code
const apiKey = process.env.MY_API_KEY; // ✅ Works (Next.js loads it)
```

```json
// In turbo.json
{
  "tasks": {
    "build": {
      "env": ["MY_API_KEY"] // ✅ Required (Turborepo needs to know about it)
    }
  }
}
```

---

## ESLint Validation

### `eslint-config-turbo`

**Purpose**: Automatically detects environment variables used in code but missing from `turbo.json`.

**Installation**: Already installed at root.

**Configuration**:

**File**: `apps/web/eslint.config.js` and `apps/admin/eslint.config.js`

```js
import turboConfig from "eslint-config-turbo/flat";

export default [
  ...turboConfig,
  // Other config
];
```

**Usage**:

```bash
# Check for missing env vars in web app
cd apps/web && npx eslint .

# Check for missing env vars in admin app
cd apps/admin && npx eslint .
```

**What It Catches**:

```typescript
// Code uses env var
const key = process.env.MY_NEW_KEY;

// Error if MY_NEW_KEY not in turbo.json:
// Environment variable MY_NEW_KEY is not declared in turbo.json
```

**Solution**: Add to `turbo.json`:

```json
{
  "tasks": {
    "build": {
      "env": ["MY_NEW_KEY"]
    }
  }
}
```

**Note**: This runs separately from Biome (our primary linter). Use ESLint specifically for env var validation.

---

## Verification

### Check Environment Variable Summary

**Command**:

```bash
turbo run build --summarize
```

**Output**: JSON file with env var usage, hashes, and cache status.

**Use Cases**:
- Verify all vars are listed
- Check task hashes include env vars
- Debug cache misses/hits

### Test Cache Invalidation

**Steps**:

1. Build once:
```bash
turbo run build
```

2. Change `.env.local`:
```bash
echo "TEST_VAR=changed" >> apps/web/.env.local
```

3. Build again:
```bash
turbo run build
```

4. **Expected**: Cache miss (new hash because `.env*` changed)
5. **If cache hit**: Check `globalDependencies` includes `.env*`

### Verify Strict Mode

**Test**: Remove an env var from `turbo.json` that's used in code.

**Expected**: Build fails with error about missing env var.

**If it succeeds**: Check that you're not using `--env-mode=loose`.

---

## Current Configuration Summary

### Files

- **`turbo.json`**: Main configuration
  - `globalPassThroughEnv`: `["VERCEL_*", "CI", "NODE_ENV"]`
  - `globalDependencies`: Includes `.env*` for cache invalidation
  - Task-specific `env` arrays for build tasks

- **`apps/web/eslint.config.js`**: ESLint config with `eslint-config-turbo`
- **`apps/admin/eslint.config.js`**: ESLint config with `eslint-config-turbo`

### Environment Variables

**Automatically Handled** (via Framework Inference):
- `NEXT_PUBLIC_*` - All Next.js public env vars

**Explicitly Listed** (in `turbo.json`):
- `CLERK_*` - Authentication
- `SUPABASE_*` - Database
- `STRIPE_*` - Payments
- `NYLAS_*` - Calendar
- `KV_*` - Upstash Redis
- `SENTRY_AUTH_TOKEN` - Error tracking
- AI keys: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_*`
- `DUB_*` - Link shortening
- `INNGEST_*` - Background jobs
- `RESEND_*` - Email
- `AI_GATEWAY_API_KEY` - AI Gateway
- `INTEGRATION_ENCRYPTION_KEY` - Encryption

**Pass-Through** (don't affect hashing):
- `VERCEL_*` - Vercel deployment metadata
- `CI` - CI environment detection
- `NODE_ENV` - Node environment

---

## Best Practices

### ✅ DO

- **List all env vars** in `turbo.json` (except `NEXT_PUBLIC_*` which are automatic)
- **Use wildcards** for prefixes (`CLERK_*` instead of listing each var)
- **Add `.env*` to `globalDependencies`** so cache invalidates on changes
- **Use Strict Mode** (default) to catch missing vars early
- **Place `.env` files in app directories** (not root) when possible
- **Run ESLint** periodically to catch missing vars: `npx eslint apps/web apps/admin`
- **Verify with `--summarize`** before deploying to production

### ❌ DON'T

- **Use Loose Mode** unless migrating or debugging
- **Create/mutate env vars at runtime** (Turborepo won't detect them)
- **Forget to add new env vars** to `turbo.json` when adding them to code
- **Place `.env` files at root** (use app-level when possible)
- **Ignore ESLint warnings** about missing env vars

---

## Troubleshooting

### "Environment variable X is not available"

**Cause**: Variable used in code but not in `turbo.json` (Strict Mode).

**Solution**: Add to `env` array in `turbo.json`:

```json
{
  "tasks": {
    "build": {
      "env": ["X"]
    }
  }
}
```

**Or**: If it shouldn't affect hashing, use `passThroughEnv`:

```json
{
  "tasks": {
    "build": {
      "passThroughEnv": ["X"]
    }
  }
}
```

---

### Cache hit with wrong env values

**Cause**: `.env` file changed but `globalDependencies` doesn't include `.env*`.

**Solution**: Add `.env*` to `globalDependencies`:

```json
{
  "globalDependencies": [".env*"]
}
```

---

### ESLint warns about `NEXT_PUBLIC_*` vars

**Cause**: `eslint-config-turbo` doesn't know about framework inference.

**Solution**: This is a false positive. Framework inference handles `NEXT_PUBLIC_*` automatically. You can ignore these warnings or add an allowlist:

```js
// eslint.config.js
export default [
  ...turboConfig,
  {
    rules: {
      "turbo/no-undeclared-env-vars": [
        "error",
        {
          allowList: ["^NEXT_PUBLIC_"],
        },
      ],
    },
  },
];
```

---

## References

- [Turborepo Docs: Using Environment Variables](https://turbo.build/repo/docs/core-concepts/environment-variables)
- [Turborepo Docs: Framework Inference](https://turbo.build/repo/docs/core-concepts/environment-variables#framework-inference)
- [Turborepo Docs: eslint-config-turbo](https://turbo.build/repo/docs/core-concepts/environment-variables#use-eslint-config-turbo)
- [Environment Setup Guide](../internal/guides/ENV_SETUP.md) - How to set up actual env var values
