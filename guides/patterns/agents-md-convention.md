---
title: "AGENTS.md Convention: Cross-Editor AI Config"
description: "How your project uses the AGENTS.md open standard to provide AI context across all coding tools."
tags: ["ai-tooling", "claude-code", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
# AGENTS.md Convention

How your project uses the [AGENTS.md open standard](https://agents.md) to provide AI context across all coding tools.

---

## What is AGENTS.md?

`AGENTS.md` is an open format stewarded by the [Agentic AI Foundation](https://agents.md) under the Linux Foundation. It's a **README for AI agents** — a dedicated, predictable place to provide context and instructions that help AI coding tools work on your project.

Used by 60k+ open-source projects (including OpenAI Codex with 88 AGENTS.md files) and supported by 20+ tools:

| Category | Tools |
|----------|-------|
| IDE Agents | Cursor, VS Code, Windsurf, Zed |
| CLI Agents | Claude Code, Gemini CLI, Codex (OpenAI), Aider |
| Autonomous Agents | Devin, Jules (Google), Factory, Amp |
| Code Review | Semgrep, RooCode |

---

## How Your Project Uses It

Every directory that needs AI context has two files:

```
AGENTS.md   ← real file (source of truth, read by all AI tools)
CLAUDE.md   ← contains "@AGENTS.md" (Claude Code import directive)
```

**Why two files?** Claude Code reads `CLAUDE.md` natively. Every other tool reads `AGENTS.md` natively. The `@AGENTS.md` import in `CLAUDE.md` is Claude Code's official syntax for pulling in external content. This gives us one source of truth with universal coverage.

---

## Current Inventory

The repo has 31 `AGENTS.md`/`CLAUDE.md` pairs:

| Location | Content |
|----------|---------|
| Root | Core project rules, tech stack, critical DO/DON'T |
| `.github/` | CI/CD, commit, and PR conventions |
| `supabase/` | Database schema and migration context |
| `zapier/` | Zapier integration context |
| `apps/admin/` | Admin app context |
| `apps/agents/` | Mastra agents app |
| `apps/api/` | Partner API (GraphQL + REST) |
| `apps/web/app/` | App layer structure and conventions |
| `apps/web/app/(protected)/*/` | Route-specific context (calls, dashboard, scheduler, etc.) |
| `apps/web/app/(public)/*/` | Public route context (booking links, events, zoom) |
| `apps/web/app/_shared/*/` | Shared infrastructure (repositories, nylas) |
| `apps/web/app/api/webhooks/` | Webhook handler conventions |
| `packages/*/` | Package-specific context (agents, services, test-utils) |

---

## Creating New AGENTS.md Files

When a directory has enough complexity that AI tools need context to work in it effectively:

### Step 1: Write `AGENTS.md`

```markdown
# Feature Name

## Rules
- Always do X
- Never do Y

## File Structure
- `page.tsx` — Server Component, data fetching
- `actions.ts` — Server Actions
- `components/` — Route-specific UI

## Context
Brief explanation of what's unique about this directory.
```

### Step 2: Create `CLAUDE.md`

```bash
echo "@AGENTS.md" > CLAUDE.md
```

That's it. `CLAUDE.md` is always a one-liner. All content goes in `AGENTS.md`.

### Step 3: Commit both files

Both `AGENTS.md` and `CLAUDE.md` should be committed to the repo.

---

## Rules

### DO

- Write all AI context in `AGENTS.md` (the source of truth)
- Create `CLAUDE.md` with only `@AGENTS.md` in every directory that has an `AGENTS.md`
- Keep content concise — this loads into every AI interaction in that directory
- Link to deeper docs (`docs/patterns/`, `docs/runbook/`) rather than inlining
- Use imperative language ("Always use X", "Never do Y") — AI tools follow directives better than prose

### DON'T

- Put content directly in `CLAUDE.md` — it should only contain `@AGENTS.md`
- Create `AGENTS.md` and `CLAUDE.md` with different content — that causes drift
- Skip creating `CLAUDE.md` when adding `AGENTS.md` — Claude Code users won't get the context
- Over-document — a directory `AGENTS.md` should cover what's **unique** about that directory, not repeat project-wide rules from the root

---

## Precedence

When multiple `AGENTS.md` files exist in a directory tree, the **closest one to the file being edited wins**. This is consistent across tools:

```
Root AGENTS.md          ← always loaded (project-wide rules)
  └── apps/api/AGENTS.md    ← loaded when working in apps/api/
      └── (overrides root for this directory)
```

The root `AGENTS.md` provides global rules. Nested files provide directory-specific context.

---

## Relationship to Other Documentation

| File | Audience | Purpose |
|------|----------|---------|
| `AGENTS.md` | AI coding tools | Imperative rules and context for generating code |
| `README.md` | Human developers | Quick start, project description, contribution guidelines |
| `docs/patterns/` | Human developers | Deep explanations of patterns (the *why*) |
| `.claude/skills/` | Claude Code + Cursor | Specialized skills that auto-activate for specific tasks |
| `llms.txt` | External AI models (ChatGPT, etc.) | Product description for AI discovery |

`AGENTS.md` and `README.md` are complementary — `README.md` is for humans getting started, `AGENTS.md` is for AI tools generating code. Don't duplicate between them.

---

## References

- [agents.md — Official site](https://agents.md)
- [agents.md — GitHub](https://github.com/anthropics/agents-md) (examples + spec)
- [60k+ projects using AGENTS.md](https://github.com/search?q=filename%3AAGENTS.md&type=code)
