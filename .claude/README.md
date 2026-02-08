# Claude Code Configuration for your application

> **A complete AI-native development system** that automatically enforces coding standards, delegates specialized tasks, and accelerates development velocity.
>
> **For Claude Code.** This directory contains skills, agents, commands, and hooks that Claude Code uses to enforce patterns mechanically. For human-readable documentation of the same patterns (the *why* behind the rules), see [`docs/README.md`](../docs/README.md).

**Created:** November 2024
**Video Script:** `docs/marketing/14_CLAUDE-CODE-AUTOMATION.md`

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Skills (5 total)](#skills)
4. [Subagents (4 total)](#subagents)
5. [Slash Commands (6 total)](#slash-commands)
6. [Hooks (1 total)](#hooks)
7. [How They Work Together](#how-they-work-together)
8. [Usage Guide](#usage-guide)
9. [File Structure](#file-structure)
10. [Troubleshooting](#troubleshooting)

---

## Executive Summary

### The Problem

Before this setup, code reviews repeatedly caught the same issues:
- Direct Supabase queries in server actions (should use repositories)
- Column picking instead of `select *`
- Missing `revalidatePath()` after mutations
- Hardcoded colors instead of CSS variables
- Raw HTML elements instead of shadcn/ui components

**This wasted senior engineer time on pattern enforcement instead of architecture review.**

### The Solution

A four-layer system that automates pattern enforcement:

| Layer | What It Does | How It Triggers |
|-------|-------------|-----------------|
| **Skills** | Teach Claude patterns | Auto-invokes when relevant |
| **Subagents** | Specialized assistants | Delegated tasks with own context |
| **Commands** | User shortcuts | Explicitly type `/command` |
| **Hooks** | Deterministic rules | Runs before every edit |

### The Result

- Pattern violations blocked **before** they're written
- Specialized agents for code review, database work, testing, PRs
- One-command workflows for common tasks
- Code reviews focus on architecture, not style

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLAUDE CODE SESSION                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   SKILLS     │  │  SUBAGENTS   │  │   COMMANDS   │          │
│  │  (5 total)   │  │  (4 total)   │  │  (6 total)   │          │
│  │              │  │              │  │              │          │
│  │ Auto-invoke  │  │ Own context  │  │ User-invoke  │          │
│  │ when relevant│  │ Delegated    │  │ /command     │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                   │
│         └────────┬────────┴────────┬────────┘                   │
│                  │                 │                            │
│                  ▼                 ▼                            │
│         ┌────────────────────────────────┐                      │
│         │           HOOKS                │                      │
│         │    (Deterministic Gate)        │                      │
│         │                                │                      │
│         │  PreToolUse: pattern-enforcer  │                      │
│         │  Blocks anti-patterns BEFORE   │                      │
│         │  they're written               │                      │
│         └────────────────────────────────┘                      │
│                          │                                      │
│                          ▼                                      │
│                  ┌───────────────┐                              │
│                  │  FILE SYSTEM  │                              │
│                  └───────────────┘                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Differentiators

| Feature | Behavior | Can Be Skipped? |
|---------|----------|-----------------|
| Skills | Claude decides when to use | Yes (but rare) |
| Subagents | Claude or user invokes | Yes |
| Commands | User explicitly invokes | Yes |
| **Hooks** | **Always runs** | **No** |

---

## Skills

Skills are **model-invoked expertise packages**. Claude automatically uses them when the task matches the skill's description.

### How Skills Work

1. At startup, only name + description loaded (~30-50 tokens each)
2. When task matches description, full SKILL.md loads
3. Claude follows the instructions in the skill
4. Progressive disclosure keeps context efficient

### Skill 1: `repository-pattern`

**Location:** `.claude/skills/repository-pattern/SKILL.md`

**Auto-invokes when:** Writing database queries, creating repositories, adding data access code

**Enforces:**
- ✅ Always use `select *` (never column picking)
- ✅ Accept `SupabaseClient` as first parameter
- ✅ Use generated types from `database.types.ts`
- ✅ Let RLS handle `organization_id` filtering
- ✅ Use Pino logger, not console.log

**Example trigger:** "Create a repository for user feedback"

---

### Skill 2: `server-action`

**Location:** `.claude/skills/server-action/SKILL.md`

**Auto-invokes when:** Creating mutations, form handlers, data operations

**Enforces:**
- ✅ Use repository functions (never direct Supabase)
- ✅ Call `revalidatePath()` after mutations
- ✅ Return `{ success, data/error }` structure
- ✅ Colocate in route's `actions.ts`
- ✅ Use Pino logger

**Example trigger:** "Add a server action to cancel a booking"

---

### Skill 3: `component-creation`

**Location:** `.claude/skills/component-creation/SKILL.md`

**Auto-invokes when:** Creating UI components, styling, using DataGrid or Sheet

**Enforces:**
- ✅ Use shadcn/ui components (never raw HTML)
- ✅ Use CSS variables (never hardcoded colors)
- ✅ Don't override shadcn classes (use variants)
- ✅ Sheet uses single toggle handler
- ✅ DataGrid uses shadcn themes

**Example trigger:** "Create a card component for displaying leads"

---

### Skill 4: `database-migration`

**Location:** `.claude/skills/database-migration/SKILL.md`

**Auto-invokes when:** Discussing schema changes, creating tables, migrations

**Enforces:**
- ✅ Update domain.sql files (schema-first)
- ✅ Use `bun run supabase db diff` (never manual SQL)
- ✅ Generate types after migration
- ✅ Include RLS policies

**Example trigger:** "Add a cancellation_reason column to calls"

---

### Skill 5: `timezone-handling`

**Location:** `.claude/skills/timezone-handling/SKILL.md`

**Auto-invokes when:** Formatting dates, sending emails with times, displaying events

**Enforces:**
- ✅ Always pass timezone to formatters
- ✅ Use user-specific timezones
- ✅ Multi-recipient emails use discriminated formatting
- ✅ Never use `toLocaleDateString()` without timezone

**Example trigger:** "Format the booking date for the confirmation email"

---

## Subagents

Subagents are **specialized AI assistants** with their own context window, tools, and prompts.

### How Subagents Work

1. Invoked by Claude or user ("Use the code-reviewer agent")
2. Gets a fresh context window (doesn't pollute main conversation)
3. Has specific tools and skills available
4. Returns structured output to main conversation

### Subagent 1: `code-reviewer`

**Location:** `.claude/agents/code-reviewer.md`

**Purpose:** Review code changes against codebase patterns

**Tools:** Read, Grep, Glob, Bash

**Model:** Sonnet (fast)

**Skills loaded:** repository-pattern, server-action, component-creation

**Checks:**
- Repository pattern compliance
- Server action patterns
- Component patterns
- TypeScript strict compliance
- No `any` types

**Invoke:** "Use the code-reviewer agent to check my changes"

**Output format:**
```markdown
## Critical Issues (MUST FIX)
### [File: path/to/file.ts]
- Line X: Issue description
  - Problem: What's wrong
  - Fix: How to fix

## Warnings (SHOULD FIX)
...
```

---

### Subagent 2: `database-expert`

**Location:** `.claude/agents/database-expert.md`

**Purpose:** Handle all Supabase/PostgreSQL/schema work

**Tools:** Read, Edit, Bash, Grep, Glob

**Model:** Inherit (same as main conversation)

**Skills loaded:** database-migration, repository-pattern

**Expertise:**
- Schema-first workflow
- RLS policy patterns
- Migration safety
- Type generation
- Query optimization

**Invoke:** "Use the database-expert agent to add a new table"

---

### Subagent 3: `test-runner`

**Location:** `.claude/agents/test-runner.md`

**Purpose:** Run tests and fix failures

**Tools:** Read, Edit, Bash, Grep, Glob

**Model:** Haiku (fast iteration)

**Workflow:**
1. Run tests
2. Analyze failures
3. Determine if test or source is wrong
4. Fix while preserving test intent

**Invoke:** "Use the test-runner agent to fix the failing tests"

---

### Subagent 4: `pr-creator`

**Location:** `.claude/agents/pr-creator.md`

**Purpose:** Create PRs following team conventions

**Tools:** Bash (git, gh)

**Model:** Haiku (fast)

**Workflow:**
1. Analyze ALL commits since branching
2. Generate summary with bullet points
3. Create PR with proper template

**Invoke:** "Use the pr-creator agent to create a PR"

---

## Slash Commands

Commands are **user-invoked shortcuts** for common workflows.

### How Commands Work

1. User types `/command [args]`
2. Command markdown expands into prompt
3. Claude follows the instructions
4. Some commands have `allowed-tools` restrictions

### Command 1: `/audit [path]`

**Location:** `.claude/commands/audit.md`

**Purpose:** Comprehensive codebase audit

**Sections:**
- Architecture & code quality
- Data fetching patterns
- Testing coverage
- Reliability & production health
- Best practices compliance

**Usage:**
```
/audit app/(protected)/calls
/audit app/_shared/repositories
```

---

### Command 2: `/review`

**Location:** `.claude/commands/review.md`

**Purpose:** Review recent code changes

**Process:**
1. Gets `git diff` of recent changes
2. Checks each file against patterns
3. Reports issues by severity

**Usage:**
```
/review
```

---

### Command 3: `/create-migration [name]`

**Location:** `.claude/commands/create-migration.md`

**Purpose:** Guide through schema-first migration workflow

**Steps:**
1. Identify domain file to update
2. Describe your change
3. Update domain SQL
4. Generate migration with `db diff`
5. Review and apply
6. Generate types

**Usage:**
```
/create-migration add_feedback_table
```

---

### Command 4: `/new-feature [name]`

**Location:** `.claude/commands/new-feature.md`

**Purpose:** Scaffold a new feature

**Creates:**
```
app/(protected)/[name]/
├── page.tsx
├── actions.ts
├── components/
│   ├── [Name]List.tsx
│   ├── [Name]Item.tsx
│   └── [Name]Form.tsx
└── types.ts
```

**Usage:**
```
/new-feature feedback
```

---

### Command 5: `/test [path]`

**Location:** `.claude/commands/test.md`

**Purpose:** Run tests and analyze failures

**Process:**
1. Run tests (all or specific)
2. Parse failures
3. Analyze root cause
4. Suggest fixes

**Usage:**
```
/test
/test app/(protected)/calls
```

---

### Command 6: `/pr`

**Location:** `.claude/commands/pr.md`

**Purpose:** Create PR with proper formatting

**Process:**
1. Verify tests pass
2. Analyze all commits
3. Generate summary
4. Create PR with template

**Usage:**
```
/pr
```

---

## Hooks

Hooks are **deterministic automation** that runs at specific points in Claude's workflow.

### How Hooks Work

1. Configured in `.claude/settings.json`
2. Run automatically (can't be skipped)
3. Can block operations (exit code 2)
4. Provide feedback to Claude

### Hook: `pattern-enforcer`

**Location:** `.claude/hooks/pattern-enforcer.py`

**Trigger:** PreToolUse (before Edit/Write/MultiEdit)

**Checks:**
- Direct Supabase queries in server actions → Block
- Column picking in repositories → Block
- Hardcoded colors in components → Block
- Raw HTML elements → Block
- Protected file edits → Block

**Blocked output:**
```
⛔ Pattern Violations Detected

File: app/(protected)/calls/actions.ts

1. Line 25: Direct Supabase query in server action.
   Found: supabase.from("calls").insert()
   Fix: Import from @/app/_shared/repositories/
```

**Protected files:**
- `database.types.ts` (auto-generated)
- `.env*` files (secrets)
- `package-lock.json` (auto-generated)

---

## How They Work Together

### Scenario 1: Creating a New Repository

```
User: "Create a repository for user feedback"

1. SKILL ACTIVATION
   └── repository-pattern skill loads (matches "repository")

2. CLAUDE WRITES CODE
   └── Follows skill instructions:
       - Uses select *
       - Accepts SupabaseClient parameter
       - Uses generated types

3. HOOK VALIDATION (PreToolUse)
   └── pattern-enforcer.py checks:
       ✅ No column picking
       ✅ Correct patterns
   └── Allows edit

4. FILE WRITTEN
```

### Scenario 2: Fixing Anti-Pattern

```
User: "Add a function to create a call directly with supabase"

1. SKILL ACTIVATION
   └── server-action skill loads (matches "create")

2. CLAUDE WRITES CODE
   └── Attempts: supabase.from("calls").insert()

3. HOOK VALIDATION (PreToolUse)
   └── pattern-enforcer.py checks:
       ❌ Direct Supabase in server action
   └── BLOCKS edit with feedback

4. CLAUDE RECEIVES FEEDBACK
   └── Rewrites using repository pattern

5. HOOK VALIDATION (retry)
   └── ✅ Correct pattern
   └── Allows edit

6. FILE WRITTEN
```

### Scenario 3: Code Review Workflow

```
User: "Review my changes and create a PR"

1. COMMAND: /review
   └── Expands to review instructions
   └── Claude checks recent changes
   └── Reports issues by severity

2. USER FIXES ISSUES

3. COMMAND: /pr
   └── Expands to PR instructions
   └── Claude analyzes commits
   └── Creates PR with template

4. SUBAGENT (optional)
   └── "Use code-reviewer agent for final check"
   └── Agent runs in own context
   └── Returns structured report
```

---

## Usage Guide

### Daily Workflow

```bash
# Start your day
claude

# Work on feature (skills auto-activate)
> Create a repository for call recordings
> Add a server action to upload recordings
> Create a component to display recordings

# Review before committing
/review

# Run tests
/test

# Create PR
/pr
```

### Database Changes

```bash
# Start migration workflow
/create-migration add_recordings_table

# Or invoke the specialist
> Use the database-expert agent to design the recordings schema
```

### New Features

```bash
# Scaffold entire feature
/new-feature recordings

# This creates:
# - page.tsx
# - actions.ts
# - components/RecordingsList.tsx
# - components/RecordingsItem.tsx
# - components/RecordingsForm.tsx
```

### Code Quality

```bash
# Quick review
/review

# Deep audit
/audit app/(protected)/calls

# Specialist review
> Use the code-reviewer agent to check for security issues
```

---

## File Structure

```
.claude/
├── README.md                              ← This file
├── settings.json                          ← Hook configuration
│
├── skills/                                ← Model-invoked expertise (19)
│   ├── billing-patterns/
│   ├── component-creation/
│   ├── data-fetching/
│   ├── database-migration/
│   ├── detail-view-pattern/
│   ├── documentation/                    ← NEW: where/when to create docs
│   ├── graphql-api-design/
│   ├── nylas-integration/
│   ├── observability-logging/
│   ├── performance-patterns/
│   ├── pull-request/
│   ├── repository-pattern/
│   ├── route-architecture/
│   ├── sanity-cms/
│   ├── security-patterns/
│   ├── server-action/
│   ├── solid-webhook-patterns/
│   ├── testing-patterns/
│   ├── timezone-handling/
│   └── webhook-observability/
│
├── agents/                                ← Specialized assistants (4)
│   ├── code-reviewer.md
│   ├── database-expert.md
│   ├── test-runner.md
│   └── pr-creator.md
│
├── commands/                              ← User shortcuts (6)
│   ├── audit.md
│   ├── review.md
│   ├── create-migration.md
│   ├── new-feature.md
│   ├── test.md
│   └── pr.md
│
└── hooks/                                 ← Deterministic automation (1)
    └── pattern-enforcer.py
```

---

## Troubleshooting

### Skill Not Activating

**Symptoms:** Claude doesn't follow pattern despite task matching

**Solutions:**
1. Check skill description matches your task
2. Explicitly mention the pattern: "following the repository pattern..."
3. Ask Claude: "What skills are available?"

### Hook Blocking Valid Code

**Symptoms:** Hook rejects code that should be valid

**Solutions:**
1. Check `pattern-enforcer.py` regex patterns
2. Protected file list may need updating
3. Temporarily disable hook for edge cases:
   ```json
   // In settings.json, comment out hook
   ```

### Subagent Context Issues

**Symptoms:** Subagent doesn't have enough context

**Solutions:**
1. Provide more detail in invocation
2. Subagents don't see main conversation - include relevant info
3. Consider using skill instead if context needed

### Command Not Found

**Symptoms:** `/command` doesn't work

**Solutions:**
1. Check file exists in `.claude/commands/`
2. Check frontmatter syntax (YAML)
3. Restart Claude Code session

---

## Contributing

### Adding a New Skill

1. Create directory: `.claude/skills/your-skill/`
2. Create `SKILL.md` with frontmatter:
   ```yaml
   ---
   name: your-skill
   description: When this activates...
   allowed-tools: Read, Grep, Glob
   ---
   ```
3. Add instructions in markdown
4. Test by describing a matching task

### Adding a New Subagent

1. Create file: `.claude/agents/your-agent.md`
2. Add frontmatter:
   ```yaml
   ---
   name: your-agent
   description: When to use...
   tools: Read, Edit, Bash
   model: sonnet
   skills: skill1, skill2
   ---
   ```
3. Add system prompt in markdown
4. Test: "Use the your-agent agent to..."

### Adding a New Command

1. Create file: `.claude/commands/your-command.md`
2. Add frontmatter:
   ```yaml
   ---
   description: What it does
   argument-hint: [optional args]
   allowed-tools: Read, Grep
   ---
   ```
3. Add instructions in markdown
4. Test: `/your-command`

### Modifying Hooks

1. Edit `.claude/hooks/pattern-enforcer.py`
2. Test by attempting blocked patterns
3. Update `.claude/settings.json` if adding new hooks

---

## References

- **CLAUDE.md** - Project coding standards
- **docs/testing/README.md** - Testing guide
- **docs/guides/DECLARATIVE_SCHEMA_WORKFLOW.md** - Database workflow
- **docs/marketing/14_CLAUDE-CODE-AUTOMATION.md** - Video script for this system

---

*This system transforms Claude Code from autocomplete into an autonomous code quality system. Skills teach patterns. Subagents specialize. Hooks enforce. Commands accelerate.*
