# Blueprint Swarm - Batch Strategy

Token estimation, batching rules, and progressive scaling for large datasets.

## Token Estimates by Data Type

| Data Type | Typical Size | Token Estimate |
|-----------|-------------|----------------|
| Gong call (30 min) | 4,000 - 8,000 tokens | ~6,000 avg |
| Gong call (60 min) | 8,000 - 16,000 tokens | ~12,000 avg |
| Chorus call (30 min) | 4,500 - 9,000 tokens | ~6,500 avg |
| Raw transcript (30 min) | 3,500 - 7,000 tokens | ~5,000 avg |
| PDF transcript (30 min) | 4,000 - 8,000 tokens | ~6,000 avg |
| Salesforce Opportunity row | 150 - 300 tokens | ~200 avg |
| Salesforce Account row | 100 - 250 tokens | ~175 avg |
| HubSpot Deal row | 150 - 350 tokens | ~225 avg |
| Support ticket row | 200 - 500 tokens | ~300 avg |
| Call extraction output | 800 - 2,000 tokens | ~1,200 avg |
| Account extraction output | 1,500 - 4,000 tokens | ~2,500 avg |

### Quick Estimation Formula

```
Total tokens = (num_calls * avg_call_tokens) + (num_crm_rows * avg_row_tokens) + system_prompt_overhead
System prompt overhead = ~3,000 tokens (schema + instructions)
```

## Model Context Limits

| Model | Total Context | Usable After Headroom | Role |
|-------|--------------|----------------------|------|
| Sonnet | 1,000,000 tokens | 800,000 tokens (20% headroom) | Classification, extraction, synthesis |
| Opus | 1,000,000 tokens | 800,000 tokens (20% headroom) | Complex synthesis, final report |
| Haiku | 200,000 tokens | 160,000 tokens (20% headroom) | Quick classification, sorting |

The 20% headroom accounts for:
- System prompt and schema definitions (~3,000 tokens)
- Output generation space (~10-20% of input)
- Safety margin for token count estimation errors

## Batch Sizing Rules

### Classification Phase (~100-200 calls per agent)

Classification is lightweight — the agent reads each call and assigns a type label plus basic metadata. Each call needs ~6,000 tokens of input and produces ~100 tokens of output.

```
Batch size = floor(800,000 / (avg_call_tokens + output_overhead))
           = floor(800,000 / (6,000 + 100))
           = ~131 calls per agent

Conservative target: 100-200 calls per agent depending on call length
```

- Short calls (< 30 min): Up to 200 per batch
- Long calls (> 45 min): Cap at 100 per batch
- Mixed: Default to 130 per batch

### Extraction Phase (~100 calls per agent)

Extraction is heavier — the agent produces detailed structured output per call. Each call needs ~6,000 tokens input and produces ~1,200 tokens of output.

```
Batch size = floor(800,000 / (avg_call_tokens + extraction_output))
           = floor(800,000 / (6,000 + 1,200))
           = ~111 calls per agent

Conservative target: ~100 calls per agent
```

- **Extraction agents receive the full schema** for their output type, consuming ~2,000 additional tokens
- Reduce batch by 10% when CRM data is joined (additional context per call)

### Account Analysis Phase (3-8 accounts per agent)

Account analysis requires reading ALL calls for an account and producing a narrative. Token consumption scales with account call volume.

```
Tokens per account = (num_calls * avg_call_tokens) + account_output (~2,500)
Batch size = floor(800,000 / avg_tokens_per_account)
```

| Calls per Account | Tokens per Account | Accounts per Agent |
|-------------------|-------------------|--------------------|
| 2-5 calls | ~30,000 - 40,000 | 8 accounts |
| 5-15 calls | 40,000 - 100,000 | 5-6 accounts |
| 15-30 calls | 100,000 - 200,000 | 3-4 accounts |
| 30+ calls | 200,000+ | 1-2 accounts |

### Synthesis Phase (all extracted data)

Synthesis agents receive the aggregated extraction outputs, not raw calls. This is much more token-efficient.

```
Synthesis input = num_calls * avg_extraction_output (~1,200 tokens)
1,000 calls → ~1.2M tokens → needs 2 synthesis passes
500 calls → ~600K tokens → fits in single synthesis pass
```

- Under 500 calls: Single synthesis agent per synthesis type
- 500-2,000 calls: Split into regional/segment sub-syntheses, then meta-synthesis
- 2,000+ calls: Progressive reduction (see below)

## Progressive Batching for Large Datasets (10K+ calls)

For datasets exceeding 10,000 calls, use a 4-tier progressive strategy:

### Tier 1: Classification (fan out)
```
10,000 calls ÷ 150 per agent = ~67 classification agents
Output: 10,000 classified call records (~100 tokens each = 1M tokens)
```

### Tier 2: Extraction (fan out)
```
10,000 calls ÷ 100 per agent = ~100 extraction agents
Output: 10,000 extraction records (~1,200 tokens each = 12M tokens)
```

### Tier 3: Intermediate Synthesis (reduce)
Split extractions into logical groups (by account, segment, time period):
```
12M tokens ÷ 600K usable per agent = ~20 intermediate synthesis agents
Each produces a sub-synthesis (~3,000 tokens)
Output: 20 sub-syntheses = ~60K tokens
```

### Tier 4: Final Synthesis (single agent)
```
60K tokens of sub-syntheses → single Opus agent
Produces final synthesis reports
```

### Progressive Reduction Schedule

| Dataset Size | Classification Agents | Extraction Agents | Intermediate Synth | Final Synth |
|-------------|----------------------|-------------------|--------------------|-------------|
| 100 calls | 1 | 1 | 0 (direct) | 1 |
| 500 calls | 3-4 | 5 | 0 (direct) | 1 |
| 1,000 calls | 7-8 | 10 | 2-3 | 1 |
| 5,000 calls | 35 | 50 | 10 | 1 |
| 10,000 calls | 67 | 100 | 20 | 1 |
| 50,000 calls | 335 | 500 | 100 → 5 | 1 |

## Wall Clock Estimates (with Auto-Resume Watchdog)

The Progressive Reduction Schedule above shows TOTAL agents needed. This section shows realistic wall clock time including rate limit pauses.

Claude Code rate limits use a 5-hour rolling window. The watchdog script (`scripts/swarm-watchdog.sh`) auto-resumes after each rate limit pause, enabling fully unattended overnight execution.

| Dataset Size | Total Agents | Rate Limit Pauses | Est. Wall Clock | Overnight? |
|-------------|-------------|-------------------|----------------|:----------:|
| 100 calls | 3-5 | 0 | ~15 min | No need |
| 500 calls | 10-15 | 0-1 | 1-2 hours | No need |
| 1,000 calls | 20-25 | 1-2 | 3-6 hours | Optional |
| 5,000 calls | 50-70 | 3-5 | 15-25 hours | Yes |
| 10,000 calls | 100-120 | 6-8 | 30-40 hours | Yes |
| 50,000 calls | 440+ | 25+ | 5-7 days | Yes |

**Rule of thumb**: Start before bed for datasets up to ~5K calls. Expect results by morning.

### Wave Execution Model

Agents launch in waves of 3 (rate limit pool is shared between agents and orchestrator):

```
Session 1 (runs until rate limited):
  Wave 1: classify-001, classify-002, classify-003  → ~7 min
  Wave 2: classify-004, extract-001, extract-002    → ~7 min
  Wave 3: extract-003, extract-004, extract-005     → ~7 min
  ...
  Wave N: [rate limited] → state saved, watchdog waits for reset

  ⏸ Rate limit pause (~5 hours)

Session 2 (auto-resumed by watchdog):
  Wave N+1: extract-006, extract-007, extract-008   → ~7 min
  ...continues until done or rate-limited again...
```

### Adjusting for Your Plan Tier

The default wave size of 3 works for all plan tiers. If you're on a higher tier with more generous limits, you can experiment with wave size 4-5 by modifying `wave_size` in `state.json`. Reduce to 2 if experiencing frequent timeouts.

## Format Hierarchy for Token Efficiency

When space is tight, compress data using these formats (most to least efficient):

### 1. Markdown Tables (most efficient)
Best for: CRM data, account lists, classification results
```
| Account | Stage | Amount | Close |
|---------|-------|--------|-------|
| Acme | Closed Won | $50K | 2025-03 |
```
Token savings: ~60% vs raw CSV with headers

### 2. Compressed Markdown
Best for: Extraction summaries, intermediate results
```
**Acme Corp** (Churned, $50K ARR)
- Pain: Missing API integration (critical), slow support response (high)
- Champion: Jane Doe (VP Eng) — disengaged after Q2
- Competitor: Competitor X mentioned 3x (switching_to)
```
Token savings: ~40% vs full JSON extraction output

### 3. Filtered JSON
Best for: Passing structured data between agents when schema compliance matters
- Strip null fields
- Remove empty arrays
- Collapse single-item arrays to values
- Use short keys where the schema is known

Token savings: ~25% vs pretty-printed JSON

### 4. Raw CSV (least efficient in context)
Only use when: The agent needs to perform its own column detection/mapping
- Include header row
- Strip empty columns
- Limit to relevant columns (never pass 50+ column CRM exports raw)

## Batching Decision Tree

```
1. Count total calls and CRM rows
2. Estimate total tokens
3. IF total_tokens < 600K:
     → Single-agent mode (no batching needed)
4. IF total_tokens < 5M:
     → Standard batching (classification → extraction → synthesis)
5. IF total_tokens < 50M:
     → Progressive batching with intermediate synthesis
6. IF total_tokens > 50M:
     → Progressive batching with 2-level reduction
     → Consider sampling strategy (analyze 20% representative sample first)
7. Calculate wall clock estimate:
     total_agents = classification_agents + extraction_agents + synth_agents + 1 (auditor)
     rate_limit_pauses = floor(total_agents / 15)  (rough estimate)
     wall_hours = (total_agents * 7 / 60) + (rate_limit_pauses * 5)
     → Report to user: "This will take approximately {wall_hours} hours.
        Recommend starting the watchdog for overnight execution."
```

## Sampling Strategy for Massive Datasets

When datasets exceed 50,000 calls:

1. **Classify all** — Classification is cheap, always do 100%
2. **Extract a stratified sample** — Select calls proportionally across:
   - Call types (discovery, demo, churn exit, etc.)
   - Time periods (even distribution)
   - Accounts (at least 2 calls per account in sample)
   - Outcomes (proportional won/lost/churned)
3. **Extract remaining on demand** — If synthesis reveals gaps, extract targeted additional calls
4. **Report sample size and confidence** — Always disclose the sample percentage in outputs

Minimum viable sample sizes:
- Churn analysis: 80% of churned account calls (churn is rare, need full coverage)
- Win/loss: 50% of won + 50% of lost (balanced)
- Competitive: 100% of calls with competitor mentions (pre-filtered in classification)
- Product gaps: 70% of support/escalation calls + 30% of churned
- Playbook: 40% of discovery + 40% of demo calls (high volume, patterns emerge fast)
