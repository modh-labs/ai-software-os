---
title: "CI Pipeline: Extensible Step Runner"
description: "How your project's CI quality gate works and how to extend it."
tags: ["ci-cd", "architecture", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# CI Pipeline Pattern

How your project's CI quality gate works, and how to extend it.

## Architecture

```
Developer pushes code
    │
    ├──→ GitHub Actions (CI)          ← Quality gate (this pattern)
    │    ├── Lint & Format (Biome)
    │    ├── AGENTS.md Convention
    │    ├── TypeScript Typecheck
    │    └── Unit & Integration Tests
    │
    └──→ Vercel (Deployment)          ← Automatic, not managed by CI
         ├── Preview deployment (PR)
         └── Production deployment (merge to main)
```

**CI and deployment are completely separated.** GitHub Actions runs quality checks. Vercel deploys automatically via Git Integration. There are no deployment commands in CI.

## How It Works

### Local: `bun run ci`

Runs `scripts/ci.sh` — an extensible shell script with a step runner:

```bash
run_step "Lint & Format (Biome)" bunx biome check --write --unsafe .
run_step "AGENTS.md Convention"  ./scripts/lint-agents-md.sh
run_step "TypeScript Typecheck"  bunx turbo typecheck
run_step "Unit & Integration Tests" bunx turbo test:ci
```

Each step gets: named output, timing, fail-fast behavior, and a summary table.

### CI: GitHub Actions

`.github/workflows/ci.yml` mirrors the same steps as discrete GitHub Actions steps. Each step has an `id` for summary reporting and appears as a separate check in the PR UI.

### Parity

Same checks, same order, same fail-fast behavior. What passes locally passes in CI.

## Adding a New CI Check

### Step 1: Create the check

Either a standalone script or a single command:

```bash
# Option A: Script
cat > scripts/my-check.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
# ... your check logic
EOF
chmod +x scripts/my-check.sh

# Option B: Direct command (for simple checks)
# Just use the command directly in run_step
```

### Step 2: Add to `scripts/ci.sh`

Place it in the correct position — **cheapest checks first**:

```bash
# ── Conventions & Linting ────────────────────────────────────────────────────
run_step "Lint & Format (Biome)" bunx biome check --write --unsafe .
run_step "AGENTS.md Convention" ./scripts/lint-agents-md.sh
run_step "My New Check" ./scripts/my-check.sh          # ← add here if cheap

# ── Type Safety ──────────────────────────────────────────────────────────────
run_step "TypeScript Typecheck" bunx turbo typecheck

# ── Tests ────────────────────────────────────────────────────────────────────
run_step "Unit & Integration Tests" bunx turbo test:ci
```

### Step 3: Add to `.github/workflows/ci.yml`

Add a matching step with an `id`:

```yaml
- name: "My New Check"
  id: my-check
  run: ./scripts/my-check.sh
```

### Step 4: Update the summary

In the `Generate summary` step of `ci.yml`:

```yaml
echo "| My New Check | ${{ steps.my-check.outcome == 'failure' && 'FAIL' || 'PASS' }} |" >> $GITHUB_STEP_SUMMARY
```

### Step 5: Update docs

- Update the step list in `.github/AGENTS.md`
- Test locally: `bun run ci`

## Design Decisions

### Why a shell script and not `package.json`?

The inline `"ci": "cmd1 && cmd2 && cmd3"` pattern in `package.json` is:
- Opaque — no step names, no timing, no indication of what failed
- Hard to extend — long `&&` chains are error-prone to edit
- No middleware pattern — you can't wrap steps with logging, timing, or reporting

The shell script provides all of these for zero additional dependencies.

### Why cheapest-first ordering?

Steps run sequentially and fail fast. If linting fails (2 seconds), there's no point running tests (2 minutes). Ordering by cost minimizes wasted CI time:

| Step | Typical Duration | Catches |
|------|:---:|---|
| Lint & Format | ~5s | Style, formatting, import issues |
| AGENTS.md Convention | ~1s | Missing CLAUDE.md files |
| TypeScript Typecheck | ~30-60s | Type errors across monorepo |
| Tests | ~60-120s | Logic errors, regressions |

### Why not separate GitHub Actions jobs?

Separate jobs (lint job, test job, etc.) run in parallel but each needs its own setup (checkout, install, cache). For our pipeline, sequential steps in one job are faster because:
- Setup runs once (~30s saved per step)
- Turborepo cache is shared across steps
- Fail-fast still works (step failure stops the job)

If CI time grows beyond 10 minutes, consider splitting into parallel jobs.

## Performance Optimizations

The CI pipeline is tuned for speed at every layer. When adding new steps or modifying existing ones, preserve these optimizations.

### Turborepo Caching

Both `typecheck` and `test:ci` have Turbo caching enabled in `turbo.json`:

```json
"typecheck": { "cache": true, "outputs": [".tsbuildinfo"] }
"test:ci": { "cache": true }
```

On repeat runs with no file changes, cached steps replay instantly (~1s instead of 8-14s).

### TypeScript Incremental Compilation

All `tsconfig.json` files across the monorepo have `"incremental": true`. This generates `.tsbuildinfo` files that let TypeScript skip re-checking unchanged files.

**When adding a new package:** always include `"incremental": true` in its `tsconfig.json`.

### find -prune (Not -not -path)

Custom lint scripts that traverse the repo (like `scripts/lint-agents-md.sh`) must use `-prune` to skip large directories — NOT `-not -path`:

```bash
# WRONG — walks into node_modules then filters (25s)
find . -name "AGENTS.md" -not -path "*/node_modules/*"

# RIGHT — never enters node_modules at all (0.3s)
find . \( -path "*/node_modules" -o -path "*/.next" \) -prune -o -name "AGENTS.md" -print
```

This is an 80x speedup on a typical monorepo.

### Step Ordering

Steps are ordered cheapest-first so failures are caught as fast as possible:

| Step | Duration | Why This Position |
|------|:---:|---|
| Lint & Format | ~1s | Biome is very fast with built-in caching |
| AGENTS.md Convention | ~1s | Simple file checks with pruned find |
| TypeScript Typecheck | ~8s | Needs to parse types across packages |
| Tests | ~14s | Most expensive — runs Vitest across 3 apps |

## Anti-Patterns

| Don't | Do Instead |
|-------|-----------|
| Add `vercel deploy` to CI | Let Vercel Git Integration handle it |
| Inline checks in `package.json` ci script | Add `run_step` to `scripts/ci.sh` |
| Put tests before linting | Order cheapest-first |
| Skip step IDs in GitHub Actions | Always add `id:` for summary reporting |
| Use `continue-on-error: true` on checks | Let failures fail — that's the point |
| Add deployment secrets to GitHub Actions | Vercel has its own secrets management |

## Related

- `.github/AGENTS.md` — CI/CD quick reference
- `scripts/ci.sh` — CI orchestration script
- `.github/workflows/ci.yml` — GitHub Actions workflow
- `scripts/lint-agents-md.sh` — AGENTS.md convention linter
