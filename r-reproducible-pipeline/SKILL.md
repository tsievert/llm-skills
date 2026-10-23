---
name: r-reproducible-pipeline
description: 'Builds reproducible multi-step R analysis pipelines with the targets package, renv lockfiles and Quarto reports (tarchetypes::tar_quarto), including Python steps through uv, YAML config, seeds, dynamic branching per sample or animal, and re-running the whole chain on a Slurm cluster with crew.cluster. Compares targets with Snakemake and other tools. For a Python-centred or mixed non-R workflow use python-reproducible-pipeline; for a plain Rscript job use hpc-r-code. Ships a tested project template and a static checker (check_targets_project.R). Use when the user wants to turn R scripts into a re-runnable pipeline, rerun only what changed, pin R packages with renv, make a Quarto report depend on analysis results, run targets on a cluster, or asks about targets, _targets.R, tar_make, renv.lock, crew or reproducible R analysis.'
---

# Reproducible R pipelines (targets + renv + Quarto)

Goal: anyone with the repository, the raw data and R can regenerate every result with one
command (`targets::tar_make()`), and a change to code, parameters or data reruns only the
targets it affects. Default stack: **targets** for the step graph, **renv** for R packages,
**Quarto** for the report, **uv** for any Python step. For Python-centred or mixed projects,
Snakemake may fit better: see "Choose the tool".

Tested with targets 1.12.0, tarchetypes 0.14.1, crew 1.3.3, crew.cluster 0.4.0, renv 1.3.1
and uv 0.12.5 on Windows 11 (R 4.6.0). Versions move: check the installed ones and the live
docs (sources in [references/sources.md](references/sources.md)) before stating an argument name.

## Where this skill runs

The assistant runs on the user's local machine, not on the cluster. It can scaffold the
project, run the pipeline locally, build the Slurm controller object without submitting, and
run the static checker. It cannot submit to Slurm, so partitions, accounts, modules, walltime,
filesystem behaviour and the `crew.cluster` Slurm controller are **untested until the user
runs them**.

**Requirement:** whenever information is needed that only the cluster has (partitions,
accounts, R modules, whether the main process may run on a login node, `sacct` output, logs),
stop and ask the user to run the specific command in their own shell, given in a code block,
and paste back the output. Do not guess. Start with `hpc-cluster-docs` if the site is unknown.

## Choose the tool (ask first, briefly)

Ask: how many steps and how long; mostly R, or mixed with Python or shell; where it will run
(laptop only, or Slurm); does the user already use a tool.

| Situation | Suggestion |
|---|---|
| A few R scripts run in sequence, laptop only | `source()` from one driver script is enough until rerunning only changed steps matters |
| Mostly R, objects passed between steps, one report | **targets** (default of this skill) |
| Many samples/animals/sessions, same steps per unit | targets with dynamic branching (`pattern = map(...)`, in the template) |
| Python-centred, or many non-R tools, or the user already uses Snakemake | Snakemake: see `python-reproducible-pipeline` |
| Reusing an existing nf-core pipeline | Nextflow (JVM, Windows only through WSL) |

Rerun semantics differ: targets compares **content hashes** of code, dependencies and files,
so touching a file or editing a comment does not rerun anything; Snakemake's triggers are
mtime, code, params, input and software environment. Say so when the user compares them. More
in [references/tool-choice.md](references/tool-choice.md). Give one or two sentences of
reasoning and leave the decision to the user.

## Workflow

Copy this checklist and tick it off:

```
- [ ] 1. Inventory the existing scripts: inputs, outputs, parameters, seeds, languages
- [ ] 2. Scaffold from assets/project-template (or adapt the user's repo)
- [ ] 3. Packages: renv::init(), commit renv.lock + .Rprofile + renv/activate.R + renv/settings.json
- [ ] 4. One target per step; functions in R/; inputs, scripts and config as file targets
- [ ] 5. tar_make(); change one setting and one function; confirm only the right targets rerun
- [ ] 6. Report: tar_quarto() with literal tar_read() calls
- [ ] 7. Cluster: controller from user-supplied facts; user runs it on the cluster
- [ ] 8. Run scripts/check_targets_project.R and fix findings
```

### 1-2. Inventory and scaffold

Copy [assets/project-template](assets/project-template): a working pipeline with a YAML
config, a Python step run through `uv run --locked` for each sample (dynamic branching), a
model fit, a Quarto report, an executor switch (`PIPELINE_EXECUTOR`) and a Slurm job script
with placeholders. Replace the example steps with the user's. Keep targets thin and put logic
in `R/` functions: targets reruns a target when a function it uses changes.

| File | Role |
|---|---|
| `_targets.R` | the pipeline: a list of `tar_target()` calls, `tar_option_set(seed=, controller=)` |
| `R/functions.R`, `R/controllers.R` | step functions; executor choice (sequential, local crew, Slurm) |
| `py/simulate.py`, `py/pyproject.toml`, `py/uv.lock` | Python step with its own `pyproject.toml`, `.python-version`, `uv.lock` |
| `config/config.yml` | parameters |
| `report.qmd` | Quarto report built by `tar_quarto()` |
| `_dependencies.R` | never run; lets renv see packages used only at run time (`quarto`) |
| `slurm/run_targets.sbatch` | main-process job script with `<PLACEHOLDER>` values |
| `.gitignore`, `README.md` | ignores (`_targets/`, `renv/library/`, `.venv/`), run instructions |

### 3. Packages (renv)

`renv::init()` once, then `renv::snapshot()` after adding packages. Packages used only at run
time are invisible to renv's static scan: **`quarto` was missed in a test** until a
`library(quarto)` line was added to `_dependencies.R`. Details, what to commit, and the shared
cache hazard: [references/renv-and-pinning.md](references/renv-and-pinning.md).

### 4. Targets: what makes a rerun correct

- **Files are file targets.** Input data, config and external scripts are
  `tar_target(x, "path", format = "file")` and are passed to the function that uses them.
  A path hard-coded inside a function is invisible to targets (the checker flags literal
  `read.csv("...")` and `system2(... "script.py")`).
- **Depend on small values, not the whole config.** `tar_target(n_obs, config$n_obs)` then use
  `n_obs`. Depending on the whole `config` list reran every branch when a sample was added
  (tested); with per-setting targets only the new branches ran.
- **Seeds:** `tar_option_set(seed = <integer>)`; each target (and branch) gets a seed from its
  name and the global seed, readable with `tar_meta()`. Use `tar_seed_get()` inside a target to
  pass the seed to a Python or external step (`tar_seed()` is deprecated). Deleting the store
  and rebuilding reproduced identical results (tested). `seed = NA` disables seeding.
- **YAML trap:** R's `yaml` reads unquoted keys `n`, `y`, `yes`, `no`, `on`, `off` as logical,
  so `n: 40` becomes `FALSE: 40`. Use descriptive keys (`n_obs`); `read_config()` in the
  template fails early on this.
- Line-ending changes alter file hashes: rewriting a tracked file with CRLF instead of LF
  reran its dependants in a test (relevant with git `autocrlf` on Windows).
- More patterns (invalidation table, dynamic branching, storage formats, debugging):
  [references/targets-patterns.md](references/targets-patterns.md).

### 5-6. Run, report

```r
targets::tar_make()          # runs only outdated targets, in a fresh R process
targets::tar_outdated()      # what would run; tar_visnetwork() draws the graph
targets::tar_read(coef_table)
```

Prove the incremental behaviour before trusting it: change one config value and one function,
run `tar_outdated()`, and confirm only the expected targets are listed. A report is a target
that displays upstream results: use literal `tar_read(name)` / `tar_load(name)` in the Quarto
document (static scan), and keep computation out of it. `tar_quarto()` needs the CRAN package
`quarto`. A Python chunk in a targeted report is **untested**; the dependency scan is R-only.

### 7. Cluster (crew.cluster)

`PIPELINE_EXECUTOR=slurm` selects `crew.cluster::crew_controller_slurm()` in
`R/controllers.R`; `slurm/run_targets.sbatch` runs the main process as a small job. Set
`log_output` (workers log to `/dev/null` by default), `time_minutes` (the real Slurm limit;
`seconds_wall` is not), and `script_directory`. Where the main process may run and what the
workers need come from the site documentation, never from memory. Facts, the commands to ask
the user for, and the untested parts: [references/hpc-crew.md](references/hpc-crew.md). Job
scripts and sizing: `hpc-job-scripts`, `hpc-resource-allocation`.

### 8. Check

```r
source("<skill-dir>/scripts/check_targets_project.R")
check_targets_project(".")        # or: Rscript <skill-dir>/scripts/check_targets_project.R .
```

It flags: no `_targets.R`; `seed = NA` or no explicit seed; literal-path reads and literal
script calls (untracked inputs); `setwd()`, absolute paths, run-time installs (packages,
Python); deprecated `reporter = "summary"`; YAML keys and values read as logical; `_targets/`
committed or not ignored, `renv/library` committed; missing `renv.lock`, `.Rprofile` not
activating renv, packages used but absent from `renv.lock`; Python steps without `uv.lock`,
pin or `--locked`; a crew Slurm controller without `log_output` or `time_minutes`;
`<PLACEHOLDER>` values left in a controller or job script; report dependency pitfalls. It is
static: it does not run targets, see the cluster, or judge whether the design is right. The
shipped template reports one expected ERROR class (placeholders) plus a missing `renv.lock`
until `renv::init()` is run; in the assistant's R session `.Rprofile` may be unreadable (the
session guard), which the checker reports as INFO.

## Status of the claims in this skill

| Claim | Status |
|---|---|
| Template runs end to end (Python step via `uv run --locked`, dynamic branching, `tar_quarto`), second run skips everything | tested locally |
| Content-hash behaviour: touch, comment edits and unused functions do not rerun; used-function edits and config changes do; unchanged output stops downstream reruns | tested locally |
| Adding one sample runs only its new branches (with per-setting targets) | tested locally |
| Seeds reproduce after deleting the store | tested locally |
| `renv::init()` on the template; pipeline runs inside the project library; `quarto` needs `_dependencies.R` | tested locally |
| `PIPELINE_EXECUTOR=local` (crew local, two workers) | tested locally |
| `crew_controller_slurm()` builds | tested locally; submission untested |
| `slurm/run_targets.sbatch` passes the `hpc-job-scripts` linter | tested locally; never submitted |
| Checker on the clean template, an `renv::init()` copy, and a copy with seeded defects; CLI exit status | tested locally |
| `tar_make()` inside a Slurm job, workers submitting from a compute node, NFS behaviour, Linux/macOS/WSL | untested |
| Python chunk inside a targets-built report; `tar_map`, `tar_rep`, `tar_resources_*` | untested |
| Snakemake/Nextflow/Prefect/Dagster statements | read from docs, never run here |

## Pitfalls seen while building this skill

- **Never copy or overwrite an renv project directory with `file.copy()` or similar.** Its
  `renv/library` links into the shared renv cache, so copying a project onto itself truncated
  63 cache entries (repaired by copying the matching installed package versions back and
  verifying with `diff -r`). Copy only source files, and let `renv::init()` or
  `renv::restore()` build a new library.
- R's `yaml` key trap above; `tar_make(reporter = "summary")` is deprecated; `tar_quarto()` fails
  without the `quarto` package.
- Run `renv::init()` and project runs in a **subprocess** (`callr::r()`): `init()` restarts the
  session in interactive use.
- The assistant's R session may be blocked from reading `.Rprofile` and writing outside the
  project; use a git-ignored folder such as `tmp-examples/` for tests and delete it afterwards.

## Related skills

- `python-reproducible-pipeline`: Snakemake and uv for Python-centred or mixed workflows; the other side of the "choose the tool" decision.
- `hpc-cluster-docs`: identify the cluster and its documentation before filling the Slurm controller or job script.
- `hpc-r-code`: R scripts and package libraries on a cluster (parallel workers, RNG, checkpoints).
- `hpc-job-scripts`: sbatch scripts, log directories and the linter used on the template job script.
- `hpc-resource-allocation`: sizing `memory_gigabytes_required` and `time_minutes` from `sacct` measurements.
- `manuscript-figures-ggplot`: journal-ready figures produced inside targets.
- `data-repository-readme`: documenting the code and data deposit that accompanies the pipeline.
- `git-for-research-projects`: `.gitignore` for `_targets/` and the data folder, keeping `renv.lock` tracked, tagging a version.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
