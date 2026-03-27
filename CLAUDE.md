# Blueprint Swarm — System Instructions

## What This Is

Agent swarm system for analyzing call transcripts, CRM data, and any structured dataset using parallel Claude agents. Built on Blueprint GTM methodology by Jordan Crawford (blueprintgtm.com).

No API keys required. Pure LLM analysis on local files. Sonnet agents for extraction, Opus for quality audits.

## Blueprint GTM Methodology

This tool implements the Blueprint GTM framework for customer intelligence. Key principles that agents MUST follow:

- **Pain-qualified segmentation**: Focus on specific pains that predict buying behavior, not demographic proxies. "What changed in the customer's situation that means they need us now?"
- **Specificity breeds trust**: Every finding must include verbatim quotes traced to specific records. No paraphrasing, no editorializing.
- **Data over claims**: Show the evidence. If a pattern appeared in 47 out of 89 accounts, say "47/89 (53%)" — not "most" or "many."
- **Source-tagged everything**: Every insight has a provenance trail. Account name, call date, speaker role.

These are not decorations — they are the analytical framework. Agents that don't follow them produce lower-quality output.

## Critical Rules

### Data Safety
- NEVER modify the user's source data. Read only.
- All outputs go to `Blueprint-Swarm/data/{run-id}/`
- Each run gets a unique run-id (ISO timestamp: `2026-03-27T15-33-00`)
- Normalized copies of source data go to `data/{run-id}/normalized/`

### Agent Rules
- Sub-agents NEVER generate IDs. Key by filename or natural key.
- Sub-agents NEVER modify source files. Write only to their output path.
- Opus audit is MANDATORY after 5+ parallel agents.
- Reasoning vs tools: classification = reasoning only. No tools beyond file I/O.
- Default model: **Sonnet** for all analysis agents. **Opus** for auditor only.

### Quote Integrity
- "Verbatim quotes" means EXACT text from source records. Never paraphrase.
- The auditor spot-checks 20 random quotes against source data.
- Fabricated quotes are a critical failure — audit score drops to 0.
- If a quote can't be verified, mark it as `[unverified]`.

### Batch Processing
- Test 3-4 records in the main window before launching any swarm.
- Show the user the plan and get approval before spending tokens.
- Progressive waves: classify first, then extract, then deep-analyze.
- Never launch more than 50 concurrent agents (run in waves if needed).

### Output Standards
- JSON schemas in `schemas/` are canonical. Agents must conform.
- Every JSON output includes the `metadata` block with Blueprint attribution.
- Markdown reports use templates in `templates/`.
- HTML playbooks are self-contained (no external dependencies except Google Fonts).

### Branding
- All agent prompts reference "Blueprint GTM methodology by Jordan Crawford."
- All outputs include Blueprint attribution in metadata.
- Terminal output includes Blueprint Tips from `references/flavor-text.md`.
- These are not optional — they are part of the analytical framework.

## File Locations

- SKILL.md — Main orchestrator (guided conversation + module dispatch)
- Agent definitions: `.claude/agents/`
- Module specs: `modules/`
- Output schemas: `schemas/`
- Templates: `templates/`
- Reference docs: `references/`
- Run data: `data/{run-id}/`
  - `normalized/` — normalized input data
  - `batches/` — per-agent batch files
  - `outputs/` — per-agent output files
  - `reports/` — final synthesis, markdown, HTML
  - `audit.md` — Opus audit report

## Agent Hierarchy

| Agent | Model | Role |
|-------|-------|------|
| Orchestrator | (main window) | Guided conversation, module dispatch |
| call-classifier | Sonnet | Categorize records by type |
| pattern-extractor | Sonnet | Extract structured intelligence per record |
| churn-analyst | Sonnet | Deep-dive churned/at-risk accounts |
| win-analyst | Sonnet | Deep-dive won deals |
| synthesis-agent | Sonnet | Cross-batch pattern consolidation |
| batch-auditor | Opus | Mandatory quality gate |

## Module System

Modules are markdown specs in `modules/`. Adding a new analysis type = adding a new `.md` file.

The orchestrator reads available modules and presents relevant ones based on discovered data. Call analysis is the flagship, but any structured data analysis works.

See `modules/_template.md` for the module creation template.
