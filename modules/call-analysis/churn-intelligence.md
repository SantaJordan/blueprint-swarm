# Churn Intelligence

Warning signals — the moments where intervention could have saved the account — **in the customer's own unprompted words.**

## Speaker Attribution (Phase 0 — REQUIRED before this module)

This is a customer-voice module, so **Phase 0 (Speaker Attribution) must complete before any churn analyst fans out.** See `references/speaker-attribution-protocol.md`. The churn reason MUST be the customer's, not the seller's: a rep asking "is pricing a concern?" and getting "a little" is `led`, not a churn driver; a buyer parroting the rep's pitch is `seller_echo`, excluded. Analysts read the role-tagged transcript (`role = company | customer | unknown`) and the `customer_statements` (`elicitation = unprompted | led | seller_echo`) from `data/{run-id}/attribution/` — never a raw blob. **A churn reason built on a seller or unknown turn is invalid.**

## Required Data

- Calls classified as `churn_exit`, `support`, `renewal`, `escalation`
- **Speaker-attributed** (Phase 0 artifacts present): roster + role-tagged turns + elicitation-graded customer statements
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

Each analyst extracts per the `call-extraction.json` schema with churn-specific focus, **customer-only and weighted by elicitation** (the churn-analyst agent embeds the full attribution contract):

- **Churn reasons**: What specifically drove the decision, as the CUSTOMER said it **unprompted** (product gap, service failure, pricing, competitor)? Rep-led or rep-echoed concerns are listed separately, not counted as reasons.
- **Warning signals**: What early signs appeared in customer turns before the churn decision was made?
- **Intervention points**: Where could the seller have changed the outcome?
- **Timeline to churn**: How long from first (customer-voiced) warning signal to cancellation?
- **Competitor displacement**: Who did they switch to, and why — counted only when the *customer* raised the competitor (a rep-introduced name is led)?
- **Champion erosion**: Did the champion (a `role == customer` person) disengage before churn? What caused it?
- **Seller framing observed**: what the rep pitched/repeated — context only, never a churn reason.

### 4. Audit Pass

A single auditor agent reviews all analyst outputs for:
- Consistency of churn reason categorization across accounts
- Quote accuracy (spot-check verbatim quotes against source transcripts)
- **Attribution integrity** — no `company`/`unknown` turn used as a churn reason, no `led` concern presented as discovered demand, no `seller_echo` line counted, every customer quote carries `{ speaker, role, elicitation }` (see batch-auditor point 8)
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
- `pain_themes` where `category` is `product_gap` or `service_failure` — evidenced by `role == customer` quotes, ideally `elicitation == unprompted`
- `competitive_mentions` where `context` is `switching_to` — counted only when the customer raised the competitor
- `sentiment_trajectory` = `declining` (read from customer turns)
- `champion_profile` with `engagement_level` = `disengaged` (a `role == customer` person)

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
