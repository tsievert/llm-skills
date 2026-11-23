# Triage: why fixes are minimal, and how to get better fixes

Generic wording only (public repo). Created 2026-11-23. Append new rounds as dated sections.

## Section index

1. Requirements
2. Round 2026-11-23: diagnosis of the least-effort tendency
3. Sources
4. Proposed changes
5. Open items
6. Log

## 1. Requirements

| # | Requirement | Date |
|---|---|---|
| R1 | The triage skill goes for one-line fixes where a broader, better-researched fix is needed; one-off fixes accumulate. Find out why and how to improve. | 2026-11-23 |

## 2. Diagnosis (local evidence)

| # | Finding | Evidence |
|---|---|---|
| D1 | Unit of work is the issue (cluster of entries), never the target file or the underlying cause. Nothing asks "what else has been patched into this section?" | `SKILL.md` step 3-5; ledger tables have one row per issue |
| D2 | The gates added 2026-11-17 to stop bloat push every outcome toward the smallest edit: "replace or merge, never append", "SKILL.md gets at most one line plus a pointer", "one report + behaviour change = park", 12 KB budget. They bound size, but nothing rewards or even permits restructuring a section, and no gate asks for a consolidation. | `triage-method.md` "Where a change goes"; `triage-process-ledger.md` round 1 |
| D3 | Research checklist is per claim (reproduce, upstream, CRAN, OpenAlex, read skill text) and answers "is this report true?", not "why did the skill/assistant allow this, and what design would prevent the whole class?" | `triage-method.md` checklist |
| D4 | Cause classification table maps "skill right, assistant did not follow it" to "strengthen wording or move the rule earlier" and "silent on a real case" to "add a short section". Both are text patches; no row says "enforce mechanically" (lint, script, hook) or "restructure". | `triage-method.md` "Classifying the cause" |
| D5 | `already-present` is treated as a clean close. A recurring report of text that already exists means the text failed, which is evidence for a different fix, not for closing. Example from a run ledger: the same CRLF-after-edit issue reported in three entries, closed `already-present` because two skills already say "run `file` after every edit". | `triage-run-2026-11-20b-ledger.md` row 2 |
| D6 | Several rows end as "add-note, merged into existing bullets" for one-project, unreproducible findings (cluster, GPU). Each is cheap and defensible alone; together they grow a reference file with unrelated bullets. | same ledger rows 3-7 |
| D7 | No churn signal. Edit counts since 2026-10-20 (from `git log`): `deeplabcut-hpc/SKILL.md` 27, `skill-feedback-triage/SKILL.md` 26, `hpc-job-scripts` 23, `github-skill-maintenance` 22, `gam-mgcv` 20. Files with many small edits are the candidates for a redesign, but triage never looks at this. | `git log --name-only` count |
| D8 | Ledgers are per run (nine `triage-run-*` files), so cross-run recurrence of a theme is invisible unless the assistant happens to remember it. | `research/` listing |

Not verified: whether the high-churn files are actually degraded (not read for contradictions); the churn count mixes triage edits with non-triage work.

## 3. Sources

| Source | Status | Facts used |
|---|---|---|
| ITIL problem management explainers (https://itsm.tools/problem-management-itsm-firefighting-to-prevention/, https://infraon.io/blog/itil-problem-management-guide-best-practices/, https://www.splunk.com/en_us/blog/learn/problem-management.html) | read (search extracts); skipped as authority for details: vendor blogs, commercial | Concept only: incident = restore quickly with a workaround; problem = root cause of a cluster of incidents; a "known error" has a cause and workaround but no permanent fix; permanent workarounds accumulate technical debt and should be reviewed for conversion to a real fix; the useful metric is repeat incidents, not activity counts. Used as an analogy, not as evidence about LLM skills. |
| "Why Does CLAUDE.md Keep Growing?" https://www.alphaxiv.org/abs/2608.11095 | partial (abstract/figures only); preprint, not peer reviewed | Across 1,867 repos, instruction files grow until a wholesale rewrite, drop about 40%, then regrow at a slightly faster rate; appending is cheap, deleting without the original rationale is risky. Implication: a rewrite needs the rationale kept somewhere (ledger/history), and a one-time rewrite is not enough without a standing prune rule. |
| "Harnesses That Improve Themselves" https://arxiv.org/html/2611.22299v1 | partial (search extract); preprint | Appending ad-hoc fixes accumulates contradictory rules; a single-run reflection mistakes random slips for missing rules; suggested defence: require repeated failures, deterministic verification. Partly supports the repo's existing thresholds, but argues against stopping at text patches. |
| Prompt Bloat pattern https://www.designpattern.fyi/patterns/prompt_bloat/ | read (search extract); practitioner site, weak | Remedies: owner, eviction policy, review of diffs, periodic pruning, lift recurring procedures into skills. Low evidence quality; consistent with the others. |
| fullsend-ai/agents issue 1646 | read (extract); anecdote | Recommends consolidation or deterministic linting rather than repeated fix cycles. Anecdote only. |
| SkillGrad https://arxiv.org/pdf/2605.27760 | partial; preprint | Skill structure target: body holds general knowledge only, single-instance content goes to references. Matches the repo's placement rule. |
| Agent Skills spec | not re-read this round (read 2026-11-17, see `triage-process-ledger.md`) | |
| Own-repo evidence | read | Section 2 |

Source quality: no peer-reviewed evidence found on skill-maintenance practice; the proposals below are design judgments supported by analogy, not tested.

## 4. Proposed changes (not yet applied; need user approval)

Principle: change the unit of triage from "issue" to "cause and target", and make a broader fix a first-class outcome with its own gate, rather than only restricting size.

1. **New outcome `rework`.** Rewrite or restructure a section, reference file or mechanism, in its own change, with a research row that goes beyond the checklist: read the whole target file, list every prior patch in it (`git log -p` on the file), name the underlying design, write the new shape, and check that every rule that existed before is either kept or deliberately dropped (a before/after rule list in the ledger, since deleting without rationale is the risky step).
2. **Cluster step before the table (new step 3a).** For each target file touched by an issue, show: edits in the last 60 days, other open or recently closed entries naming the file, and `already-present` closures that recurred. Trigger for `rework` proposal: at least 3 edits plus at least 2 entries in the window, or any recurring `already-present`.
3. **Recurrence rule.** An entry whose fix already exists is `already-present` only if it is the first report. A repeat report of the same issue after the fix date is a failed fix: reclassify and escalate along the ladder (text, then moved earlier or restructured, then mechanical enforcement such as a `lint_skills()` check, script or hook).
4. **Fix ladder replaces the single "strengthen wording" row** in the cause table: (a) text, (b) structure (move, merge, turn prose into a checklist or decision table), (c) enforcement (lint, script, hook, template), (d) remove the cause (delete the step, change the default). Each proposed fix states the lowest rung tried and why a higher rung was or was not chosen. Teaching rule: say why the cheap rung was enough.
5. **Table column "alternative considered"** next to the proposed change: one broader option and why not (cost, evidence, risk). Forces the comparison D1 and D3 show is missing.
6. **Batching of cheap notes.** `add-note` outcomes for one-project, unreproducible findings go to a per-skill `references/field-notes.md` section organised by topic, and each triage run that adds to it re-reads and re-groups that file (merge duplicates, promote notes seen in 2 or more projects into the proper reference). Replaces "merged into existing bullets" as the default.
7. **Standing ledger per target skill** instead of only per-run ledgers: a "pattern log" (one row per theme: entries, runs, fixes applied, rung, recurrence) so cross-run recurrence is visible (D8). Run ledgers keep the evidence; the pattern log is read in step 1.
8. **Churn check in `usage-review.md`** and as an info-level `lint_skills()` or helper output: edits per file from git in a window, shown beside size. High churn is a prompt to consider `rework`, not an error.
9. **Cap on the gates' side effect.** Reword gate 2 so "at most one line" applies to the default case; a `rework` is allowed to change more, under the size gate (net size not increased).

Verification for a `rework`: lint, `skills-ref validate`, re-run the original failing case if reproducible, and keep the before/after rule list; per the standing "verify before reporting ready" rule.

Cost/trade-off to tell the user: more research and more tokens per run, fewer runs touching the same files; the user decides how often a rework is worth it (suggest at most 1-2 per run, chosen by churn).

## 5. Open items

| # | Item | Status |
|---|---|---|
| O1 | Read the full alphaxiv and arXiv 2611.22299 papers (only extracts read) before relying on their numbers | open |
| O2 | Inspect the top-5 churn files for contradictions or redundant patches, to test D7 and choose a pilot `rework` | open |
| O3 | Count recurring `already-present` closures across all nine run ledgers and the dispositions file (D5) | open |
| O4 | Decide which of proposals 1-9 to implement | needs user |
| O5 | Prototype `file_churn()` in `read_lessons.R` or `github-skill-maintenance` | open |

## 6. Log

- 2026-11-23: read triage skill, `triage-method.md`, process ledger, run ledger 2026-11-20b, `git log` churn; 3 web searches (ITIL problem management; prompt bloat and holistic rewrite). No skill files edited.

## 7. Implementation and pilot (2026-11-23)

Implemented proposals 1-4 and 9 (see `HISTORY.md` 2026-11-23). Proposals 5 (alternative-considered column) is folded into step 5 and the ladder text; 6-8 not implemented.

### First `target_scan` on the real inbox

11 new, 26 parked, 139 closed entries. Only three skills have new entries; no possible repeats of closed entries were found.

| Skill | Edits (60 d) | Busiest file (edits) | Files with 3+ edits | New entries |
|---|---|---|---|---|
| job-opportunity-watch | 108 | `scripts/jobwatch.R` (12) | 15 | 5 |
| skill-feedback-triage | 51 | `SKILL.md` (26) | 4 | 5 (two worked-well, one use-case) |
| web-fetching-r | 8 | `SKILL.md` (4) | 1 | 1 |

Limits found: `target_scan` only covers skills that have new entries, so the highest-churn file overall (`deeplabcut-hpc/SKILL.md`, 27 edits, no new entries) is not flagged; the 5 job-opportunity-watch entries were already resolved in the same-day fetch-ladder commit and are still `new` only because they are not yet dispositioned (expect `already-present` or `fix`).

### Pilot candidate: `job-opportunity-watch/scripts/jobwatch.R`

Trigger met (3+ edits and 2+ entries). Evidence: 71 KB, 1103 lines, 66 functions in one file; 12 edits since 2026-10-20 from nine different triage or refactor commits; the 2026-11-23 commit already restructured its fetch path by failure class (a rework in substance, done without the gate). Design problem (one sentence): one script mixes links parsing, probing, JSON endpoint discovery, state, ledger, editing and social-tag code, so each lesson lands as another function in the same file.

Section sizes (functions): links file 10, probing 8, JSON sources and endpoint discovery 17, state/diff/audit 4, opportunities ledger 2, editing links/profile 7, headless run 1, replacement finder 4, social-tag ledger 4.

Proposed shape (rung 2, structure): split by concern into files sourced from a thin `jobwatch.R` loader, so every existing `source("jobwatch.R")` call keeps working (21 references in the skill): `jw_links.R`, `jw_probe.R` (probing plus JSON discovery), `jw_state.R`, `jw_edit.R`, `jw_social.R`. Rung 3 candidate: a test or `lint` check that each concern file stays under a size and that the loader sources all of them.

Gate status: step 1 (read whole target) and 2 (rule inventory) not done, only section-level counts; the function-level inventory with rationale per function is the first task if the user approves. Alternative considered: leave the file whole and only prune comments (cheaper, does not stop regrowth); not proposed because the churn comes from adding functions, not from comment text. Risk: sourced-path assumptions in `scripts/pipeline/*.R`, tests and `run_probe.R`; verify with the 41 offline tests and a probe on the fixture links, not a live probe.

### Open items added

| # | Item | Status |
|---|---|---|
| O6 | Extend `target_scan` to list all skills by churn, not only those with new entries | open |
| O7 | Disposition the 11 new entries (job-watch five likely `already-present`/`fix`) in the next triage run | open |
| O8 | User decision on the jobwatch.R pilot rework | needs user |
