# Competitive Intelligence

Surface every competitive mention, positioning battle, and displacement pattern across all analyzed calls.

## Required Data

- Any calls with competitive mentions (detected during pattern extraction)
- This module piggybacks on the extraction phase — it does not require separate data
- Works best with a large call corpus (20+ calls) for statistically meaningful patterns

## Agent Pipeline

### 1. Competitive Mention Harvesting

No additional agents needed beyond what classification and extraction produce. The competitive intelligence module operates as a **synthesis-only pass** over existing extractions.

It reads all `competitive_mentions` arrays from every extracted call and aggregates them.

### 2. Synthesis Agent — Competitive Pass

A single synthesis agent runs a competitive-specific analysis:

- **Mention frequency**: How often is each competitor mentioned?
- **Context distribution**: For each competitor, what is the breakdown of `evaluation`, `comparison`, `switching_to`, `switching_from`, `positive`, `negative`?
- **Win/loss correlation**: When a competitor is mentioned, what is the deal outcome?
- **Positioning battles**: What specific dimensions are buyers comparing on? (price, features, support, integration, ease of use)
- **Displacement direction**: Net flow of customers — who is gaining from whom?
- **Verbatim competitive quotes**: The exact language prospects use when comparing

### 3. Competitive Landscape Map

The synthesis agent produces a competitor-by-competitor breakdown:

```
Competitor: {name}
──────────────────────────────
Mentions:        {count} across {n} calls
Win rate when mentioned: {%}
Primary comparison dimensions:
  - {dimension}: {who_wins} ({evidence_count} mentions)
  - {dimension}: {who_wins} ({evidence_count} mentions)
Top quote: "{verbatim}"
```

## Extraction Schema

Reads `competitive_mentions` from `schemas/call-extraction.json`:
- `competitor` — competitor name
- `context` — evaluation, comparison, switching_to, switching_from, positive, negative
- `verbatim_quote` — exact quote

Also cross-references:
- `pain_themes` where `category` = `competitor` — pains attributed to competitive pressure
- `objection_handling` — objections that reference competitors

## Blueprint Methodology

Blueprint GTM treats competitive intelligence not as a static battlecard exercise, but as a **live signal from the market**. The patterns that emerge from actual buyer conversations reveal:

1. **Real competitive dimensions** — not what marketing thinks buyers compare on, but what they actually compare on
2. **Positioning gaps** — where the product is losing the comparison and needs better messaging or features
3. **Displacement opportunities** — competitors whose customers are showing switching signals
4. **Battlecard content** — real quotes and objection-response pairs, not hypothetical talking points

## Output

`data/{run-id}/competitive-synthesis.json`

```json
{
  "module": "competitive-intelligence",
  "run_id": "string",
  "generated_at": "ISO-8601",
  "summary": {
    "total_competitors_identified": 0,
    "total_competitive_mentions": 0,
    "calls_with_competitive_mentions": 0,
    "top_competitors": []
  },
  "competitors": [
    {
      "name": "string",
      "mention_count": 0,
      "context_distribution": {
        "evaluation": 0,
        "comparison": 0,
        "switching_to": 0,
        "switching_from": 0,
        "positive": 0,
        "negative": 0
      },
      "comparison_dimensions": [
        {
          "dimension": "string",
          "who_wins": "string",
          "evidence_count": 0,
          "key_quotes": []
        }
      ],
      "displacement_direction": "gaining|losing|stable",
      "top_quotes": []
    }
  ],
  "positioning_gaps": [],
  "displacement_matrix": {},
  "battlecard_content": []
}
```
