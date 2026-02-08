---
description: Create a pull request with proper formatting and commit analysis
allowed-tools: Bash
---

# PR Command

Create a pull request following team conventions.

## Pre-Flight Checks

Before creating PR, verify:

```bash
# Tests pass
npm run test:ci

# TypeScript compiles
npm run typecheck

# Linting passes
npm run fix

# Branch is up to date
git fetch origin main
```

## PR Creation Process

### Step 1: Gather Context

```bash
# Current branch
git branch --show-current

# Status
git status

# All commits since branching from main
git log main..HEAD --oneline

# Full diff
git diff main...HEAD --stat
```

### Step 2: Analyze Changes

I'll review ALL commits (not just the latest) to understand:
- What was changed
- Why it was changed
- What areas are affected

### Step 3: Generate PR

```bash
gh pr create --title "TYPE: Description" --body "$(cat <<'EOF'
## Summary
- What this PR does
- Why this change is needed
- Key decisions made

## Changes
- List of specific changes
- Organized by area/component

## Test plan
- [ ] Tests pass locally (`npm run test:ci`)
- [ ] TypeScript compiles (`npm run typecheck`)
- [ ] Linting passes (`npm run fix`)
- [ ] Manual testing: [describe what to test]

## Screenshots (if UI changes)
[Add screenshots here]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

## PR Title Convention

Use conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code restructuring
- `docs:` Documentation
- `test:` Tests
- `chore:` Maintenance

Examples:
- `feat: Add call cancellation with reason tracking`
- `fix: Resolve timezone bug in booking emails`
- `refactor: Extract repository pattern for leads`

## PR Body Sections

### Summary
1-3 bullet points explaining:
- What the PR accomplishes
- Why the change is needed
- Any important context

### Changes
Organized list of:
- Files modified
- Features added
- Bugs fixed

### Test Plan
- [ ] Automated tests
- [ ] Manual testing steps
- [ ] Edge cases considered

## Common Issues

### Branch Not Pushed

```bash
git push -u origin $(git branch --show-current)
```

### Conflicts with Main

```bash
git fetch origin main
git rebase origin/main
# Fix conflicts
git push --force-with-lease
```

### Missing gh CLI

```bash
brew install gh
gh auth login
```

## Output

After creating PR:

```markdown
## PR Created Successfully

**Title**: feat: Add call cancellation with reason tracking
**URL**: https://github.com/[YOUR_ORG]/[YOUR_REPO]/pull/123
**Branch**: feature/call-cancellation → main

**Commits Included**: 5
- abc1234 feat: Add cancellation_reason column
- def5678 feat: Update cancelCallAction
- ghi9012 feat: Add CancelDialog component
- jkl3456 test: Add tests for cancellation
- mno7890 docs: Update CLAUDE.md

**Files Changed**: 8
**Additions**: +234
**Deletions**: -12
```
