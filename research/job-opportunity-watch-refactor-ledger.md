# job-opportunity-watch refactor ledger (staged weekly report)

Started 2026-10-27. Working notes, not a skill. Related: `research/pipeline-resources-ledger.md` (targets/crew/arrow facts),
inbox lessons triaged 2026-10-27 (see `HISTORY.md`).

## 1. Requirements (user, 2026-10-27)

| # | Requirement |
|---|---|
| R1 | Keep the weekly report: it must show what is new since the last run. |
| R2 | Clear task dependencies: what runs in which order, with what input and output. |
| R3 | Run across several conversations (stages) so one chat does not swell and cost more. |
| R4 | Research and use the R ecosystem (arrow suggested). |

## 2. Sources

| Source | Status | Facts |
|---|---|---|
| https://docs.ropensci.org/tarchetypes/reference/tar_age.html | read | `tar_age(age = difftime)` reruns a target when its output is older than `age`; **not suited to dynamic branching** (no timestamps for whole dynamic targets); use `tar_older()` + `tar_invalidate()` before `tar_make()` there. Age is not a hard guarantee if inputs changed rules apply. |
| https://cran.r-project.org/web/packages/taskscheduleR/index.html | read | v1.8, 2023-07-02, Windows only, imports data.table; no macOS binaries. Fine for the Windows scheduling case; `cronR` is the Linux/macOS counterpart (not looked up). |
| https://arrow.apache.org/docs/r/articles/dataset.html | read | `write_dataset()` hive-partitioned parquet, `open_dataset()` lazy with filter pushdown. Guidelines: avoid files < 20 MB and > 10,000 partitions; **no ACID, concurrent writes unsafe**, use unique basenames or a temp dir; parquet/IPC expose partial writes (CSV does not). Page does not cover append semantics. |
| https://ellmer.tidyverse.org/articles/structured-data.html | read | ellmer 0.5.0: `chat$chat_structured()` / `parallel_chat_structured(chat, prompts, type = type_array(type_object(...)))` returns a tibble, one row per prompt; `type_enum` for classes; `required = FALSE` to avoid hallucinated fields; tools are disabled in structured mode. Needs a provider API key (separate cost), so it is a user decision, not a default. |
| targets manual, crew (earlier ledger) | read (2026-10-23) | Make-like DAG, hash-based skipping, `format = "file"` tracking, Quarto via tarchetypes. |
| duckdb, pins, blastula, nanoparquet, qs2 | not researched | Installed? No (arrow 26.0.0, targets 1.12.0, crew 1.3.3, quarto 1.5.1, DT, reactable, gt, withr, callr are installed). |

## 3. Local test (2026-10-27, targets 1.12.0, arrow 26.0.0, Windows, R 4.6)

Pattern: an **assistant stage as a file target**. `llm_file()` stops with `STAGE_PENDING` if `classified.parquet` is missing;
`tar_target(llm_out, llm_file("classified.parquet"), format = "file", cue = tar_cue(mode = "always"))`; downstream `report` reads it.
- Missing file: `tar_make()` errors on that target only (`tar_progress`: errored); upstream targets that do not depend on it still complete.
- After the assistant writes the file: everything completes. Re-run with no change: all skipped.
- After the assistant changes the file: only `llm_out` and `report` rerun (hash change), upstream stays skipped.
So the DAG can contain stages the model performs, with skip/invalidation handled by targets. The error on a pending stage is
ugly; a status function that checks the file first is nicer. Gotcha: a global object in the session with the same name as a target
(`probe`) triggers a warning; run in `callr` (default) to avoid it.

## 4. Facts from the repo (current skill)

Steps 0-5 live in one SKILL.md (203 lines) and one script (520 lines); state is TSV files in `job-watch/state/`; `jw_headless()`
produces a digest of tier-1 titles only. Lessons show what was added by hand in the real project (deadline checker, nav-only
check, sitemap source, feed filter, weekly wrapper), i.e. the pipeline already exists informally and is not in the skill.

## 5. Open research items

- Whether a persistent store with `tar_age` per source, or one store per ISO week, fits better (dynamic branching per source
  rules out `tar_age`).
- `cronR` / Linux scheduling, email delivery (`blastula`) and a Quarto HTML report: not looked up.
- Parquet vs TSV for state: arrow dependency size vs readability; no benchmark at this data size (about 1,000 rows per baseline).
- ellmer batch classification: cost, privacy of profile text sent to a provider, reliability; untested.

## 6. Log

- 2026-10-27: read tar_age, taskscheduleR, arrow dataset and ellmer structured-data pages; tested the file-target hand-off
  pattern locally (results above); no secrets recorded.

## 7. Decisions (user, 2026-10-27)

| # | Decision |
|---|---|
| D1 | Stage 4 (classification) stays an assistant stage; no ellmer headless mode. |
| D2 | The user will not edit files by hand: R functions handle everything (links, profile, ledgers). Parquet for state is therefore fine. |
| D3 | One targets store / folder per ISO week. |
| D4 | Refactor `job-opportunity-watch` in place (no new skill). |
| D5 | Strongly integrate existing skills, especially `skill-lessons`. |

## 8. Round 2 research (2026-10-27): report template, safeguards, integration

| Source | Status | Facts |
|---|---|---|
| https://quarto.org/docs/dashboards/ and /data-display.html | read | Dashboards are static HTML, no server needed. Rows/columns/tabsets/cards via headings; value boxes via `#| content: valuebox` returning `list(icon, color, value)`; htmlwidget tables (DT, reactable) work; JS widgets embed one copy of the data per widget (heavier pages). Quarto 1.10 is current. |
| https://quarto.org/docs/computations/parameters.html | read | knitr parameters via YAML `params:`; override with `-P` or `--execute-params file.yml`; from R `quarto_render(execute_params = list())`. |
| https://docs.ropensci.org/tarchetypes/reference/tar_quarto.html | read | `tar_quarto()` finds upstream targets by scanning for `tar_load()`/`tar_read()` calls with symbol names in active R chunks (child documents and calls inside user functions are not detected); output is a file target; `execute_params` is an unevaluated expression; runs in the current working directory (a different `working_directory` needs matching `store=` in every `tar_read()`). |
| skill-lessons SKILL.md, scripts/lesson_helpers.R | read | `lesson_add()`, `usecase_add()`, `lesson_file()`; one file per session; R cannot write to the home inbox (fallback: print then `write` tool); hooks log skill loads (`usage.tsv`) and remind once per session; privacy rules (no paths, IDs, data values). |
| r-reproducible-pipeline, web-fetching-r, social-research-search | read (headers) | Existing targets conventions and checker; `pf_*` polite fetch; Bluesky/Mastodon helpers. |

Local test: a parameterised `format: dashboard` Quarto document (value boxes, tabset with two `reactable` tables, link cells) rendered
with `quarto::quarto_render(..., execute_params = list(week = ...))` on Quarto 1.10.18: success, `embed-resources: true`, single
3.1 MB HTML, about 23 s. Content checked by text search only (value boxes, tab titles present); not inspected visually; params
only change what code reads (a static YAML title does not update). 3 MB for a toy table suggests inlined Bootstrap and widget
libraries, so size is a fixed overhead, not data.

Design facts derived: the dashboard HTML is not cheap for the assistant to read, so the report stage must also write a short
`summary.md` that later conversations read instead.

## 9. Open items after round 2

- Visual check of the dashboard in a browser (user), and a decision on print/email output (`blastula`, PDF): not researched.
- `cronR` and macOS/Linux scheduling: not researched (user is on Windows; `taskscheduleR` 1.8).
- A validation package (`pointblank`, `validate`) vs hand-written arrow schema checks: not compared.
- Lock-file behaviour on synced folders (the project sits in a Syncthing folder per the user memory): not tested; risk of
  conflicting writes if two machines run stages.

## 10. Log

- 2026-10-27 (round 2): read Quarto dashboard, parameters and tar_quarto pages; prototyped and rendered a dashboard; read
  skill-lessons helpers; wrote decisions D1-D5. No secrets recorded.

## 11. Validation tooling comparison (2026-10-27)

Question: are `pointblank` or `validate` better than hand-written arrow schema checks for stage-output validation?
CRAN pages could not be fetched (network error); versions and dependencies come from `available.packages()` instead.

| Package | CRAN | Hard dependencies (recursive, CRAN db) | Notes |
|---|---|---|---|
| pointblank | 0.12.4 | 91 (imports include gt, dplyr, dbplyr, blastula, testthat, tidyr, DBI) | installed from CRAN 2026-10-27 (also pulled blastula, getPass, settings) |
| validate | 1.1.7 | 7 (stats, graphics, grid, settings, yaml, methods) | installed 2026-10-27 |
| checkmate | 2.3.4 | 2 | already installed; argument/object checks, not table reports |
| assertr, dataReporter | 3.0.1 / 1.0.5 | not compared | not tested |

Test: one faulty 5-row stage table (duplicate id, class outside A-E, http URL and NA URL, a 2031 deadline, ids not in the shortlist,
two shortlisted ids missing), written to parquet and read back. Same 8 rules three ways.

| Rule | Hand (arrow + base R) | validate | pointblank |
|---|---|---|---|
| Schema of the parquet file itself (date32 etc.) | yes, `schema$Equals()` on the file | no (checks R objects; `inherits()` was silently dropped with a warning: 10 rules given, 9 kept) | yes, `col_schema_match()` on the data frame (R classes, not file types) |
| Duplicates, enum, URL pattern, deadline range | all found | all found, failing counts per rule; `is_unique` flags both duplicate rows (2) | all found, per-step failure counts |
| Extra ids vs shortlist | found | found (`%in%` against reference) | found |
| Missing shortlisted ids (cross-file completeness) | found (setdiff) | not a row rule; needs a separate setdiff | not a row rule; separate setdiff |
| Failure output | text lines, no row detail unless coded | `summary()` table, `violating()` rows; rules are data (can be stored in the manifest) | gt agent report, thresholds (`warn_at`, `stop_at`), email actions |
| Weight and cost | about 12 lines | light | heavy installs; value is mostly the HTML report, which the weekly dashboard already replaces |

Findings and gotchas:
- The two checks that matter most for this pipeline (schema of the written file, completeness of the shortlist) are **not** covered
  by either package, so they stay hand-written regardless.
- `validate` is useful for the row rules because they read as data and can be listed in the Run log; verify the rule count
  after `validator()` (unsupported syntax is dropped with a warning, not an error).
- `pointblank` adds 80+ packages for a report we do not need; rejected on weight, not on capability.
- Limits: tiny synthetic table, no timing, no arrow Dataset input; `pointblank`'s thresholds/actions and YAML agents untested.

Recommendation: schema contracts as one named list of `arrow::schema()` objects used both to write and to validate; row rules
with `validate` (optional dependency) or plain base R; completeness gates by hand.

## 12. Skeleton build log (2026-10-27)

Built under `job-opportunity-watch/`: `scripts/pipeline/{jw_contracts,jw_pipeline,jw_report,jw_stubs}.R`, `tests/test_pipeline.R`,
`assets/pipeline/{_targets.R,report.qmd}`, `references/{pipeline,stage-s4-classify,stage-s5-discover}.md`, SKILL.md section.
Findings while building (all verified by tests or an end-to-end run):
- validate's `!logical_column` is unsupported and was dropped with only a warning; the rule-count check in `jw_make_validator()` caught it.
- Windows: `arrow::read_parquet()` memory-maps by default; overwriting/renaming a file that was just read fails (error 1224). Use `mmap = FALSE`.
- `targets::tar_make(script=, store=)` lets one skill-owned `_targets.R` drive a per-week store; the assistant stage as a
  `format = "file"` target with `cue = always` stops with a clear message until the stage is closed; afterwards only the report reruns.
- `tar_quarto()` was not used: it would render inside the skill folder; `jw_render_report()` copies the template into the run folder.
- `.gitattributes` had no rule for `.qmd`; added `*.qmd text eol=lf`.
Tested: 14 unit tests (64 expectations), end-to-end `tar_make()` with fixture stubs (stop at s4, rerun builds the report, third run no change),
Quarto 1.10.18 dashboard render. Not tested: real s1-s3 (stubs), non-Windows, synced-folder locking, two machines, a scheduled run, visual check of the dashboard.

## 13. Stage implementations s1-s3 (2026-10-27)

Source: user scripts in the gitignored `context-inbox/` (no web research this round). Built `scripts/pipeline/jw_checks.R` (pure text
checks), `jw_stage_fns.R` (s1-s3), `tests/test_stages.R` (12 tests); removed `jw_stubs.R`.
Decisions and findings:
- s2 needs the anchors, which the s1 contract did not carry: added side contract `s1_anchors` (source_id, text, href, job_like). "New" is
  derived from earlier finished weeks' `s1_anchors` (stateless; no seen-file), so reruns are idempotent and an unfinished earlier week
  does not count as seen. First week = baseline (info problem `s2_baseline`).
- Personal data: the inbox `feed_filter.R` had a synonym table keyed by the user's research field. Not copied. The skill now builds word
  lists from the profile and an optional `search_synonyms` block (key -> regex); keys without an entry fall back to their own words. An empty
  key list must produce a never-matching regex (an empty alternative matches everything).
- s3: the inbox `filter_expired.R` used dates in the href and a "post URL older than 75 days" rule; both are false-drop risks (posting dates)
  and the stale rule cannot satisfy the s3 contract, so s3 reads only cue-adjacent dates, from the link text first, then the page (tier 1 only,
  chunks of 150, resumable `s3_partial.parquet`). Dates outside 2020..today+3y become `parse_error` (contract rule `s3_plausible`).
- Gotchas: `as.Date("2026-02-30")` errors without `format=` (use `format="%Y-%m-%d"` to get NA); a length-1 `Date` column with zero-length
  siblings in `data.frame()` errors (empty queue case, found by a real-page smoke test); the write tool and `edit` produced CRLF files again,
  converted with `sed -i 's/\r$//'`.
- Tested: 26 tests green in total (was 14); one real page (nav-only) through s1-s3 on a temp data folder. Not tested: a real vacancy
  portal with many links, chunking against a live server, non-Windows, `tar_make()` with the real functions (only fixtures earlier).
- Open: next action 2 (sitemap/feed sources in `jw_probe_one`); `run_weekly` runner asset not written (scheduling notes are in `references/pipeline.md`).
