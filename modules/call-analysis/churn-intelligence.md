# Churn Intelligence

Warning signals — the moments where intervention could have saved the account.

## Required Data

- Calls classified as `churn_exit`, `support`, `renewal`, `escalation`
- Minimum: 5 churn-relevant calls for meaningful pattern detection
- Optional: CRM data with contract dates, ARR, renewal status

## Agent Pipeline

### 1. Classification Agent (if not pre-classified)

Filter the normalized call set for churn-relevant calls. Signals:
- Explicit churn language ("canceling", "not renewing", "switching to")
- Support escalation patterns (repeated issues, frustration markers)
- Renewal calls with declining engagement
- Any call with `sentiment_trajectory: declining`

### 2. Churn Grouping

Group churn-relevant calls by account. Build an account timeline:

```
Account: {name}
──────────────────────────
{date}  support     Reported integration failure (3rd time)
{date}  escalation  Demanded VP-level response
{date}  renewal     "We're evaluating alternatives"
{date}  churn_exit  Confirmed switch to {competitor}
```

### 3. Dispatch Churn Analysts (Agent Swarm)

Fan out one agent per account group (batch size: 3-5 accounts per agent).

Each analyst extracts per the `call-extraction.json` schema with churn-specific focus:

- **Churn reasons**: What specifically drove the decision? (product gap, service failure, pricing, competitor)
- **Warning signals**: What early signs appeared before the churn decision was made?
- **Intervention points**: Where could the seller have changed the outcome?
- **Timeline to churn**: How long from first warning signal to cancellation?
- **Competitor displacement**: Who did they switch to, and why?
- **Champion erosion**: Did the champion disengage before churn? What caused it?

### 4. Audit Pass

A single auditor agent reviews all analyst outputs for:
- Consistency of churn reason categorization across accounts
- Quote accuracy (spot-check verbatim quotes against source transcripts)
- Missing patterns that individual analysts may not have caught
- Cross-account signal correlation

### 5. Synthesis

The synthesis agent aggregates all audited extractions into a unified churn intelligence report:

- **Top churn reasons** ranked by frequency and revenue impact
- **Warning signal taxonomy** — the recurring early indicators
- **Intervention playbook** — what actions at what stage could have saved the account
- **Time-to-churn analysis** — average window between first signal and cancellation
- **Competitor displacement matrix** — who is winning accounts and on what dimensions

## Extraction Schema

Uses `schemas/call-extraction.json` with emphasis on:
- `pain_themes` where `category` is `product_gap` or `service_failure`
- `competitive_mentions` where `context` is `switching_to`
- `sentiment_trajectory` = `declining`
- `champion_profile` with `engagement_level` = `disengaged`

## Blueprint Methodology

This module operationalizes Blueprint GTM's core principle: **pain-qualified segmentation**. Instead of demographic segments, churn intelligence reveals the specific pains that predict account loss. These become:

1. **Red flag signals** for the CS team to monitor
2. **Qualification criteria** — if a prospect has the same pain profile as churned accounts, the sales team needs a different approach
3. **Product roadmap inputs** — when churn clusters around product gaps, that is product strategy data, not just CS data

## Output

`data/{run-id}/churn-synthesis.json`

```json
{
  "module": "churn-intelligence",
  "run_id": "string",
  "generated_at": "ISO-8601",
  "summary": {
    "total_churn_calls_analyzed": 0,
    "accounts_analyzed": 0,
    "top_churn_reasons": [],
    "warning_signal_taxonomy": [],
    "avg_time_to_churn_days": 0
  },
  "accounts": [
    {
      "account_name": "string",
      "churn_reason": "string",
      "warning_signals": [],
      "intervention_points": [],
      "competitor_displaced_by": "string",
      "timeline": [],
      "key_quotes": []
    }
  ],
  "patterns": {
    "churn_reasons_ranked": [],
    "warning_signals_ranked": [],
    "competitor_displacement_matrix": {},
    "intervention_playbook": []
  }
}
```
