# AI Software OS

> A production-tested AI engineering operations system — skills, agents, commands, hooks, and 45+ engineering guides — ready to drop into any project.

**Built by [Imran Gardezi](https://modh.ca) at Modh Labs** over 12+ months of shipping production software with AI-assisted development.

---

## What This Is

A complete AI-native development system that:

- **Teaches AI your patterns** via 21 skills that auto-activate when relevant
- **Delegates specialized work** to 4 purpose-built subagents
- **Accelerates common workflows** with 6 slash commands
- **Blocks anti-patterns deterministically** with pre-edit hooks
- **Documents everything** with 45+ battle-tested engineering guides

### The Four-Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     CLAUDE CODE SESSION                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   SKILLS     │  │  SUBAGENTS   │  │   COMMANDS   │      │
│  │  (21 total)  │  │  (4 total)   │  │  (6 total)   │      │
│  │              │  │              │  │              │      │
│  │ Auto-invoke  │  │ Own context  │  │ User-invoke  │      │
│  │ when relevant│  │ Delegated    │  │ /command     │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                 │               │
│         └────────┬────────┴────────┬────────┘               │
│                  ▼                 ▼                        │
│         ┌────────────────────────────────┐                  │
│         │           HOOKS                │                  │
│         │    (Deterministic Gate)        │                  │
│         │  Blocks anti-patterns BEFORE   │                  │
│         │  they're written               │                  │
│         └────────────────────────────────┘                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

| Layer | Count | Trigger | Can Skip? |
|-------|-------|---------|-----------|
| **Skills** | 21 | Auto (AI decides) | Rarely |
| **Subagents** | 4 | Delegated or user-invoked | Yes |
| **Commands** | 6 | User types `/command` | Yes |
| **Hooks** | 1 | Every edit operation | **No** |

---

## File Counts

| Category | Files | Location |
|----------|-------|----------|
| Skills | 21 SKILL.md + 10 references | `.claude/skills/` |
| Agents | 4 | `.claude/agents/` |
| Commands | 6 | `.claude/commands/` |
| Hooks | 1 | `.claude/hooks/` |
| Rules | 2 | `.claude/rules/` |
| Pattern guides | 26 | `guides/patterns/` |
| Standards | 8 | `guides/standards/` |
| Testing guides | 6 | `guides/testing/` |
| Security docs | 5 | `guides/security/` |
| Examples | 3 | `examples/` |
| Meta-docs | 5 | Root |
| Config | 3 | `.claude/`, `.github/` |
| **Total** | **~100** | |

---

## Quick Start

```bash
# 1. Clone into your project's parent directory
git clone https://github.com/modhlabs/ai-software-os.git

# 2. Copy the .claude/ directory into your project
cp -r ai-software-os/.claude/ your-project/.claude/

# 3. Copy the engineering guides (optional, for team reference)
cp -r ai-software-os/guides/ your-project/docs/

# 4. Customize placeholders (see SETUP.md)
# Replace [YOUR_APP], @your-org/*, [YOUR_SENTRY_PROJECT], etc.

# 5. Start Claude Code — skills auto-activate
claude
```

See **[SETUP.md](./SETUP.md)** for detailed customization instructions.

---

## 🚀 NEW: Modh Fundamentals

**My system for growing and scaling engineering teams.**

Four battle-tested operational systems I install at every SaaS company:

| System | Problem It Solves | Outcome |
|--------|-------------------|---------|
| **[Project Scoping](./fundamentals/project-scoping.md)** | Projects take 3+ months, scope creeps | 90% of projects <3 weeks, velocity 3x |
| **[Decision Velocity](./fundamentals/decision-velocity.md)** | Teams debate everything, analysis paralysis | 90% decisions same-day, 5x shipping |
| **[Engineering Values](./fundamentals/engineering-values.md)** | Culture is vague, no operational clarity | Clear values that translate to daily behavior |
| **[Backlog Hygiene](./fundamentals/backlog-hygiene.md)** | 500+ ticket backlogs, decision paralysis | Clean <50 ticket backlogs in 1–2 weeks |

**Content Strategy Included:** Turn these systems into LinkedIn posts, Instagram carousels, and Reels. See [`fundamentals/content-strategy.md`](./fundamentals/content-strategy.md).

**Quick Start:** [`fundamentals/QUICK-START.md`](./fundamentals/QUICK-START.md) — 5-day plan to ship your first content.

**Ready-to-Post:** [`fundamentals/WEEK-1-CONTENT.md`](./fundamentals/WEEK-1-CONTENT.md) — Copy-paste content for Week 1.

**Use Cases:**
- **Consulting/Advisory:** Diagnose organizational dysfunction, install the right system
- **Personal Brand:** Position yourself as a tech enabler and systems expert
- **Your Company:** Install at your own company, measure before/after impact

**Read:** [`fundamentals/README.md`](./fundamentals/README.md) for full overview.

---

## Skills Overview

### Core Architecture
| Skill | Auto-Triggers When... |
|-------|-----------------------|
| `repository-pattern` | Writing database queries |
| `server-action` | Creating mutations or form handlers |
| `database-migration` | Discussing schema changes |
| `route-architecture` | Creating routes or deciding file placement |
| `data-fetching` | Fetching data in pages |

### Quality & Testing
| Skill | Auto-Triggers When... |
|-------|-----------------------|
| `testing-patterns` | Writing tests |
| `security-patterns` | Working with auth, validation, webhooks |
| `ci-pipeline` | Modifying CI/CD workflows |
| `performance-patterns` | Optimizing pages or adding loading states |
| `observability-logging` | Adding logging or error tracking |

### API & Integrations
| Skill | Auto-Triggers When... |
|-------|-----------------------|
| `solid-webhook-patterns` | Creating webhook handlers |
| `webhook-observability` | Adding webhook logging |
| `graphql-api-design` | Building GraphQL APIs |
| `timezone-handling` | Formatting dates or times |

### Workflow & Ops
| Skill | Auto-Triggers When... |
|-------|-----------------------|
| `pull-request` | Creating PRs |
| `linear-ticket` | Creating issue tickets |
| `triage` | Reviewing backlog items |
| `documentation` | Adding docs |
| `cross-editor-compatibility` | Setting up multi-editor AI config |
| `component-creation` | Building UI components |
| `detail-view-pattern` | Creating detail/sheet views |

---

## Guides as Blog Posts

Every file in `guides/` has YAML frontmatter with `title`, `description`, `tags`, `category`, `author`, and `publishable: true` — ready to publish as blog posts or technical guides.

```yaml
---
title: "Repository Pattern: Type-Safe Database Access"
description: "How to structure database queries..."
tags: ["database", "supabase", "typescript", "patterns"]
category: "patterns"
author: "Imran Gardezi"
publishable: true
---
```

---

## Tech Stack

This system is built for and tested with:

- **Framework:** Next.js (App Router) + React + TypeScript
- **Database:** Supabase (PostgreSQL + RLS)
- **Auth:** Clerk
- **Payments:** Stripe
- **Testing:** Vitest + Playwright
- **Observability:** Sentry + OpenTelemetry
- **CI/CD:** GitHub Actions
- **AI Dev:** Claude Code + Cursor

See **[TECH-STACK.md](./TECH-STACK.md)** for alternatives and adaptation notes.

---

## License

MIT — Use freely. Attribution appreciated.

---

*Built by [Modh Labs](https://modh.ca). Ship production software with AI-assisted engineering.*
