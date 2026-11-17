# Skill-trigger hooks: reference

Merged 2026-11-17 from three files (explicit-instruction hook, file-signal hook, prompt-signal channel). Design
research and history: `research/skill-trigger-hooks-ledger.md` and `research/staged-assistant-workflow-ledger.md`.

## Contents

- Overview: two hook scripts, three triggers
- R1: the explicit-instruction hook (`skill-trigger-hook.sh`)
- R2: the signal hook (`skill-file-signal-hook.sh`): file channel and prompt channel
- Escalation
- Settings entries
- State files
- Declared signals per skill
- Test recipe
- Tested and not tested

## Overview: two hook scripts, three triggers

Two undertrigger modes exist (the manual trigger-query side is in [testing-skills.md](testing-skills.md)):

| Trigger | Script | Behaviour |
|---|---|---|
| The user explicitly asks for a skill ("trigger/use/load ... skill") and no `skill()` call follows | `scripts/skill-trigger-hook.sh` (R1) | Deterministic: blocks the `Stop` once per session. |
| Tool output (file content) matches a skill's `metadata.file_signals` | `scripts/skill-file-signal-hook.sh` (R2) | Non-blocking nudge (`additionalContext`) once per (session, skill). |
| The user's prompt matches a skill's `metadata.prompt_signals` | `scripts/skill-file-signal-hook.sh` (R2) | Same nudge, same shared markers. |

R1 cannot judge whether the skill eventually loaded was the right one, only that some `skill()` call happened.
R2 cannot judge whether a skill should have fired, only whether a declared text pattern appeared; its worst case is
one ignorable line, which is why it never blocks. Prior art for the non-blocking pattern is in the ledger (sections 6
and 8). Real-session evidence: a real HPC/DeepLabCut session confirmed both hooks fire and are visible to the model,
that a single nudge was ignored twice (which motivated the escalation below), and that R1 forced a `skill()` call but
the wrong skill (`skill-lessons`) was loaded, the documented limit.

## R1: the explicit-instruction hook

Three events:

| Event | Matcher | Action |
|---|---|---|
| `UserPromptSubmit` | none | If the prompt matches an imperative "trigger/use/load/invoke/apply ... skill(s)" phrase (or the passive form), not immediately followed by `?`, write `state/<session>.pending`. Never blocks. |
| `PostToolUse` | `skill` | Any skill load clears the pending marker for the session. |
| `Stop` | none | If a pending marker (or an escalation marker, see below) still exists and the session has not been reminded, block once (`decision:"block"`), log it, clear the markers. `stop_hook_active` guards the loop. |

The `Stop` reason is a fixed generic string for explicit instructions; it does not quote the user's text, because
extracting a JSON string field with `sed` breaks on embedded quotes and relaying raw text through `printf` adds
escaping risk. A skill name taken from an escalation marker filename is safe (controlled vocabulary).

**The phrase match scans the whole raw payload, not just `prompt`.** `jstr()` (single-capture `sed`) is fine for
structural fields (`session_id`, `cwd`, `tool_name`) but truncates free text at the first `\"`. The other
`UserPromptSubmit` fields cannot plausibly contain the phrase, so false matches from outside the prompt are negligible.
R2 scans the payload the same way.

**Question versus instruction.** "Is the pitfall a reason to trigger the lessons-learned rule in some of your skills?"
is a question about triggering. The regex excludes a match when `skill(s)` or the verb is immediately followed by `?`
(PCRE negative lookahead, `grep -P`):

```
\b(trigger|use|load|invoke|apply)\b[^.?!\n]{0,60}\bskills?\b(?!\s*\?)
|\bskills?\b[^.?!\n]{0,60}\b(triggered|loaded|used|invoked|applied)\b(?!\s*\?)
```

Known, accepted false positive: a question with more words before the `?` still matches ("Should we use a different
skill here?"). Cost: one extra forced turn, once per session. `grep -P` must work in the hook's shell (GNU grep 3.0
under Git Bash confirmed); if detection misfires, check `grep --version` in the real hook shell, which
`check_sync_setup()` flags as an `info` item it cannot verify.

## R2: the signal hook

Script `scripts/skill-file-signal-hook.sh`, built after a second independent recurrence of the context-clue
undertrigger. Events:

| Event / matcher | Action |
|---|---|
| `PostToolUse` `skill` | Marks that skill loaded (`state/<session>.loaded.<skill>`); it is never nudged again. |
| `PostToolUse` `read\|grep\|bash` | Scans `tool_response` against every skill's `metadata.file_signals`. First match for a skill not yet loaded: emits `additionalContext` naming it and marks it nudged. Second match: writes an escalation marker instead. |
| `UserPromptSubmit` | Scans the raw payload against every skill's `metadata.prompt_signals`, with the same nudge and escalation logic. |

Both fields are a single `'|'`-separated regex-alternation string in the skill's own `SKILL.md` frontmatter (flat
string, never a YAML list). Both channels share one marker namespace per skill, so a skill nudged via one channel is
not nudged via the other, and a second ignored hit on either escalates. Both channels run through one shared
`check_signal()` function. The prompt channel exists because some skills (for example `staged-assistant-workflow`)
trigger on a quality of the request, not on file content.

Rules for declaring signals: opt-in and deliberately narrow; only a strong, low-ambiguity signature that matches a clause
already in the skill's description; never speculative, since a vague pattern produces noise. `lint_skills()` checks that
each field is one string, compiles as an extended regex and has reasonably specific alternatives. Its specificity check
splits only on top-level `|` (outside parentheses), so `every (week|day|month)` is one alternative; bracket expressions
are not parsed; escaped characters are skipped. Avoid `^` anchors (the scan runs over the response as one string) and
groups containing `|`.

**`grep -E -- "$pat"` pitfall:** a pattern starting with `-` (`--gres=gpu`) is parsed by `grep` as an option. The hook
uses `grep -qE -- "$pat"`. `lint_skills()` compiles with R's `grepl()`, which does not catch this; any future script
that greps a signal value needs the same `--` guard (not enforced by the linter).

## Escalation

A single nudge was visible but ignored in a real session. On a second match for a skill already nudged and still
unloaded, R2 writes `state/<session>.pending.fs.<skill>` instead of repeating the line. R1's `Stop` handler checks
these markers with its own `pending` marker and blocks once if any exists; all sources share the single per-session
"reminded" budget, so there is no second nag. The reason names the skill(s) from the markers. R2 itself never emits
`decision:"block"`; `check_sync_setup()` errors if that ever changes. Failure costs stay matched to reliability: the
nudge is cheap and can be wrong; the one block reuses R1's bounded cost (one forced turn per session).

## Settings entries

Global `~/.posit/assistant/settings.json`. Hooks are additive and every matching hook runs.

```json
"UserPromptSubmit": [{"hooks": [
  {"type": "command", "command": "bash C:/Users/<you>/Sync_Home_Work/llm-skills/scripts/skill-trigger-hook.sh", "timeout": 10},
  {"type": "command", "command": "bash .../skill-file-signal-hook.sh", "timeout": 10}
]}],
"PostToolUse": [
  {"matcher": "skill", "hooks": [
    {"type": "command", "command": "bash .../lessons-hook.sh", "timeout": 10},
    {"type": "command", "command": "bash .../skill-trigger-hook.sh", "timeout": 10},
    {"type": "command", "command": "bash .../skill-file-signal-hook.sh", "timeout": 10}
  ]},
  {"matcher": "read|grep|bash", "hooks": [
    {"type": "command", "command": "bash .../skill-file-signal-hook.sh", "timeout": 10}
  ]}
],
"Stop": [{"hooks": [
  {"type": "command", "command": "bash .../lessons-hook.sh", "timeout": 10},
  {"type": "command", "command": "bash .../skill-trigger-hook.sh", "timeout": 10}
]}]
```

`check_sync_setup()` audits these entries like the lessons hooks (script exists, LF endings, `bash -n`,
`stop_hook_active` guard, valid handler fields, file-signal never blocks, which skills declare each signal field, and
an error if a skill declares `prompt_signals` with no `UserPromptSubmit` command wired).

## State files

All under `~/.posit/skill-triggers/`. No project-identifying or user-text content is stored.

| Path | Content |
|---|---|
| `state/<session>.pending` | explicit instruction unresolved; timestamp only |
| `state/<session>.reminded` | this session was already blocked once |
| `state/<session>.loaded.<skill>` | that skill was loaded this session |
| `state/<session>.nudged.<skill>` | a nudge already fired for that pair |
| `state/<session>.pending.fs.<skill>` | second ignored match; read and cleared by R1's `Stop` handler |
| `reminders.tsv` | one row per block issued (time, session, project) |
| `state/DEBUG` | create (empty) to dump raw payloads to `state/debug-payloads.jsonl`; may hold private content, delete afterwards |

## Declared signals per skill

Declared in each skill's own frontmatter; read the frontmatter for the current values. The set at the last review
(2026-11) and the reasons:

| Skill | Channels | Notes |
|---|---|---|
| `hpc-job-scripts` | file, prompt | `#SBATCH`, `sbatch`, `srun` |
| `deeplabcut-hpc` | file, prompt | package import, config file names, `analyze_videos`, `train_network` |
| `hpc-gpu-jobs` | file | `--gres=gpu`, `--gpus`, `CUDA_VISIBLE_DEVICES`, `torchrun` |
| `hpc-resource-allocation` | file, prompt | `OUT_OF_MEMORY`, `oom-kill`, `sacct`, `seff`, time-limit text |
| `hpc-python-code`, `hpc-r-code` | file | signal handling, `parallelly::availableCores`, `R_LIBS_USER` |
| `keypoint-moseq` | file, prompt | imports, `kpms.<fn>(`, `jax_moseq`, kappa plus syllable |
| `mixed-models-glmm`, `gam-mgcv` | prompt | function names, singular-fit text, `gam.check`, `gratia` |
| `r-reproducible-pipeline`, `python-reproducible-pipeline` | prompt | `_targets.R`, `tar_make`, `snakemake`, `uv.lock` |
| `staged-assistant-workflow` | prompt | length and complexity phrases first, recurrence phrases second |
| `tidy-data-wrangling` | file, prompt | tidyr/janitor/readxl function names and `library()` calls, "wide to long", "wrangling", cleaning phrases, wrangling section headers in `.qmd`/`.Rmd`/`.R` |

Deliberately left out: `hpc-cluster-docs` (a run-first skill, no distinguishing content pattern); `hpc-gpu-jobs`,
`hpc-python-code`, `hpc-r-code` on the prompt channel (a pasted Slurm message would nudge four HPC skills at once);
`animal-behaviour-tracking-analysis` (generic vocabulary); task-defined skills (`openalex`, `manuscript-*`,
`data-repository-readme`); and for wrangling, `library(dplyr)`, `library(tidyverse)`, `mutate`, `filter` and joins
(they appear in almost every R script).

Known over-matches (cost: one ignorable line): the scan covers the whole raw payload, so a `cwd` path containing a
signal word matches; `weekly` or `daily` in an unrelated prompt nudges `staged-assistant-workflow` (not calibrated
against negative examples); `tidy data` or "Data cleaning" in a README or methods section nudges `tidy-data-wrangling`.

## Test recipe

No real session needed. Pipe synthetic payloads into the script with `SKILL_TRIGGER_DIR` pointing at a scratch folder
(mirrors `skill-lessons/references/hook-setup.md`). R1: a prompt without trigger phrasing writes no marker; an
explicit instruction writes one; `Stop` with the marker blocks once and leaves a `reminded` flag; a second `Stop`
stays silent; a `skill` `PostToolUse` clears the marker first; `stop_hook_active: true` never blocks; a missing
`session_id` exits silently; embedded `"` quotes are still detected; the question near-miss is excluded; empty or
non-JSON stdin does not crash. R2: a matching `read` result nudges once; a repeat is silent; a second match writes
`pending.fs.<skill>`; a prior `skill` load keeps it silent; unrelated content and non-matching tools are silent;
embedded quotes are detected; a `--`-leading pattern works; a matching prompt nudges and a second one escalates; two
skills escalating together give one block naming both; an explicit-instruction marker plus an escalation marker give
one block mentioning both.

## Tested and not tested

Tested on Windows (R 4.6.0, Git Bash, GNU bash 5.3, GNU grep 3.0) with synthetic piped payloads: all scenarios in the
test recipe, `bash -n`, the `lint_skills()` signal checks (observed on the declaring skills, no findings), and
`check_sync_setup(cfg = <real settings.json text>)` (read with bash and passed as `cfg`, since the R session cannot
read that path). Real-session observations: both hooks fire and their output is visible to the model; one nudge was
ignored twice; the R1 `Stop` handler forced a `skill()` call but the wrong skill was loaded.

Not tested: the escalation firing inside a real turn (only the single nudge was seen live); the prompt channel live;
`SubagentStop`; Linux or macOS; a second machine; the cost of scanning every skill's frontmatter at scale;
calibration of the prompt phrases against real negative examples; whether naming the skill in the escalated block
steers the assistant to the right skill (a hypothesis); whether the sandboxed bash matches the real Git Bash
`grep`/`sed` behaviour.
