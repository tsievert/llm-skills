# targets patterns

Contents: project layout; file targets and external tools; invalidation (tested); dynamic
branching; seeds; Quarto reports; storage formats and memory; debugging; what to commit.

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
(arrow) for data frames; `"file"` for data too large for memory. Parquet is not covered on the
performance page. Large runs: `tar_option_set(memory = "transient", garbage_collection = 10)`.

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
