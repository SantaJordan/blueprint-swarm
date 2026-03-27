# Playbook Extraction

Mine closed-won calls for the specific discovery questions, objection handlers, and closing patterns that top performers use.

## Required Data

- Closed-won calls with full transcripts (not summaries)
- Best with complete deal arcs: discovery through closing
- Minimum: 5 closed-won deals for pattern extraction
- Ideal: 15+ deals to identify statistically significant patterns

## Agent Pipeline

### 1. Deal Arc Reconstruction

If win-pattern-analysis has already run, use its deal groupings. Otherwise, reconstruct deal arcs by grouping calls per account in chronological order.

Classify each call's position in the deal arc:
- **Opening** — first call, discovery-focused
- **Middle** — demo, technical evaluation, stakeholder expansion
- **Closing** — negotiation, procurement, final decision

### 2. Dispatch Playbook Analysts (Agent Swarm)

Fan out one agent per deal arc (batch size: 2-3 deals per agent — deep reading required).

Each analyst extracts three playbook categories:

**Discovery Questions:**
- Exact questions asked by the seller that elicited high-value responses
- Score each question by information yield (did it reveal pain, budget, timeline, competition, or decision process?)
- Note the sequence — which questions opened which follow-up threads?

**Objection Handling:**
- The objection as stated by the buyer
- The seller's response (exact language)
- Outcome: resolved, escalated, or unresolved
- Techniques used: reframe, social proof, concession, redirect, empathy-first

**Closing Patterns:**
- What triggered the close? (urgency event, champion advocacy, competitive pressure, budget cycle)
- Closing language used by the seller
- How the seller handled procurement/legal
- Multi-threading patterns — how many buyer-side contacts were engaged?

### 3. Pattern Aggregation

A synthesis agent collects all analyst outputs and identifies repeating patterns:

- **Top discovery questions** — ranked by frequency of use across won deals and information yield
- **Objection taxonomy** — clustered objections with best-performing responses
- **Closing pattern types** — the 3-5 distinct closing motions that appear across won deals
- **Anti-patterns** — techniques that appeared in lost deals but not won deals (if loss data available)

### 4. Playbook Assembly

Structure the output as an actionable sales playbook:

```
Discovery Framework
───────────────────
Phase 1: Situational (understand current state)
  Q: "{question}" — used in {n} won deals
  Q: "{question}" — used in {n} won deals

Phase 2: Problem (surface pain)
  Q: "{question}" — elicited pain in {n} deals
  ...

Phase 3: Implication (amplify urgency)
  Q: "{question}" — drove urgency in {n} deals
  ...

Objection Handlers
───────────────────
Objection: "{objection}"
  Best response: "{response}"
  Win rate when used: {n}/{total} deals
  Technique: {reframe|social_proof|concession}

Closing Patterns
───────────────────
Pattern: {name}
  Trigger: {what initiates the close}
  Technique: {how the seller executes}
  Deals using this pattern: {n}
  Key quote: "{verbatim}"
```

## Extraction Schema

Uses `schemas/call-extraction.json` with emphasis on:
- `objection_handling` — all entries with full context
- `key_quotes` — quotes that demonstrate technique
- `champion_profile` — champion engagement as a closing factor
- `participants` — multi-threading patterns (number of buyer-side contacts)

Additional extraction beyond the base schema:
- Seller questions (parsed from transcript turns where seller asks a question)
- Sequence analysis (what order were topics addressed?)
- Talk ratio per call stage

## Blueprint Methodology

Blueprint GTM's playbook philosophy: **the best playbook is extracted from your own winning conversations, not copied from a methodology book.**

This module produces:
1. **Rep onboarding material** — new reps study actual winning conversations
2. **Coaching content** — managers use specific question and objection patterns for call reviews
3. **Methodology validation** — does the team's actual winning behavior match the prescribed methodology?
4. **Competitive prep** — objection responses that specifically address competitor comparisons

## Output

`data/{run-id}/playbook-synthesis.json`

```json
{
  "module": "playbook-extraction",
  "run_id": "string",
  "generated_at": "ISO-8601",
  "summary": {
    "deals_analyzed": 0,
    "total_calls_analyzed": 0,
    "discovery_questions_extracted": 0,
    "objection_patterns_found": 0,
    "closing_patterns_found": 0
  },
  "discovery_framework": {
    "situational_questions": [],
    "problem_questions": [],
    "implication_questions": [],
    "top_questions_by_yield": []
  },
  "objection_playbook": [
    {
      "objection_cluster": "string",
      "frequency": 0,
      "best_response": "string",
      "technique": "string",
      "win_rate_when_resolved": 0,
      "key_quotes": []
    }
  ],
  "closing_patterns": [
    {
      "pattern_name": "string",
      "trigger": "string",
      "technique": "string",
      "deals_using": 0,
      "key_quotes": []
    }
  ],
  "anti_patterns": []
}
```
