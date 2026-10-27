# Hand-off: job-opportunity-watch staged-pipeline refactor

Written 2026-10-27 to restart in a fresh conversation. Read this file first, then only what the
"Next actions" below name. Delete or archive it (move to `research/`) when the work stream ends.

## Goal and decisions (user, 2026-10-27)

Weekly report that shows what is new since the last run; clear stage order with named inputs and outputs;
stages run in separate conversations (or headless) so no conversation swells. Decisions: stage 4 stays an
assistant stage (no `ellmer`); no hand-editing of files, R functions handle everything (parquet state is fine);
one folder/store per ISO week; refactor `job-opportunity-watch` in place; integrate existing skills,
especially `skill-lessons`. Full research and test log: `research/job-opportunity-watch-refactor-ledger.md`
(sections 1-12; do not repeat a search that has a row there).

## What exists (all under `job-opportunity-watch/`, nothing committed yet)

| Path | What |
|---|---|
| `scripts/pipeline/jw_contracts.R` | per-stage `arrow` schemas, `validate` row rules (`jw_make_validator()` refuses dropped rules), gates `jw_gate_s1/s3/s4` |
| `scripts/pipeline/jw_pipeline.R` | stage table `jw_stages`, run folders, manifest, lock, atomic parquet write (`mmap = FALSE`), `jw_stage_begin/close/run/skip`, `jw_part_write/jw_pending` (resumable s4), ledger, `jw_status()`, problems log, `jw_lessons_candidates()`, `jw_usecase_args()`, `jw_freeze_inputs()` |
| `scripts/pipeline/jw_report.R` | `jw_load()`, `jw_preflight()` (s0), `jw_write_summary()`, `jw_render_report()` (s6) |
| `scripts/pipeline/jw_checks.R`, `jw_stage_fns.R` | **done 2026-10-27**: s1-s3 functions (`jw_s1_probe`, `jw_s1_expected_n`, `jw_s2_queue`, `jw_s3_deadlines`) and pure text checks; side contract `s1_anchors`; network injected for tests (ledger section 13) |
| `scripts/pipeline/tests/` | `test_pipeline.R` (14) and `test_stages.R` (12), 26 tests all passing; s0 runs them |
| `assets/pipeline/_targets.R`, `report.qmd` | headless DAG (stops at the assistant stage until closed), Quarto dashboard |
| `references/pipeline.md`, `stage-s4-classify.md`, `stage-s5-discover.md` | contracts, untrusted-text rule, batches, lessons close-out |
| `SKILL.md` | one new section pointing to the above; the old Steps 0-5 still apply |

Verified: unit tests; end-to-end `tar_make(script=, store=)` with fixture stubs (stops at s4, report rebuilds
after close, third run no change); dashboard renders (Quarto 1.10.18). Not verified: real s1-s3, non-Windows,
a scheduled run, two machines or a synced-folder lock, visual look of the dashboard.

## Next actions (in this order)

1. **DONE (2026-10-27): stubs implemented.** Not done from it: a `run_weekly` runner asset (notes are in
   `references/pipeline.md`, "Scheduling notes"), `tar_make()` rerun with the real functions, test on a real
   multi-link portal. Original brief, source material in the gitignored
   `context-inbox/` (user scripts that worked on real pages): `job_like_check.R` (`jw_job_like_check`,
   `jw_probe_sitemap`, `jw_sitemap_anchors`; s1 flag and sitemap sources), `filter_expired.R` and
   `deadline_check.R` (s3; use the revised first-date-after-cue version, German/Finnish/Swedish cues, topic
   prefilter first, chunks of about 150 URLs), `feed_filter.R` (s2; profile-derived word lists, reason column,
   keep/drop title test list, smoke test), `run_weekly.R` (scheduling notes: path variable, seed the seen-files,
   ask before installing a task, `//` switches for `schtasks` from Git Bash). Output must match
   `jw_contracts()` (columns and types); gates in `jw_contracts.R` define completeness.
   Do not copy personal data (profile, links, URLs) from those files into the skill.
2. **DONE (2026-10-27):** native sitemap support (`type = sitemap`) in `jw_probe_one`; vacancy-likeness check after
   every probe in `jw_probe`; `\b` fix in `.jl_pat`; `tar_make()` run on 3 real links (s1-s3 done, stops at s4). Open:
   category links like `/jobs/life-science/` count as job-like (portal "fine" is weak evidence); feed sources not built.
3. **DONE (2026-10-27)** (new `stage-s1-probe.md`, `stage-s6-report.md`; triage/verify folded into `stage-s4-classify.md`,
   tag ledger into `stage-s5-discover.md`; `jw_category_link()` added to the job-like check). Original: Rewrite `SKILL.md` around the stages (shrink Steps 0-5 into the stage references; keep description and the
   standing sections: Related skills, Explain the reasoning, Capture lessons). Add a subagent note only where a
   genuine case exists (s4 bulk title skim is already covered).
4. Remaining notes from triage (add to `job-opportunity-watch` references): feed-verification checklist, JS-only
   source handling, aggregator noise and near-miss line in `classification.md`, tag ledger `query_type` and
   posts per month, subagent handoff files go inside the data folder.
5. Verify with `github-skill-maintenance` (`lint_skills()`, `check_skill_links()`, `check_skill_clashes()`,
   `skills-ref validate` if `uvx` is available), then commit in logical groups: (a) `social-research-search`
   notes, (b) pipeline skeleton, (c) later stage implementations.

## Lessons triage state

- Original inbox: 7 `job-search_*` files in `~/.posit/lessons/inbox/` (40 entries, one project). Triage table
  was shown and approved in part. Applied: issue 7 for `social-research-search` only (Bluesky AND-matching,
  single words for non-English text, job-bot accounts, Mastodon tag saturation, screening filter, compact
  printing; reproduced live). Everything else is folded into the refactor above (issues 1, 2, 4 = next action 1;
  3, 5, 6, 8 = next action 4; 9 = see below; 10 parked).
- New file `llm-skills_20261027-170000_job-watch-refactor.md` (10 entries from this refactor, already in the
  inbox): 5 for `r-reproducible-pipeline` (assistant stage as file target with `tar_make(script, store)`; Windows
  parquet `mmap`; data validation hybrid; `executeCode` `setwd` pitfall; Quarto dashboards; the built-in
  `quarto-authoring` skill is not in this repo), 1 each for `skill-feedback-triage` (reading conversation
  exports), `skill-lessons` (entry types seen in practice; per-stage use-case entries), `github-skill-maintenance`
  (do not write files through bash heredocs), `agents-md-maintenance` (hand-off note pattern, this file is an
  example), and a low-confidence `new-skill-suggestion` `staged-assistant-workflow` (wait for a second workflow).
- Not done: `usage.tsv` does not exist on this machine (no load counts); inbox not archived to `processed/`;
  watermark in `AGENTS.md` not advanced (`triage_watermark_set()` only after the user has seen the full table).
  Rerun `skill-feedback-triage`; it will include the new file. Issue 9 (lesson types) is still open.

## Working-tree notes

Uncommitted: `.gitattributes` (`*.qmd` rule, mine), `HISTORY.md` (mine), `research/...-refactor-ledger.md`
(mine), `social-research-search/SKILL.md`, `job-opportunity-watch/` (new files and SKILL.md section), plus
`AGENTS.md` and `.gitignore` changes that were already present when this session started: check
`git diff AGENTS.md .gitignore` before committing so they are not committed by accident.
`AGENTS.md` is about 17 KB and `HISTORY.md` about 105 KB; consider the `agents-md-maintenance` skill.

## Pitfalls met in this work stream (details in the lessons above)

Write multi-line files with the `write`/`edit` tools, not bash heredocs; after every edit check LF endings
(`git ls-files --eol`, or `file` for untracked files); `executeCode` does not restore `setwd()` via a
top-level `on.exit`; `validate` drops unsupported rule syntax with only a warning; on Windows read parquet
with `mmap = FALSE`; CRAN installs are allowed without asking, GitHub/R-universe need the user's permission.

## How to resume

Say: "Continue the job-watch refactor from `HANDOFF-job-watch-refactor.md`, next action 1." Start with
`source("job-opportunity-watch/scripts/pipeline/jw_report.R"); jw_load()` and run the tests
(`testthat::test_dir("job-opportunity-watch/scripts/pipeline/tests")`) to confirm the baseline is green.

## Todo: arrow reuse and cross-linking (from `research/arrow-and-crosslinks-ledger.md`, none applied yet)

Separate from the refactor. Each item needs the user's go-ahead (link decisions are theirs); after edits run
`lint_skills()`, `check_skill_links()` and record `no-backlink` rows in
`github-skill-maintenance/references/link-decisions.tsv` where a backlink is declined.

Quick fixes (suggested first):
- [ ] `r-reproducible-pipeline/references/targets-patterns.md`: replace "Parquet is not covered" with the tested
  `format = "parquet"` (targets 1.12.0, arrow 26.0.0); add schema contract + `validate` + set-equality gate and the
  Windows `mmap = FALSE` note (lessons already in the inbox).
- [ ] `hpc-r-code`: per-array-task `part-<taskid>.parquet`, merge with `open_dataset()`, then check each part is
  readable and diff against the expected task ids (a truncated part is still listed by `open_dataset()`).
- [ ] Links: `job-opportunity-watch` -> `r-reproducible-pipeline` plus backlink as a worked example of an
  assistant-stage pipeline; `animal-behaviour-tracking-analysis` -> `r-reproducible-pipeline` (record
  `no-backlink`); `manuscript-writing-quarto` <-> `r-reproducible-pipeline` (render a manuscript from a targets pipeline).

Later / optional:
- [ ] `reproducible-research-data`: note to write parquet with an explicit schema and keep a CSV copy of key tables.
- [ ] `data-repository-readme`: let `draft_data_dictionary.R` read types via `open_csv_dataset()$schema` and parquet
  footers (it reads delimited text only now).
- [ ] `github-skill-maintenance`: optional `check_skill_coverage()` listing unlinked skill pairs that share tool signals.
- [ ] `animal-behaviour-tracking-analysis`: per-frame parquet dataset and per-video completeness gate (idea, needs real DLC data).
- [ ] Planned skills: reuse the staged ledger/gate pattern for `literature-review-workflow`; test pyarrow/Python reading
  R-written parquet before writing `python-r-interop` (Python was unavailable); `staged-assistant-workflow` waits for a second use.
- [ ] Not recommended (do not revisit without new evidence): parquet for `skill-lessons` logs (`usage.tsv`,
  `reminders.tsv`: shell appends) and for `codebase-map` (must stay greppable text).
