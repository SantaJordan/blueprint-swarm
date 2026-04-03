```
  ██████╗ ██╗     ██╗   ██╗███████╗██████╗ ██████╗ ██╗███╗   ██╗████████╗
  ██╔══██╗██║     ██║   ██║██╔════╝██╔══██╗██╔══██╗██║████╗  ██║╚══██╔══╝
  ██████╔╝██║     ██║   ██║█████╗  ██████╔╝██████╔╝██║██╔██╗ ██║   ██║
  ██╔══██╗██║     ██║   ██║██╔══╝  ██╔═══╝ ██╔══██╗██║██║╚██╗██║   ██║
  ██████╔╝███████╗╚██████╔╝███████╗██║     ██║  ██║██║██║ ╚████║   ██║
  ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝

         ███████╗██╗    ██╗ █████╗ ██████╗ ███╗   ███╗
         ██╔════╝██║    ██║██╔══██╗██╔══██╗████╗ ████║
         ███████╗██║ █╗ ██║███████║██████╔╝██╔████╔██║
         ╚════██║██║███╗██║██╔══██║██╔══██╗██║╚██╔╝██║
         ███████║╚███╔███╔╝██║  ██║██║  ██║██║ ╚═╝ ██║
         ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝
  ─────────────────────────────────────────────────────────────────────────
  Every call analyzed. Every pattern surfaced. Every quote sourced.
```

**Your customers already told you why they buy and churn. You just weren't listening at scale.**

Blueprint Swarm launches a swarm of Claude agents to analyze your data in parallel. Each agent reads a batch of records. A synthesis agent finds the patterns no single analyst could. Every insight is source-tagged — traced back to a specific call, account, or record.

No API keys. No database. Just your data and Claude Code.

## Quick Start

```bash
# 1. Put your data in a directory (transcripts, CRM exports, anything)
# 2. Open Claude Code in this repo
# 3. Run:

/blueprint-swarm /path/to/your/data

# 4. Answer 2-3 questions about what you want to learn
# 5. Watch agents analyze your data
# 6. Get your intelligence report
```

## What It Analyzes

| Module | What It Does | Required Data |
|--------|-------------|---------------|
| **Churn Intelligence** | Why customers leave, warning signals, preventable churn | Call transcripts (churn/support) |
| **Win Pattern Analysis** | What makes deals close, champion profiles, pain themes | Call transcripts (won deals) |
| **Competitive Intelligence** | Who's mentioned, win/loss by competitor | Any calls with competitor mentions |
| **Product Gap Detection** | Product issues driving churn or blocking deals | Churn + support data |
| **Playbook Extraction** | Best discovery questions, objection handlers | Won deal transcripts |
| **Account Health** | Per-account risk scoring | Any account-level data |

Call analysis is the flagship, but the engine works with any structured data — support tickets, CRM exports, survey responses, whatever you've got.

## Data Formats Supported

| Format | Source | Auto-Detected |
|--------|--------|:------------:|
| Gong JSON | Gong export | Yes |
| Chorus JSON | Chorus export | Yes |
| Raw transcripts (.txt, .md) | Any | Yes |
| PDF transcripts | Meeting notes | Yes |
| Salesforce CSV | SFDC export | Yes |
| HubSpot CSV | HubSpot export | Yes |
| Support tickets CSV | Zendesk, Intercom, etc. | Yes |
| Generic CSV | Any CRM | Yes |

The data discovery phase auto-detects your format and normalizes everything before analysis.

## How It Works

```
You: /blueprint-swarm ./my-gong-export/

  Phase 1: DISCOVER — Scan your data, profile each source
  Phase 2: FOCUS   — Ask what you care about (churn? wins? all?)
  Phase 3: TEST    — Validate approach on 3-4 sample records
  Phase 4: SWARM   — Launch agents in waves of 3, auto-resume through rate limits
  Phase 5: REPORT  — Synthesize findings, generate outputs

Output: JSON synthesis + Markdown report + Interactive HTML playbook
```

## What You'll See

```
Swarm: Churn Intelligence
═══════════════════════════════════════════════════════════════
  scout-alpha   ████████████  done   Accts A-F     14 signals
  scout-bravo   ██████████░░   83%   Accts G-M     processing
  scout-charlie ████████████  done   Accts N-S     11 signals
  scout-delta   ████████░░░░   67%   Accts T-Z     processing
  auditor       ░░░░░░░░░░░░  wait   (blocked)
───────────────────────────────────────────────────────────────
  2/4 done  |  4m elapsed  |  ~3m left  |  25 signals so far
═══════════════════════════════════════════════════════════════

  ─── Blueprint Tip ──────────────────────────────────────────
  "Specificity breeds trust. Generalities breed skepticism."
  — Jordan Crawford, Blueprint GTM  |  blueprintgtm.com
```

## Overnight Mode

For large datasets, Blueprint Swarm runs unattended through rate limits:

```bash
# 1. Start in tmux
tmux new -s swarm

# 2. Run the swarm
/blueprint-swarm /path/to/data

# 3. Accept the watchdog when prompted
#    It'll auto-resume after rate limit pauses

# 4. Walk away. Come back to results.
```

The swarm runs waves of 3 agents continuously. When it hits Claude Code's rate limit (~5hr rolling window), the watchdog waits for the reset and auto-resumes. State is saved after every wave — nothing is lost.

Check progress anytime:
```bash
cat data/*/state.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"agents_completed_total\"]}/{d[\"total_batches\"]} done ({d[\"status\"]})')"
```

If you need to stop and resume later, just exit and re-run `/blueprint-swarm` — it'll detect the existing state and offer to resume.

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) CLI
- `tmux` recommended for visible agent execution and overnight mode (`brew install tmux`)
- Agent Teams enabled: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings (optional — degrades to plain sub-agents)
- Your data in a local directory

No API keys. No external services. Pure LLM reasoning on your files.

## Outputs

Every run produces three artifacts:

1. **JSON synthesis** — Machine-readable, structured findings. Feed into dashboards, automations, or further analysis.
2. **Markdown report** — Human-readable, shareable via Slack or email. Every finding has confidence level and source quotes.
3. **HTML playbook** — Interactive dark-mode report with tabbed navigation, searchable quote explorer, and Blueprint branding.

## Adding Custom Modules

Blueprint Swarm is extensible. To add a new analysis type:

1. Copy `modules/_template.md`
2. Define: required data, agent pipeline, extraction schema, output format
3. Drop it in `modules/`
4. The orchestrator auto-detects it on the next run

## Architecture

```
Blueprint-Swarm/
├── SKILL.md                 # Orchestrator (guided conversation + dispatch)
├── CLAUDE.md                # System instructions
├── .claude/agents/          # 6 agent definitions (Sonnet + Opus)
├── hooks/                   # StopFailure hook for rate limit state saving
├── scripts/                 # Watchdog for auto-resume after rate limits
├── modules/                 # Analysis modules (call-analysis/ + extensible)
├── schemas/                 # JSON output contracts
├── templates/               # Markdown + HTML report templates
├── references/              # Data formats, batch strategy, rate limit protocol
└── data/{run-id}/           # Per-run outputs
    ├── state.json           # Progress tracking (survives rate limits + restarts)
    ├── batches/             # Per-agent input files
    ├── outputs/             # Per-agent output files
    └── reports/             # Final synthesis, markdown, HTML
```

## About

Blueprint Swarm is built by [Jordan Crawford](https://linkedin.com/in/jordancrawford), a fractional go-to-market engineer who teaches teams to find creative data and build AI-powered campaigns.

The methodology behind this tool has been used to analyze 100K+ sales calls, identify millions in preventable churn, and build outbound campaigns that prospects actually want to read.

> "The message isn't the problem. The LIST is the problem."

Want Blueprint GTM for your team? [blueprintgtm.com](https://blueprintgtm.com)
