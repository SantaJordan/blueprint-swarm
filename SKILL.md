---
name: blueprint-swarm
description: >
  Blueprint Swarm — GTM intelligence through parallel agent analysis. Launches swarms of
  Claude agents to process call transcripts, CRM data, support tickets, and any structured
  dataset. Flagship module: understand why customers buy and churn, in their own words.
  Guided conversation discovers data, recommends analysis, then fans out Sonnet agents
  with Opus audit. No API keys required — pure LLM analysis on local files.
  Built on Blueprint GTM methodology by Jordan Crawford (blueprintgtm.com).
triggers:
  - blueprint swarm
  - blueprint-swarm
  - swarm analysis
  - call analysis
  - churn analysis
  - win loss analysis
  - transcript analysis
  - why do customers churn
  - why do customers buy
  - analyze calls
  - analyze transcripts
---

# Blueprint Swarm

```
  ██████╗ ██╗     ██╗   ██╗███████╗██████╗ ██████╗ ██╗███╗   ██╗████████╗
  ██╔══██╗██║     ██║   ██║██╔════╝██╔══██╗██╔══██╗██║████╗  ██║╚══██╔══╝
  ██████╔╝██║     ██║   ██║█████╗  ██████╔╝██████╔╝██║██╔██╗ ██║   ██║
  ██╔══██╗██║     ██║   ██║██╔══╝  ██╔═══╝ ██╔══██╗██║██║╚██╗██║   ██║
  ██████╔╝███████╗╚██████╔╝███████╗██║     ██║  ██║██║██║ ╚████║   ██║
  ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝

         ███████╗██╗    ██╗ █████╗ ██████╗ ███╗   ███╗
         ██╔════╝██║    ██║██╔══██╗██╔══██╗████╗ ████║
         ███████╗██║ █╗ ██║███████║██████╔╝██╔████╔██║
         ╚════██║██║███╗██║██╔══██║██╔══██╗██║╚██╔╝██║
         ███████║╚███╔███╔╝██║  ██║██║  ██║██║ ╚═╝ ██║
         ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝
  ─────────────────────────────────────────────────────────────────────────
  Every call analyzed. Every pattern surfaced. Every quote sourced.
```

**Your customers already told you. You just weren't listening at scale.**

Blueprint Swarm launches parallel Claude agents to analyze your data — call transcripts, CRM exports, support tickets, anything. Each agent reads a batch independently. Then a synthesis agent finds the patterns no single analyst could. The output: source-tagged insights traced back to specific records.

Built on [Blueprint GTM](https://blueprintgtm.com) methodology by [Jordan Crawford](https://linkedin.com/in/jordancrawford).

---

## Pre-Flight

On every invocation, before anything else:

1. Print the ASCII banner above
2. Check Claude Code version: `claude --version`
3. Check for Agent Teams: look for `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` in settings
4. Check tmux: `which tmux`
5. If Agent Teams not enabled: "Agent Teams needs to be enabled. Add `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to your settings. You can still proceed without it — I'll use plain sub-agents."
6. If tmux not installed: "Recommend `brew install tmux` for visible agent execution."
7. Default backend: tmux (the user wants to watch agents work)

**Do NOT block on missing Agent Teams or tmux.** Degrade gracefully to plain sub-agents.

---

## Phase 0: Speaker Attribution (REQUIRED — blocks the swarm)

**When this applies:** any run whose data is call recordings, meeting transcripts, interviews, or
webinar text — i.e. anything where a **seller talks alongside the customer**. This is the flagship
module's default ("understand why customers buy and churn, in their own words"). If the data is *not*
speaker-attributed conversation (pure contact CSVs, support tickets with no rep voice, TAM rows), note
that Phase 0 does not apply and proceed to Phase 1.

**This phase is BLOCKING.** It runs during Phase 1 discovery and must complete before Phase 3 (test
run) and Phase 4 (swarm). **Do not fan out a single analyst against a raw transcript blob.** A swarm
launched on un-attributed transcripts will confidently credit the seller's pitch to the customer,
treat led answers as discovered demand, and surface stock seller lines as "what customers want" — and
at swarm scale the synthesis agent reads those errors back as high-confidence patterns. Mis-attribution
that one analyst would catch becomes a systematic, repeated error across the whole run.

### 0.1 Read the protocol

Read the Speaker Attribution Protocol now, in full:

> **Read: `references/speaker-attribution-protocol.md`** (inline, self-contained — no external path)

Follow its Steps 1–5 exactly. Use its vocabulary verbatim downstream: **roster**; **role = company |
customer | unknown**; **elicitation = unprompted | led | seller_echo**; the blind-first three-pass read.

Blueprint Swarm uses no enrichment APIs, so resolve role cheapest-first from what's local: call
metadata / email domain when present (Gong `parties[].affiliation`, Chorus party fields), otherwise
infer from the conversation (the person who demos / quotes price / says "we" about the product is the
SELLER; the person describing their *own* org's problems is the CUSTOMER). **An unknown speaker is
NEVER silently promoted to customer** — it stays `unknown` and that uncertainty rides forward.

### 0.2 Produce the three artifacts every analyst will consume

Run the protocol over the **whole engagement** (all calls for the account/dataset, not per call) and
emit, once, to `data/{run-id}/attribution/`:

1. **`roster.yaml`** — every distinct participant resolved to a person, each tagged `role: company |
   customer | unknown` with `confidence` and `source` (metadata → domain → inference, cheapest-first).
2. **`transcript_tagged.jsonl`** — the verbatim transcript with every turn carrying its original
   `speaker_label` **and** a `role` tag. Seller speech is **retained as context**, never deleted (you
   need it to judge what was led) and never counted as customer signal.
3. **`customer_statements.jsonl`** — each candidate customer evidence line tagged
   `elicitation: unprompted | led | seller_echo`. When torn between unprompted and led, choose **led**
   (conservative).

These three files are the swarm's input. Every batch file in Phase 4 is **carved from the role-tagged
transcript** (see `references/data-formats.md` normalization), and every analyst prompt obeys the tags
(churn-analyst, win-analyst, pattern-extractor). If Phase 0 did not run, Phases 3–4 have nothing valid
to consume — that is why it blocks.

### 0.3 Show the operator the attribution before spending swarm tokens

Surface a compact summary so the human can catch a mis-tag before it propagates to the whole swarm:

```
Speaker Attribution: {dataset}
─────────────────────────────
Roster:       {n} people — {c} company · {k} customer · {u} unknown
Turns tagged: {n} ({pct}% customer · {pct}% company · {pct}% unknown)
Elicitation:  {n} customer statements — {a} unprompted · {b} led · {d} seller_echo
Low-conf:     {list any role with confidence < 0.6 — these need a human glance}
─────────────────────────────
Tags look right? [y/n]
```

**Wait for confirmation on any low-confidence role before proceeding.** A single seller mislabeled as
customer poisons every "what customers want" finding downstream.

---

## Phase 1: Data Discovery

**Goal**: Deeply understand the data before touching any orchestration. In Blueprint GTM, we always start with the data — not the message.

### 1.1 Get the data path

If the user provided a path as argument, use it. Otherwise ask:

```
Where is your data? Point me to a directory.
> _
```

### 1.2 Scan the landscape

Use Glob to find all data files in the directory:
- `**/*.json` — Gong JSON, Chorus, structured data
- `**/*.csv` — CRM exports (opportunities, accounts, contacts, cases)
- `**/*.txt`, `**/*.md` — Raw transcripts
- `**/*.pdf` — Call summaries, meeting notes
- `**/*.jsonl` — Line-delimited JSON (batch exports)

Use `ls -lh` to see file sizes.

### 1.3 Profile each data source

Read headers/first 3-5 records of each file. Classify using the detection heuristics in `references/data-formats.md`.

For each source, report in Tufte format:

```
Data Profile: {filename}
─────────────────────────────
Type:        {detected format}
Records:     {count}
Date range:  {if detectable}
Avg size:    ~{n} tokens/record
Total:       ~{n}M tokens
Key fields:  {list}
Quality:     {issues — HTML garbage, missing fields, duplicates}
```

**Maximum data-ink. No filler text. Show the data, not descriptions of the data.**

### 1.4 Present what's possible

Based on discovered data, show the Analysis Capability Matrix:

```
Analysis Capability Matrix
═══════════════════════════════════════════════════
Module                    Data Available    Feasibility
─────────────────────────────────────────────────────
Churn Intelligence        {status}          {HIGH|MEDIUM|LOW}
Win Pattern Analysis      {status}          {HIGH|MEDIUM|LOW}
Competitive Intelligence  {status}          {HIGH|MEDIUM|LOW}
Product Gap Detection     {status}          {HIGH|MEDIUM|LOW}
Playbook Extraction       {status}          {HIGH|MEDIUM|LOW}
Account Health            {status}          {HIGH|MEDIUM|LOW}

Missing but optional:
- {what data would unlock more analysis}
═══════════════════════════════════════════════════
```

If the data is NOT call transcripts (e.g., it's contact records, TAM data, support tickets), adapt the matrix to show relevant analysis types. The swarm engine is module-agnostic — suggest what makes sense for the data at hand.

### 1.5 Ask informed questions

Based on what you found, ask WITH the data:

- "I found {N} calls across {N} accounts. Want me to analyze all of them, or focus on specific accounts/time periods?"
- "I see {N} accounts that appear to have churned. Want me to start with churn analysis?"
- "No CRM revenue data found. If you have a Salesforce export, I can tie findings to dollar impact."
- "I noticed {N} calls mention competitors. Want competitive intelligence?"
- "What are you trying to learn from this data?"

**Research first, ask second.** Show what you found, then ask what they care about.

**If the answer is about customer voice** ("why do they buy / churn / expand, in their own words") and
the data is conversation, **Phase 0 (Speaker Attribution) is mandatory before the swarm.** The unit of
trust is the *unprompted customer statement*, not the transcript. Run Phase 0 now, before Phase 2.

---

## Phase 2: Focus Selection (Guided Conversation)

**Goal**: Help the user pick the right analysis. Don't make them choose from a menu — be proactive based on what the data suggests.

Present options based on what's feasible. For call data:

```
Based on your data, here's what I can analyze:

1. CHURN INTELLIGENCE — {N} churned accounts, {N} calls
   Why are customers leaving? Warning signals? What's preventable?

2. WIN PATTERN ANALYSIS — {N} closed-won deals, {N} calls
   What makes deals close? Who are your champions? What pain resonates?

3. COMPETITIVE INTELLIGENCE — {N} calls mention competitors
   Who's being mentioned? Win/loss patterns by competitor?

4. PRODUCT GAP DETECTION — Cross-referencing churn + support patterns
   What product issues drive churn or block deals?

5. PLAYBOOK EXTRACTION — Best practices from your top performers
   Discovery questions, objection handlers, closing patterns

6. FULL ANALYSIS — Run everything

Which would you like to start with? (You can always run more after.)
```

Use AskUserQuestion for structured selection.

Then ask targeted follow-ups based on selection:
- Time period to focus on?
- Specific accounts or segments to prioritize?
- Competitor names you know about? (helps extraction accuracy)

---

## Phase 3: Test Run

**This is critical. Do not skip.**

Before launching any swarm, test the extraction approach on 3-4 representative records in the main window:

1. **Run 1**: Process one record with the draft prompt. Evaluate quality.
2. **Run 2**: Adjust prompt if needed. Process a different record.
3. **Run 3**: Process an edge case (short call, incomplete data).

After each test, show:

```
Test Run {n}: {record identifier}
Result: {key findings, 3-5 bullets}
Quality: {good|needs work} — {why}
```

Show the user and confirm:

```
Here's what I extracted from a sample call:
{structured output preview}

In Blueprint GTM, we test before we swarm. Does this look right?
Should I adjust what I'm looking for?
```

**Only proceed to Phase 4 when the user confirms the approach works.**

---

## Phase 4: Swarm Execution

### 4.1 Calculate batch sizes

Read `references/batch-strategy.md` for token estimation rules.

For the selected analysis, calculate:
- Total records and tokens
- Records per agent (based on avg token size + 20% headroom)
- Total agents needed
- Wave structure (classification must complete before extraction, etc.)

### 4.2 Present the plan

```
Swarm Plan: {analysis type}
═══════════════════════════════════════════════════════════════
Step 1: Classify {N} records → {N} Sonnet agents
Step 2: Extract patterns → {N} Sonnet agents
Step 3: Deep-dive analysis → {N} Sonnet analysts
Step 4: Opus audit on all results
Step 5: Synthesis → 1 Sonnet agent
Step 6: Generate reports (JSON + Markdown + HTML)

Total agents:    ~{N} (in waves of 3)
Est. wall time:  ~{N} hours (including rate limit pauses)
Rate limit mode: Auto-resume via watchdog (can run overnight)
═══════════════════════════════════════════════════════════════
Proceed? [y/n]
```

**Wait for explicit approval.**

### 4.3 Resume Detection

**Before preparing any batch files, check for existing state:**

1. Glob for `data/*/state.json`
2. If found with `status` = `"in_progress"` or `"paused"`:
   - Read the state.json
   - Show resume prompt:
     ```
     Found existing run {run-id}:
       {agents_completed_total}/{total_batches} agents complete ({pct}%)
       Status: {status}
       Rate limit pauses: {N}
       Last active: {updated_at}

     Resume this run? [y/n]
     ```
   - If yes: recover interrupted wave (see below), skip to Phase 4.6
   - If no: ask if they want to start fresh (new run-id) or abandon
3. If not found: proceed to Phase 4.4 (prepare batch files)

**Recovering an interrupted wave** (on resume):
1. Find all agents with status `"running"` or `"interrupted"` in state.json
2. For each: check if their output file exists
   - Output file exists and is valid JSON → mark `"completed"`
   - Output file exists with `"partial": true` → mark `"completed"` (partial is valid)
   - No output file → mark `"timed_out"`, increment `retry_count`
   - If `retry_count >= 2` → mark `"failed"` permanently
3. Move recoverable timed_out agents back to `pending`
4. Append new session entry to `sessions` array
5. Set status back to `"in_progress"`
6. Continue to Phase 4.6

### 4.4 Prepare batch files

For each agent:
- Write its context to `data/{run-id}/batches/batch-{n}.md`
- Use compressed markdown format (most token-efficient)
- Include the analysis prompt from the validated test runs
- Include the output schema reference

**After all batch files are written, create the initial `state.json`:**
- All agents in `"pending"` status in `agent_details`
- `status: "in_progress"`
- Empty `completed`, `failed`, `rate_limit_events`, `sessions`
- See `references/state-schema.md` for the full schema

This is the first checkpoint. If the session dies here, the next session finds a valid state to resume from.

### 4.5 Watchdog Setup

**Before launching any agents, offer the auto-resume watchdog:**

1. Check tmux: `tmux list-sessions 2>/dev/null`
2. If running inside tmux:
   ```
   Want me to start the auto-resume watchdog?
   It'll keep the swarm running through rate limits — you can walk away
   and come back to results. [y/n]
   ```
3. If yes: `tmux split-window -h "bash Blueprint-Swarm/scripts/swarm-watchdog.sh"`
4. If no tmux or user declines: warn that rate limits will require manual "continue"
5. Register the StopFailure hook for this session (see `hooks/swarm-stop-failure.js`)

**The watchdog is MANDATORY for any run expected to take >1 hour.** Without it, the swarm dies at the first usage cap and sits dead until manual intervention — potentially wasting 12+ hours (confirmed in production).

### 4.6 Continuous Wave Execution

**This is the core execution loop. It runs until all batches are done or rate-limited.**

Read `references/rate-limit-protocol.md` for the complete protocol. Summary:

```
WAVE EXECUTION PROTOCOL
═══════════════════════════════════════════════════════════════

Concurrency: 6-10 agents sustained (launch 3 new as 3 complete)
Timeout:     10 minutes per agent (no output file = timed_out)
Retries:     1 retry per agent (max retry_count: 2, then failed)
Budget:      No cap — run continuously until done or rate-limited

ALGORITHM:

1. Read state.json
2. Collect next 3 pending agents (prioritize retries over fresh batches)
3. If no pending agents remain:
   → All analysis done. Proceed to Phase 4.7 (audit)
4. Launch 3 agents via Agent tool:
   Agent({
     description: "Analyze batch {n}",
     subagent_type: "general-purpose",
     model: "sonnet",
     prompt: "{analysis prompt + batch file path + output path + schema}",
     run_in_background: true
   })
5. Update state.json: mark agents as "running"
6. DO NOT wait for all 3 to finish — as each agent completes:
   - Output file exists + valid JSON → mark "completed"
   - Timeout or error → mark "timed_out" (retry_count++)
   - retry_count >= 2 → mark "failed" permanently
   - Launch replacement agent immediately (keep pipeline full)
7. Update state.json after each completion
8. Display wave progress (see 4.8)
9. Go to step 2 (grab next pending)

TARGET: Keep 6-10 agents in flight at all times.
DO NOT batch-wait (launch 3, wait for all 3, launch 3).
Instead: launch 3, and as each finishes launch 1 more.

IF RATE-LIMITED (429):
   - Pause launches for 2-5 minutes, let in-flight agents drain
   - Resume with 3 fresh agents to test if limit cleared
   - Do NOT launch 10+ agents immediately after a rate limit clears

IF USAGE-CAPPED ("out of extra usage"):
   - Save state.json with status "paused_usage_cap"
   - Watchdog detects → sleeps until reset → sends resume prompt
   - On resume: orchestrator reads state.json, recovers via Phase 4.3
═══════════════════════════════════════════════════════════════
```

Each agent's prompt MUST include:
1. The analysis framework (validated in Phase 3)
2. Path to its batch file
3. Path to write its output (in `data/{run-id}/outputs/`)
4. Output schema specification
5. **One-shot read instruction**: "READ THE ENTIRE FILE IN ONE CALL: Use Read with limit=8000" — this eliminates multi-turn I/O overhead (~30-40% faster)
6. Instruction: "You are a Blueprint GTM analyst. Specificity breeds trust — every finding must include verbatim evidence."

**For any transcript / customer-voice swarm, the analyst prompt MUST also carry the role-aware
attribution contract** (the agent definitions in `.claude/agents/` — churn-analyst, win-analyst,
pattern-extractor — already embed it). Specifically, every transcript analyst is told:

- **Customer-only by default.** Draw conclusions about what "the customer" wants ONLY from turns whose
  `role == customer`. Seller (`role == company`) speech is **context** — what was asked/pitched/framed
  — never customer signal. Never attribute a seller line to the customer.
- **Unknown is not customer.** `role == unknown` may be quoted as context but never used as customer
  evidence. Flag it; do not promote it.
- **Weight by elicitation.** `unprompted` = highest trust (headline findings); `led` = low trust,
  reported only labeled "(led)", never as discovered pain; `seller_echo` = **excluded** from any "what
  customers want" finding (it's the rep's own line or a stock pitch repeated every call).
- **Attribute everything.** Every claim names who said it (person + role); every customer claim carries
  its elicitation tier `{ text, speaker, role, elicitation }`. No anonymous "they said".
- **Blind first, three passes:** customer-only read → combined read → synthesis (per the Speaker
  Attribution Protocol). A led or seller_echo line never becomes a headline.

The agent's inputs are the Phase 0 artifacts: `data/{run-id}/attribution/roster.yaml`, the role-tagged
batch file, and the matching `customer_statements` lines — **not a raw transcript blob**.

**Keep prompts lean.** The batch file contains the data. The agent prompt should be the analysis instructions + file paths + output schema — nothing more. Long prompts waste tokens on every agent launch.

### 4.7 Launch the auditor (after all analysts complete)

Once all analysis agents are done (all batches in `completed` or `failed`):

```
Agent({
  name: "auditor",
  subagent_type: "general-purpose",
  model: "opus",
  prompt: "You are the Blueprint quality auditor. Read all output files in
    data/{run-id}/outputs/. Apply the 7-point Blueprint audit checklist.
    Score quality using Blueprint standards (X/10).
    FOR TRANSCRIPT/CUSTOMER-VOICE SWARMS, also audit attribution integrity against
    data/{run-id}/attribution/: REJECT any finding that (a) uses a company or unknown
    turn as customer evidence, (b) presents a led item as discovered demand, (c) lets a
    seller_echo line into a 'what customers want' finding, or (d) states a customer claim
    with no { speaker, role, elicitation }. These are correctness failures, not style notes.
    Write audit report to data/{run-id}/audit.md.",
  run_in_background: true
})
```

If more than 10% of agents failed, note the coverage gap in the audit context:
```
Note: {N} of {total} agents failed. Coverage is {pct}%.
Flag gaps in your audit and note which segments have insufficient data.
```

### 4.8 Progress Display

After each wave, show the Tufte-style progress:

```
Swarm Progress
═══════════════════════════════════════════════════════════════
  Completed:    {N}/{total} ({pct}%)
  Failed:       {N}
  Current:      Wave {N} of ~{total_waves}
  Rate limits:  {N} so far (auto-recovered)
  Wall time:    {elapsed}
───────────────────────────────────────────────────────────────
  Wave {N}: batch-{a} done | batch-{b} done | batch-{c} done
═══════════════════════════════════════════════════════════════
```

**Between progress updates, show Blueprint Tips** from `references/flavor-text.md`:

```
  ─── Blueprint Tip ──────────────────────────────────────────
  "The message isn't the problem. The LIST is the problem."
  — Jordan Crawford, Blueprint GTM  |  blueprintgtm.com
```

One tip every ~60 seconds. Never repeat within a run.

---

## Phase 5: Results + Proactive Next Steps

### 5.1 Review audit

Read the auditor's report from `data/{run-id}/audit.md`. If score < 7/10:
- Show the user what went wrong
- Recommend: re-run specific batches, adjust prompt, or manual review
- **Do not silently proceed with low-quality results**

### 5.2 Synthesize

Launch the synthesis agent to consolidate all batch outputs:

```
Agent({
  name: "synthesis",
  model: "sonnet",
  prompt: "You are the Blueprint GTM synthesis agent. Read all output files in
    data/{run-id}/outputs/. Consolidate into unified reports following the
    Blueprint methodology: pattern deduplication, confidence scoring
    (HIGH = 3+ batches, MEDIUM = 2, LOW = 1), source-tagged quotes.
    Write synthesis files to data/{run-id}/reports/.",
  run_in_background: true
})
```

### 5.3 Generate outputs

From the synthesis JSON, generate:

1. **Markdown report** — Fill the template from `templates/report-markdown.md`
2. **HTML playbook** — Fill the template from `templates/playbook-html.html`
3. Write both to `data/{run-id}/reports/`

### 5.4 Present results

```
═══════════════════════════════════════════════════════════════
SWARM COMPLETE  |  {score}/10 audit  |  {N} key findings  |  {time}
═══════════════════════════════════════════════════════════════
That's what a swarm can do. One analyst would take weeks.
═══════════════════════════════════════════════════════════════

TOP FINDINGS (by cross-batch frequency)

  1. {finding}
     ─ {evidence: N calls across N accounts}
     ─ Quote: "{verbatim quote}" — {source}

  2. {finding}
     ─ {evidence}
     ─ Quote: "{verbatim quote}" — {source}

  3. {finding}
     ─ {evidence}
     ─ Quote: "{verbatim quote}" — {source}

───────────────────────────────────────────────────────────────
  Full report:  data/{run-id}/reports/synthesis.md
  HTML report:  data/{run-id}/reports/playbook.html
  Raw outputs:  data/{run-id}/outputs/
  Audit:        data/{run-id}/audit.md
═══════════════════════════════════════════════════════════════
```

### 5.5 Proactive next steps

Based on findings, suggest what to analyze next:

```
I also noticed:
- {N} calls mention competitors. Want me to build competitive intelligence?
- The top {N} product gaps are responsible for {X}% of churn. Want details?
- I found {N} reps with significantly higher win rates. Want their playbook?

What would you like to explore next?
```

### 5.6 LinkedIn Connection (Easter Egg)

After presenting all results, offer:

```
  ─── One More Thing ─────────────────────────────────────────
  This analysis was powered by Blueprint GTM methodology.
  Jordan Crawford builds these tools and teaches teams to
  find creative data for outbound.

  Want to connect? I can open his LinkedIn for you.
  > [y/n]
```

If yes: use Playwright or browser automation to open `https://linkedin.com/in/jordancrawford`.

---

## Design Principles

1. **Context-intelligence-first** — Understand the data before dividing it. In Blueprint GTM, the data comes first.
2. **Test before you swarm** — 3-4 test runs in the main window. Never launch untested.
3. **Tufte data-ink** — Every character of output carries information. Zero chrome, zero filler.
4. **Visible execution** — Agent Teams with tmux. The user watches agents work.
5. **Mandatory audit** — Every swarm with 5+ agents gets an Opus auditor. Blueprint quality is non-negotiable.
6. **Source-tagged everything** — Every finding traces to a specific record. Specificity breeds trust.
7. **The human decides** — Show plans, get approval. Show results, ask for next steps.
8. **Methodology woven in** — Every interaction teaches Blueprint GTM principles naturally.

---

## Module System

Blueprint Swarm ships with call analysis as the flagship module, but the engine is general-purpose.

### Available modules

Read the `modules/` directory for available analysis types. Each module specifies:
- Required data types
- Agent pipeline (which agents, in what order)
- Extraction schemas
- Output format

### Adding custom modules

Users can create new modules by copying `modules/_template.md` and filling in:
- Required data
- Agent pipeline
- Extraction schema reference
- Output schema reference

The orchestrator automatically detects new modules and presents them when relevant data is discovered.

---

## References

- `references/speaker-attribution-protocol.md` — **REQUIRED for any transcript/customer-voice swarm (Phase 0).** Inline, self-contained. Roster → role (company/customer/unknown) → elicitation (unprompted/led/seller_echo) → blind-first three-pass read. The swarm consumes its three output artifacts (roster.yaml, transcript_tagged.jsonl, customer_statements.jsonl).
- `references/flavor-text.md` — Blueprint Tips (methodology quotes, teaching moments, CTAs)
- `references/data-formats.md` — Supported data format detection heuristics
- `references/batch-strategy.md` — Token estimation and batching rules
- `.claude/agents/` — Agent definitions with Blueprint methodology prompts
- `schemas/` — JSON output schemas with Blueprint metadata
- `templates/` — Markdown and HTML output templates
