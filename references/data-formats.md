# Blueprint Swarm - Supported Data Formats

## Format Detection Table

| Format | Source | Detection Heuristic |
|--------|--------|-------------------|
| Gong JSON | Gong export | `parties` array, `media` object, `trackers` |
| Chorus JSON | Chorus export | `recording_url`, `participants`, `topics` |
| Raw transcript (.txt/.md) | Any source | Conversational pattern: Speaker: or timestamp-prefixed |
| PDF transcript | Meeting notes | PDF with conversational content |
| Salesforce Opportunity CSV | SFDC export | StageName, CloseDate, Amount columns |
| Salesforce Account CSV | SFDC export | AccountName, Industry, BillingState |
| Salesforce Case CSV | SFDC export | CaseNumber, Subject, Priority |
| HubSpot Deal CSV | HubSpot export | Deal Name, Pipeline, Deal Stage |
| Generic CRM CSV | Any CRM | Deal/account/contact terminology |
| Support ticket CSV | Zendesk/Intercom | Ticket, Priority, Status fields |

## Format Detection Logic

The orchestrator uses a two-pass detection strategy:

1. **Extension check** — `.json`, `.csv`, `.txt`, `.md`, `.pdf` determine the broad category
2. **Content heuristic** — First 5KB of the file is inspected for format-specific markers

### JSON Detection

```
IF file contains "parties" AND "media" → Gong JSON
IF file contains "recording_url" AND "participants" → Chorus JSON
ELSE → Generic JSON (attempt field mapping)
```

### CSV Detection

```
IF headers contain "StageName" AND "CloseDate" → Salesforce Opportunity
IF headers contain "AccountName" AND "Industry" → Salesforce Account
IF headers contain "CaseNumber" AND "Subject" → Salesforce Case
IF headers contain "Deal Name" AND "Pipeline" → HubSpot Deal
IF headers contain "Ticket" AND "Priority" → Support ticket
ELSE → Generic CRM CSV (attempt field mapping)
```

### Transcript Detection

```
IF line matches /^\[?\d{1,2}:\d{2}/ → Timestamp-prefixed transcript
IF line matches /^[A-Z][a-z]+ [A-Z][a-z]+:/ → Speaker-prefixed transcript
IF line matches /^Speaker \d+:/ → Anonymous speaker transcript
```

## Format Normalization

All formats are normalized to a common internal representation before processing. The normalization step handles:

### Call Transcripts → Normalized Call Object

Every call transcript (Gong, Chorus, raw text, PDF) is normalized to:

```json
{
  "call_id": "string",
  "source_format": "gong|chorus|raw_transcript|pdf",
  "account_name": "string (from filename, metadata, or first mention)",
  "call_date": "YYYY-MM-DD (from metadata or filename)",
  "duration_minutes": "number or null",
  "participants": [
    { "name": "string", "role": "string or unknown", "side": "seller|buyer|unknown" }
  ],
  "transcript": [
    { "speaker": "string", "timestamp": "string or null", "text": "string" }
  ],
  "raw_text": "string (full concatenated transcript for token counting)"
}
```

### CRM Data → Normalized Deal/Account Object

CRM exports are normalized to:

```json
{
  "record_id": "string",
  "source_format": "sfdc_opp|sfdc_account|sfdc_case|hubspot_deal|generic_crm|support_ticket",
  "account_name": "string",
  "deal_name": "string or null",
  "stage": "string",
  "outcome": "won|lost|open|churned|unknown",
  "close_date": "YYYY-MM-DD or null",
  "amount": "number or null",
  "owner": "string or null",
  "custom_fields": {}
}
```

### Field Mapping Rules

When normalizing, the following field aliases are recognized:

| Target Field | Accepted Aliases |
|-------------|-----------------|
| account_name | AccountName, Account Name, Company, Company Name, Account, company_name, account |
| deal_name | Deal Name, Opportunity Name, OpportunityName, DealName, deal_name, opportunity |
| stage | StageName, Stage, Deal Stage, Pipeline Stage, stage_name, deal_stage |
| close_date | CloseDate, Close Date, Closed Date, close_date, closed_date, Expected Close |
| amount | Amount, Deal Value, Contract Value, ACV, ARR, MRR, amount, deal_value |
| owner | Owner, Deal Owner, Account Owner, Rep, Sales Rep, owner_name, assigned_to |

### Handling Mixed Datasets

When a user provides multiple file types (e.g., Gong exports + Salesforce CSV), the orchestrator:

1. Detects each file independently
2. Normalizes all files to internal format
3. Attempts account-level joins on `account_name` (fuzzy matching with 85% threshold)
4. Tags calls with CRM outcome data when a join is found
5. Proceeds with analysis using the enriched dataset

### Encoding and Cleanup

- All files are read as UTF-8 with fallback to Latin-1
- BOM markers are stripped
- CSV dialect is auto-detected (comma, tab, semicolon, pipe)
- Empty rows and header-only files are skipped with a warning
- Duplicate calls (same account + date + duration within 5 minutes) are flagged for review
