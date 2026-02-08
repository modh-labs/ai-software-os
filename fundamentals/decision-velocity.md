# Decision Velocity

> How I help engineering teams move 10x faster by teaching them which decisions matter.

**The Problem I See Everywhere:**

Teams get stuck waiting for consensus. They treat every decision like it's permanent. Engineering managers schedule meetings to pick CSS class names. Three-day Slack threads debating whether to use a div or a span.

Meanwhile, competitors are shipping.

**What I Do:**

I teach teams to **distinguish reversible decisions from irreversible ones** — then default to autonomy for 90% of their work.

---

## The Two-Way Door Framework

Stolen from Amazon, refined through shipping software daily.

### Two-Way Doors (Reversible Decisions)

**Definition:** Decisions that can be easily changed later.

**What I tell teams:** "If you can undo this in <1 hour of work, you don't need permission. Ship it."

**Examples:**
- Component structure or naming
- CSS styling or layout choices
- Internal API structure (not public-facing)
- Copy or microcopy
- Feature flags
- Logging levels
- Test organization

**My Rule:**
- **Who decides:** Individual engineer
- **Review needed:** No (code review catches quality issues)
- **Documentation:** PR description is enough
- **Timeline:** Ship today

When I join a company, I find teams asking for approval on these decisions. I stop that immediately.

---

### One-Way Doors (Hard to Reverse)

**Definition:** Decisions that are expensive, risky, or time-consuming to reverse.

**What I tell teams:** "This one we talk about. But for 24–48 hours max, then we decide."

**Examples:**
- Database schema changes (migrations are painful)
- Public API contracts (breaking changes hurt users)
- Authentication patterns (hard to swap later)
- Billing logic (money is involved)
- Third-party integrations (Stripe, payment processors)
- Data retention policies (legal implications)

**My Rule:**
- **Who decides:** Engineer proposes, 1–2 people review
- **Review needed:** Yes (async in Linear or PR, not a meeting)
- **Documentation:** Write down the trade-offs (what you considered, why you chose this)
- **Timeline:** 24–48 hours max, then decide and move on

**No endless debate.** Set a deadline, make the call, ship it.

---

## When I Tell Teams to Ship vs Keep Iterating

### Ship Now If:

- [ ] **Core workflow works** — Happy path is complete
- [ ] **Edge cases handled** — Error states, loading states, empty states exist
- [ ] **No data loss risk** — Users won't lose work
- [ ] **Tests pass** — CI is green
- [ ] **You can explain it** — Future you (or another engineer) can understand this

**My Motto:** "Good enough to ship beats perfect in a branch."

I've seen too many engineers sit on great work for weeks because it's not "perfect." Ship it. Users will tell you what's actually important.

---

### Keep Iterating If:

- [ ] **Core workflow is broken** — Happy path doesn't work
- [ ] **Data loss risk** — Users could lose their work
- [ ] **Major UX issues** — Confusing, error-prone, or unusable
- [ ] **Security vulnerability** — XSS, SQL injection, auth bypass
- [ ] **CI failing** — Tests fail, linting errors, type errors

**My Motto:** "Don't ship broken work — but also don't wait for perfect."

---

## How I Document Trade-Offs (One-Way Doors Only)

When making a hard-to-reverse decision, I teach teams to write down their thinking.

**Why:** Six months from now, someone will ask "why did we do it this way?" If you didn't document the trade-offs, you'll waste hours re-litigating the decision.

### Template I Use

```markdown
## Decision: [What we're doing]

**Problem:** [What problem does this solve?]

**Options Considered:**

1. **Option A:**
   - ✅ Pros: [Benefits]
   - ❌ Cons: [Downsides]

2. **Option B:**
   - ✅ Pros: [Benefits]
   - ❌ Cons: [Downsides]

**Chosen:** Option [A/B]

**Why:** [1-2 sentences on the key trade-off]

**Reversibility:** [How hard to undo? What would it take?]
```

This takes 5 minutes to write. It saves hours of future confusion.

---

## Scope Decisions: When I Tell Teams to Build vs Skip

### Build Now If:

- [ ] **User explicitly requested it** — Real user, real pain, clear value
- [ ] **Blocks a planned feature** — Enabler work for next milestone
- [ ] **Fixes a production bug** — Users are feeling pain right now
- [ ] **Removes tech debt** — Actively slowing down current development

### Skip (or Defer) If:

- [ ] **No user asked for it** — "Nice to have" is code for "don't build"
- [ ] **Speculative optimization** — "This might be slow later" without data
- [ ] **Over-engineering** — Building for hypothetical future requirements
- [ ] **Low impact** — <10 users would benefit

**My Rule:** If you're unsure whether to build something, **don't build it**. Wait for user pain. You can always build it later. You can't unbuild wasted time.

---

## How I Run Async Decisions (No Meetings)

Most one-way door decisions happen in Linear or GitHub. Here's my process:

### 1. Propose in Linear or PR

**Format:**
- Post decision template in comments
- Tag relevant people (@mention)
- Set a deadline (24–48 hours)

### 2. Team Reacts

- 👍 if you agree
- Comments if you have concerns (be specific, not vague)

### 3. Proposer Decides

After 24–48 hours, the proposer makes the final call:
- Addresses feedback (or explains why not)
- Documents the decision
- Ships it

**No consensus required.** We're optimizing for speed, not unanimous agreement.

---

## Common Decision Patterns I Teach

### "Should I refactor this now or later?"

**My Answer:**

**Refactor now if:**
- You're about to build on top of it (refactor first, then extend)
- The code is actively dangerous (data loss, security hole)

**Ship now if:**
- The code works and is tested
- Refactoring is cosmetic (naming, structure)

**Rule:** Refactor when you touch the code, not speculatively.

---

### "Should I add this feature or keep it simple?"

**My Answer:**

**Add it if:**
- User explicitly requested it
- Solves a real pain point (not hypothetical)

**Keep it simple if:**
- No user asked for it
- Adds complexity without clear value

**Rule:** Simplicity wins. Add features only when there's proven demand.

---

### "Should I build this abstraction or copy-paste?"

**My Answer:**

**Build abstraction if:**
- Pattern is used in 3+ places
- Logic is complex and error-prone (DRY helps correctness)

**Copy-paste if:**
- Pattern is used in <3 places
- Logic is simple and unlikely to change

**Rule:** [Rule of Three](https://en.wikipedia.org/wiki/Rule_of_three_(computer_programming)) — abstract on the third use, not the first.

---

## Red Flags: When I Tell Teams to Stop and Discuss

Even with heavy autonomy, some situations need alignment.

**Stop and discuss if:**
- [ ] **Multiple engineers disagree** — Get on a quick call, hash it out
- [ ] **User data at risk** — Data loss, privacy, security concerns
- [ ] **Breaking change to public API** — Affects external integrations
- [ ] **High cost or irreversible** — Expensive migration, long-term commitment
- [ ] **Unclear requirements** — You don't understand the problem well enough

**How I escalate:** Post in Linear with @mention. If not resolved in 24 hours, 15-minute call.

---

## What I've Seen Work (Real Results)

**Before my system:**
- 3-day Slack threads debating component structure
- Teams waiting days for "approval" on trivial changes
- Analysis paralysis on every decision

**After my system:**
- 90% of decisions made same-day (two-way doors)
- One-way doors decided in 24–48 hours (vs weeks)
- Engineers ship 3–5x more because they stop waiting

**The unlock:** Teaching teams that **most decisions don't matter long-term** — and the ones that do should be decided quickly, not perfectly.

---

## How to Implement This at Your Company

### Week 1: Classify Your Decisions

Audit your last 20 team decisions. Classify each:
- **Two-way door:** Could this have been reversed easily? (Yes = stop asking for approval)
- **One-way door:** Was this hard to reverse? (Yes = keep the discussion, but time-box it)

You'll find 80–90% are two-way doors being treated like one-way doors.

### Week 2: Set Default Rules

Tell your team explicitly:

**Two-way doors:**
- "You don't need permission. Ship it in your PR."

**One-way doors:**
- "Propose in Linear/GitHub. 24–48 hour discussion window. Then we decide."

### Week 3: Measure Impact

Track:
- Time from proposal to decision (before/after)
- % of decisions made without meetings (target: 90%+)
- Team sentiment (are they moving faster?)

### Week 4: Iterate

Find the edge cases where autonomy went wrong:
- Was it actually a one-way door disguised as two-way?
- Did the engineer lack context to make the call?

Adjust your classification, don't abandon autonomy.

---

## When You Need Me

I install this system in 2–4 weeks when I join a company as an advisor or fractional CTO.

**Typical engagement:**
1. **Week 1:** Audit current decision-making (where are teams blocked?)
2. **Week 2:** Train team on two-way vs one-way doors
3. **Week 3:** Shadow decisions, course-correct in real-time
4. **Week 4:** Measure impact, hand off to team

**Outcome:** Teams moving 5–10x faster on decisions. More shipping, less talking.

---

## Bottom Line

**Most teams optimize for perfect decisions.** They debate endlessly, seek consensus, avoid mistakes.

**I optimize for fast decisions.** Ship two-way doors immediately. Decide one-way doors in 48 hours. Learn from production, not from planning docs.

**Speed wins.** The team that ships faster learns faster. The team that learns faster builds better products.

This is how I grow and scale your engineering team.
