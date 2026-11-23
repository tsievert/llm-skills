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

## 14. `run_weekly.R` runner and a real `tar_make()` end-to-end run (2026-10-27)

Closes next action 1's leftovers. Built `assets/pipeline/run_weekly.R`: derives `JW_SKILL` from its own
location, reads `JW_ROOT`/`JW_WEEK` env vars, calls `tar_make()`, always prints `jw_status()` at the end
(success or failure), treats `STAGE_PENDING` as expected rather than a failure, and carries the `schtasks`
install command (doubled-slash switches for Git Bash) as a comment only -- not run automatically, matching the
"ask before installing a scheduled task" rule.

Machine state found first: `arrow`, `validate`, `reactable` were not actually installed in this R session
(`requireNamespace()` FALSE) despite an earlier round's note that arrow 26.0.0 was installed -- likely stale
from a different machine/session or lost after an R point-release (session reported packages "built under R
4.6.1" while running R 4.6.0). Reinstalled all three from CRAN (allowed without asking per the project rule);
`arrow` 26.0.0 as before.

Real end-to-end test: copied the skill's own `assets/links.template.csv` (5 real links: EURAXESS search,
academicpositions.com, two university career pages, one society page) and `job_profile.template.yml`
(placeholder profile, not the user's) into a throwaway `tmp-examples/jw-real-test` data folder, then ran
`targets::tar_make(script=, store=)` directly (not `jw_stage_run()` calls) for the current ISO week.

Results: all 6 upstream targets built from a cold store; `preflight` 20-22 s (includes the 26-test unit suite);
`s1` fetched all 5 links for real in under 7 s (1.5 s/host politeness, 5 hosts) -- EURAXESS 200/68 anchors/27
job-like (`fine`), academicpositions.com 403 (`blocked`, `not_assessed`), jyu.fi 200/95 anchors/12 job-like
(`fine`), SLU 200/20 anchors/2 job-like (`weak`, correctly below the 3-job-like floor), chemecol.org 200/40
anchors/4 job-like (`fine`); `s2` kept 35 of 216 anchors, all tier 2 (role word only -- the template profile's
placeholder terms like `focal_system_1` cannot match real topic words, so no tier-1 hits is expected, not a
bug) and logged 181 drops by reason (`s2_dropped`, info); `s3` ran (35 rows); `s4_file` errored with
`STAGE_PENDING` as designed, confirmed by `jw_status()`. Total wall time about 35 s including the network
round trip. A second run against the same store (via `source(run_weekly.R)`) showed the intended caching:
preflight reran (`cue = always`) but `s1`-`s3` were skipped (cached), confirming `run_weekly.R`'s own logic
(path derivation, `jw_status()` printing, `STAGE_PENDING` treated as success) without a second network hit.

Finding carried to the open items (not a new bug, reproduces the known gap): among the kept tier-2 items were
aggregator navigation chrome rows ("Newest offers first", "Jobs & Opportunities", "ResearchComp") that matched
the role-word regex incidentally; this is the aggregator-noise gap already named in next action 4
(`classification.md`), now confirmed against real text rather than inferred.

Not tested: Windows Task Scheduler itself (`schtasks`, a real scheduled trigger), a second calendar week
(ledger diffing against a prior week with real data), non-Windows. Cleanup: `tmp-examples/jw-real-test`
deleted after the test (gitignored, nothing committed from it).

## 15. Next action 4: remaining triage notes folded into references (2026-10-27)

Source: the two inbox lesson files quoted in the handoff (`job-search_20261027-092841_manual.md`,
`job-search_20261027-150000_social-web-discovery.md`; no new web research this round). Five items, all
documentation-only except the tag ledger:

- **Feed-verification checklist** ([stage-s1-probe.md](../job-opportunity-watch/references/stage-s1-probe.md)):
  expanded the one-line "Feeds" bullet into a 5-point checklist (item count, titles are vacancies, dates present,
  links to the vacancy page, filter honoured or filterable locally); a plain 200/sitemap is not evidence.
- **JS-only source handling** (same file): added "do not silently simplify a long filtered search URL" (it
  changes what is searched) to the existing `ok_js_suspect`/feed/sitemap guidance, which already covered most of
  this lesson.
- **Aggregator noise and near-miss** ([classification.md](../job-opportunity-watch/references/classification.md)):
  added a "Near-miss" section (one hard rule otherwise strong, `near_miss`/`near_miss_rule`, record a stated
  range rather than one number) and an "Aggregator noise" section (field-category aggregators are mostly site
  furniture and off-topic titles; `fine` is not relevance; add only where deadlines are structured); also added
  `language` as its own assessed dimension per the lesson. `portal-quirks.md` got a matching note that
  `jw_job_like_check()` reports a count, not a noise share -- documented as a known gap, not fixed in code (would
  need an excluded-title stop-word pass or a share metric, out of scope for a docs-only round).
- **Tag ledger `query_type`/`posts_per_month`**: these were already *described* in `stage-s5-discover.md` but not
  actually implemented -- `social_tags.tsv` had no such columns and `jw_tags_record()` had no such arguments.
  Added both as optional columns/arguments in `jobwatch.R` (`query_type` one of hashtag/text/author+tag/
  web_keywords, validated; `posts_per_month` overwritten each run, not accumulated) and updated
  `state-and-files.md` and `stage-s5-discover.md`. Tested interactively (new-row and update-row paths, both
  columns round-trip through `.tsv_write`/`.tsv_read`) and the full suite re-run (132 tests, 0 failures, no
  regressions). Explicitly not built (recorded as an open gap, not implemented): a separate web-keyword ledger
  for `web_search` queries (language, keywords, channel, outcome) -- `query_type = "web_keywords"` with a
  descriptive string in `tag` is the documented workaround for now.
- **Subagent handoff files inside the data folder**: already present in `stage-s4-classify.md` from the next
  action 3 round; added a short cross-reference in `state-and-files.md`'s Layout section so it is discoverable
  from the file-layout reference too, not only from the s4 stage doc.

Also updated `pipeline.md`'s forward reference ("not yet written") now that the aggregator-noise note exists.

Verification: `lint_skills(skills = "job-opportunity-watch")` is unchanged from before this round (one
pre-existing info-level `reference-toc` note on `pipeline.md`; `classification.md` now also crosses the same
line-count threshold, confirmed by comparing lint output before/after via `git stash`, not a new defect).
`check_skill_links()` found nothing (no new skill-to-skill links, only internal cross-references).
`uvx --from skills-ref agentskills validate job-opportunity-watch` passes. CRLF crept back into several files
after `edit` calls (the known repo pitfall); fixed with `sed -i 's/\r$//'` and re-checked with
`git ls-files --eol` before finishing.

Not done in this round: the companion web-keyword ledger, the `jw_job_like_check()` noise-share metric, and
the excluded-title stop-word pass for tier-2 filtering (all explicitly deferred above, not silently dropped).

## 2026-11-03 (evening): lessons triage, failing sources investigated

Inputs: 4 inbox files (25 entries, one project). `usage.tsv` missing from `~/.posit/lessons/` again, so no coverage
counts and no watermark update.

| # | Source / check | Status | Finding |
|---|---|---|---|
| 1 | `employment.ku.dk` (curl, 20 s) | read | timeout on `/faculty/` and `/`; machine/network side, not fixable in the skill |
| 2 | `www.ecro.online`, `ecro.online` (curl) | read | DNS fails here; web search shows the site live with a Job Offers page, so not dead; `ecro.org` answers 200 (parked landing page) |
| 3 | `jobs.uni-graz.at` page + `main.*.js` | read | Angular app; `apiUrl` = `personal.uni-graz.at/api/erec/public`; `/job-postings` returns JSON with deadlines |
| 4 | Oracle Candidate Experience REST (SDU instance) | read | `recruitingCEJobRequisitions` finder works keyless: 66 postings with `PostingEndDate` |
| 5 | EURES `jv-searchengine` POST | read | works keyless: 5136 records for one keyword |
| 6 | Jobbnorge `api.jobbnorge.no` | read | 401, key needed; web search found no public RSS |
| 7 | `english.hi.is/vacancies` | read | one real vacancy, title without a role word: `nav_only` false negative |
| 8 | `uhasselt.be` English vacancies | read | no vacancy anchors in the HTML |
| 9 | academicpositions.com `/rss` | read | 403 (bot wall); not bypassed |
| 10 | Reproduction: `jw_probe()` on a url/section-only data frame | tested | silent empty result (fixed: stops with missing columns); `jw_stage_file("s1_sources")` error lacked valid names (fixed) |
| 11 | Reproduction: "could not find function" | tested, not reproduced | `jobwatch.R` attaches httr2, xml2, rvest, readr on source |

Open: a `type = json` source (Oracle, EURES, Graz) is not built; needs the user's decision and a terms-of-use read.

## 2026-11-03 (late): json sources built, terms of use read

| # | Source | Status | Finding |
|---|---|---|---|
| 12 | https://eures.europa.eu/legal-notice_en | read | reuse authorised with acknowledgement of ELA; no rule on automated access; logos not reusable |
| 13 | https://europa.eu/robots.txt | read | no rule on `/eures/`; `Disallow` for `/cgi-bin/`, `/eur-lex/`, `/archives/`, some other paths |
| 14 | https://personal.uni-graz.at/robots.txt | read | `Disallow: /` for all agents: Graz API not built, reported by `jw_discover_endpoints()` |
| 15 | https://jobs.uni-graz.at/robots.txt, instance robots of the Oracle portal | read | 404 (no rules) |
| 16 | https://www.oracle.com/legal/terms.html (curl; webfetch got 403) | read | forbids robots, spiders, scrapers on the oracle.com Site; applicability to a customer-hosted career site unclear; employer terms not read: opt-in per portal |
| 17 | Oracle finder facets (live) | tested | category 66 to 27, plus date 22; categories + organizations (`;` separated) + date 9; keyword works; `PostingEndDate` often null |
| 18 | EURES API (live) | tested | works only with `accept_encoding = "identity"` from R libcurl (compressed request: "Failure when receiving data"); `educationLevel=8,NS` and `positionScheduleCodes=NS,fulltime` accepted; saved search gave 2 records |
| 19 | Greenhouse, Lever, Personio, Recruitee, SmartRecruiters public job APIs | not researched | fingerprints only in `jw_discover_endpoints()`, marked untested |

Built: `jw_robots_allowed()`, `.probe_eures()`, `.probe_oracle()` (opt-in `json:eures` / `json:oracle`), JSON-LD JobPosting
anchors in the HTML branch, `jw_discover_endpoints()`; 4 offline unit tests added (35 pass). Open: multi-page runs,
real-portal comparison of EURES counts, JSON-LD on a live page, verification of the five platform APIs.

## 2026-11-03 (late): lessons hook registration

`~/.posit/lessons/usage.tsv` was missing because the global `settings.json` on this machine only had the `SessionStart`
sync hook; `PostToolUse` (matcher `skill`) and `Stop` entries for `scripts/lessons-hook.sh` were absent (the docs say hooks
are additive and `Stop` ignores `matcher`). Registered both, created an empty `usage.tsv` (no rows invented; earlier loads
cannot be reconstructed), and tested the script with synthetic payloads in a scratch `LESSONS_DIR` (repo skill logged,
unknown skill ignored). Effective from the next session.

## 2026-11-03: safeconduct (MountainMath) evaluated for fetch skills

| # | Source | Status | Finding |
|---|---|---|---|
| 20 | https://doodles.mountainmath.ca/posts/2026-10-26-introducing-safeconduct-and-r2parquet/ | read | `safeconduct` (not on CRAN, CRAN submission planned; GitHub mountainMath/safeconduct) escalates curl, headless Chrome, spoofed UA, interactive Chrome, captcha. `fetch()`, `page_html()`, `probe()`. StatCan wait about 2 min; may fail in automated/Docker; clearance not transferable to curl. Not installed or tested (GitHub: needs user permission). |

Assessment: relevant only as an opt-in fallback after `web-fetching-r` bot-wall detection (`probe()` is a diagnostic). Not for
social-research-search (Bluesky/Mastodon are open APIs). Evasion of bot walls conflicts with the polite-fetch/robots stance.

## 2026-11-03: Google search links (`search_engine` type)

| # | Source / test | Status | Finding |
|---|---|---|---|
| 21 | Local: `jw_read_links()` on a long Google URL (q, tbs, sxsrf, ved, gs_lp, `#ip=1`) | tested | classified `search_engine`; `q` decoded correctly incl. `OR`, `-term`, `-site:`. `tbs=qdr:m` (past month) is dropped; `jw_key()` keeps only the fragment-stripped URL, so volatile params (`sxsrf`, `ved`, `gs_lp`, `sca_esv`) change `key`/`id` when the user re-pastes the "same" search |
| 22 | stage-s1-probe.md "search_engine" bullet | read | says run query "without operators" through `web_search`: drops the exclusions that define the search |
| 23 | https://developers.google.com/custom-search/v1/overview | read (via search) | Custom Search JSON API closed to new customers, discontinued 2027-01-01; new engines limited to 50 sites |
| 24 | Bright Data blog (brightdata.com) | search; skipped: commercial | reports direct HTTP to Google gets no results / CAPTCHA |
| 25 | SERP vendor posts (SerpApi, Serper, DataForSEO, Apify, Keirolabs, Searlo) | skipped: commercial | paid; not recommended |
| 26 | CRAN: duckduckr (Instant Answer API only, not web results), googler (wraps CLI tool), websearchr (opens URLs), serp (unrelated) | read (CRAN_package_db) | no usable search-results package |

Open: Brave Search API (independent index, key needed, has `-`/`site:` style operators; plan terms not read); the `web_search` tool
ignores or only partly honours operators and `tbs`.

Built (2026-11-03): `jw_search_parts()`, `jw_search_note()`, `jw_recency_label()`, search-aware `jw_key()` (ignores sxsrf/ved/gs_lp/sca_esv/client/fragment, keeps q and time filter); s1 reference now says keep operators, filter exclusions by hand, report the query used. 1 unit test block added to `test_json.R` (15 expectations), existing tests pass. Not done: Brave `json:brave` source; `web_search` behaviour with operators not tested live.

## 2026-11-03: `web_search` with the full operator query (live test)

| # | Test | Status | Finding |
|---|---|---|---|
| 27 | `jw_search_note()` on the user's full Google URL, query passed unchanged to `web_search` | tested | 8 results: 2 US job boards (ZipRecruiter, Indeed; commercial, US), 2 patents, 3 PMC papers, 1 arXiv/bioRxiv paper. Excluded terms/sites (wiley, jstor, wikipedia, msu.edu, eurekalert) were absent, but that could be coincidence: 3 results mention COVID, which `-covid` should remove (a bioRxiv paper did), so operators are at best partly honoured. No time filter, no dates, no Europe-based academic vacancy. Conclusion: not a substitute for the Google search; useful only as a weak discovery pass. |

| 28 | Live retry loop: `web_search` round 1 -> `jw_search_refine` -> round 2 with 6 added `-site:` | tested | Round 1: 9 results, noise share 100% (ziprecruiter, indeed, biorxiv, arxiv, uspto, ncbi); rerun with `-site:` for all six. Round 2: 10 results, 9 from the just-excluded domains (uspto x4, ncbi x3, arxiv, biorxiv), noise share 90%; the one non-noise hit was a 2023 US (Monell) job ad on an EU project site. `web_search` ignores `-site:` entirely, so the rerun loop cannot improve results; `jw_search_refine` correctly stops in round 2 ("every noisy domain already excluded: weak source"). Conclusion: operators are not applied by this tool; the retry loop only documents the weakness. A real fix needs a different source (portal, feed, Brave API) |

## 2026-11-16: user-supplied Google scraping links re-checked

| # | Source | Status | Finding |
|---|---|---|---|
| 29 | https://github.com/salimk/rcrawler (Rcrawler, CRAN) | read | General site crawler; no Google SERP scraping. Google appears only as a manual tip (run `site:` query by hand, paste URLs into `ContentScraper`). Maintainer seeks co-maintainers; no dated release shown. Not a solution |
| 30 | r-bloggers 2023-03 (webbotparseR, schochastics) | read | Parses saved SERP HTML (`parse_search_results(engine = "google text")`); the fetching is done by the WebBot browser extension driven by a human session. GitHub-only install (needs explicit user permission); CSS-selector parsers described as fragile. Semi-manual, not unattended: weak fit for a weekly pipeline |
| 31 | https://dev.to/darshan_sd/scraping-google-search-results-using-r-5gn8 | read | Direct `rvest::read_html()` on google.com/search with CSS classes (`div.g`, `.yuRUbf`, `.VwiC3b`); `read_html()` has no `headers` argument so the User-Agent is not sent. Otherwise pushes Serpdog (paid API). Outdated: see #32 |
| 32 | https://webclaw.io/blog/how-to-scrape-google-search-results | read; skipped: commercial | Vendor claim: Google now returns a JS shell to plain HTTP clients, TLS/HTTP2 fingerprinting, CAPTCHAs after ~50-100 searches/day. Consistent with #24 (Bright Data) and earlier findings; vendor source, so treat as supporting only |

Conclusion: no listed method is a reliable, unattended, free way to read Google results. Direct HTTP scraping no longer works; headless-browser/ fingerprint tools or paid SERP APIs would be needed and conflict with Google's terms and the repo's source-quality rules. Not tested live (deliberately not sending automated requests to Google). Remaining options unchanged: Brave Search API (key, terms unread), user-run browser export (webbotparseR-style, manual), or replace the Google link with the underlying portals/feeds.

## 2026-11-16: alternative search engines (DuckDuckGo, Ecosia, Brave, Mojeek, SearXNG)

Source-quality note: most hits were vendor/SEO/scraper-API blogs (skipped as evidence of product claims, used only where several independent items agree or where the item is a primary GitHub issue/vendor page).

| # | Source | Status | Finding |
|---|---|---|---|
| 33 | Brave pricing coverage (dev.to/cloro, websearchapi.space, apiserpent.com, agentdeals.dev, implicator.ai; brave.com/search/api NOT fetched) | search; mixed commercial, treat as secondary | Free plan replaced 2026-02-12 by $5 monthly credit per plan (~1,000 Search requests at $5/1,000), card required, 50 QPS; max 20 results/request. Attribution requirement for the credit is reported inconsistently (blog says yes, Terms say optional). Terms updated 2026-09-01 reportedly forbid storing results and training/benchmarking AI models. Own independent index. Primary terms still unread |
| 34 | DuckDuckGo: SearXNG issues #3927, #4824, #6596 (GitHub); pcbuildsage issue #42 (robots.txt quote); scraper blogs | read (search snippets); GitHub = primary | No official web-search API. `html.duckduckgo.com/html/` returns HTTP 202 + image CAPTCHA to non-browser clients (SearXNG: "always captcha" Aug-Sep 2026; fix via curl-impersonate PR, reports mixed). Reported live robots.txt: `Disallow: /html`, `/lite`. ToS reportedly bars automated use. `ddgs` library unofficial |
| 35 | Ecosia: searchengines.net, euvetted.com, builtineu.eu (cites Ecosia help centre) | search | No search API found. Results are Bing, Google or EUSP/Staan (own index, partial, France first; German index reported 2026-07-30). Provider not controllable. Scraping the web UI = same bot walls with no independent index. Not usable |
| 36 | Mojeek API (mojeek.com/services/search/web-search-api/) | read via search snippet | Own independent UK index; Startup 5 QPS, Business 10 QPS; pay-as-you-go GBP 2-3 per 1,000; full operators; country/language boosting; storage rights and AI usage listed as included; free trial credit with bank card. Smaller index (weaker coverage of niche vacancies, unverified) |
| 37 | SearXNG self-host (docs.searxng.org server settings; ssdnodes, contabo, apiserpent test) | read (docs snippet) + secondary | JSON is off by default (enable `search.formats: json`), limiter must be off for scripts on a private instance. Public instances block bots / disable JSON, do not use. A self-hosted test from one IP: Google zero results, Brave/Startpage suspended, only DDG answered (vendor test, not reproduced). Needs Docker; upstream engines still CAPTCHA |
| 38 | Bing Search API | search (Mojeek forum, community claim) | Reported withdrawn 2025-08-11 for all but large customers. Not verified from Microsoft |

Conclusion: a keyless, free, unattended scraper of any consumer engine is not dependable. The credible routes are (a) Brave Search API, ~1,000 queries/month inside the credit (a weekly run of a few dozen queries fits easily); (b) Mojeek API as second index; (c) self-hosted SearXNG only as a heavy fallback. Not tested live (no key). Open: read brave.com terms (storage, attribution) and the Mojeek terms directly; check `-site:`/`site:`/`-term` and `freshness` parameter in Brave docs; decide key storage (env var, never in files).

## 2026-11-16 (later): CRAN, GitHub and Python re-check

| # | Source | Status | Finding |
|---|---|---|---|
| 39 | CRAN_package_db keyword scan (search engine / SERP / duckduckgo / brave / bing / google / searxng / mojeek) | tested (local) | Only relevant: `duckduckr` (Instant Answer API only, 2017), `searcher` (opens browser tabs, no results returned), `websearchr` (2018), `RWsearch` (bookmarks/console), `RAGFlowChainR` 0.1.7 (web search only via Tavily API, key needed, commercial), `serpstatr` (Serpstat SEO API, commercial). Nothing returns Google/Bing/DDG/Brave/Mojeek results. No `brave`/`mojeek`/`searxng` package on CRAN. A Brave or Mojeek client = small `httr2` call, no package needed |
| 40 | GitHub repo search via `gh` (language R: duckduckgo, search engine results, web search api, brave search, searxng) | tested (local) | Only `dirkschumacher/duckduckr` (Instant Answers), `cadnza/duckImages` (images), `asonpeikoff/gptswaRm` (wraps paid SerpAPI), CRAN mirrors. No maintained R package for web-results scraping or Brave/Mojeek |
| 41 | PyPI `ddgs` 9.16.1 (2026-10-23, MIT, Python >= 3.10) + README | read | Metasearch library (formerly duckduckgo-search). Text backends: bing, brave, duckduckgo, google, mojeek, startpage, yandex, yahoo, wikipedia (+grokipedia: never use, standing rule). Has CLI, `ddgs api` local HTTP server (port 4479, `/search/text`) and MCP server. `timelimit` d/w/m/y; `filetype:` shown, `site:` not documented. README: "educational purposes only"; no block caveats stated; scrapes the engines' web pages, so the walls in rows 24, 31-32, 34 apply |
| 42 | Local machine | tested | no system `python`/`py` on PATH (Windows Store stub only); `uv` 0.12.5 and `gh` 2.104 present. Python can be provided by `uv` |

## 2026-11-16 (later 2): throwaway `uvx ddgs` test (permission given by user 2026-11-16) and httr2 ecosystem

Test: `uvx --python 3.12 --from ddgs python t.py` (ddgs 9.16.1, Python 3.12 via uv, throwaway env, script in assistant scratch dir). 4 queries x 5 backends, `max_results=10`, `timelimit="m"`, 4 s pause, one residential IP, one run. Queries were generic (no personal profile): `postdoc "behavioural ecology" Europe`; `PhD position insect chemical ecology 2026`; `postdoc ecology site:academicpositions.com`; `postdoc ecology -site:linkedin.com -site:indeed.com`.

| Backend | Calls OK | Notes |
|---|---|---|
| bing | 4/4 (7-8 results) | Relevant job pages (euraxess, academicpositions, chemecol.org, openpostdoc, university pages). `site:` honoured (7/8 hits on the domain, 1 was a Bing ad redirect `bing.com/aclick`). `-site:` honoured (no linkedin/indeed). Ads leak into results: filter `aclick` URLs. Some "ad" hits and aggregator/directory pages included; several hits are listing pages, not single vacancies |
| google | 2/4 | Worked for query 1 and the `site:` query, "No results found" for the other two. Query-1 result list was identical to Bing's (same 7 URLs, same order); suspicious, not investigated |
| duckduckgo, brave, mojeek | 0/4 each | "No results found" every call (consistent with the CAPTCHA/anomaly blocks in row 34) |

Not done: Brave API comparison (no `BRAVE_API_KEY`/`BRAVE_SEARCH_API_KEY` set; none created). Whether `timelimit="m"` actually filtered by date was not checked (no dates returned by the text backend). Single run from one IP; reliability over a week unknown.

httr2 ecosystem (CRAN_package_db, 2026-11-16): httr2 1.3.0 (2026-07-13) has built-in `req_throttle`, `req_retry`, `req_cache`, `req_perform_parallel`, so no extension is needed for polite fetching. Reverse dependencies: 604 packages, almost all single-API clients. Related tools: `robotstxt` 0.7.15 (2024-08, robots.txt checks), `ratelimitr` 0.4.2, `chromote` 0.5.1 / `selenider` 0.4.1 (JS rendering), `curl` 8.1.0, `httptest2` 1.2.2 / `vcr` 2.1.0 / `webmockr` 2.2.0 / `webfakes` 1.5.0 (tests), `reqres` 1.2.0 (request/response classes for servers), `mirai` / `nanonext` (async). No CRAN package found that adds browser-like TLS fingerprinting to httr2 (checked by title/description scan only).

## 2026-11-23: alternative routes for sources unreadable in the W48 probe (triage of lessons 116, 130, 132)

Request: find fetch routes for the 17 s1 sources that were not `ok` (list from `s1_sources.parquet` of the W48 run). Method: curl with a plain
descriptive UA, one request per URL, one machine, one time. Nothing bypassed: Cloudflare challenges were left alone (rule in `portal-quirks.md`).

| Source (s1 status) | Result 2026-11-23 | Route / verdict |
|---|---|---|
| en.uit.no/ledigestillinger (http_error 503) | `en.` host 503/502; `https://uit.no/ledigestillinger` 200, 74 KB | **Fixed by URL**: drop the `en.` subdomain (also found by the 403-on-/en/ lesson: try the language-neutral host first). Page links to `uit.no/tavla/stillinger` |
| uib.no .../84777/vacant-positions-uib (404) | old path 404; `https://www.uib.no/en/about-uib/career-at-uib/vacancies` 200, links to a Jobbnorge employer page | **Fixed by URL** (replace the dead path); listing itself is on Jobbnorge |
| jobbnorge.no search (ok_js_suspect) | `/rss` redirects to an HTML shell (no feed); `/search?...` is a JS shell, no job anchors in HTML; `api.jobbnorge.no` 401 (earlier note) | **No route found**; Norwegian posts also reachable via EURES (`json:eures`) or EURAXESS; manual check |
| euraxess.ec.europa.eu search (blocked 403) | curl with the exact 908-character URL: 200, 221 KB, job links `/jobs/<id>` present; also with UA `curl/8` | **Probe-side**: httr2's request was blocked, curl was not. Check UA/headers or rate (not tested which); retry the probe before treating as blocked |
| ut.ee, emu.ee, academicpositions.com (blocked 403) | every path, including `robots.txt`, returns the Cloudflare "Just a moment" challenge | **Do not bypass**. Use mirrors already in the list: EURAXESS (searchable by university name, 200), `universitypositions.eu/rss/jobs` (200, 1 MB RSS) |
| Oracle HCM, `fa-eosd-saasfaprod1...` (ok_js_suspect) | REST `recruitingCEJobRequisitions` `findReqs;siteNumber=CX_1001` answers 200 JSON without login; no `robots.txt` (404) | **Route exists**: `json:oracle` opt-in in the link `note`; needs the user's per-portal acceptance of the terms (table in `portal-quirks.md`) |
| europa.eu EURES search (ok_js_suspect) | `POST /eures/api/jv-searchengine/public/jv-search/search` answers 200 | **Route exists**: `json:eures` opt-in (user acceptance) |
| valtiolle.fi (ok_js_suspect, nav_only) | server HTML already contains `/en/jobs/<slug>-<id>/` links; `robots.txt` allows all | **Probe-side**: anchors exist, so `nav_only` is likely a filter/threshold false negative; filters are in the URL, so verify the filtered list on a real run. Not tested end to end |
| jobs.uni-graz.at (ok_js_suspect) | page 200 (7.8 KB shell); API host is `Disallow: /` (earlier note) | Not fetched; browser only |
| kuleuven.be jobsite (ok_js_suspect, flag fine) | 200, 24 KB; `.rss` 404 | Already readable (`fine`); `ok_js_suspect` is a status warning only |
| careers.un.org (nav_only) | page 200 (120 KB, JS app) | not investigated further |
| universitypositions.eu jobs (weak) | the RSS link in the list (200, 1 MB) covers it; filter locally | use the RSS row |
| 3 Google search URLs (search_engine) | cannot be replayed | use `web_search`/ddgs route (earlier test), not a link |

Facts for the skill: (1) on a 403/404/503 try the language-neutral or local-language host/path before search (uit.no confirmed, W48 French URL lesson);
(2) Cloudflare "Just a moment" on a whole host (even `robots.txt`) is a stop, mirror it; (3) `json:oracle` and `json:eures` are the only JSON routes that
worked; both need user opt-in; (4) a plain-`curl` 200 where httr2 got 403 suggests a probe-side cause, which is worth a retry before a source is called blocked.
Not done: any link edit (needs user confirmation per the project AGENTS.md), httr2 header comparison, JS-rendering (chromote) tests.

### Build and test of the generic fetch ladder (2026-11-23, same day)

Request (user): make link fetching generic by link type/failure class, not per site; review the whole logic; add packages if needed.
Review result: before, `jw_probe_one` made one request with an identifying user agent and mapped the status code to `blocked`/`http_error`; recovery was a per-site note.
Findings that drove the design: (1) one research portal answered 403 to the identifying agent form and to `curl/8` but 200 to `Mozilla/5.0 (compatible; <tool>; ...)`, so a WAF rule on the agent token, not a bot challenge; (2) Cloudflare challenge pages carry `cf-mitigated: challenge` and also cover `robots.txt`: a stop; (3) several JS-built listings render fine in headless Chrome (chromote 0.5.1, Chrome found on this machine, CRAN, already installed) and the Fetch domain lets every page/XHR request be vetted against `robots.txt` (a university job API that disallows all agents was cancelled correctly); (4) `en.` language subdomains can be flaky while the neutral host works; (5) the static job-like count is fooled by words like "all vacancies" in the menu, so the render trigger is "thin, or fewer than 10 vacancy-like links".
Packages: `chromote` used (optional); `robotstxt` not installed, the existing `jw_robots_allowed` kept (tested, handles longest match); no CRAN package for WAF-friendly agents.
Live result: see HISTORY.md (5 of 17 now `ok`, 12 stay: 3 Cloudflare hosts, 1 moved link, 3 search-engine links, thin pages incl. one needing interaction). Open: render time (7 min for 114 links), `jobwatch.render_min_hits` default untuned, a Linux/macOS test, links.csv edits (uit.no `en.` host, the moved UiB vacancies URL) left to the user.
