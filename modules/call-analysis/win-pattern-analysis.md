# Win Pattern Analysis

Pain-qualified segmentation — specific pains that predict buying.

## Required Data

- Calls classified as `discovery`, `demo`, `negotiation`, `closing` on won deals
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

Each analyst extracts:

- **Win factors**: What specifically caused the buyer to choose this vendor?
- **Pain-to-value narrative**: What pain was articulated, and how did it map to the product's value?
- **Champion profile**: Who was the internal champion? What made them effective?
- **Decision process**: Who else was involved? What was the evaluation criteria?
- **Objection patterns**: What objections arose and how were they resolved?
- **Competitive positioning**: How was the product positioned against alternatives?
- **Closing triggers**: What moment or event accelerated the close?
- **Discovery quality**: What questions elicited the most useful information?

### 3. Audit Pass

Auditor reviews all analyst outputs for:
- Win factor consistency — are the same factors appearing across deals?
- Champion archetype validation — do champion profiles cluster into types?
- Quote quality — are the strongest quotes actually representative?
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
- `pain_themes` — all severities, especially `critical` and `high`
- `champion_profile` — full profile with `engagement_level` = `high`
- `objection_handling` — all entries, especially `outcome` = `resolved`
- `competitive_mentions` — all contexts
- `key_quotes` — highest signal quotes that capture the "why they bought" moment

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
