# The skill-trigger hook

## Contents

- What it does and does not fix
- How it works
- The question-vs-instruction problem
- Settings entry
- Files
- Test recipe (no real session needed)
- Tested and not tested

Closes the gap found 2026-10-24 in `tmp-examples/conversation-export.json` (see the lesson
at `~/.posit/lessons/inbox/anon_20261024-162307_manual.md` and
`research/skill-trigger-hooks-ledger.md` in this repo for the design research): a user
message explicitly asked the assistant to "trigger the appropriate skills" immediately
before switching into Plan mode and delegating to a subagent; no skill was ever loaded in
the four turns that followed, and the instruction was never revisited.

## What it does and does not fix

Two different undertrigger modes exist (see `references/testing-skills.md`'s "Common
trigger-miss pattern" section for the other one):

- **An explicit instruction is dropped** (this hook's target): the user's own words asked
  for a skill, but attention moved on. This is checkable — "was a `skill()` call made
  after this instruction" is a fact, not a judgement — so a hook can enforce it
  deterministically.
- **A context clue is never acted on** (file content implies a skill, no explicit ask): a
  second script, `skill-file-signal-hook.sh`, gives this a best-effort, **non-blocking**
  nudge (see "The file-signal hook (R2)" below). It cannot judge whether a skill *should*
  have fired, only whether a declared text pattern appeared in a tool result — a much
  narrower, mechanical check than the full relevance judgement, and the worst case is one
  ignorable extra line of context, never a forced action. See
  `research/skill-trigger-hooks-ledger.md` section 6 for why the original, shelved R2 design
  (section 4, item R2) was revised and built after a second independent recurrence of this
  undertrigger and after finding prior art for the same non-blocking pattern elsewhere.

It also cannot judge whether the skill that was eventually loaded was the *right* one —
only that *some* `skill()` call happened after the instruction.

## How it works

Script: `scripts/skill-trigger-hook.sh` at the repo root (next to `lessons-hook.sh` and
`sync-skills.sh`). Three events:

| Event | Matcher | Action |
|---|---|---|
| `UserPromptSubmit` | none | If the prompt text matches an imperative "trigger/use/load/invoke/apply ... skill(s)" phrase (or the passive form), not immediately followed by `?`, write `~/.posit/skill-triggers/state/<session>.pending`. Never blocks. |
| `PostToolUse` | `skill` | Any skill load clears the pending marker for that session. |
| `Stop` | none | If a pending marker still exists and this session hasn't been reminded yet, block once (`decision:"block"`), log the reminder, and clear the marker so the loop guard (`stop_hook_active`) only has to cover the one forced turn. |

The `Stop` reason is a fixed, generic string — it does not quote the user's original
instruction back. This was a deliberate simplification from the first design sketch in the
ledger (section 4): extracting one JSON string field cleanly with `sed` breaks on embedded
quotes (a prompt that itself contains `"..."` would truncate), and relaying raw user text
back through a shell `printf` adds an escaping risk for no real benefit — the assistant
already has the actual transcript.

### Why the phrase match scans the whole payload, not just `prompt`

`lessons-hook.sh`'s `jstr()` helper (`sed`, single capture group) is used elsewhere in this
script for structural fields (`session_id`, `cwd`, `tool_name`) that cannot contain embedded
quotes. User prompt text can and does contain them, so `jstr(prompt)` would silently
truncate at the first `\"`. The hook instead runs the trigger regex over the raw JSON text
of the whole payload. The other fields on a `UserPromptSubmit` payload (`session_id`,
`transcript_path`, `cwd`, `hook_event_name`, `permission_mode`) cannot plausibly contain the
phrase, so the risk of a false match from outside the prompt is negligible.

### The question-vs-instruction problem

A real near-miss, found while designing the phrase match: "Is the pitfall a reason to
trigger the lessons-learned rule in some of your skills?" (from
`tmp-examples/conversation-export-3.json`) contains "trigger ... skills" but is a question
*about* triggering, not an instruction *to* trigger — and the assistant's decision not to
act on it there was correct. The regex excludes a match when `skill(s)` (or the matched
verb) is immediately followed by `?` using a PCRE negative lookahead (`grep -P`):

```
\b(trigger|use|load|invoke|apply)\b[^.?!\n]{0,60}\bskills?\b(?!\s*\?)
|\bskills?\b[^.?!\n]{0,60}\b(triggered|loaded|used|invoked|applied)\b(?!\s*\?)
```

**Known, accepted false positive:** a question with more words between the skill mention
and the `?` still matches, e.g. "Should we use a different skill here?" — the lookahead
only excludes `?` immediately after the match. Cost of this miss is low (one extra forced
turn, bounded to once per session by the `reminded` flag), so it was left as a documented
limitation rather than built out further (sentence splitting would need real JSON string
decoding, which is the same embedded-quotes problem above).

**`grep -P` dependency:** the question exclusion needs PCRE lookahead support in the `grep`
that runs inside the hook's shell. Confirmed working here with GNU grep 3.0 under Git
Bash/Cygwin on Windows. If trigger detection seems to misfire (the lookahead silently not
excluding questions, or the whole pattern not matching), check `grep --version` in the
actual hook execution shell — `check_sync_setup()` flags this as an `info` item it cannot
verify itself, since it doesn't run the hook end to end.

## Settings entry

Global `~/.posit/assistant/settings.json` (hooks are additive; a second `PostToolUse`/`Stop`
hook was added alongside the existing `lessons-hook.sh` entries — every matching hook runs,
not just the first):

```json
"UserPromptSubmit": [{"hooks": [{"type": "command",
  "command": "bash C:/Users/<you>/Sync_Home_Work/llm-skills/scripts/skill-trigger-hook.sh", "timeout": 10}]}],
"PostToolUse": [{"matcher": "skill", "hooks": [
  {"type": "command", "command": "bash .../lessons-hook.sh", "timeout": 10},
  {"type": "command", "command": "bash .../skill-trigger-hook.sh", "timeout": 10}
]}],
"Stop": [{"hooks": [
  {"type": "command", "command": "bash .../lessons-hook.sh", "timeout": 10},
  {"type": "command", "command": "bash .../skill-trigger-hook.sh", "timeout": 10}
]}]
```

`check_sync_setup()` audits this entry the same way it audits the lessons hooks (script
exists, LF line endings, `bash -n`, `stop_hook_active` guard present, handler fields valid).

## Files (all under `~/.posit/skill-triggers/`)

| Path | Content |
|---|---|
| `state/<session>.pending` | exists while an instruction is unresolved; holds only a timestamp, no user text |
| `state/<session>.reminded` | marks that this session has already been blocked once |
| `reminders.tsv` | one row per block issued (time, session, project) |
| `state/DEBUG` | create this empty file to dump raw hook payloads to `state/debug-payloads.jsonl` (may hold private content; delete afterwards) |

No project-identifying or user-text content is stored anywhere — unlike the lessons inbox,
this hook never needs to display the instruction back to anyone, so it never has to scrub
one.

## Test recipe (no real session needed)

Pipe synthetic payloads into the script with `SKILL_TRIGGER_DIR` pointing at a scratch
folder (mirrors the `lessons-hook.sh` recipe in `skill-lessons/references/hook-setup.md`):
a prompt without trigger phrasing writes no marker; an explicit instruction writes one; a
`Stop` with the marker present blocks once and clears both the marker and leaves a
`reminded` flag; a second `Stop` for the same session stays silent; a `skill` `PostToolUse`
call clears the marker before `Stop` runs, so no block follows; `stop_hook_active: true`
never blocks regardless of a pending marker; a missing `session_id` exits silently; a
prompt containing embedded `"` quotes (a realistic multi-sentence message) is still
detected, because the match runs over the whole payload rather than an extracted field; the
question near-miss from the "known, accepted false positive" section above is correctly
excluded; empty or non-JSON stdin does not crash the script.

## The file-signal hook (R2)

Script: `scripts/skill-file-signal-hook.sh`, built 2026-10-24 after a second, independent
real-session recurrence of the context-clue undertrigger (see the `github-skill-maintenance`
lesson `anon_20261024-audit_manual.md` and ledger section 6). Two events, both `PostToolUse`:

| Matcher | Action |
|---|---|
| `skill` | Any skill load marks that skill as loaded for the session (`state/<session>.loaded.<skill>`), so it is never nudged for again. |
| `read\|grep\|bash` | Scans `tool_response` against every skill's declared `metadata.file_signals` (a single, skill-owned `'|'`-separated regex-alternation string in that skill's own `SKILL.md` frontmatter). On a match for a skill not yet loaded or already nudged this session, emits `hookSpecificOutput.additionalContext` naming it, and marks it nudged (`state/<session>.nudged.<skill>`) so it fires at most once per (session, skill). **Never blocks.** |

`file_signals` is opt-in and deliberately narrow: only add it to a skill with a strong,
low-ambiguity file signature (seeded on `hpc-job-scripts`:
`'#SBATCH|\bsbatch\b|\bsrun\b'` and `deeplabcut-hpc`:
`'import deeplabcut|pytorch_config\.yaml|pose_cfg\.yaml'`, matching the file-content clauses
already in both descriptions). Do not add it to every skill speculatively — a vague pattern
produces noise, not signal (`lint_skills()` warns on short, non-word-bounded alternatives).
The table lives in each skill's own frontmatter, not centrally in the hook script, so it is
reviewed alongside the skill it serves (the maintenance-burden objection in ledger section 5
was the reason this was revised rather than hardcoded).

Why non-blocking was judged acceptable here where the original sketch worried about false
positives: every piece of prior art found (ledger section 6.3 — two independent community
hooks doing close to the same thing, plus Anthropic's own PostToolUse-linter-nudge pattern)
only injects `additionalContext`, never blocks, on a content match. The cost of a false
positive is one ignorable extra sentence of context, at most once per (session, skill) — not
a wrong action. `check_sync_setup()` has a `file-signal hook never blocks` check that errors
if the script is ever changed to emit `decision:"block"`, to keep this invariant enforced.

### Settings entry (added alongside the existing `PostToolUse` group)

```json
"PostToolUse": [
  {"matcher": "skill", "hooks": [
    {"type": "command", "command": "bash .../lessons-hook.sh", "timeout": 10},
    {"type": "command", "command": "bash .../skill-trigger-hook.sh", "timeout": 10},
    {"type": "command", "command": "bash .../skill-file-signal-hook.sh", "timeout": 10}
  ]},
  {"matcher": "read|grep|bash", "hooks": [
    {"type": "command", "command": "bash .../skill-file-signal-hook.sh", "timeout": 10}
  ]}
]
```

### Files (shares `~/.posit/skill-triggers/state/` with `skill-trigger-hook.sh`, disjoint names)

| Path | Content |
|---|---|
| `state/<session>.loaded.<skill>` | exists once that skill has been loaded this session |
| `state/<session>.nudged.<skill>` | exists once a nudge has fired for that (session, skill) pair |
| `state/DEBUG` | shared debug switch with `skill-trigger-hook.sh` |

### Tested and not tested (file-signal hook)

Tested on Windows (Git Bash, GNU bash 5.3, GNU grep/sed/awk): `bash -n`; a matching `read`
result with no skills loaded yet (nudges once); a repeat call in the same session (silent,
already nudged); a session where the skill was already loaded via a `skill` `PostToolUse`
call first (silent); unrelated content (silent); a DeepLabCut-matching `grep` result
(nudges `deeplabcut-hpc`); a non-matching tool (`ls`, silent even with matching text in its
response); a missing `session_id` (silent, no crash); empty/malformed stdin (no crash, exit
0); a `tool_response` containing an embedded double quote (still detected — the match runs
over the raw payload, not an extracted field, same reasoning as `skill-trigger-hook.sh`);
the `file_signals` extractor directly, against both seeded skills and a skill with none
declared (empty, correctly). `lint_skills()`'s new `file_signals` regex-compile and
specificity checks were tested by observation (both seeded skills pass with no new
findings). `check_sync_setup()`'s new section was run against the real, updated
`settings.json` content (same path-guard workaround as the other hook audits) — all `ok`.
**Not tested:** the hook firing inside a real conversation turn (whether
`hookSpecificOutput.additionalContext` from `PostToolUse` is actually visible to the model
the way a community Claude Code implementation demonstrated — see ledger section 6.3 — is
confirmed there, not here); the cost of scanning ~24 `SKILL.md` files per matching tool call
at scale (unsized, see ledger section 6.6); Linux/macOS; a second machine; whether the two
seeded `file_signals` patterns actually reduce real-world misses (needs another real
recurrence, or lack thereof, to tell).

## Tested and not tested

Tested on Windows (R 4.6.0, Git Bash via the agent's sandboxed shell, GNU grep 3.0, GNU
bash 5.3): all twelve scenarios in the test recipe above, `bash -n`, and
`check_sync_setup(cfg = <the real settings.json text>)` against the live settings file (the
assistant's own R session cannot read that path directly — same session guard documented
for the lessons hooks — so the content was read with `bash`/`cat` and passed as `cfg`).
**Not tested:** the hook firing inside a real conversation turn (this file was written and
tested entirely with synthetic piped payloads, the same limitation `lessons-hook.sh` has);
whether the sandboxed bash used for these tests has identical `grep`/`sed` behaviour to the
real Git Bash the hook runs under on this machine (both are "GNU grep", but confirm with
`grep --version` if detection seems off); `SubagentStop` (a pending instruction that is only
addressed, or not, inside a subagent's own completion is not covered by this design — see
"What it does and does not fix" above); Linux or macOS; a second machine.
