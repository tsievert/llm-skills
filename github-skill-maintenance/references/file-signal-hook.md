# The file-signal hook (R2)

Non-blocking nudge toward a skill when tool output (file content) matches that skill's declared `metadata.file_signals`. Sibling of the explicit-instruction hook in [skill-trigger-hook.md](skill-trigger-hook.md) (R1), whose `Stop` handler also carries R2's escalation. The prompt-wording variant and the per-skill declaration tables for later rollouts are in [prompt-signal-channel.md](prompt-signal-channel.md).

## Contents

- What it does
- Escalation: a repeated, ignored nudge forces one block
- Settings entry (and why non-blocking, grep pitfall)
- Files
- Tested and not tested (file-signal hook)

## What it does

Script: `scripts/skill-file-signal-hook.sh`, built 2026-10-24 after a second, independent
real-session recurrence of the context-clue undertrigger (see the `github-skill-maintenance`
lesson `anon_20261024-audit_manual.md` and ledger section 6). Two events, both `PostToolUse`:

| Matcher | Action |
|---|---|
| `skill` | Any skill load marks that skill as loaded for the session (`state/<session>.loaded.<skill>`), so it is never nudged for again. |
| `read\|grep\|bash` | Scans `tool_response` against every skill's declared `metadata.file_signals` (a single, skill-owned `'|'`-separated regex-alternation string in that skill's own `SKILL.md` frontmatter). On the *first* match for a skill not yet loaded this session, emits `hookSpecificOutput.additionalContext` naming it, and marks it nudged (`state/<session>.nudged.<skill>`). On a *second* match for the same still-unloaded skill, writes an escalation marker instead (see below) rather than repeating the same line. **Never blocks itself.** |

## Escalation: a repeated, ignored nudge forces one block

Added 2026-10-26 after the `dlc-pig-method-paper` session (see the update note at the top of
this file) showed a single non-blocking nudge is not sufficient in practice: both
`hpc-job-scripts` and `deeplabcut-hpc` were nudged once each, visibly (the nudge text appeared
in the transcript as a `hook-feedback` block), and neither was acted on.

On a second match for a skill already nudged once and still not loaded, `skill-file-signal-hook.sh`
writes `state/<session>.pending.fs.<skill>` instead of emitting a second `additionalContext`
line. `skill-trigger-hook.sh`'s `Stop` handler (R1) now checks for these markers alongside its
own explicit-instruction `pending` marker, and blocks once if either is present — the two
sources share the single per-session "reminded" budget, so this does not add a second,
independent nag. The block `reason` names the specific skill(s) when it knows them from a
`pending.fs.<skill>` marker (unlike the explicit-instruction case, which stays a fixed generic
string — see "Why the phrase match scans the whole payload" above for why extracting free text
is avoided; a skill *name* from a marker filename has no such risk, since it is this repo's own
controlled vocabulary of skill folder names, not arbitrary user text).

`skill-file-signal-hook.sh` itself still never emits `decision:"block"` — the escalation marker
is just a file; only `skill-trigger-hook.sh` blocks, now triggered by either source. The
`check_sync_setup()` `file-signal hook never blocks` check still guards this invariant on the
unchanged script. This keeps the two scripts' failure costs matched to their reliability: R2's
own non-blocking nudge is still cheap and can be wrong without consequence, while the one block
it can now trigger reuses R1's already-accepted bounded cost (at most one forced turn, once per
session).

`file_signals` is opt-in and deliberately narrow: only add it to a skill with a strong,
low-ambiguity file signature, matching a file-content clause already in that skill's own
description. Do not add it to every skill speculatively — a vague pattern produces noise, not
signal (`lint_skills()` warns on short, non-word-bounded alternatives). The table lives in each
skill's own frontmatter, not centrally in the hook script, so it is reviewed alongside the skill
it serves (the maintenance-burden objection in ledger section 5 was the reason this was revised
rather than hardcoded). Declared on six skills as of 2026-10-26 (seeded on `hpc-job-scripts` and
`deeplabcut-hpc` round 1/2; widened round 4 after the escalation mechanism above made a repeated
nudge actionable — see `research/skill-trigger-hooks-ledger.md` section 9 for the full rationale
per skill):

| Skill | `file_signals` |
|---|---|
| `hpc-job-scripts` | `'#SBATCH\|\bsbatch\b\|\bsrun\b'` |
| `deeplabcut-hpc` | `'import deeplabcut\|pytorch_config\.yaml\|pose_cfg\.yaml'` |
| `hpc-gpu-jobs` | `'--gres=gpu\|--gpus[=:]\|\bCUDA_VISIBLE_DEVICES\b\|\btorchrun\b'` |
| `hpc-resource-allocation` | `'OUT_OF_MEMORY\|\boom-kill\b\|\bsacct\b\|\bseff\b'` |
| `hpc-python-code` | `'\bSIGUSR1\b\|signal\.signal\(signal\.SIGTERM'` |
| `hpc-r-code` | `'parallelly::availableCores\|future\.batchtools\|\bR_LIBS_USER\b'` |
| `keypoint-moseq` (added 2026-10-29) | `'import keypoint_moseq\|from keypoint_moseq\|\bjax_moseq\b\|\bkpms\.[a-z_]+\('` — any top-level `kpms.<fn>(` call plus the imports; synthetic-payload tested (`kpms.fit_model(...)`, `import keypoint_moseq as kpms` nudge; `fit_model_in_stan()` silent), not tested in a live turn |

`hpc-cluster-docs` deliberately has none: it is a "run this first" skill about identifying a
cluster, not keyed to a distinguishing content pattern the way the others are.

**`grep -E -- "$pat"` pitfall, found round 4:** a pattern whose first alternative starts with
`-` (here, `--gres=gpu`) makes `grep` parse it as an option instead of a pattern, failing with
"unknown option". `lint_skills()`'s regex-compile check uses R's `grepl()`, a different engine
with no option-parsing step, so it does not catch this. Fixed with the `--` end-of-options
marker in the hook script's `grep -qE -- "$pat"` call; any `file_signals` value is now safe
regardless of what it starts with. If a future shared script adds its own `grep` call against a
`file_signals` value, it needs the same `--` guard — not yet enforced by the linter (see ledger
section 9.4, open item).

Why non-blocking was judged acceptable here where the original sketch worried about false
positives: every piece of prior art found (ledger section 6.3 — two independent community
hooks doing close to the same thing, plus Anthropic's own PostToolUse-linter-nudge pattern)
only injects `additionalContext`, never blocks, on a content match. The cost of a false
positive is one ignorable extra sentence of context, at most once per (session, skill) — not
a wrong action. `check_sync_setup()` has a `file-signal hook never blocks` check that errors
if the script is ever changed to emit `decision:"block"`, to keep this invariant enforced.

## Settings entry (added alongside the existing `PostToolUse` group)

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

## Files (shares `~/.posit/skill-triggers/state/` with `skill-trigger-hook.sh`, disjoint names)

| Path | Content |
|---|---|
| `state/<session>.loaded.<skill>` | exists once that skill has been loaded this session |
| `state/<session>.nudged.<skill>` | exists once a nudge has fired for that (session, skill) pair |
| `state/<session>.pending.fs.<skill>` | written on a *second*, still-ignored match for that skill; read and cleared by `skill-trigger-hook.sh`'s `Stop` handler, not by this script |
| `state/DEBUG` | shared debug switch with `skill-trigger-hook.sh` |

## Tested and not tested (file-signal hook)

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
**2026-10-26 update:** the `dlc-pig-method-paper` session gave the real-conversation-turn
confirmation this entry had marked untested — `additionalContext` from `PostToolUse` *was*
visible to the model (it appeared as a `hook-feedback` block addressed to it) — but visibility
did not translate into action: the nudge fired once each for `hpc-job-scripts` and
`deeplabcut-hpc` and both were ignored, which is what motivated the escalation path above.
The escalation itself (second match → `pending.fs.<skill>` marker → one named `Stop` block) was
tested with synthetic piped payloads, mirroring the existing recipe: a first match nudges and
marks `nudged`; a second match for the same still-unloaded skill writes `pending.fs.<skill>`
instead of a second `additionalContext`; a `skill` load between the first and second match
clears the path (no escalation, confirming `loaded.<skill>` is still checked first); two
different skills each escalating in the same session produce one `Stop` block naming both,
not two; combined with an explicit-instruction `pending` marker, one block fires with a reason
that mentions both sources; `bash -n` and `check_sync_setup()` both still pass, including the
unchanged `file-signal hook never blocks` guard. **Still not tested:** the escalation firing
inside a real conversation turn (only the original nudge was confirmed live, not yet a second,
ignored one); the cost of scanning ~24 `SKILL.md` files per matching tool call at scale
(unsized, see ledger section 6.6); Linux/macOS; a second machine; whether this closes the gap
for skills beyond the two seeded `file_signals` patterns (needs a broader rollout decision, not
made here).
