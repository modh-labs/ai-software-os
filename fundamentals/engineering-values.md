# Engineering Values

> The 6 operating principles I use to build high-velocity engineering teams.

**What I've Learned:**

Most companies have values on a wall. "Innovation." "Collaboration." "Excellence."

Nobody knows what they actually mean in practice.

**What I Do:**

I install **6 concrete values** with clear "In Practice" examples. Every value translates to daily behavior. No fluff, no corporate speak.

---

## The Six Values

### 1. Ship Over Plan

**What It Means:**

Deploy to production multiple times a day. Scope work to 1–3 week chunks. The fastest way to validate an idea is to build it, ship it, and see what happens.

**In Practice:**

- Scope every project to <3 weeks (anything longer gets broken down)
- Ship the smallest version that delivers value
- Iterate based on real usage, not assumptions
- Default to shipping now vs perfect later
- Celebrate deployments, not plans

**What I See:**

Teams spend weeks planning the "perfect" solution. Meanwhile, competitors ship v1 and learn what actually matters.

I flip this. Ship fast. Learn from production. Iterate based on reality.

**Red Flag:**

If your team spends more time planning than shipping, this value is broken.

---

### 2. Own the Outcome

**What It Means:**

You're not done when your PR merges — you're done when users get value. Every project has a **single owner** who makes decisions and moves fast. You watch your features in production and fix what breaks.

**In Practice:**

- Every project has exactly one owner (not a team, one person)
- Monitor your features in Sentry/observability tools after deploy
- Fix production issues you introduce (don't hand off to "ops")
- Write tests that prevent regressions
- Success = users using the feature, not code merged

**What I See:**

Teams throw code over the wall. "I shipped it, not my problem if it breaks."

I don't allow that. You own it from idea to production to maintenance.

**Red Flag:**

If engineers say "I don't know if my feature works in prod," this value is broken.

---

### 3. AI-Native

**What It Means:**

We're building software in 2025+. Claude Code, Cursor, Copilot, ChatGPT — these are table stakes, not optional.

**In Practice:**

- Use AI tools to multiply your output (Claude Code, Cursor, Copilot)
- Expect AI to handle repetitive tasks (migrations, tests, boilerplate)
- Build AI-powered features where appropriate (analysis, insights, automation)
- Ship faster by delegating grunt work to AI

**What I See:**

Some teams still resist AI tools. "Real engineers don't need help."

Wrong. Real engineers use every force multiplier available. AI is the biggest one.

**Red Flag:**

If your team isn't using AI daily, you're falling behind. Fast.

---

### 4. Build for Creators

**What It Means:**

We build for coaches, agencies, sales teams, creators — **not enterprise committees**. Purpose-built workflows that solve real problems beat infinite flexibility every time.

**In Practice:**

- Solve specific user problems (booking, lead management, payments)
- Choose opinionated workflows over endless configuration
- Talk to users to understand their actual workflows
- Say no to features that add complexity without clear value
- Build for the 80% use case, not the 1% edge case

**What I See:**

Teams build "flexible" platforms that solve nothing well. Endless config screens, no clear workflow.

I build opinionated tools. Solve one problem really well. Say no to everything else.

**Red Flag:**

If users say "it's powerful but I don't know how to use it," you're building for committees, not creators.

---

### 5. Finish Everything

**What It Means:**

The last 10% — error handling, edge cases, loading states, tests — is where most of the value lives. We ship **complete** work to production.

**In Practice:**

- Every route needs: loading states, error boundaries, tests, validation
- Handle edge cases before shipping (empty states, errors, race conditions)
- Write tests that cover realistic scenarios
- Complete documentation before marking work done
- No "we'll fix it later" — finish it now

**What I See:**

Teams ship 90% solutions. "We'll add error handling later." Later never comes.

I don't allow 90%. If it's not done, it's not shipped.

**Red Flag:**

If your production error rate is high, this value is broken. Teams are shipping incomplete work.

---

### 6. Direct Communication

**What It Means:**

Say what you mean. If something is broken, say it. If you disagree, explain why. No time for passive communication.

**In Practice:**

- Be clear and concise in PRs, issues, async messages
- Call out problems directly (broken builds, bad patterns, tech debt)
- Disagree with context, not vague concerns
- Default to public channels over DMs (transparency)
- Say "no" when needed (don't take on work you can't finish)

**What I See:**

Teams use corporate speak. "We might want to consider potentially revisiting..."

Just say it: "This approach won't scale. Here's why. Here's what we should do instead."

**Red Flag:**

If your team has recurring problems nobody talks about, this value is broken.

---

## How I Install These at a Company

### Week 1: Audit Current Culture

I look for:
- How long do projects take? (If >3 weeks, Ship Over Plan is broken)
- Who owns production issues? (If "the team," Own the Outcome is broken)
- Are engineers using AI? (If no, AI-Native is broken)
- Are features complete when shipped? (If no, Finish Everything is broken)
- Do people speak directly? (If lots of passive language, Direct Communication is broken)

### Week 2: Define "In Practice" Examples

I work with the team to translate each value into **specific behaviors** for your context.

**Example:** If you're building a B2B SaaS tool:
- **Build for Creators** → "We build for sales managers, not IT committees"
- **Own the Outcome** → "You monitor your feature for 48 hours post-deploy"

Make it concrete. No abstract language.

### Week 3: Reinforce Daily

Every code review, every standup, every decision:
- "Does this align with Ship Over Plan?" (Is this the smallest shippable version?)
- "Who owns this?" (Own the Outcome)
- "Did you use AI to speed this up?" (AI-Native)
- "Are all edge cases handled?" (Finish Everything)

Values only work if they're used daily.

### Week 4: Celebrate Examples

When someone ships a complex feature in <1 week → **Ship Over Plan** win.

When an engineer fixes their own prod bug → **Own the Outcome** win.

When a feature ships with perfect error handling → **Finish Everything** win.

Celebrate these publicly. Values become culture through repetition.

---

## Real Results I've Seen

**Before these values:**
- Projects take months, scope creeps endlessly
- Production bugs sit unfixed for weeks (nobody owns them)
- Features ship half-done, users complain
- Communication is vague, decisions take forever

**After these values:**
- 90%+ of projects ship in <3 weeks
- Production issues fixed within hours (owner jumps on it)
- Features ship complete (error handling, tests, docs)
- Clear communication, decisions made in 24–48 hours

**The unlock:** Values that translate to **specific daily behaviors**, not abstract ideals.

---

## How to Adapt This to Your Company

**Don't copy these blindly.** Adapt them to your culture and product.

**If you're a startup (<10 people):**
- Add: **"Move Fast, Break Things"** (iterate speed over stability)
- Remove: **"Finish Everything"** (ship 80% solutions, iterate)

**If you're enterprise (50+ people):**
- Add: **"Boring Technology"** (stability > novelty)
- Emphasize: **"Finish Everything"** (compliance, security, edge cases matter)

**If you're product-led growth:**
- Emphasize: **"Build for Creators"** (opinionated, easy to start)
- Add: **"Self-Service First"** (no sales calls to activate)

**The values should reflect how you actually want to work**, not generic "best practices."

---

## When You Need Me

I install these values as part of a broader engagement (typically 4–8 weeks).

**Typical process:**
1. **Audit:** What's broken about current culture?
2. **Define:** What values would fix those problems?
3. **Translate:** What does each value mean in practice?
4. **Reinforce:** How do we make these stick?

**Outcome:** Team operating from a shared playbook. Faster decisions, better quality, clearer culture.

---

## Bottom Line

**Most companies have values nobody uses.**

I install values that guide **every decision, every day**.

**Ship Over Plan** → Scope work to <3 weeks, ship fast.

**Own the Outcome** → You monitor prod, you fix bugs.

**AI-Native** → Use every force multiplier available.

**Build for Creators** → Solve specific problems really well.

**Finish Everything** → No 90% solutions.

**Direct Communication** → Say what you mean.

This is how I grow and scale your engineering team.
