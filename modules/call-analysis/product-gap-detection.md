# Product Gap Detection

Cross-reference churn intelligence with support patterns to surface the product gaps that are costing accounts.

## Required Data

- Calls classified as `churn_exit`, `support`, `escalation`
- Calls with `pain_themes` where `category` = `product_gap`
- Works best when churn intelligence module has already run (uses its outputs)
- Minimum: 10 support/churn calls for meaningful gap clustering

## Agent Pipeline

### 1. Product Gap Harvesting

Collect all product-gap signals from two sources:

**Source A — Direct extraction:**
- All `pain_themes` where `category` = `product_gap` from any call type
- All `objection_handling` entries where the objection references missing features
- Support calls with repeated issues (same account, same topic)

**Source B — Churn intelligence cross-reference:**
- If `churn-synthesis.json` exists, read `churn_reasons_ranked` for product-gap entries
- Map churned accounts back to their support history for pre-churn gap signals

### 2. Gap Clustering Agent

A single agent clusters all product gap mentions into distinct gaps:

- **Deduplication**: "Can't export to PDF" and "no PDF export" and "we need PDF output" are the same gap
- **Severity scoring**: Based on mention frequency, account revenue impact, and churn correlation
- **Category assignment**: Feature request, integration gap, performance issue, UX friction, platform limitation

### 3. Impact Analysis

For each clustered gap, assess:

- **Revenue at risk**: How many accounts mention this gap, and what is their combined ARR?
- **Churn correlation**: What percentage of churned accounts cited this gap?
- **Support burden**: How many support calls does this gap generate?
- **Competitive dimension**: Do competitors solve this gap? (cross-reference competitive intelligence)
- **Workaround existence**: Are customers working around it, or is it a blocker?

### 4. Synthesis

Produce a prioritized product gap report:

```
Product Gap: {name}
──────────────────────────────
Severity:    CRITICAL | HIGH | MEDIUM | LOW
Mentions:    {count} across {n} accounts
Churn link:  {x}% of churned accounts cited this
Revenue risk: ${amount} ARR affected
Competitor:  {name} solves this
Quote:       "{verbatim}"
```

## Extraction Schema

Reads from `schemas/call-extraction.json`:
- `pain_themes` — filtered to `category: product_gap`
- `objection_handling` — objections about missing features
- `competitive_mentions` — where competitors are winning on product capabilities

Cross-references:
- `churn-synthesis.json` — churn reasons and warning signals
- `competitive-synthesis.json` — competitor comparison dimensions

## Blueprint Methodology

Product gap detection bridges GTM intelligence and product strategy. Blueprint GTM's stance: **the product roadmap should be informed by patterns in customer conversations, not just feature request tickets.**

This module produces:
1. **Prioritized gap list** — ranked by revenue impact, not vote count
2. **Churn prevention inputs** — gaps that correlate with churn get escalated
3. **Competitive response priorities** — gaps where competitors are winning become urgent
4. **Customer evidence packages** — verbatim quotes that product teams can use to understand the "why"

## Output

`data/{run-id}/product-synthesis.json`

```json
{
  "module": "product-gap-detection",
  "run_id": "string",
  "generated_at": "ISO-8601",
  "summary": {
    "total_gaps_identified": 0,
    "critical_gaps": 0,
    "total_accounts_affected": 0,
    "estimated_revenue_at_risk": "string"
  },
  "gaps": [
    {
      "gap_name": "string",
      "category": "feature_request|integration|performance|ux|platform",
      "severity": "critical|high|medium|low",
      "mention_count": 0,
      "accounts_affected": [],
      "churn_correlation_pct": 0,
      "support_call_count": 0,
      "competitor_solves": [],
      "workaround_exists": false,
      "key_quotes": [],
      "revenue_at_risk": "string"
    }
  ],
  "recommendations": [
    {
      "gap_name": "string",
      "action": "string",
      "priority": "string",
      "rationale": "string"
    }
  ]
}
```
