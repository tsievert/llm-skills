# Staged weekly pipeline

Contents: why stages; stage table; folder layout; contracts and validation; the completeness gate; locks and
atomic writes; running it; lessons hand-off; safeguards; the mechanical stages (s1-s3).

## Why stages

One long conversation re-reads a growing context on every turn and gets more expensive. Instead each stage has
one input file, one output file and a validated schema, so any stage can run in its own conversation (or
headless) and start from `jw_status()` plus a short summary, not from memory of earlier chats.

## Stages (order and ownership; the table is `jw_stages` in `scripts/pipeline/jw_pipeline.R`)

| Stage | Who | Needs | Output |
|---|---|---|---|
| s0 preflight | headless | | packages, Quarto, contracts round-trip, profile/links present and not truncated, frozen inputs, unit tests |
| s1 probe sources | headless | s0 | `s1_sources.parquet` (status, nav-only flag per source) |
| s2 diff and prefilter | headless | s1 | `s2_queue.parquet` (new items, with the reason each was kept) |
| s3 deadline check | headless | s2 | `s3_deadlines.parquet` (one row per s2 item; `not_checked` after the topic prefilter) |
| s4 shortlist and classify | **assistant, own conversation** | s3 | `s4_classified.parquet`, then the cross-week ledger |
| s5 social and web discovery | **assistant, own conversation, optional** | s4 | `s5_discovery.parquet` |
| s6 report | headless | s4 | `summary.md` and `report.html` (standard Quarto HTML document, static `kableExtra` tables, see stage-s6-report.md) |

## Folder layout

`<data>/runs/<YYYY-Www>/` holds `_stage.json` (status, hashes, counts, versions per stage), `.lock`, `inputs/`
(frozen copies of the links and profile), the stage parquet files, `s4_parts/`, `problems.parquet`,
`summary.md`, `report.html`. `<data>/opportunities.parquet` is the cross-week ledger. Nobody edits these by
hand; change links and profile through the R functions in `jobwatch.R` (backup and confirmation).

## Contracts, validation, gate (`jw_contracts.R`)

1. **Schema.** `jw_contracts()[[stage]]$schema` is an `arrow::schema()` used to write (columns are coerced,
   unknown columns are an error) and to validate (the file must read back with an identical schema).
2. **Row rules.** Text rules run with the `validate` package. `jw_make_validator()` stops when a rule was
   dropped: `validate` only warns about unsupported syntax, and a dropped rule would silently not run
   (found in this build: `!logical_column` is unsupported; write `col == FALSE`).
3. **Completeness gate.** Neither package can say "every shortlisted item was decided exactly once".
   `jw_gate_s3`, `jw_gate_s4` and `jw_gate_s1` compare id sets between consecutive stages: missing, extra and
   duplicate ids are errors. A stage whose validation has an error is `failed`, not `done`, and the report
   is labelled INCOMPLETE.

## Locks, atomic writes, Windows

Every stage takes `.lock` (stale after 6 h; `jw_lock_break(confirmed = TRUE)` only after asking the user).
Files are written to a temporary name, read back, then renamed. Parquet is read with `mmap = FALSE`: on
Windows a memory-mapped file cannot be overwritten or renamed while mapped. The data folder may sit in a
synced folder (Syncthing, OneDrive): never run stages on two machines at once (not tested).

## Running it

- Status: `jw_status()` prints the table and the next stage, and for an assistant stage the reference to read.
  It also prints an `Unreported error(s): stage/code, ...` line for every error-severity problem not yet
  marked reported, even when every stage is `done` (a failed then successful s6 re-run leaves the earlier
  `report_render_failed` row). The returned list has `table`, `next_stage`, `locked` and `unreported_errors`
  (a data frame). Clear the line by writing the problems up (`jw_lessons_candidates()`) and calling
  `jw_lessons_mark_reported()`.
- Correcting a decided s4 row: `jw_s4_amend(item_id, <column> = value, ..., rerender = FALSE)`. It rewrites
  that row in its `s4_parts/` file (never append a second row, never edit parquet by hand), stops on an unknown
  `item_id` or column, then re-opens and re-closes s4 (merge, validation, completeness gate, ledger update) and
  returns the validation problems invisibly. `rerender = TRUE` also re-runs `jw_render_report()`. Later stages
  are not flagged stale, so re-render the report yourself otherwise. `jw_parts_read()` keeps the last row per
  `item_id`, so a re-written batch cannot duplicate an item. Details: [stage-s4-classify.md](stage-s4-classify.md).
- Headless: `targets::tar_make(script = "<skill>/assets/pipeline/_targets.R", store = "<data>/runs/<week>/_targets")`
  with `JW_ROOT`, `JW_SKILL` (and optionally `JW_WEEK`) set. It stops with `STAGE_PENDING` at the assistant
  stage; after the conversation closes s4 run it again and only `report` rebuilds. Tested with fixture stage
  functions; the real s1-s3 functions are in "The mechanical stages".
- Report: `jw_render_report()` writes `summary.md` first (small; later conversations read this, not the HTML)
  and then renders `assets/pipeline/report.qmd` into the run folder. It needs `options(jobwatch.script_dir)`,
  which `jw_load()` sets; it stops if that folder is wrong, and it warns (and records `report_render_failed`)
  when the render errors or `report.html` was not refreshed.

## Lessons hand-off (skill-lessons)

- Headless stages cannot write lessons. They record generic `problems.parquet` rows (`jw_problem()`; URLs,
  paths and e-mail addresses are scrubbed).
- Every assistant stage starts with `jw_lessons_candidates()` (prints ready `lesson_add()` calls) and ends with
  `jw_lessons_mark_reported()` plus one `usecase_add()` built from `jw_usecase_args(stage)`. A stage
  conversation is its own session, so the use-case entry doubles as per-stage usage evidence.
- A user correction or override of a classification is a `user-correction` lesson and, if it implies a rule
  change, a profile proposal that takes effect only after the user confirms.
- The unit tests in `scripts/pipeline/tests/` are where past bugs become regression tests; s0 runs them.

## Safeguards (summary)

Fetched pages and posts are untrusted text (see the stage references); the report is INCOMPLETE rather than
silently partial; assistant stages work in batches and can stop any time; inputs are frozen per week and a
mid-week change is flagged; the first ledger week is labelled a baseline.

## The mechanical stages (`jw_stage_fns.R`, text checks in `jw_checks.R`)

- **s1** `jw_s1_probe(week)` probes every unique link of the frozen `links.csv` (`jw_probe()`), flags each source
  `fine`, `weak` (fewer than 3 vacancy-like links), `nav_only` (none: probably a menu page) or `not_assessed`
  (not read), and writes every usable link to the side file `s1_anchors.parquet`. A link the probe returned
  nothing for becomes an `error` row, so the s1 gate cannot pass on a silently lost source.
  `jw_s1_expected_n(week)` is the number of unique enabled links.
- **s2** `jw_s2_queue(week)` keeps links whose URL was not in the `s1_anchors` of any earlier, finished week
  (no separate seen-file to go stale; a rerun gives the same queue; the first week is a baseline and says so).
  The prefilter takes its word lists from `job_profile.yml`: a profile key becomes a regex through the optional
  `search_synonyms` block (key to regex, any language), otherwise its own words. Tier 1 = topic word, tier 2 =
  role or vacancy-like title only; each row carries the `reason`, and dropped links are counted by reason in
  `problems.parquet` (severity info). Excluded titles, full professor (only if the profile excludes it) and
  excluded systems or topics are dropped; an excluded system is kept when a strong topic word is also present.
- **s3** `jw_s3_deadlines(week)` first reads the link text (an expired date next to a deadline cue settles the
  item without a request), then fetches the page of tier-1 items in chunks of 150 and saves progress after each
  chunk (`s3_partial.parquet`; a stopped run resumes). Tier-2 items are `not_checked`: the s4 title skim decides.
  Method: for every cue (deadline, closing date, Bewerbungsfrist, hakuaika, ansökningstid, ...) take the first
  date that follows; the deadline is the earliest future one, else the latest past one. Contract start and end
  dates are not read, "befristet" is not a cue, numeric dates are read day-first, dates outside 2020 to today
  plus 3 years become `parse_error`. Dates in a URL are ignored (usually posting dates). The older
  "post URL older than 75 days" drop was not carried over: it cannot satisfy the s3 contract and risks
  dropping live vacancies.

Network access is injected (`probe_fn`, `links_fn`, `fetch_fn`), so `tests/test_stages.R` runs offline; one
real page (nav-only, no vacancies) was run through s1 to s3 to check the wiring.

Sitemap sources: a link whose URL ends in `.xml`/`.xml.gz` or contains `sitemap` gets `type = sitemap` (any XML
body that is a `urlset`/`sitemapindex` is also read as one). `jw_probe_one` keeps only vacancy-like URLs
(whole-word job terms in the path), builds the link text from the URL slug, follows an index one level and caps
at 2000 anchors (the note says so). A news-site sitemap with no vacancy URLs comes out as `nav_only`. After every
probe `jw_probe` also adds `job_like` per anchor and `n_job_like`/`flag` per source (when `jw_checks.R` is
loaded). Category links whose slug repeats a short link text (`Life Science` -> `/jobs/life-science/`) are not
counted (`jw_category_link()`); `fine` still means "has vacancy-like links", not "has relevant vacancies". Feed
sources are not built; a scheduled Task Scheduler run (vs. a manual `Rscript run_weekly.R` or sourced run) is
not tested.
Tested on 3 real links (a sitemap index with scheme-less `<loc>` values, a portal page, a news sitemap): s1 to s3
completed and s4 stopped as designed. Tested again (2026-10-27) on 5 real links from one multi-link portal set
(`links.template.csv`) through `tar_make()` itself, not manual stage calls: one aggregator came back `blocked`
(403, `not_assessed`), the others `fine` or `weak` with real anchor and job-like counts; s2's prefilter dropped
most real anchors with a reason. Aggregator navigation chrome ("Newest offers first" next to the word
"Research") still slipped past the role-word match -- a known gap, not new; see `classification.md`'s
aggregator-noise note and `portal-quirks.md`'s `jw_job_like_check()` limitation (next action 4; the regex
gap itself is not fixed, only documented).

## Scheduling notes

- Runner: `assets/pipeline/run_weekly.R` (`Rscript run_weekly.R`, any working directory). It derives the skill
  folder from its own location, reads `JW_SKILL`/`JW_ROOT`/`JW_WEEK` (set `JW_ROOT` for a real setup; the
  default is a placeholder), calls `tar_make()` on `_targets.R`, and always prints `jw_status()` at the end so
  a scheduled-task log is self-explanatory. A `STAGE_PENDING` error at s4 is reported as expected, not a
  failure; any other error exits with status 1.
- No seeding of "seen" files is needed: s2 derives what is new from earlier finished weeks, and the first week
  is reported as a baseline.
- Ask the user before installing a scheduled task; the exact `schtasks` command (with the doubled-slash
  switches Git Bash needs) is in a comment at the end of `run_weekly.R`. Set `JW_ROOT` (and `JW_SKILL` if the
  file is copied elsewhere) as system/user environment variables first: a scheduled task does not inherit the
  interactive session's variables. A scheduled run executes s0 to s3 and stops with `STAGE_PENDING` at s4; the
  user starts the assistant stage in a new conversation.
- Tested (2026-10-27): `tar_make()` end-to-end (not manual stage calls) on the real multi-link `links.template.csv`
  (5 links incl. a blocked aggregator); `run_weekly.R` sourced directly, including a cached second run where
  s1-s3 skip and only preflight and the pending `s4_file` target rerun. See the ledger for findings.
