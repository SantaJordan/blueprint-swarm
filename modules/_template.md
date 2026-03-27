# Module Name

One-line Blueprint framing — the insight this module delivers.

## Required Data

What data types does this module need?

- List the call classifications, file formats, or external data required
- Specify minimums (e.g., "Minimum: 5 calls for meaningful patterns")
- Note optional data that enriches the output
- Note dependencies on other modules (if any)

## Agent Pipeline

### 1. {First Stage Name}

What happens first? Typically filtering, grouping, or classification.

- Describe the input
- Describe the processing logic
- Describe the output passed to the next stage

### 2. Dispatch {Analyst Type} (Agent Swarm)

Fan out agents for parallel processing.

- Batch size: {n} items per agent
- What each agent extracts (reference schema fields)
- Quality criteria for agent output

### 3. Audit Pass

How is agent output validated?

- Consistency checks
- Quote accuracy verification
- Cross-item pattern detection

### 4. Synthesis

How are individual extractions aggregated?

- What patterns are identified?
- How are findings ranked?
- What is the final structure?

## Extraction Schema

Reference the schema file in `schemas/` and specify which fields this module emphasizes.

- Primary fields: `{field}` — why this field matters for this module
- Secondary fields: `{field}` — supporting context
- Cross-references: what other module outputs does this read?

## Blueprint Methodology

How does this module connect to Blueprint GTM principles?

- What GTM insight does it produce?
- How does the output inform sales, marketing, CS, or product teams?
- What is the "so what" — why does this analysis matter?

## Output

`data/{run-id}/{output-filename}.json`

```json
{
  "module": "module-name",
  "run_id": "string",
  "generated_at": "ISO-8601",
  "summary": {},
  "items": [],
  "patterns": {}
}
```
