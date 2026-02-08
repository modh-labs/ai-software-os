# Backlog Hygiene

> How I clean up 500-ticket backlogs and keep them clean.

**The Problem I See Everywhere:**

I join a company. I open their backlog. 500+ tickets. Half are from 2 years ago. Nobody knows what's actually getting worked on.

Classic backlog bankruptcy.

**What I Do:**

I ruthlessly prune the backlog to <50 actionable tickets. Then I install a system to keep it clean.

**Timeline:** This takes me 1–2 weeks. The impact lasts years.

---

## The Backlog Audit (Week 1)

### Step 1: Export Everything

I pull the full backlog into a spreadsheet. I need to see:
- Ticket ID
- Title
- Created date
- Last updated date
- Status (Backlog, Todo, In Progress, etc.)
- Owner (if any)

**Why:** You can't fix what you can't see.

### Step 2: Classify Every Ticket

I go through the backlog and classify each ticket into one of four categories:

| Category | Definition | Action |
|----------|------------|--------|
| **Zombie** | Created >3 months ago, never started, no recent activity | **Close immediately** |
| **Duplicate** | Same work as another ticket (happens all the time) | **Close, link to original** |
| **Vague** | "Improve dashboard", "Fix performance" (no specifics) | **Close or rewrite with specifics** |
| **Actionable** | Clear scope, recent, someone might actually work on this | **Keep** |

**My Experience:**

In a typical 500-ticket backlog:
- 60–70% are Zombies (close them)
- 10–15% are Duplicates (close them)
- 10–15% are Vague (close or rewrite)
- 10–20% are Actionable (keep these)

**After this step:** Backlog drops from 500 → 50–100 tickets.

---

### Step 3: Add Complexity Assessment

For every actionable ticket, I add a complexity label:

| Complexity | Signals | Label |
|------------|---------|-------|
| **Quick Win** | 0–2 days, single file, clear scope | `Quick Win` |
| **Standard** | 3–5 days, multi-component, tests | (no special label) |
| **Needs Breakdown** | 6+ days, vague scope, too complex | `Needs Breakdown` |

**Why:**

This lets engineers filter:
- "Show me Quick Wins" → Batch of small wins between projects
- "Show me tickets that need breakdown" → Planning work

**How I Do This Fast:**

I use an AI tool (Claude, ChatGPT) to batch-classify tickets:
- Read ticket title + description
- Classify as Quick Win, Standard, or Needs Breakdown
- Add label in Linear/Jira

Takes ~2 hours for 50 tickets.

---

### Step 4: Triage Thin Tickets

Some tickets are actionable but **thin** — missing context that an engineer needs.

**Examples:**
- No repro steps (bugs)
- No acceptance criteria (features)
- No architecture context (refactors)

For these tickets, I either:
1. **Enrich them** (add missing context from Sentry, database, codebase)
2. **Close them** (if I can't figure out what they mean)

**Tool I Use:**

I built an automated triage system (see Aura's `/triage` skill) that:
- Finds thin tickets
- Pulls data from Sentry (errors), database (affected users), codebase (relevant files)
- Enriches ticket with user story, architecture, edge cases, acceptance criteria

This is reusable. I can install it at any company.

---

## The Ongoing System (Weeks 2+)

Cleaning the backlog once is easy. **Keeping it clean is the hard part.**

Here's my system:

### Rule 1: Tickets Expire After 3 Months

If a ticket sits in Backlog/Todo for >3 months without being started:
- **Auto-close it** (use automation in Linear/Jira)
- **Why:** If it was important, someone would have started it

**Exception:** Long-term strategic work (mark with `Strategic` label to exempt from auto-close)

---

### Rule 2: Triage New Bugs Within 72 Hours

Every new bug that comes in gets triaged within 72 hours:
- Assign complexity (Quick Win, Standard, Needs Breakdown)
- Add priority (Urgent, High, Normal, Low)
- Enrich if needed (Sentry context, repro steps, affected users)

**Why:** Bugs that sit for weeks lose context. Triage fast while memory is fresh.

**Tool:** Automated triage (runs daily, flags thin bugs)

---

### Rule 3: No Vague Tickets Allowed

If a ticket doesn't have:
- Clear scope (what needs to be done)
- Acceptance criteria (how do you know it's done)

**It gets closed or sent back to the author for revision.**

**My Standard:**

Every ticket should pass the "handoff test":
- Could a new engineer pick this up and complete it without asking questions?
- If no → ticket is incomplete

---

### Rule 4: Archive "Nice to Have" Ideas

Teams love to create tickets for every idea. "What if we added this feature?"

I don't let these live in the backlog. I move them to a **separate "Ideas" backlog** (or close them with a comment "revisit when we have demand").

**Why:** The backlog should reflect **actual priorities**, not aspirations.

**My Rule:** If no user has explicitly asked for it, it's an idea, not a priority.

---

## Backlog Health Metrics

I track these metrics monthly to ensure the system is working:

### Metric 1: Backlog Size

**Target:** <50 actionable tickets

**Red Flag:** Backlog growing >10% month-over-month (too many ideas, not enough shipping)

---

### Metric 2: Age Distribution

**Target:** <20% of backlog is >3 months old

**Red Flag:** Lots of old tickets (team not starting work, or auto-close isn't running)

---

### Metric 3: Completion Rate

**Target:** 70%+ of tickets marked "In Progress" get completed within 1 month

**Red Flag:** Lots of abandoned work (tickets started but never finished)

---

### Metric 4: Thin Ticket %

**Target:** <10% of new tickets need enrichment

**Red Flag:** Teams creating tickets without enough context (need to improve ticket creation process)

---

## How I Implement This at Your Company

### Week 1: The Big Cleanup

**Days 1–3:**
- Export backlog
- Classify (Zombie, Duplicate, Vague, Actionable)
- Close 60–70% immediately

**Days 4–5:**
- Add complexity labels to remaining tickets
- Triage thin tickets (enrich or close)

**Outcome:** Backlog reduced from 500 → <50 actionable tickets

---

### Week 2: Install Ongoing System

**Set up automation:**
- Auto-close tickets >3 months old (with exemptions for strategic work)
- Daily triage for new bugs (flag thin tickets)
- Weekly report on backlog health (size, age distribution, completion rate)

**Train the team:**
- What makes a good ticket (clear scope, acceptance criteria)
- How to use complexity labels (Quick Win, Needs Breakdown)
- When to close vs keep tickets

**Outcome:** Backlog stays clean without manual work

---

## Real Results I've Seen

**Before my system:**
- 500+ ticket backlogs (nobody knows what's real)
- Teams create vague tickets ("improve performance")
- Old tickets sit for years
- Decision paralysis (too many options)

**After my system:**
- <50 ticket backlogs (every ticket is actionable)
- All tickets have complexity assessment
- Tickets auto-close after 3 months
- Clear priorities, fast decisions

**The unlock:** A backlog that reflects reality, not wishful thinking.

---

## Tools I Use

### Automation (Linear)

I set up Linear automation rules:
- **Auto-close:** If ticket in Backlog >90 days AND no label:Strategic → Close with comment "Auto-closed due to inactivity"
- **Auto-label:** If new bug created → Auto-assign to triage queue
- **Auto-notify:** If ticket sits in "In Progress" >2 weeks → Notify owner

### Triage Scripts

I use Claude Code + Linear API to batch-process tickets:
- Fetch all tickets in Backlog
- Classify complexity (Quick Win, Standard, Needs Breakdown)
- Add labels in bulk

This is open-source. I can share the scripts.

---

## Adaptation Notes

**For startups (<10 people):**
- Keep backlog even smaller (<20 tickets)
- Close aggressively (if not started in 1 month, close it)
- Focus on Quick Wins (batch small improvements)

**For scale-ups (10–50 people):**
- Maintain <50 tickets per team
- Use complexity labels heavily (helps with capacity planning)
- Track backlog health metrics weekly

**For enterprises (50+ people):**
- Backlog per team (not org-wide)
- Stricter ticket quality standards (block vague tickets)
- Monthly backlog reviews (ensure auto-close is working)

---

## When You Need Me

I install this system in 1–2 weeks as part of a broader engagement.

**Typical engagement:**
1. **Week 1:** Backlog audit + big cleanup (500 → 50 tickets)
2. **Week 2:** Install automation + train team
3. **Week 3:** Monitor first month (ensure system sticks)
4. **Week 4:** Hand off to team (they own it going forward)

**Outcome:** Clean backlog, ongoing system, team moves faster.

---

## Bottom Line

**Most teams have backlog bankruptcy.** 500+ tickets, half from years ago, nobody knows what's real.

**I fix this in 1–2 weeks.** Ruthless pruning, complexity assessment, automation to keep it clean.

**The result:** A backlog that reflects **actual priorities**, not wishful thinking.

This is how I grow and scale your engineering team.
