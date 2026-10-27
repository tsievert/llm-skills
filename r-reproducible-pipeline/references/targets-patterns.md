# targets patterns

Contents: project layout; file targets and external tools; invalidation (tested); a
human/assistant stage as a file target; dynamic branching; seeds; Quarto reports; storage
formats and memory (including parquet/arrow and data validation); Quarto dashboards for
scheduled reports; debugging; what to commit.

## Project layout

One folder = one pipeline = one renv library = one git repository (manual, "projects"
chapter). Functions in `R/`, loaded with `tar_source()`; `_targets.R` returns a list of
targets. Use several pipelines in one folder only when they share goals and code
(`tar_config_set(script=, store=, project=)`, `TAR_PROJECT`).

## File targets and external tools

```r
tar_target(sim_script, "py/simulate.py", format = "file")   # tracked by content hash
tar_target(sim_csv, run_python_sim(sim_script, sample_id, n_obs, slope, tar_seed_get()),
           pattern = map(sample_id), format = "file")       # function returns the output path
```

- A target with `format = "file"` returns paths; targets hashes the files. Downstream targets
  that take the target as an argument rerun when the file content changes.
- Passing the script as an argument is what makes edits to it count. A literal path inside the
  function is not tracked (expected from the design; the negative case was not run, the checker
  warns on literal script paths).
- Call Python with `system2("uv", c("run", "--locked", "--project", "py", "python", shQuote(script), ...))`
  and stop when the status is not 0. Quote paths with `shQuote()`.
- The Python environment is its own lock (`py/uv.lock`); see `python-reproducible-pipeline`
  for uv and pinning.

## Invalidation (tested on Windows, targets 1.12.0)

| Change | Reran |
|---|---|
| `touch` a file target, content unchanged | nothing |
| comment-only edit in a function file | nothing |
| add an unused function | nothing |
| edit the body of a used function | that target and dependants |
| edit a Python script (declared file target), output unchanged | the script and call targets reran; downstream targets skipped because the output hash was unchanged |
| change one config value | targets depending on that value (with per-setting targets) |
| add a sample | only the new dynamic branches and their combine steps |
| CRLF vs LF rewrite of a tracked file | dependants reran (content differs) |

Rules are "cues" (`tar_cue()`); do not switch them off to hide a rerun you do not understand.
Compare Snakemake's mtime-based triggers in `python-reproducible-pipeline`.

## A human/assistant stage as a file target

When one pipeline stage is performed outside the R process — a person edits a file, or an
assistant conversation produces one — model it as an ordinary `format = "file"` target that
stops with a clear message when the expected file is missing, using `tar_cue(mode = "always")`
so the target is checked (not rebuilt) on every run:

```r
tar_target(stage_file, {
  if (!file.exists("stage/handoff.parquet"))
    stop("Waiting for stage/handoff.parquet; see <instructions>.")
  "stage/handoff.parquet"
}, format = "file", cue = tar_cue(mode = "always"))
```

Tested (targets 1.12.0, Windows): a missing file stops only that target and leaves everything
upstream cached (`tar_progress()` shows it as `errored`); once the file appears, only this
target and its downstream reran; a second run with no change reran nothing except the
always-cued target itself (cheap: it only checks `file.exists()` and a hash).

For a project that runs the same pipeline script against a fresh store per run (e.g. one run
per calendar week), pass both explicitly instead of relying on the working directory:

```r
targets::tar_make(script = "assets/pipeline/_targets.R", store = "runs/2026-W43/_targets")
```

`tarchetypes::tar_quarto()` was not a fit for this shape in one project: it renders inside the
working directory of the `_targets.R` it's declared in, which doesn't match a template file
reused across many per-run store folders. The template was copied into the run folder instead
and rendered as a plain file target with `quarto::quarto_render()`.

## Dynamic branching

`tar_target(x, f(sample_id), pattern = map(sample_id))` creates one branch per element; branch
names are stable hashes of the element, so existing branches survive when elements are added.
The combine step (`x` itself) is rebuilt. With `format = "file"` each branch returns its path.
For many tiny branches batch the work (`tarchetypes::tar_rep()`); millions of quick targets are
slow (manual, "performance"). `tar_map()`, `tar_rep()` and `tar_resources_*()` were read about
but **not tested** here.

## Seeds

`tar_option_set(seed = n)`: each target's seed comes from its name and `n` (`tar_meta()`
shows it); the order of execution does not matter. `seed = NA` disables seeding (targets then
always look outdated unless `tar_cue(seed = FALSE)`). `tar_seed_get()` returns the current
target's seed, for external tools. Avoid `set.seed()` inside project functions (the manual does
not cover its interaction; the checker raises an INFO).

## Quarto reports

`tar_quarto(report, "report.qmd")` renders when upstream targets named in literal `tar_read()` /
`tar_load()` calls change; it finds them by static scan of active R chunks (not `*_raw()`,
not inside user functions). The target is a file target holding the rendered files; it needs
the CRAN package `quarto`. Keep reports light. `tar_quarto_rep()` renders one document per
parameter row. Quarto's own `freeze`/`cache` are separate mechanisms; avoid stacking them
without a reason.

## Storage formats and memory

Default RDS; `format = "qs"` (package qs2/qs) for speed and size on any object; `"feather"`
(arrow) for data frames; `"file"` for data too large for memory. Large runs:
`tar_option_set(memory = "transient", garbage_collection = 10)`.

**Parquet, `format = "file"` and `format = "parquet"` (arrow): schema contract, row rules, a
completeness gate, and a Windows `mmap` trap.** Tested with arrow 26.0.0 on Windows: reading a
parquet file with `arrow::read_parquet()` (or the `targets` built-in `format = "parquet"`
target) memory-maps it by default, which then blocks overwriting or renaming that same file
later in the same session —

```
IOError: Failed to open local file ... [Windows error 1224] The requested operation cannot be
performed on a file with a user-mapped section open.
```

Fix: pass `mmap = FALSE` to every `read_parquet()` call on a file a later step rewrites, and
write atomically (write to a temp name, then rename) rather than overwriting in place. This
only bit on Windows; it was not seen reading-only or on files nothing rewrites.

For validating data *between* pipeline stages, a hybrid approach (tested against `validate`
1.1.7 and `pointblank` 0.12.4 on a small synthetic stage table) worked better than either tool
alone: one `arrow::schema()` per stage, used both to write the parquet file and to validate it
against; `validate::validator()` for row-level rules; a hand-written set-equality check for
"every expected id appears exactly once" across stages (neither validation package covers this
directly). `pointblank` was heavier than needed here (its own dependency tree pulls in roughly
90 packages) for a report the pipeline already renders through Quarto. Caveat found while
testing: `validate` silently **drops** a rule it can't parse (e.g. one written with
`!logical_column`) and only emits a warning, not an error — compare `length(validator)` against
the number of rules you wrote, not just whether validation ran. Write `NA` handling explicitly
(`is.na(x) | ...`), since missing values otherwise pass or fail unpredictably depending on the
rule.

## Quarto dashboards for scheduled reports

`format: dashboard` (Quarto's dashboard layout, not a plain document) suits a static,
recurring report better than a long document when there's a handful of headline numbers and a
few tables: value boxes (a `#| content: valuebox` chunk returning `list(icon, color, value)`),
and a tabset of `reactable` tables. Tested (Quarto 1.10.18) rendering with
`embed-resources: true` from a copy of the template placed in the run folder (see the
assistant-stage pattern above) via `quarto::quarto_render(execute_params = list(...))`: a
single self-contained HTML of about 3 MB took about 23 seconds to render. `execute_params`
only changes what the code reads — a static YAML `title:` does not update per run, so
parameterise the title from a chunk if it needs to vary. Each `htmlwidget` table embeds its own
copy of its data, which is part of why file size grows with table count; for a report an
assistant will need to re-read later, write a short plain-text `summary.md` alongside the HTML
rather than re-parsing the rendered dashboard.

## Debugging

`tar_meta(fields = error, complete_only = TRUE)` and `fields = warnings`;
`tar_option_set(error = "null")` to finish the rest of the pipeline;
`tar_load_globals()` then `tar_load(upstream)` to reproduce in the console;
`tar_make(callr_function = NULL, use_crew = FALSE, as_job = FALSE)` with `browser()` (restart R
afterwards, debugging only); workspaces saved on error: `tar_workspaces()`, `tar_workspace()`,
`tar_traceback()`. The target-level `warnings` field also records "package built under R
version" messages, which are harmless.

## What to commit

Commit `_targets.R`, `R/`, `config/`, `py/` (with `uv.lock`), `report.qmd`, `renv.lock`,
`.Rprofile`, `renv/activate.R`, `renv/settings.json`. Do not commit the `_targets/` store;
optionally commit `_targets/meta/meta` (needed to read status). Several `tar_make()` calls
on one store at once can corrupt it.
