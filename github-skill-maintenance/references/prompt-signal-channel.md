# The prompt-signal channel and per-skill signal declarations

Second channel of `skill-file-signal-hook.sh`: it keys off the user's own prompt wording (`metadata.prompt_signals`) instead of file content. The file-content channel, the escalation mechanism and the marker files are in [file-signal-hook.md](file-signal-hook.md); the explicit-instruction hook is in [skill-trigger-hook.md](skill-trigger-hook.md). This file also holds the later per-skill declarations for both channels (tool-vocabulary skills, `tidy-data-wrangling`).

## Contents

- The prompt-signal channel
- Prompt signals declared on tool and code-vocabulary skills
- Wrangling signals on `tidy-data-wrangling`

## The prompt-signal channel (added 2026-10-28)

A second, parallel channel reuses all of the above mechanics (nudge once, escalate on a second
ignored match, never block itself) but keys off the **user's own prompt wording** instead of file
content, via a `metadata.prompt_signals` field (same shape as `file_signals`: a single
`'|'`-separated regex-alternation string). Added for `staged-assistant-workflow`, whose trigger is
"this task's own length/complexity" — a quality of the user's request, not something that shows up
in a file read — so the file-content channel doesn't apply (see
`research/staged-assistant-workflow-ledger.md` section 9 for the design history).

`skill-file-signal-hook.sh` now also handles `UserPromptSubmit`, scanning the whole raw payload
(same embedded-quotes reasoning as `skill-trigger-hook.sh`'s `UserPromptSubmit` handler) against
every skill's declared `prompt_signals`. Both channels share one marker namespace per skill
(`$sid.loaded.<skill>` / `$sid.nudged.<skill>` / `$sid.pending.fs.<skill>`), so a skill nudged once
via either channel is not nudged again via the other, and a second ignored hit on *either* channel
escalates into `skill-trigger-hook.sh`'s `Stop` block the same way.

| Skill | `prompt_signals` |
|---|---|
| `staged-assistant-workflow` | length/complexity phrases first (`huge/massive/very large/too big or long` + task noun; `many/several/multiple sessions ... to finish`; `will take weeks/days/sessions`), recurrence phrases second (`weekly/daily/recurring/periodic/every week`) — length leads per the skill's own rescoped definition (section 6 of its ledger), recurrence is a named secondary case, not the trigger. |

Settings entry: `skill-file-signal-hook.sh` added alongside `skill-trigger-hook.sh` under
`hooks.UserPromptSubmit` (additive, not a replacement):

```json
"UserPromptSubmit": [{"hooks": [
  {"type": "command", "command": "bash .../skill-trigger-hook.sh", "timeout": 10},
  {"type": "command", "command": "bash .../skill-file-signal-hook.sh", "timeout": 10}
]}]
```

`check_sync_setup()` gained matching checks: `prompt-signal UserPromptSubmit hook` (the command is
present), `prompt-signal declaring skills` (which skills declare the field, mirroring the
file-signal one), and an error if any skill declares `prompt_signals` but no hook command is wired
under `UserPromptSubmit`. `lint_skills()` gained a matching `prompt_signals` check (single string,
compiles as an extended regex, specificity warning on short alternatives) — note the specificity
check splits only on top-level `|` (outside parentheses), so a nested alternation such as
`every (week|day|month)` counts as one alternative. Before 2026-11-05 it split on every `|` and
raised a spurious low-specificity warning on the inner word `day` for `staged-assistant-workflow`;
fixed, and the same pattern now lints clean. Escaped characters are skipped; bracket expressions
(`[|]`) are not parsed, which could only mis-split in the cautious direction.

**Tested** (synthetic piped payloads, Windows Git Bash): a matching `UserPromptSubmit` prompt
nudges once; a second matching prompt in the same session escalates (writes
`pending.fs.<skill>`, no second `additionalContext` line) instead of repeating itself; an unrelated
prompt is silent; a length/complexity-phrased prompt and a recurrence-phrased prompt both match
(two different alternatives in the same field); a skill already loaded via a prior `PostToolUse`
`skill` call is never nudged via `UserPromptSubmit` either (shared marker namespace confirmed); a
prompt with embedded double quotes is still detected (whole-payload scan, not an extracted field);
a missing `session_id` and malformed/empty stdin do not crash the script; the pre-existing
`file_signals`/`PostToolUse` channel still works unchanged after the refactor that factored both
channels through one shared `check_signal()` function, including the dash-leading-pattern `--`
guard (`hpc-gpu-jobs`'s `--gres=gpu`). **Not tested:** firing inside a real conversation turn (only
synthetic payloads this round); Linux/macOS; whether the length/complexity phrasing is well
calibrated against real negative examples (e.g. "I check my email daily" containing "daily" with no
task relevance) — drafted from the ledger's phrase sketches, not yet tuned against a negative-example
set the way `references/testing-skills.md`'s trigger-query protocol recommends.

## Prompt signals declared on tool/code-vocabulary skills (added 2026-10-29)

Besides `staged-assistant-workflow`, `prompt_signals` is now declared on skills whose users typically paste code or
error text into the prompt, using distinctive tokens only. Where a skill already had `file_signals`, the prompt pattern
mirrors it (plus a few prompt-only terms).

| Skill | `prompt_signals` |
|---|---|
| `keypoint-moseq` | `'\bkpms\b\|keypoint[-_]moseq\|\bjax[-_]moseq\b\|\bkappa\b[^.?!\n]{0,60}\bsyllable'` |
| `deeplabcut-hpc` | `'deeplabcut\|DeepLabCut\|\banalyze_videos\b\|\btrain_network\b\|pytorch_config\.yaml\|pose_cfg\.yaml'` |
| `hpc-job-scripts` | `'#SBATCH\|\bsbatch\b\|\bsrun\b'` |
| `hpc-resource-allocation` | `'OUT_OF_MEMORY\|\boom-kill\b\|DUE TO TIME LIMIT\|\bseff\b\|\bsacct\b'` |
| `mixed-models-glmm` | `'\b(glmmTMB\|glmer\|lmer\|lmerTest\|DHARMa)\b\|boundary \(singular\) fit'` |
| `gam-mgcv` | `'\bmgcv\b\|\bgam\.check\b\|\bbam\(\|\bgratia\b'` |
| `r-reproducible-pipeline` | `'_targets\.R\|\btar_make\b\|\btar_target\b\|\bcrew\.cluster\b'` |
| `python-reproducible-pipeline` | `'\bsnakemake\b\|\bSnakefile\b\|\buv\.lock\b'` |

Deliberately not added: `hpc-gpu-jobs`, `hpc-python-code`, `hpc-r-code` (a pasted Slurm message would nudge four HPC
skills at once; the nudge budget is per skill, so noise multiplies), `animal-behaviour-tracking-analysis` (no distinctive
token, its vocabulary is generic: "distance", "freezing"), and skills defined by task rather than vocabulary
(`openalex`, `manuscript-*`, `data-repository-readme`). Caveat: the scan covers the whole raw payload, so a `cwd` path
containing a signal word also matches. Tested with synthetic `UserPromptSubmit` payloads (kpms code, glmmTMB singular
fit, oom-kill, `analyze_videos` nudge; "what is a mean" silent; a repeat kpms match escalates silently). `weekly` in an
unrelated prompt still nudges `staged-assistant-workflow` (the known calibration gap above). Not tested live.

## Wrangling signals on `tidy-data-wrangling` (added 2026-10-30)

Both channels are declared, because wrangling shows up as function names in prompts (`pivot_longer`, `clean_names`) and
in scripts the assistant reads. Alternatives are tidyr/janitor/readxl/tidyxl/unpivotr function names, `library(tidyr)`,
`library(janitor)`, `library(readxl)`, `tidyr::`, `janitor::` (file channel), and the phrases `wide to long`, `long to wide`,
`messy data`, `tidy data` (prompt channel). `library(dplyr)`, `library(tidyverse)`, `mutate`, `filter` and joins were left out on
purpose: they appear in almost every R script, so every analysis session would be nudged. Tested with synthetic payloads
(`pivot_longer` prompt nudges, a second match escalates silently, `fit a gam` silent, `library(janitor)` file read nudges,
`library(dplyr)` file read silent, `wide to long` nudges). Regex probes: `read_excel(path)` matches; "my tidy plot", "use dplyr
filter" do not. Known over-match: `tidy data` in a README or deposit request nudges this skill too (cost: one ignorable line).
Not tested live.

Round 2 (2026-10-30, same day): added wording triggers for the word "wrangling" and for cleaning phrases in the prompt channel
(`wrangl*`, "data cleaning", "data tidying", "reshaping", "clean my/the/this data", "clean up (my|this) data"), and section-header
and script-banner wording in the file channel for `.qmd`, `.Rmd` and `.R` files read by the assistant (`## Data wrangling`,
`# ---- Clean data ----`, `### Import data`, `## Tidy ...`, `## Reshape ...`, `## Join tables`, `## Missing values`, plus
"data cleaning", "data preparation"). Patterns avoid `^` anchors because the scan runs over the tool response as one string,
and avoid groups containing `|` because the linter splits naively on every `|`. Synthetic payloads: a qmd with `## Data wrangling`
and an R script with `# ---- Clean data ----` nudge; `## Results` / `## Figure 1` stay silent; "help me wrangle this table" nudges.
Over-match risk: a README or methods section titled "Data cleaning" in a non-R project also nudges; cost is one ignorable line.
