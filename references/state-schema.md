# Blueprint Swarm - State Schema

The `state.json` file tracks swarm progress across waves, rate limit pauses, and session restarts. Written to `data/{run-id}/state.json`.

## Schema

```json
{
  "run_id": "2026-04-03T10-15-00",
  "created_at": "2026-04-03T10:15:00Z",
  "updated_at": "2026-04-03T14:23:00Z",
  "status": "in_progress",
  "data_path": "/path/to/user/data",
  "analysis_type": "churn_intelligence",

  "total_batches": 120,
  "completed": ["batch-001", "batch-002", "batch-003"],
  "failed": [],
  "pending": ["batch-004", "batch-005"],

  "current_wave": 5,
  "wave_size": 3,
  "waves_completed": 4,
  "agents_completed_total": 12,

  "rate_limit_events": [
    {
      "timestamp": "2026-04-03T12:30:00Z",
      "reset_time": "2026-04-03T17:30:00Z",
      "agents_completed_before": 12,
      "wave_interrupted": 5
    }
  ],

  "sessions": [
    {
      "number": 1,
      "started_at": "2026-04-03T10:15:00Z",
      "ended_at": "2026-04-03T12:30:00Z",
      "agents_completed": 12,
      "waves_completed": 4,
      "reason_ended": "rate_limited"
    }
  ],

  "agent_details": {
    "batch-001": {
      "status": "completed",
      "batch_file": "data/2026-04-03T10-15-00/batches/batch-001.md",
      "output_file": "data/2026-04-03T10-15-00/outputs/batch-001.json",
      "wave": 1,
      "started_at": "2026-04-03T10:20:00Z",
      "completed_at": "2026-04-03T10:27:00Z",
      "retry_count": 0,
      "error": null,
      "partial": false
    },
    "batch-004": {
      "status": "running",
      "batch_file": "data/2026-04-03T10-15-00/batches/batch-004.md",
      "output_file": "data/2026-04-03T10-15-00/outputs/batch-004.json",
      "wave": 5,
      "started_at": "2026-04-03T12:28:00Z",
      "completed_at": null,
      "retry_count": 0,
      "error": null,
      "partial": false
    }
  }
}
```

## Field Reference

### Top-Level

| Field | Type | Description |
|-------|------|-------------|
| `run_id` | string | ISO timestamp (used as directory name) |
| `created_at` | ISO-8601 | When the run was created |
| `updated_at` | ISO-8601 | Last state.json write |
| `status` | enum | `in_progress`, `paused`, `completed`, `failed` |
| `data_path` | string | Absolute path to user's source data |
| `analysis_type` | string | Module being run (e.g., `churn_intelligence`) |

### Progress Counters

| Field | Type | Description |
|-------|------|-------------|
| `total_batches` | int | Total number of agent batches |
| `completed` | string[] | Batch IDs that finished successfully |
| `failed` | string[] | Batch IDs that permanently failed (retry_count >= 2) |
| `pending` | string[] | Batch IDs not yet started or queued for retry |
| `current_wave` | int | Wave number currently executing |
| `wave_size` | int | Agents per wave (default: 3) |
| `waves_completed` | int | Total waves finished |
| `agents_completed_total` | int | Total agents completed across all sessions |

### Agent Status Values

| Status | Meaning | Next Action |
|--------|---------|-------------|
| `pending` | Not yet launched | Include in next wave |
| `running` | Launched, awaiting output | Check output file on resume |
| `completed` | Output file exists and valid | Done |
| `timed_out` | 10 min elapsed, no output | Retry (if retry_count < 2) |
| `failed` | Permanently failed | Skip, report in synthesis |
| `interrupted` | Session died mid-execution | Recover on resume (check output) |

### State Transitions

```
pending → running → completed
                  → timed_out → running (retry) → completed
                                                 → timed_out → failed
running → interrupted (session died) → running (resume recovery)
                                     → timed_out (no output found)
```

### Rate Limit Events

Each entry in `rate_limit_events` records:
- When the limit was hit
- When the window resets (parsed from Claude Code message)
- How many agents completed before the limit
- Which wave was interrupted

### Session Log

Each entry in `sessions` records:
- Session number (monotonically increasing)
- Start/end times
- Agents completed in this session
- Why the session ended: `rate_limited`, `all_complete`, `user_stopped`, `error`

## Usage

### Creating state.json (Phase 4.3)

After batch files are prepared, write the initial state.json:
- All agents in `pending` status
- `status: "in_progress"`
- Empty `completed`, `failed`, `rate_limit_events`, `sessions`

### Updating after each wave (Phase 4.5)

After wave completes:
1. Move completed agents from `pending` to `completed`
2. Move failed agents to `failed` (if retry_count >= 2) or back to `pending` (for retry)
3. Increment `waves_completed` and `agents_completed_total`
4. Update `updated_at`

### On rate limit (StopFailure hook)

1. Set `status: "paused"`
2. Mark `running` agents as `interrupted`
3. Append to `rate_limit_events`
4. Append to `sessions` with `reason_ended: "rate_limited"`

### On resume (Phase 4.3 resume detection)

1. Read state.json
2. For each agent with status `interrupted` or `running`:
   - Check if output file exists → mark `completed`
   - No output file → mark `timed_out` (add to retry queue)
3. Move timed_out agents back to `pending` (if retry_count < 2)
4. Set `status: "in_progress"`
5. Append new session entry
6. Continue from next pending wave
