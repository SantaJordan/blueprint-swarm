# Blueprint Swarm - Rate Limit Protocol

How Blueprint Swarm handles Claude Code's shared rate limit pool. This is the authoritative reference — the SKILL.md wave execution protocol and agent definitions defer to this document.

## Why This Exists

Claude Code subagents share the session's rate limit pool with the orchestrator. Launching N agents simultaneously means N+1 consumers (N agents + orchestrator) competing for the same token budget in the same 5-hour rolling window. When N > 3-5, cascading failures occur: agents queue behind each other, timeouts cascade, and most work is wasted.

Blueprint Swarm solves this with three layers:

```
Layer 1: Wave execution     — max 3 agents at a time, state.json after each wave
Layer 2: StopFailure hook   — auto-saves state when rate-limited
Layer 3: Watchdog script    — auto-resumes after rate limit window resets
```

## Hard Rules

### Wave Size: Maximum 3 Concurrent Agents

- NEVER launch more than 3 agents simultaneously
- Wait for ALL agents in a wave to complete before launching the next wave
- The orchestrator needs token headroom for state management and progress display
- 3 is the proven reliable number. 5+ causes intermittent failures.

### No Session Budget Cap

Do NOT artificially limit agents per session. Run continuously until:
- All batches are complete, OR
- Rate limit is hit (auto-recovered by watchdog)

The old "15 agents per session" approach wasted available capacity. The correct approach: use every token available, auto-recover when the limit is hit, repeat.

### Agent Timeout: 10 Minutes

- If an agent produces no output file within 10 minutes, mark as `timed_out`
- Retry timed_out agents once (max `retry_count`: 2)
- After 2 timeouts: mark as `failed`, skip, continue with next wave
- Timed-out agents may have been rate-limited internally — retrying in a later wave often succeeds

### Partial Results Are Valid

- Agents should write partial output rather than fail completely
- A partial extraction of 80/100 calls is far more valuable than a timeout with 0
- The synthesis agent handles partial data gracefully and reports coverage gaps

## Rate Limit Recovery (Three-Layer System)

### Layer 1: State Tracking

After every wave completion, the orchestrator updates `data/{run-id}/state.json`:
- Completed agents move from `pending` to `completed`
- Failed agents get logged with error details
- `waves_completed` counter increments
- This is the checkpoint. If the session dies at any point, state.json has the latest progress.

### Layer 2: StopFailure Hook (`hooks/swarm-stop-failure.js`)

When Claude Code hits the rate limit:
1. The `StopFailure` hook fires with matcher `rate_limit`
2. The hook reads `state.json`, updates status to `"paused"`
3. Any agents marked `"running"` are marked `"interrupted"`
4. The rate limit event is logged with timestamp
5. State is written back to disk

This ensures state is saved even if the orchestrator can't run its normal save logic.

### Layer 3: Watchdog Script (`scripts/swarm-watchdog.sh`)

Runs in a separate tmux pane. When rate-limited:
1. Detects the rate limit message in the Claude Code pane (polls every 5s)
2. Parses the reset time from the message
3. Sleeps until reset time + 60s safety margin
4. Sends a resume prompt to the Claude Code pane
5. Claude resumes → reads state.json → continues from next pending wave

The watchdog makes the swarm fully autonomous. Start it, walk away, come back to results.

## Resume Protocol

On every invocation of `/blueprint-swarm`:

1. Glob for `data/*/state.json`
2. If found with status `in_progress` or `paused`:
   a. Display progress summary
   b. Ask: resume or start fresh?
   c. If resume: recover interrupted wave, continue
3. If not found: proceed with new run

### Recovering an Interrupted Wave

When resuming, some agents may be marked `running` from the interrupted session:
1. Check if their output file exists
2. If output exists and is valid JSON: mark as `completed`
3. If output exists but is partial (`"partial": true`): mark as `completed`
4. If no output exists: mark as `timed_out` (they were interrupted mid-execution)
5. Timed-out agents join the next wave as retries

## Wall Clock Estimates

| Dataset Size | Total Agents | Rate Limit Pauses | Est. Wall Clock |
|-------------|-------------|-------------------|----------------|
| 100 calls | 3-5 | 0 | ~15 minutes |
| 500 calls | 10-15 | 0-1 | 1-2 hours |
| 1,000 calls | 20-25 | 1-2 | 3-6 hours |
| 5,000 calls | 50-70 | 3-5 | 15-25 hours |
| 10,000 calls | 100-120 | 6-8 | 30-40 hours |

Estimates assume Max plan (~88K-220K tokens per 5-hour window), waves of 3, with watchdog auto-resume. Actual throughput varies by data complexity and peak/off-peak hours.

**Rule of thumb**: Start before bed for datasets up to ~5K calls. Expect results by morning.

## What the User Sees

### During execution:
```
Wave 14: 3 done | Total: 42/120 (35%) | Failed: 0 | Wall: 2h 15m
```

### When rate-limited:
```
Rate limit hit. State saved (42/120 complete).
Watchdog will auto-resume after window resets (~5h).
```

### After watchdog resumes:
```
Resuming swarm from wave 15 (42/120 complete)...
Wave 15: Launching agents...
```

### When all done:
```
Swarm complete: 120/120 agents done | 0 failed | 14h 23m wall time
Proceeding to audit...
```
