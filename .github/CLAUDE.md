# CI/CD Quick Reference

**Architecture:** Local → PR → main (auto-deploy via hosting provider)
**Package:** bun + Turborepo | **Database:** Supabase | **Hosting:** Vercel

## Workflow

```bash
git checkout -b feature/xxx      # Local dev
bun run ci                        # Fast check (lint + test + types) - 5s
git push && gh pr create          # PR triggers CI
gh pr merge --squash              # Merge → auto-deploys
```

## Architecture: CI vs Deployment

**CI Quality Gate (`.github/workflows/ci.yml` + `scripts/ci.sh`)**
- Runs on PRs and pushes to main
- Each step is visible as a separate check in the PR UI
- Steps (in order): Lint & Format → AGENTS.md Convention → TypeScript Typecheck → Tests
- Adding a new check: add one `run_step` line in `scripts/ci.sh`
- GitHub Actions does NOT manage deployments

**Deployment (Hosting Provider Git Integration)**
- Auto-deploys on every push (no GitHub Actions needed)
- Preview deployments on PRs, production on main
- No manual deployment steps required

## Commands

```bash
bun dev          # Start dev server
bun run ci       # Fast CI check (lint + typecheck + tests) ~5s
bun run ci:build # Full CI with build verification ~30s
bun run db:reset # Test migrations locally
bun run db:types # Sync TypeScript types
```

## Key Files

- `scripts/ci.sh` — CI orchestration script (extensible step runner)
- `.github/workflows/ci.yml` — GitHub Actions workflow
- `supabase/migrations/` — Migration files
- `supabase/schemas/` — Schema source files

## Commits

- Format: `type(scope): description` ([Conventional Commits](https://www.conventionalcommits.org/))
- Types: `feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `chore`, `ci`
- Include: `Co-Authored-By: Claude <noreply@anthropic.com>`
- Link to project management: `Fixes: [PROJ]-XXX` or branch name with issue ID

## Issue Linking

- Use branch names from your project management tool (e.g., `user/proj-127-feature-name`)
- Commits on that branch auto-link to ticket
- Always use one label: Bug, Feature, or Improvement
