# Data Discovery

The entry point for every Blueprint Swarm run. Scans the working directory, profiles all data files, and determines what analysis modules are possible.

## Scan Algorithm

### Step 1: File Discovery

Glob for all data files recursively:

```
**/*.json
**/*.jsonl
**/*.csv
**/*.txt
**/*.md
**/*.pdf
**/*.tsv
```

Exclude patterns: `node_modules/`, `.git/`, `__pycache__/`, `data/{run-id}/` (previous outputs).

### Step 2: Format Detection Heuristics

For each discovered file, read the first 4KB and classify:

| Signal | Classification |
|--------|---------------|
| Valid JSON with array of objects | Structured records (JSON) |
| Valid JSON with nested keys | Configuration / metadata |
| JSONL (one JSON object per line) | Streaming records (JSONL) |
| First line has delimiters (comma, tab) | Tabular (CSV/TSV) |
| Lines match `Speaker:` or `[HH:MM:SS]` patterns | Call transcript |
| Markdown headers with prose | Documentation / notes |
| PDF magic bytes (`%PDF`) | PDF document |
| Plain text with no structure | Unstructured text |

For transcripts specifically, detect sub-formats:
- **Gong export**: JSON with `calls` array, each having `transcript` and `metadata`
- **Chorus export**: CSV with `transcript_text` column
- **Otter.ai**: Text with `Speaker N (HH:MM:SS)` format
- **Raw paste**: Speaker labels with no timestamps
- **SRT/VTT**: Subtitle format with numbered segments

### Step 3: Data Profiling

For each file, produce a Tufte-style profile card:

```
Data Profile: {filename}
───────────────────────────────────
Records:     {count}
Format:      {type}
Avg size:    ~{n} tokens/record
Fields:      {list}
Quality:     {issues}
Sample:      {first_record_preview}
```

For transcript files, additional metrics:

```
Transcript Profile: {filename}
───────────────────────────────────
Calls:       {count}
Avg length:  ~{n} tokens/call
Speakers:    {avg_per_call}
Date range:  {earliest} → {latest}
Has metadata: {yes/no}
Format:      {gong|chorus|otter|raw|srt}
```

### Step 4: Analysis Capability Matrix

Based on discovered data, produce a capability matrix showing what modules can run:

```
Analysis Capability Matrix
═══════════════════════════════════════════════════════
Module                    Status      Data Source
─────────────────────────────────────────────────────
Churn Intelligence        READY       47 churn/support calls
Win Pattern Analysis      READY       31 closed-won calls
Competitive Intelligence  READY       extracted from all calls
Product Gap Detection     READY       churn + support cross-ref
Playbook Extraction       READY       31 closed-won transcripts
Account Health            PARTIAL     needs CRM data for full scoring
─────────────────────────────────────────────────────
```

Status values:
- **READY** — all required data is present
- **PARTIAL** — can run with reduced output
- **BLOCKED** — missing critical data
- **N/A** — data type not applicable

### Step 5: User Confirmation

Present findings and ask:

1. Confirm the data summary is correct
2. Which modules to run (default: all READY modules)
3. Any custom focus areas or questions
4. Output format preference (markdown report, HTML playbook, or both)

### Step 6: Data Normalization

**Never modify source files.** Write normalized data to `data/{run-id}/normalized/`.

Normalization steps:
1. Convert all transcript formats to a canonical JSON structure:
   ```json
   {
     "call_id": "string",
     "source_file": "original/path.json",
     "metadata": { "date": "YYYY-MM-DD", "account": "string", ... },
     "turns": [
       { "speaker": "string", "text": "string", "timestamp": "HH:MM:SS" }
     ]
   }
   ```
2. Deduplicate records with identical content hashes
3. Write a `manifest.json` listing all normalized files with their profiles
4. Write a `run-config.json` capturing the user's module selections and parameters

## Output

- `data/{run-id}/normalized/` — all normalized data files
- `data/{run-id}/manifest.json` — file inventory with profiles
- `data/{run-id}/run-config.json` — module configuration for this run

## Handoff

After data discovery completes, the orchestrator reads `manifest.json` and `run-config.json` to dispatch the appropriate analysis modules.
