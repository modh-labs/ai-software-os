# Project Scoping

> How to estimate project size, break work down, and ship iteratively.

**Problem:** Projects drag on for months, scope creeps, teams lose momentum.

**Solution:** Scope everything to 1–3 weeks max. Use complexity tiers to guide breakdown.

---

## Core Rule: 1–3 Weeks Max

**Every project must be scoped to 1–3 weeks.** If it's longer, break it down.

**Why:**
- Momentum dies after 3 weeks
- Longer projects accumulate scope creep
- Faster feedback loops → better products
- Shipping iteratively reduces risk

**This is non-negotiable.** Make the project smaller, not the timeline longer.

---

## Complexity Tiers

Use these heuristics to estimate effort and decide if breakdown is needed.

### Quick Win (0–2 days)

**Signals:**
- Single file or component change
- Clear, well-defined scope
- No database migrations
- Existing patterns can be copied
- Minimal new tests

**Examples:**
- Add a new column to existing feature
- Fix a bug with known root cause
- Add validation to an existing form
- Update copy or styling

**Action:** Ship as-is. Perfect for quick wins between larger projects.

---

### Standard (3–5 days)

**Signals:**
- Multi-component feature
- Includes database changes + UI
- New API endpoints or services
- Requires comprehensive tests
- May touch 3–5 files

**Examples:**
- Add CRUD operations for a new entity
- Build a new page or major UI section
- Integrate a third-party API
- Add a new workflow or automation

**Action:** Ship as a single unit of work. Ensure clear acceptance criteria.

---

### Complex (6+ days)

**Signals:**
- **This needs breakdown**
- Touches many files (>10)
- Requires architectural decisions
- Involves multiple system integrations
- Introduces new patterns or infrastructure

**Examples:**
- Build a new user onboarding flow
- Add a new billing tier (payment provider + schema + UI + emails)
- Implement real-time features (WebSockets + state management + UI)

**Action:** Break into 2–3 independently shippable milestones (see breakdown section below).

---

## Breaking Down Complex Work

### Step 1: Identify Milestones

Look for **independently shippable** chunks. Each milestone should deliver user value on its own.

**Bad Breakdown (not independently shippable):**
1. Create database schema
2. Build API endpoints
3. Build UI

**Good Breakdown (each milestone ships value):**
1. **Milestone 1:** Read-only view of existing data (no schema changes, reuse existing API)
2. **Milestone 2:** Add create/edit functionality (schema + API + UI)
3. **Milestone 3:** Add bulk actions and filters (incremental UI improvement)

### Step 2: Separate Enablers from Features

**Enablers:** Foundation work that doesn't ship user-facing value (schema, API endpoints, infrastructure).

**Features:** User-facing changes that deliver value (UI, workflows, notifications).

**Pattern:** Ship enablers first, then unblock feature work.

**Example:**

- **Ticket 1 (Enabler):** Add `subscription_status` column to database [1 day]
- **Ticket 2 (Feature):** Show subscription status in user dashboard [2 days] — Blocked by Ticket 1

### Step 3: Validate Each Milestone

Before finalizing the breakdown, check each milestone:

- [ ] **Independently shippable?** Can this go to production on its own?
- [ ] **Delivers user value?** Does the user get something from this?
- [ ] **<1 week?** Can this be completed in 5 days or less?
- [ ] **Clear owner?** Is there one person responsible for this?

If any answer is "no," re-scope the milestone.

---

## Team Sizing

### Default: 1 Person

**Most projects should have a single owner.**

**Benefits:**
- Clear decision-making
- No coordination overhead
- Faster velocity
- Full context in one person's head

### When to Add a Second: 2-Person Max

**Only when:**
- Project is 2+ weeks AND has clear parallel work streams
- Example: One person builds backend, another builds frontend

**Anti-pattern:** Two people building the same thing "faster" → Usually slower due to coordination.

### Never: More Than 3 People

**If you need >3 people, the project is too big.** Break it into smaller, independently shippable pieces.

---

## Enabler vs Blocker Framework

### Enablers

**Definition:** Work that must exist before a feature can be built.

**Examples:**
- Database schema changes
- New API endpoints
- Authentication setup
- Infrastructure improvements

**When to Build:**
- Build enablers **just-in-time** (when the feature is next in queue)
- Don't build enablers speculatively ("we might need this later")

### Blockers

**Definition:** Work that prevents shipping a feature right now.

**Examples:**
- Missing API endpoint
- Incomplete database migration
- Broken CI pipeline
- Missing design specs

**When to Address:**
- Immediately, if blocking current work
- Schedule explicitly, if blocking future planned work

---

## Anti-Patterns

### ❌ Mixing Enabler Work with Feature Work

**Bad:** "Add payment processing" (includes schema, API, UI, webhooks, emails)

**Good:**
- Ticket 1 (Enabler): Add payment provider integration + schema [2 days]
- Ticket 2 (Feature): Build checkout UI [2 days]
- Ticket 3 (Feature): Add payment confirmation emails [1 day]

### ❌ Tickets That Could Be 3 Smaller Tickets

**Bad:** "Improve user dashboard" (vague, multi-week scope)

**Good:**
- Ticket 1: Add recent activity widget [1 day]
- Ticket 2: Add performance metrics chart [2 days]
- Ticket 3: Add quick actions toolbar [1 day]

### ❌ Building Features for Hypothetical Users

**Bad:** "Add configurable dashboard widgets" (flexible, but who asked for it?)

**Good:** "Add top 5 metrics widget to dashboard" (specific user request)

### ❌ Estimating in Story Points

**Use days, not story points.**

**Why:** Days are concrete. "3 story points" means different things to different people. "2 days" is clear.

---

## Examples

### Example 1: Quick Win

**Ticket:** "Add status filter to orders table"

**Complexity:**
- Single component change
- Existing filter pattern can be copied
- No schema changes
- Minimal test updates

**Estimate:** 1 day

**Action:** Ship as-is.

---

### Example 2: Standard

**Ticket:** "Add audit log for admin actions"

**Complexity:**
- New database table
- Migration + indexes
- Service layer to log events
- UI component to display logs
- Tests (unit + integration)

**Estimate:** 4 days

**Action:** Ship as a single ticket.

---

### Example 3: Complex → Breakdown Required

**Ticket:** "Add premium subscription tier"

**Complexity:**
- Payment provider setup (Stripe/Paddle)
- Schema changes (subscriptions table)
- Webhook handlers
- Checkout flow
- Admin UI for tier management
- Email templates
- Tests across all layers

**Estimate:** 10 days (too long!)

**Breakdown:**
1. **Milestone 1 (Enabler):** Payment provider integration + schema [2 days]
2. **Milestone 2 (Feature):** Checkout flow for premium tier [3 days]
3. **Milestone 3 (Feature):** Admin UI for tier management [2 days]
4. **Milestone 4 (Feature):** Email templates [1 day]

Each milestone ships independently. Total: 8 days across 4 tickets.

---

## Quick Reference

| Complexity | Days | Signals | Action |
|------------|------|---------|--------|
| **Quick Win** | 0–2 | Single file, clear scope, no migrations | Ship as-is |
| **Standard** | 3–5 | Multi-component, tests, may need migration | Ship as single ticket |
| **Complex** | 6+ | Many files, architectural decisions, new patterns | Break into 2–3 milestones |

**Default Team Size:** 1 person per project

**Max Project Length:** 3 weeks (break down if longer)

**Enablers:** Build just-in-time, not speculatively

---

## Measuring Success

Track these metrics to validate the framework is working:

**Velocity Metrics:**
- % of projects completed in <3 weeks (target: 90%+)
- Average project duration (target: <2 weeks)
- % of projects that require re-scoping (target: <20%)

**Quality Metrics:**
- % of shipped work that requires follow-up fixes (target: <10%)
- Time from "done" to production (target: <1 day)

**Team Health:**
- % of work with single owner (target: 80%+)
- % of work broken down proactively (target: 60%+)

---

## When to Use This

**Always:**
- Before starting any project (estimate complexity first)
- During backlog grooming (flag complex work for breakdown)
- When assigning work (validate scope is appropriate)

**Signs you need this:**
- Projects routinely take >1 month
- Teams constantly ask "is this done yet?"
- Scope creep is the norm, not the exception
- Unclear who owns what

---

## Adaptation Notes

This framework is a starting point. Adapt it to your context:

**For startups (<10 people):**
- Lean toward Quick Win (0–2 days) heavily
- Ship fast, iterate faster
- Break everything down aggressively

**For scale-ups (10–50 people):**
- Standard (3–5 days) is your sweet spot
- Invest in enablers (infrastructure, tooling)
- Keep team sizes at 1–2 people per project

**For enterprises (50+ people):**
- Use this framework within teams, not across the org
- Enabler work becomes more critical (shared services)
- Watch for coordination overhead (keep projects small)

---

## Next Steps

1. **Audit your current backlog:** How many tickets are >3 weeks of work?
2. **Pick 3 complex tickets:** Practice breaking them down using this framework
3. **Measure before/after:** Track completion rate before and after applying this
4. **Iterate:** Adjust the complexity tiers to match your team's actual velocity

**Remember:** The goal is sustainable speed, not unsustainable crunch.
