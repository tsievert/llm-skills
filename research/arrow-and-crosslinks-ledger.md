# Arrow reuse and cross-linking across skills (ledger)

Started 2026-10-27. Working notes, not a skill. Follows `research/job-opportunity-watch-refactor-ledger.md`
(arrow, validate, targets findings are there). Nothing here has been applied to a skill yet.

## 1. Requirement (user, 2026-10-27)

Look beyond the lessons themselves: where could `arrow` be used in more skills, and where would stronger
cross-linking between existing skills help.

## 2. Local tests (2026-10-27, arrow 26.0.0, targets 1.12.0, Windows, R 4.6)

| Test | Result |
|---|---|
| Schema of a CSV without loading it: `arrow::open_csv_dataset(f)$schema` | works; types inferred (string, date32, int64, double). Parquet schema via `read_parquet(f, as_data_frame = FALSE, mmap = FALSE)$schema` (int32 kept). |
| Job-array pattern: one uniquely named parquet part per task, then `open_dataset(dir)` | works for 3 good parts. A part truncated to half its size (simulated killed writer) was **still listed by `open_dataset()` without error** ("4 Parquet files"); reading that file alone failed. So a per-part readability check plus a set difference against the expected task ids (found 3 and 5 missing/bad of 1..5) is needed; the dataset object alone is not a check. |
| `tar_target(x, df, format = "parquet")` | works (stored `objects/x`, `tar_read()` returns the data frame, dates kept). `r-reproducible-pipeline/references/targets-patterns.md` currently says parquet "is not covered"; that sentence is outdated. |
| Python (pyarrow) reading R-written files | **not tested**: Python was not available in this session. |

## 3. Where arrow (parquet) could be used (skill audit by text search; counts of tabular-format mentions)

| Skill | Today | Proposal | Status |
|---|---|---|---|
| `r-reproducible-pipeline` | RDS/qs/feather; says parquet not covered | Fix the sentence; add `format = "parquet"`; add the schema-contract plus `validate` plus set-equality-gate pattern and the Windows `mmap = FALSE` note (lessons already recorded) | fix, small |
| `hpc-r-code` (and `hpc-python-code`, `hpc-job-scripts` already say "parquet/npz/CSV") | `saveRDS`/`arrow`/`fst`; per-task files, atomic temp-then-rename | Name the pattern: one `part-<taskid>.parquet` per array task, merge with `open_dataset()`, then a readability check per part and a set difference against expected task ids (tested above); arrow docs say no ACID, so never one shared file (matches the existing rule) | add-note |
| `data-repository-readme` | `draft_data_dictionary.R` is base R and reads delimited text only | Optional: use `open_csv_dataset()$schema` and parquet footers for types without loading large files, and support parquet inputs. "Every file documented exactly once" in `check_readme` is already the same gate pattern as `jw_gate_*` | optional extension |
| `reproducible-research-data` | "parquet where size matters"; `check_deposit.R` flags RDS | Say: write parquet with an explicit schema and keep a CSV copy of key tables; the schema doubles as the data-dictionary source | add-note |
| `animal-behaviour-tracking-analysis` | 98 mentions of CSV/h5/RDS, none of arrow | Idea, untested: per-frame tidy tables from many videos as one parquet dataset (partitioned by session); per-video completeness gate (every manifest video has exactly one result, likelihood in 0..1) with `validate`. Keep `results.h5` (kpms) as is | idea, needs real-data test |
| `skill-lessons` (`usage.tsv`, `reminders.tsv`, inbox `.md`) | append-only TSV written by bash hooks | **Not recommended**: concurrent appends from shell hooks need plain-text append; parquet cannot append | reject |
| `codebase-map` (`DEPENDS.tsv`, `INVENTORY.md`) | grep-able text for the assistant | **Not recommended**: the point is that the assistant can grep it | reject |
| `openalex`, `social-research-search`, `web-fetching-r` | data frames in memory only | Low value alone; the staged pipeline already stores leads and tags. A saved-query ledger belongs to the planned `literature-review-workflow` | defer |
| Planned: `literature-review-workflow` | not started | Same staged shape as `job-opportunity-watch` (search, dedup, title screen, abstract screen, PRISMA counts) with a parquet ledger, validated stage files and gates | reuse pattern |
| Planned: `python-r-interop` | not started | Parquet files as the exchange format; the `schema$Equals` contract, the Windows mmap fact and atomic writes are ready; the Python side needs a test first | reuse + test |
| Planned: `grant-and-cv-support`, `chemical-ecology-data` | not started | Ledger-style state (publications, peak tables) could follow the same contract pattern | defer |

## 4. Cross-link audit (textual, `` `skill-name` `` mentions in SKILL.md, 18 skills compared)

`check_skill_links()` reports no findings, but it only checks consistency (one-way, unknown, isolated), not whether
a link that should exist is missing. Signals compared: mentions of targets, Quarto, parquet/arrow, ledger/state.

| Gap | Evidence | Proposal |
|---|---|---|
| `job-opportunity-watch` links only to `skill-lessons`, `web-fetching-r`, `social-research-search`, `openalex` | The staged pipeline now uses targets, Quarto, arrow, validate | Forward link to `r-reproducible-pipeline` (DAG, per-run store, checker); backlink from `r-reproducible-pipeline` as a worked example of an assistant-stage pipeline (decision: yes) |
| `animal-behaviour-tracking-analysis` links `python-reproducible-pipeline` but not `r-reproducible-pipeline`, though it ships R scripts and GLMM advice | R scripts `dlc_metrics.R`, `kpms_results.R`, `stats_demo.R` | Forward link; record `no-backlink` for `r-reproducible-pipeline` (generic skill, already links many domain skills) |
| `manuscript-writing-quarto` and `r-reproducible-pipeline` do not mention each other | Quarto reports via `tar_quarto` vs Quarto manuscripts | Two-way pointer: render the manuscript from a targets pipeline |
| `hpc-r-code` -> `r-reproducible-pipeline` exists; `hpc-python-code` has no equivalent to `python-reproducible-pipeline` | link matrix | Check; probably a `no-backlink` decision already covers it (see `link-decisions.tsv`), do not add by default |
| `data-repository-readme` and `reproducible-research-data` share the "every file documented" gate | already linked both ways | Mention the shared gate pattern in one line each, no new link |
| Hub skills (`skill-lessons`, `skill-feedback-triage`) | by design they do not collect domain pointers | no change |
| Tooling gap | no coverage check | Optional `check_skill_coverage()` in `github-skill-maintenance`: list skill pairs that share tool signals (targets, Quarto, parquet, ledger) and are unlinked; output is a candidate list, decisions go to `link-decisions.tsv` |

## 5. Open items

- Test pyarrow/Python reading R-written parquet (needs Python); decides the `python-r-interop` claim.
- Real DLC output for the animal-behaviour idea; no data in this session.
- Whether to add `check_skill_coverage()` (small script) or keep the audit ad hoc.
- All proposals need the user's approval before skill edits (link decisions are the user's call per the repo rules).

## 6. Log

- 2026-10-27: three local tests (schema inference, array part files with a truncated part, targets parquet format); text audit of 29 skills for tabular formats; link matrix of 18 skills. No network research (docs facts were already in the refactor ledger). No secrets.
