# Hand-off: staged-assistant-workflow trigger design, section 5.2 (content-growth hook)

Written 2026-10-28 to restart in a fresh conversation. Read this file first, then
`research/staged-assistant-workflow-ledger.md` sections 2, 5.2, 9, and 10 (in that order --
section 9 resolves what section 2/5.2 left open, section 10 is the latest log). Delete or
archive this file (move the relevant bits into the ledger) once section 5.2 is built or the
work stream is explicitly closed.

## Where this stands

`staged-assistant-workflow`'s handoff step 4 ("look into hooks ... to trigger this skill
efficiently") has two parts. **5.1 (prompt-content phrase nudge) is built, tested, and live**
(see ledger section 10, commit `bc5668b`) -- a `metadata.prompt_signals` field on the skill
plus a `UserPromptSubmit` case in `scripts/skill-file-signal-hook.sh`, reusing the existing
nudge-once/escalate-on-repeat mechanism. **5.2 (a hook that nudges once a conversation's own
length/context usage looks likely to need staging) is still research only -- nothing built.**
This file is the hand-off for finishing 5.2.

## New finding this round: RStudio's own UI already bands conversation size

The user reported, from RStudio's own UI (not something this repo built): a conversation
length of **120k tokens is labelled "medium"**, and the **current length of 196.2k tokens is
labelled "very large"**. This means Posit Assistant's host UI already classifies conversation
size into named bands -- which is exactly the judgment 5.2 wants to approximate from a hook,
without the model being able to see the UI's own number (per ledger section 2: the token
counter is UI-only, not exposed to the model or any tool/hook field). If the band boundaries
can be pinned down, they would give a principled, product-aligned threshold instead of an
arbitrary one.

**Not yet done:** finding where "medium"/"large"/"very large" (and presumably "small") are
actually defined -- check the Positron/RStudio/Posit Assistant docs
(`https://assistant.posit.co/docs/features/context-management/`, already read once per the
original ledger section 2, but re-read for *numeric* band boundaries this time, not just the
"UI-only" fact) and/or ask the user to hover/inspect the Session HUD panel for any exposed
numbers between "medium" and "very large" (e.g. is there a labelled 50%/75%/90% mark, or named
bands with stated token ranges?).

## Calibration data gathered so far (this session, `09f27102-43f0-491c-a615-37a2b4575917`)

All sizes are `lm-messages.jsonl` next to the hook's `transcript_path` (see ledger section 9.2
for why this file, not `transcript_path` itself, is the useful proxy -- `transcript_path` is a
small, slow-growing index, not the content).

| When | User-reported tokens | RStudio's own label | `lm-messages.jsonl` | Lines |
|---|---|---|---|---|
| Mid-round | ~120,000 | "medium" | 357,584 B | 99 |
| End of this round | 196,200 | "very large" | 687,109 B | 233 |
| (earlier points, no token anchor) | -- | -- | 276,251 B / 667,354 B | 82 / 221 |

Two token-anchored points give a rough **average** ratio of ~3.0-3.5 bytes per token (357,584 /
120,000 ≈ 2.98; 687,109 / 196,200 ≈ 3.50), but the **incremental** ratio between the two points
is notably higher, ~4.33 bytes/token ((687,109 − 357,584) / (196,200 − 120,000)). This
non-linearity is unexplained -- plausibly the per-message JSON overhead (role tags, tool-call
metadata) is a bigger share of bytes early in a session relative to tokens, or large tool
outputs (reads/diffs) inflate bytes without proportionally inflating billed tokens. Needs more
points, ideally spread across a few different *kinds* of session (heavy tool-use vs. mostly
prose), before trusting a single bytes-per-token constant.

`ui-messages.jsonl` was also tracked and is **not recommended** as the proxy: it grew far more
spikily than `lm-messages.jsonl` (see ledger section 10's growth table, ~18x vs ~1.9x in one
stretch), plausibly because it carries larger per-entry UI-rendering payloads (full diffs, etc.)
rather than tracking billed context content.

## Next actions, in order

1. **Find the real band boundaries**, if they exist in any reachable doc or UI affordance (see
   "New finding" above). If none can be found beyond "medium" and "very large" as two labelled
   points, treat this conversation's two-point data as the only anchor and say so explicitly
   rather than inventing more bands.
2. **Gather at least one more token-anchored data point**, ideally from a *different* session
   with a different mix of prose vs. tool output, to check whether the ~3-3.5 bytes/token ratio
   (or the band boundaries) hold up or were an artefact of this one heavy-tool-use session. The
   user can report "RStudio says conversation length is now labelled X" and ask for a size
   check, the same way this round's two points were gathered.
3. **Decide the hook's actual trigger condition** once the above exists: likely "nudge once,
   non-blocking, when `lm-messages.jsonl` crosses a byte threshold equivalent to RStudio's own
   'very large' (or one band below it, so the nudge arrives with room to act)" -- not a guess
   made up independently of the product's own bands.
4. **Design and build the hook**, reusing the established pattern from 5.1 (ledger section 10)
   as closely as possible:
   - Likely a `PostToolUse` hook (broad matcher, or piggyback on the existing
     `skill-file-signal-hook.sh` script rather than adding a new one) that `stat`s
     `lm-messages.jsonl` next to `transcript_path` and compares its size against the chosen
     threshold.
   - Non-blocking `additionalContext` nudge, once per session (same marker-file convention as
     the existing hooks: `~/.posit/skill-triggers/state/<session>.<something>`).
   - The nudge should point at `staged-assistant-workflow` specifically but phrase itself
     generically enough to apply to "this conversation is very large, consider whether the
     remaining work should be staged or handed off", since a long conversation is not
     automatically a staging candidate (ledger section 5.2's original caution: some long
     conversations are better served by `/compact` or just finishing, e.g. a long but linear
     exploration with no separable stages).
5. **Verify** per this repo's standing rule before calling it done: `lint_skills()`,
   `check_skill_links()`, `check_skill_clashes()`, `check_sync_setup()` against the real
   settings.json (same `cfg=` workaround used throughout this work stream, since the R session
   cannot read that path directly), and a synthetic-payload test matrix mirroring 5.1's.
6. **Log** the finished design in `research/staged-assistant-workflow-ledger.md` (new dated
   section) and in `HISTORY.md`, then ask the user before committing/pushing.

## Known open risks to carry forward

- A byte-size threshold is a proxy for context pressure, not a direct measurement -- a single
  large `read`/`grep` result can inflate `lm-messages.jsonl` without the task itself being long
  in the sense `staged-assistant-workflow` cares about (ledger section 9.2). The nudge text
  should stay advisory, not assert certainty.
- The self-referential false-positive class found this session (ledger section 9.1/10 and the
  live reminder this round: reading/discussing another skill's `file_signals`/`prompt_signals`
  patterns as prose trips the same hook as a real occurrence) is still unfixed and unrelated to
  5.2, but worth a glance if a `skill-lessons` entry gets filed for it in the meantime.
- No real-conversation-turn test of 5.1 has happened yet either (only synthetic payloads) --
  if 5.2 reuses 5.1's code paths, both remain only synthetically tested until a live session
  exercises them.

## How to resume

Say: "Continue the staged-assistant-workflow content-growth hook from
`research/HANDOFF-content-growth-hook.md`." Start with step 1 above.
