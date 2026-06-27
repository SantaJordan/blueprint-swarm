# Win Pattern Analysis

Pain-qualified segmentation — specific pains that predict buying, **named by the buyer, not pitched by the rep.**

## Speaker Attribution (Phase 0 — REQUIRED before this module)

This is the heart of the customer-voice work, so **Phase 0 (Speaker Attribution) must complete before any win analyst fans out.** See `references/speaker-attribution-protocol.md`. The win factor MUST be the buyer's unprompted pain, not the rep's value pitch: "wouldn't multi-warehouse sync help?" → "sure" is `led`; a buyer repeating the rep's "all-in-one platform" line is `seller_echo`, excluded. The "aha moment" must be a `role == customer` turn. Analysts read the role-tagged transcript and elicitation-graded customer statements from `data/{run-id}/attribution/` — never a raw blob.

## Required Data

- Calls classified as `discovery`, `demo`, `negotiation`, `closing` on won deals
- **Speaker-attributed** (Phase 0 artifacts present): roster + role-tagged turns + elicitation-graded customer statements
- Minimum: 5 closed-won deal cycles for meaningful pattern detection
- Ideal: full deal arc (discovery through closing) for each won deal
- Optional: CRM data with deal size, sales cycle length, close date

## Agent Pipeline

### 1. Deal Grouping

Group calls by deal/account to reconstruct full deal arcs. Each deal should have:
- A chronological sequence of calls
- Identified buyer participants across calls
- Deal outcome confirmation (closed-won)

If deal grouping is ambiguous, the agent uses account name + date proximity to cluster.

### 2. Dispatch Win Analysts (Agent Swarm)

Fan out one agent per deal group (batch size: 2-3 deals per agent, since full-arc analysis requires deep reading).

Each analyst extracts, **customer-only and weighted by elicitation** (the win-analyst agent embeds the full attribution contract):

- **Win factors**: What specifically caused the buyer to choose this vendor — as the BUYER articulated it **unprompted**? Rep-led or rep-echoed "wins" are listed separately, never counted.
- **Pain-to-value narrative**: What pain did the *customer* articulate (unprompted), and how did it map to the product's value? The value claims the rep made are seller framing, kept distinct.
- **Champion profile**: Who was the internal champion (a `role == customer` person)? What made them effective?
- **Decision process**: Who else was involved? What was the evaluation criteria?
- **Objection patterns**: What objections arose and how were they resolved? (Objections = customer turns; rep responses = seller context.)
- **Competitive positioning**: How was the product positioned against alternatives? (Rep positioning is context; a competitor counts as a buyer signal only when the customer raised it.)
- **Closing triggers**: What moment or event — in a customer turn — accelerated the close?
- **Discovery quality**: What questions (seller context) elicited the most useful information? The *answers* that count as buyer pain must be `role == customer`.

### 3. Audit Pass

Auditor reviews all analyst outputs for:
- Win factor consistency — are the same factors appearing across deals?
- **Attribution integrity** — no `company`/`unknown` turn used as a win factor, no `led` "win" presented as a buying driver, no `seller_echo` pitch-line counted as buyer demand, the aha moment is a customer turn, every quote carries `{ speaker, role, elicitation }` (see batch-auditor point 8)
- Champion archetype validation — do champion profiles cluster into types?
- Quote quality — are the strongest quotes actually representative customer (not rep) voice?
- Missing patterns visible only in cross-deal comparison

### 4. Synthesis

The synthesis agent produces:

- **Win factor taxonomy** — ranked by frequency and deal size correlation
- **Pain-to-value map** — which pains predict buying, and what value messaging resonates
- **Champion archetypes** — the 2-3 types of internal champions who drive deals
- **Ideal deal arc** — the sequence of interactions that correlates with winning
- **Objection handling playbook** — proven responses to common objections
- **Competitive positioning guide** — what works when positioned against specific competitors

## Extraction Schema

Uses `schemas/call-extraction.json` with emphasis on:
- `pain_themes` — all severities, especially `critical` and `high`, evidenced by `role == customer` quotes (ideally `unprompted`)
- `champion_profile` — full profile with `engagement_level` = `high` (a `role == customer` person)
- `objection_handling` — all entries, especially `outcome` = `resolved` (objection = customer turn; response = seller context)
- `competitive_mentions` — all contexts, flagged by who raised the competitor
- `key_quotes` — highest-signal **customer** quotes that capture the "why they bought" moment, each carrying `{ speaker, role, elicitation }`

## Blueprint Methodology

This is the heart of Blueprint GTM: **the best GTM strategy comes from understanding why customers actually bought, not why you think they bought.**

Win pattern analysis produces:
1. **PVPs (Personalized Value Propositions)** — pain-specific messaging derived from actual buyer language
2. **ICP refinement** — the pain profiles that predict buying become the ICP definition
3. **Sales enablement** — real quotes and patterns that new reps can study
4. **Marketing messaging** — the exact language buyers use to describe their problems

## Output

`data/{run-id}/wonlost-synthesis.json`

```json
{
  "module": "win-pattern-analysis",
  "run_id": "string",
  "generated_at": "ISO-8601",
  "summary": {
    "total_won_deals_analyzed": 0,
    "total_calls_analyzed": 0,
    "avg_deal_arc_calls": 0,
    "top_win_factors": [],
    "top_pain_themes": []
  },
  "deals": [
    {
      "account_name": "string",
      "deal_arc": [],
      "win_factors": [],
      "champion": {},
      "pain_to_value": [],
      "objections_resolved": [],
      "closing_trigger": "string",
      "key_quotes": []
    }
  ],
  "patterns": {
    "win_factors_ranked": [],
    "pain_to_value_map": [],
    "champion_archetypes": [],
    "ideal_deal_arc": [],
    "objection_playbook": [],
    "competitive_positioning": []
  }
}
```
