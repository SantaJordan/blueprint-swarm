# Account Health

Per-account health scoring that synthesizes signals from all other modules into an actionable account-level view.

## Required Data

- Any account-level data (calls, support tickets, CRM records)
- Works with call transcripts alone, but richer with CRM data
- **Runs after other modules complete** — benefits from existing signal definitions in churn, win, and competitive syntheses

## Dependency Chain

This module is designed to run last. It reads outputs from:
- `churn-synthesis.json` — warning signal taxonomy, churn reasons
- `wonlost-synthesis.json` — win factor patterns, champion archetypes
- `competitive-synthesis.json` — competitor displacement signals
- `product-synthesis.json` — product gaps by account

If these files do not exist, account health still runs but produces a reduced scoring model based only on raw call data.

## Agent Pipeline

### 1. Account Inventory

Build the complete list of accounts from all data sources:
- Accounts mentioned in call transcripts
- Accounts in CRM exports (if available)
- Accounts referenced in support data

Deduplicate across sources (fuzzy match on company name).

### 2. Per-Account Signal Collection

For each account, collect all available signals:

| Signal | Source | Weight |
|--------|--------|--------|
| Sentiment trajectory | Call extractions | High |
| Champion engagement | Call extractions | High |
| Support velocity | Support calls (count, trend) | Medium |
| Competitive mentions | Competitive synthesis | High |
| Product gap exposure | Product synthesis | Medium |
| Contract proximity | CRM data (if available) | High |
| Interaction recency | Last call/meeting date | Medium |
| Multi-threading depth | Number of buyer contacts engaged | Medium |

### 3. Dispatch Account Scorers (Agent Swarm)

Fan out one agent per account batch (batch size: 5-8 accounts per agent).

Each scorer produces a health card:

```
Account Health: {name}
──────────────────────────────
Score:       {0-100} ({HEALTHY|AT_RISK|CRITICAL})
Trend:       {improving|stable|declining}

Sentiment:   {score} — {one-line summary}
Champion:    {name} — {engagement_level}
Support:     {velocity_trend} ({n} calls in {period})
Competitive: {mentions} — {displacement_risk}
Product:     {gaps_affecting_account}
Contract:    {days_to_renewal} days
Last touch:  {date} ({days_ago} days ago)

Risk factors:
  - {factor_1}
  - {factor_2}

Recommended actions:
  - {action_1}
  - {action_2}
```

### 4. Portfolio Synthesis

Aggregate all account health cards into a portfolio view:

- **Health distribution**: How many accounts are healthy, at-risk, critical?
- **Trend analysis**: Is the portfolio improving or declining overall?
- **Cluster analysis**: Do at-risk accounts share common risk factors?
- **Priority queue**: Ranked list of accounts needing immediate attention
- **Leading indicators**: Which signals are most predictive of churn (validated against actual churn data if available)?

## Scoring Model

### Score Calculation (0-100)

Each signal contributes to the composite score:

| Signal | Max Points | Scoring Logic |
|--------|-----------|---------------|
| Sentiment | 25 | improving=25, stable=15, declining=5, volatile=10 |
| Champion | 20 | high=20, medium=12, low=5, disengaged=0 |
| Support velocity | 15 | decreasing=15, stable=10, increasing=3 |
| Competitive risk | 15 | no_mentions=15, evaluation=8, switching_to=0 |
| Product gaps | 10 | no_critical=10, has_critical=2 |
| Interaction recency | 10 | <14d=10, <30d=7, <60d=4, >60d=1 |
| Multi-threading | 5 | 3+ contacts=5, 2=3, 1=1 |

### Risk Tiers

- **HEALTHY** (70-100): No immediate action needed
- **AT_RISK** (40-69): Proactive outreach recommended
- **CRITICAL** (0-39): Immediate intervention required

## Blueprint Methodology

Account health scoring is the operational layer of Blueprint GTM. It takes all the intelligence gathered from calls, competitive analysis, and product gaps and converts it into **a daily action list for the CS and sales team**.

The key insight: account health is not a single metric. It is a collection of signals that, when viewed together, tell a story. The narrative matters more than the number.

## Output

`data/{run-id}/account-health.json`

```json
{
  "module": "account-health",
  "run_id": "string",
  "generated_at": "ISO-8601",
  "summary": {
    "total_accounts_scored": 0,
    "healthy": 0,
    "at_risk": 0,
    "critical": 0,
    "portfolio_trend": "improving|stable|declining",
    "top_risk_factors": []
  },
  "accounts": [
    {
      "account_name": "string",
      "score": 0,
      "tier": "healthy|at_risk|critical",
      "trend": "improving|stable|declining",
      "signals": {
        "sentiment": {},
        "champion": {},
        "support_velocity": {},
        "competitive_risk": {},
        "product_gaps": [],
        "interaction_recency": {},
        "multi_threading": {}
      },
      "risk_factors": [],
      "recommended_actions": [],
      "key_quotes": []
    }
  ],
  "portfolio_analysis": {
    "health_distribution": {},
    "common_risk_factors": [],
    "priority_queue": [],
    "leading_indicators": []
  }
}
```
