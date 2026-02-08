---
name: cross-editor-compatibility
description: Ensure AI configuration works across Claude Code and Cursor. Use when creating AGENTS.md files, adding skills, setting up project rules, or discussing cross-editor compatibility. Enforces the @import convention and single-source-of-truth strategy.
allowed-tools: Read, Grep, Glob, Edit, Write
---

# Cross-Editor Compatibility Skill

## When This Skill Activates

This skill automatically activates when you:
- Create a new `AGENTS.md` file in any directory
- Create or modify a skill in `.claude/skills/`
- Discuss Cursor vs Claude Code configuration
- Set up project rules for a new directory or package

## Core Rule: AGENTS.md is the Source of Truth

Every directory that needs AI context has two files:

```
AGENTS.md   ← real file (source of truth, Cursor reads natively)
CLAUDE.md   ← contains "@AGENTS.md" (Claude Code resolves the import)
```

**Why:** Cursor reads `AGENTS.md` natively (root and subdirectories). Claude Code reads `CLAUDE.md` and uses `@` import syntax to resolve the content from `AGENTS.md`. One source of truth, both editors served.

## What Goes Where

| Config Type | Location | Claude Code | Cursor | Action |
|-------------|----------|-------------|--------|--------|
| Core project rules | `AGENTS.md` (root) | Via `@AGENTS.md` in CLAUDE.md | Native | Edit `AGENTS.md` |
| Directory context | `<dir>/AGENTS.md` | Via `<dir>/CLAUDE.md` import | Native | Edit `AGENTS.md` |
| AI skills | `.claude/skills/*/SKILL.md` | Native | Native (toggle in Settings) | No duplication needed |
| Cursor-only rules | `.cursor/rules/*.mdc` | Not read | Native | Only for Cursor-specific behavior |

## When Creating New Directory Context

Follow this exact sequence:

1. Write `AGENTS.md` with the directory context content
2. Create `CLAUDE.md` in the same directory with just one line:
   ```
   @AGENTS.md
   ```
3. Verify: `cat AGENTS.md` shows your content, `cat CLAUDE.md` shows `@AGENTS.md`

## NEVER Do These

- **NEVER put content directly in `CLAUDE.md`** — it should only contain `@AGENTS.md`. All content goes in `AGENTS.md`.
- **NEVER create `AGENTS.md` and `CLAUDE.md` with different content** — that causes drift.
- **NEVER duplicate skills into `.cursor/rules/`** — Cursor reads `.claude/skills/` natively when "Import Agent Skills" is enabled.
- **NEVER skip creating `CLAUDE.md`** when adding an `AGENTS.md` — Claude Code users won't get the context.

## Current Inventory

The repo has `AGENTS.md` + `CLAUDE.md` pairs in 31 directories:

- Root
- `.github/`
- `supabase/`, `zapier/`
- `apps/admin/`, `apps/agents/`, `apps/api/`
- `apps/web/app/` and all route-level subdirectories
- `packages/agents/`, `packages/services/`, `packages/test-utils/`

## Cursor Setup for Team Members

New team members using Cursor need one manual step:

**Cursor Settings > Rules > "Import Agent Skills"** — Enable this toggle.

This makes Cursor scan `.claude/skills/` for all `SKILL.md` files and use them the same way Claude Code does.

## Skills: Zero Duplication

Skills in `.claude/skills/*/SKILL.md` work in both editors. The frontmatter format is compatible:

```yaml
---
name: skill-name
description: When this skill activates...
allowed-tools: Read, Grep, Glob
---
```

Both Claude Code and Cursor use the `description` field to decide when to load the skill. No transformation or conversion needed.
