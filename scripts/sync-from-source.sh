#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# sync-from-source.sh — Repeatable sync from your source project to this repo
# ============================================================================
#
# Usage:
#   ./scripts/sync-from-source.sh /path/to/source/project
#
# This script:
#   1. Copies skills, agents, commands, hooks, rules from the source project
#   2. Copies guide docs (patterns, standards, testing, security)
#   3. Generalizes all project-specific references to placeholders
#   4. Preserves existing frontmatter on guide files
#   5. Reports what changed
#
# Run this whenever you've updated docs/patterns in your source project
# and want to bring those improvements back to AI Software OS.
# ============================================================================

# --- Configuration -----------------------------------------------------------
# Customize these for YOUR source project

# Package scope to generalize (e.g., @aura → @your-org)
SOURCE_PACKAGE_SCOPE="@aura"

# Product/project name to generalize
SOURCE_PRODUCT_NAME="Aura"

# Sentry project slug
SOURCE_SENTRY_PROJECT="aura-web"

# GitHub org/repo
SOURCE_GITHUB_ORG="modh"
SOURCE_GITHUB_REPO="aura"

# Domain
SOURCE_DOMAIN="aura-app.ai"

# Linear prefix
SOURCE_LINEAR_PREFIX="AUR"

# Team name
SOURCE_TEAM_NAME="Aura"

# Embed script name
SOURCE_EMBED_NAME="aura-embed"

# Webhook header prefix
SOURCE_WEBHOOK_HEADER="Aura"

# Sentry org slug
SOURCE_SENTRY_ORG="modh"

# --- End Configuration -------------------------------------------------------

DEST_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ $# -lt 1 ]; then
  echo "Usage: $0 /path/to/source/project"
  echo ""
  echo "Example: $0 ../aura"
  exit 1
fi

SRC="$(cd "$1" && pwd)"

if [ ! -d "$SRC/.claude/skills" ]; then
  echo "Error: $SRC doesn't look like a project with .claude/ configuration"
  exit 1
fi

echo "=== Syncing from $SRC to $DEST_DIR ==="
echo ""

# --- Skills to extract (skip project-specific ones) -------------------------
SKIP_SKILLS="billing-patterns nylas-integration sanity-cms"

COPIED_SKILLS=0
for skill_dir in "$SRC/.claude/skills/"*/; do
  skill_name=$(basename "$skill_dir")

  # Skip project-specific skills
  skip=false
  for skip_skill in $SKIP_SKILLS; do
    if [ "$skill_name" = "$skip_skill" ]; then
      skip=true
      break
    fi
  done
  if $skip; then
    echo "  SKIP skill: $skill_name (project-specific)"
    continue
  fi

  mkdir -p "$DEST_DIR/.claude/skills/$skill_name/references"
  [ -f "$skill_dir/SKILL.md" ] && cp "$skill_dir/SKILL.md" "$DEST_DIR/.claude/skills/$skill_name/SKILL.md"

  # Copy reference files
  if ls "$skill_dir/references/"* >/dev/null 2>&1; then
    cp "$skill_dir/references/"* "$DEST_DIR/.claude/skills/$skill_name/references/" 2>/dev/null
  fi

  COPIED_SKILLS=$((COPIED_SKILLS + 1))
done
echo "  Copied $COPIED_SKILLS skills"

# --- Agents, Commands, Rules -------------------------------------------------
for agent in "$SRC/.claude/agents/"*.md; do
  [ -f "$agent" ] && cp "$agent" "$DEST_DIR/.claude/agents/"
done
echo "  Copied agents: $(ls "$DEST_DIR/.claude/agents/" | wc -l | tr -d ' ')"

for cmd in "$SRC/.claude/commands/"*.md; do
  [ -f "$cmd" ] && cp "$cmd" "$DEST_DIR/.claude/commands/"
done
echo "  Copied commands: $(ls "$DEST_DIR/.claude/commands/" | wc -l | tr -d ' ')"

for rule in "$SRC/.claude/rules/"*.md; do
  [ -f "$rule" ] && cp "$rule" "$DEST_DIR/.claude/rules/"
done
echo "  Copied rules: $(ls "$DEST_DIR/.claude/rules/" | wc -l | tr -d ' ')"

# Hook
if [ -f "$SRC/.claude/hooks/pattern-enforcer.py.bak" ]; then
  cp "$SRC/.claude/hooks/pattern-enforcer.py.bak" "$DEST_DIR/.claude/hooks/pattern-enforcer.py"
elif [ -f "$SRC/.claude/hooks/pattern-enforcer.py" ]; then
  cp "$SRC/.claude/hooks/pattern-enforcer.py" "$DEST_DIR/.claude/hooks/pattern-enforcer.py"
fi
echo "  Copied hook"

# .claude/README.md
[ -f "$SRC/.claude/README.md" ] && cp "$SRC/.claude/README.md" "$DEST_DIR/.claude/README.md"

# --- Guide Docs --------------------------------------------------------------
# Patterns
PATTERN_FILES="repository-pattern.md server-actions.md data-fetching.md database-workflow.md ai-database-workflow.md webhook-patterns.md tracing-and-instrumentation.md performance-patterns.md testing.md graphql-api-design.md incident-runbook.md agents-md-convention.md ci-optimization.md ci-pipeline.md master-detail-realtime.md embed-redirects.md route-audit.md QUICK-REFERENCE.md sentry-alerting.md sentry-debugging.md ui-components.md repository-testing.md per-user-onboarding.md upstash-redis.md badge-design-system.md webhook-emission.md"

COPIED_PATTERNS=0
for f in $PATTERN_FILES; do
  if [ -f "$SRC/docs/patterns/$f" ]; then
    cp "$SRC/docs/patterns/$f" "$DEST_DIR/guides/patterns/$f"
    COPIED_PATTERNS=$((COPIED_PATTERNS + 1))
  fi
done
echo "  Copied $COPIED_PATTERNS pattern docs"

# Standards
for f in database.md typescript.md testing.md environment-variables.md observability.md security.md ui-components.md ui-architecture.md; do
  [ -f "$SRC/docs/standards/$f" ] && cp "$SRC/docs/standards/$f" "$DEST_DIR/guides/standards/$f"
done
echo "  Copied standards: $(ls "$DEST_DIR/guides/standards/" 2>/dev/null | wc -l | tr -d ' ')"

# Testing
for f in README.md getting-started.md factories.md integration-tests.md mocking.md; do
  [ -f "$SRC/docs/testing/$f" ] && cp "$SRC/docs/testing/$f" "$DEST_DIR/guides/testing/$f"
done
[ -f "$SRC/docs/testing/patterns/server-actions.md" ] && cp "$SRC/docs/testing/patterns/server-actions.md" "$DEST_DIR/guides/testing/patterns/server-actions.md"
echo "  Copied testing docs: $(find "$DEST_DIR/guides/testing/" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"

# Security
for f in overview.md access-control.md incident-response.md key-rotation.md data-retention.md; do
  [ -f "$SRC/docs/security/$f" ] && cp "$SRC/docs/security/$f" "$DEST_DIR/guides/security/$f"
done
echo "  Copied security docs: $(ls "$DEST_DIR/guides/security/" 2>/dev/null | wc -l | tr -d ' ')"

# --- Generalization ----------------------------------------------------------
echo ""
echo "=== Generalizing references ==="

cd "$DEST_DIR"

# Package scope
find . -type f \( -name "*.md" -o -name "*.ts" -o -name "*.tsx" -o -name "*.py" \) -not -path "./.git/*" -not -path "./scripts/*" -exec sed -i '' "s|${SOURCE_PACKAGE_SCOPE}/[a-z-]*|@your-org/\0|g" {} + 2>/dev/null || true
# More targeted replacements
find . -type f \( -name "*.md" -o -name "*.ts" -o -name "*.tsx" -o -name "*.py" \) -not -path "./.git/*" -not -path "./scripts/*" -exec sed -i '' \
  -e "s|${SOURCE_PACKAGE_SCOPE}/repositories|@your-org/repositories|g" \
  -e "s|${SOURCE_PACKAGE_SCOPE}/database-types|@your-org/database-types|g" \
  -e "s|${SOURCE_PACKAGE_SCOPE}/ui|@your-org/ui|g" \
  -e "s|${SOURCE_PACKAGE_SCOPE}/components|@your-org/components|g" \
  -e "s|${SOURCE_PACKAGE_SCOPE}/agents|@your-org/agents|g" \
  -e "s|${SOURCE_PACKAGE_SCOPE}/web|@your-org/web|g" \
  -e "s|${SOURCE_PACKAGE_SCOPE}/api|@your-org/api|g" \
  -e "s|${SOURCE_PACKAGE_SCOPE}/admin|@your-org/admin|g" \
  {} +

# Product name variants
find . -type f -name "*.md" -not -path "./.git/*" -not -path "./scripts/*" -exec sed -i '' \
  -e "s|the ${SOURCE_PRODUCT_NAME} codebase|your codebase|g" \
  -e "s|the ${SOURCE_PRODUCT_NAME} project|your project|g" \
  -e "s|the ${SOURCE_PRODUCT_NAME} team|your team|g" \
  -e "s|${SOURCE_PRODUCT_NAME}'s|your project's|g" \
  -e "s|for ${SOURCE_PRODUCT_NAME}|for your application|g" \
  -e "s|in ${SOURCE_PRODUCT_NAME}|in your application|g" \
  -e "s|from ${SOURCE_PRODUCT_NAME}|from your application|g" \
  -e "s|${SOURCE_PRODUCT_NAME} codebase|your codebase|g" \
  -e "s|${SOURCE_PRODUCT_NAME} patterns|codebase patterns|g" \
  -e "s|${SOURCE_PRODUCT_NAME} standards|codebase standards|g" \
  -e "s|${SOURCE_PRODUCT_NAME} monorepo|your monorepo|g" \
  -e "s|${SOURCE_PRODUCT_NAME} team|your team|g" \
  -e "s|${SOURCE_PRODUCT_NAME} repo|your repo|g" \
  -e "s|${SOURCE_PRODUCT_NAME} is a multi-tenant|This is a multi-tenant|g" \
  -e "s|${SOURCE_PRODUCT_NAME} uses|your project uses|g" \
  -e "s|${SOURCE_PRODUCT_NAME} has two|Your project has two|g" \
  -e "s|what ${SOURCE_PRODUCT_NAME} does|what your application does|g" \
  -e "s|in the ${SOURCE_PRODUCT_NAME} monorepo|in your monorepo|g" \
  -e "s|participant App as ${SOURCE_PRODUCT_NAME}|participant App as Application|g" \
  {} +

# URLs and external references
find . -type f -name "*.md" -not -path "./.git/*" -not -path "./scripts/*" -exec sed -i '' \
  -e "s|${SOURCE_SENTRY_PROJECT}|[YOUR_SENTRY_PROJECT]|g" \
  -e "s|${SOURCE_GITHUB_ORG}/${SOURCE_GITHUB_REPO}|[YOUR_ORG]/[YOUR_REPO]|g" \
  -e "s|github.com/${SOURCE_GITHUB_ORG}|github.com/[YOUR_ORG]|g" \
  -e "s|${SOURCE_DOMAIN}|[YOUR_DOMAIN]|g" \
  -e "s|${SOURCE_LINEAR_PREFIX}-[0-9]*|[PROJ]-XXX|g" \
  -e "s|${SOURCE_LINEAR_PREFIX}-XXX|[PROJ]-XXX|g" \
  -e "s|team: \"${SOURCE_TEAM_NAME}\"|team: \"[YOUR_TEAM]\"|g" \
  -e "s|${SOURCE_EMBED_NAME}|[app]-embed|g" \
  -e "s|X-${SOURCE_WEBHOOK_HEADER}-Signature|X-[APP]-Signature|g" \
  -e "s|${SOURCE_SENTRY_ORG}.sentry.io|[YOUR_ORG].sentry.io|g" \
  {} +

# Count remaining
REMAINING=$(grep -ri "${SOURCE_PRODUCT_NAME}" --include="*.md" --include="*.py" --include="*.ts" --include="*.tsx" -l . 2>/dev/null | grep -v scripts/ | wc -l | tr -d ' ')
echo "  Remaining files with '${SOURCE_PRODUCT_NAME}': $REMAINING"

if [ "$REMAINING" -gt 0 ]; then
  echo "  (Some references may need manual review)"
  grep -ri "${SOURCE_PRODUCT_NAME}" --include="*.md" -l . 2>/dev/null | grep -v scripts/ | head -10
fi

# Final stats
echo ""
echo "=== Sync Complete ==="
TOTAL_FILES=$(find . -type f \( -name "*.md" -o -name "*.py" -o -name "*.json" -o -name "*.ts" -o -name "*.tsx" \) -not -path "./.git/*" | wc -l | tr -d ' ')
echo "Total files: $TOTAL_FILES"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Check for remaining refs: grep -ri '${SOURCE_PRODUCT_NAME}' --include='*.md' ."
echo "  3. Run frontmatter check: head -3 guides/patterns/*.md"
echo "  4. Commit: git add -A && git commit -m 'sync: update from source project'"
