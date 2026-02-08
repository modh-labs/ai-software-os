# Setup Guide

> How to drop AI Operations Boost into any project and customize it for your stack.

---

## Step 1: Copy `.claude/` Into Your Project

```bash
# From your project root
cp -r path/to/ai-operations-boost/.claude/ ./.claude/
```

This gives you:
- 21 skills (auto-activate when relevant)
- 4 subagents (code reviewer, database expert, test runner, PR creator)
- 6 slash commands (`/audit`, `/review`, `/create-migration`, `/new-feature`, `/test`, `/pr`)
- 1 pattern-enforcer hook (blocks anti-patterns before they're written)
- 2 rules (observability + testing standards)

## Step 2: Customize Placeholders

Search and replace these placeholders across all `.claude/` files:

| Placeholder | Replace With | Example |
|-------------|-------------|---------|
| `@your-org/repositories` | Your package scope | `@acme/repositories` |
| `@your-org/database-types` | Your types package | `@acme/database-types` |
| `@your-org/ui` | Your UI package | `@acme/ui` |
| `@your-org/components` | Your components package | `@acme/components` |
| `[YOUR_APP]` | Your app name | `Acme Dashboard` |
| `[YOUR_SENTRY_PROJECT]` | Your Sentry project slug | `acme-web` |
| `[YOUR_ORG]` | Your GitHub org | `acme-inc` |
| `[YOUR_REPO]` | Your repo name | `acme-dashboard` |
| `[YOUR_TEAM]` | Your team name | `Acme Engineering` |
| `[YOUR_DOMAIN]` | Your domain | `acme.com` |
| `[PROJ]-XXX` | Your Linear project prefix | `ACM-123` |

Quick one-liner:
```bash
find .claude/ -type f -name "*.md" -exec sed -i '' \
  -e 's/@your-org/@acme/g' \
  -e 's/\[YOUR_APP\]/Acme Dashboard/g' \
  -e 's/\[YOUR_SENTRY_PROJECT\]/acme-web/g' \
  -e 's/\[YOUR_ORG\]/acme-inc/g' \
  -e 's/\[YOUR_REPO\]/acme-dashboard/g' \
  -e 's/\[YOUR_TEAM\]/Acme Engineering/g' \
  -e 's/\[YOUR_DOMAIN\]/acme.com/g' \
  -e 's/\[PROJ\]/ACM/g' \
  {} +
```

## Step 3: Configure the Hook

The pattern enforcer hook (`.claude/hooks/pattern-enforcer.py`) needs to be executable:

```bash
chmod +x .claude/hooks/pattern-enforcer.py
```

Review the hook and customize the patterns it enforces:
- Direct Supabase queries in server actions
- Column picking in repositories
- Hardcoded colors in components
- Raw HTML elements
- Protected file edits

## Step 4: Adapt Settings

Edit `.claude/settings.json` to match your project:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "cd your-app && npm run typecheck:changed || echo 'Type check done'",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

## Step 5: Copy Guides (Optional)

If you want the engineering documentation for your team:

```bash
cp -r path/to/ai-operations-boost/guides/ ./docs/
```

## Step 6: Set Up CLAUDE.md

Create a root `CLAUDE.md` in your project that points to the toolkit:

```markdown
# [Your Project] Development Guide

## Quick Reference
- See `.claude/skills/` for AI-enforced patterns
- See `.claude/commands/` for workflow shortcuts
- See `docs/` for engineering guides

## Critical Rules
[Your project-specific rules here]
```

## Step 7: Verify

```bash
# Start Claude Code
claude

# Test a skill
> "Create a repository for user profiles"
# Should auto-activate repository-pattern skill

# Test a command
/review
# Should review recent changes

# Test the hook
# Try writing a direct supabase query in an actions file
# Should get blocked by pattern-enforcer
```

---

## Removing Skills You Don't Need

If a skill doesn't apply to your stack, simply delete its directory:

```bash
# Don't use GraphQL? Remove it
rm -rf .claude/skills/graphql-api-design/

# Don't use Sentry? Remove observability skill
rm -rf .claude/skills/observability-logging/
```

Skills are self-contained — removing one doesn't break others.

---

## Monorepo vs Single App

This system works with both:

- **Monorepo:** Skills reference `@your-org/*` packages. Keep as-is.
- **Single app:** Replace `@your-org/repositories` with `@/lib/repositories` (or your path convention).
