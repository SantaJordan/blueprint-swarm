# Speaker Attribution Protocol

**When to use:** Run this BEFORE any analysis of call recordings, meeting transcripts, or interview
text. Any Blueprint Swarm run whose data is conversation (Gong / Chorus / Zoom / Otter / webinar
transcripts) must complete Steps 1–4 below before a single analyst agent fans out. The goal: never
confuse what the **seller** said for what the **customer** said, and never treat a statement the
customer was **led into** as if they raised it themselves.

> This is an **inline, self-contained copy** carried inside the public Blueprint Swarm mirror so the
> skill works offline with no external path dependency. The canonical source of this protocol lives in
> the Blueprint GTM monorepo (`skills/_shared/references/speaker-attribution-protocol.md`); the two are
> kept in sync. Consumers in this repo: the Phase 0 step in `SKILL.md`, the role-aware worker prompts in
> `.claude/agents/` (churn-analyst, win-analyst, pattern-extractor), the `batch-auditor`, the
> `synthesis-agent`, and the call-analysis modules.

---

## Why this exists

The seller talks on every call. If you analyze a transcript as one undifferentiated block, three
errors creep in and quietly corrupt every downstream finding:

1. **Mis-attribution.** You credit the seller's pitch to the customer — "they said they need X" when
   the *rep* said X.
2. **Led demand.** You treat an answer the customer was walked into ("wouldn't it help if…?" → "yeah,
   sure") as if it were demand the customer surfaced on their own.
3. **Seller-echo.** You treat a stock line the rep repeats on every call as a signal — but a constant
   the seller injects across the whole dataset discriminates nothing.

**The unit of trust in customer-voice analysis is the UNPROMPTED CUSTOMER STATEMENT.** Everything else
is context. Seller speech is never deleted — you need it to judge what was led — but it is never
counted as customer signal.

At swarm scale this matters more, not less: a mis-attribution that one analyst would catch becomes a
systematic error replicated across 150 agents, and the synthesis agent will read it back as a
high-confidence pattern ("appeared in 100+ batches") when it is really just the rep's pitch echoed
everywhere.

---

## Step 1 — Build the roster (who is on these calls?)

- Enumerate every distinct participant across **all** calls for the account / engagement, not per
  call. Dedupe to people (the same person appears under one entry even if their speaker label drifts).
- For each person capture: **name**, the **speaker id / label** as it appears in the transcript,
  **email / domain** if available, and the **calls** they appear on.
- Output one roster the whole analysis reuses. Resolve identity **once**, apply everywhere.

## Step 2 — Label each person SELLER / CUSTOMER / UNKNOWN

Resolve role **cheapest-first**:

1. **Metadata (free, preferred).** Gong / Chorus / Claap call objects already tag each party internal
   vs. external by email domain (e.g. Gong `parties[].affiliation`). Use it directly. Internal =
   **SELLER** (the company running the analysis). External = **CUSTOMER** (the buyer).
2. **Domain compare.** If you have an email, compare its domain to the seller company's own domain(s).
   Same domain → SELLER. Different → CUSTOMER.
3. **No-tool inference (this skill's default).** Blueprint Swarm uses no enrichment APIs — it is pure
   LLM analysis on local files. When the transcript has no party metadata, resolve role by reading the
   conversation: the person who schedules, demos, quotes price, or says "we" about the *product* is the
   SELLER; the person describing their *own* organization's problems is the CUSTOMER. Record low
   confidence when you infer this way.
4. **Unknown stays unknown.** If you can't confidently place someone, label **UNKNOWN**. **NEVER**
   default an unknown speaker to CUSTOMER. Carry the uncertainty forward.

## Step 3 — Tag every line of the transcript

- Join each speaker turn back to the roster: **COMPANY** (seller), **CUSTOMER**, or **UNKNOWN**.
- Preserve the **verbatim** line *and* its original speaker label (audit trail) **alongside** the role
  tag (analysis-ready). Add tags; never rewrite the transcript.
- **Do not delete seller speech.** It is context — the questions asked, claims made, framing offered.
  You need it for Step 4. You simply never count it as customer signal.

## Step 4 — Grade each CUSTOMER statement for trust (elicitation)

For every customer statement you might use as evidence, classify how it arose:

- **UNPROMPTED — highest trust.** The customer raised it on their own — volunteered a problem, brought
  up a number, named a consequence — without the seller teeing it up in the immediately preceding
  turns. **This is the gold signal; weight it most.**
- **LED / ELICITED — low trust, flag it.** The customer said it only after the seller framed it, asked
  a leading question, or proposed it ("wouldn't it be great if…", "so you'd want X, right?" → "yeah").
  Agreement-after-framing is **not** independent demand. Discount heavily; never present as a
  discovered pain.
- **SELLER-ECHO — not customer signal.** The statement is actually the seller's, **or** it's a
  customer line that merely repeats the seller's stock pitch, **or** it's a theme the seller raises on
  essentially every call. Exclude from "what customers want"; keep as context only.

Record the tier per statement. **When in doubt between UNPROMPTED and LED, choose LED** (conservative —
a wrong call should degrade to "kept it, flagged it," never "deleted a real signal").

## Step 5 — Analyze agnostically, blind first (three passes)

1. **Customer-only pass.** Read **only** the CUSTOMER turns (favoring UNPROMPTED), blind to the
   seller's framing. Form your first read of what the customer wants / feels / decides.
2. **Combined pass.** Now read the full back-and-forth. Note what emerged **only** because the seller
   raised it (LED), and what the seller repeats everywhere (SELLER-ECHO).
3. **Synthesis.** Conclude from the customer-only read, corrected by the combined read. A LED or
   SELLER-ECHO statement **never** becomes a headline finding. Attribute every claim to who actually
   said it. If a conclusion rests on customer voice, it must rest on **unprompted** customer voice.

(This is the same "answer blind, then compare" discipline a good auditor uses — independent read
first, framing second.)

---

## Output contract (what downstream steps consume)

Produce, and pass forward to every downstream step, at minimum:

```yaml
roster:
  - name: <string>
    speaker_label: <as it appears in transcript>
    role: company | customer | unknown
    confidence: 0.0–1.0
    source: metadata | domain | inference
turns:            # the transcript, tagged
  - speaker_label: <string>
    role: company | customer | unknown
    text: <verbatim>
customer_statements:
  - text: <verbatim>
    speaker: <name/label>
    elicitation: unprompted | led | seller_echo
    call_id: <id>
```

Downstream analysis **must** read these and obey them: **customer-only by default**, **unprompted
weighted highest**, **led discounted**, **seller_echo excluded** from demand. Seller speech is retained
as context and never counted as customer signal.

In this skill the contract is materialized once per run into
`data/{run-id}/attribution/` (roster.yaml + transcript_tagged.jsonl + customer_statements.jsonl), and
every batch file is carved from the **role-tagged** transcript — never from a raw blob.

## Honesty rules (non-negotiable)

- **Unknown ≠ customer.** Never silently promote an unknown speaker to customer.
- **Verbatim is preserved.** Role / elicitation tags are added alongside, never by rewriting lines.
- **A led or echoed line can be reported — but only labeled as such**, never as independent demand.
- **If most of a customer's "pain" turns out to be LED or SELLER-ECHO, lower the confidence** of any
  finding built on it, and say so.

---

Part of Blueprint Swarm. Methodology by Jordan Crawford / Blueprint GTM — [blueprintgtm.com](https://blueprintgtm.com).
