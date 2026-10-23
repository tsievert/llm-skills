---
name: python-reproducible-pipeline
description: 'Builds reproducible multi-step analysis pipelines around Python with uv (pyproject.toml, uv.lock, pinned Python) and Snakemake, including R or shell steps, parameters and seeds in config, logs and benchmarks, Snakemake reports, and re-running the whole chain on Slurm with the Slurm executor plugin. Compares Snakemake with pytask, Nextflow, DVC, Prefect and Dagster so the user can choose. Ships a tested project template and a static checker. Use when the user wants to turn scripts into a re-runnable workflow, pin or lock a Python environment, rerun only changed steps, run a pipeline on a cluster, or asks about Snakemake, uv lock, workflow managers or reproducible Python analysis.'
---

# Reproducible Python pipelines (uv + Snakemake)

Goal: anyone with the repository, the raw data and `uv` can regenerate every result with
one command, and a change to code, parameters or data reruns only the steps it affects.
Default stack: **uv** for the environment, **Snakemake** for the step graph. Other tools
are covered in [references/tool-choice.md](references/tool-choice.md); offer them when
the user's situation differs (see "Choose the tool").

Tested with Snakemake 9.27.1, snakemake-executor-plugin-slurm 2.8.0 and uv 0.12.5 on
Windows 11. Versions move quickly: check the installed ones and the live docs
(sources in [references/sources.md](references/sources.md)) before stating a flag.

## Where this skill runs

The assistant runs on the user's local machine, not on the cluster. It can scaffold the
project, run the workflow locally (Windows, macOS, Linux), do Snakemake dry runs of the
Slurm profile, and run the static checker. It cannot submit to Slurm, so profile values,
partitions, accounts, module names, filesystem behaviour and the Slurm executor itself
are **untested until the user runs them**.

**Requirement:** whenever information is needed that only the cluster has (partitions,
accounts, `uv` availability on compute nodes, Python versions, `sacct`, logs), stop and
ask the user to run the specific command in their own shell, given in a code block, and
paste back the output. Do not guess. Start with `hpc-cluster-docs` if the site is unknown.

## Choose the tool (ask first, briefly)

Ask: how many steps and how long do they run; are they all Python or mixed with R/shell;
where will it run (laptop only, or Slurm); does the user already use a tool. Then:

| Situation | Suggestion |
|---|---|
| A few Python scripts run in sequence, laptop only | `uv run --locked` calling the scripts from one short driver script is enough; use Snakemake once rerunning only changed steps matters |
| Several steps, many samples/animals/sessions, Python and/or R and/or shell, maybe Slurm | **Snakemake** (default of this skill) |
| Purely R with R-object dependencies | the `targets` package is the R-native choice (see `r-reproducible-pipeline`) |
| Python functions as tasks, laptop-scale | `pytask`; no Slurm route was verified |
| Reusing an existing nf-core pipeline, or heavy cloud use | Nextflow (JVM, Groovy, Windows only via WSL) |
| Large data files under version control | DVC for the data, Snakemake for the steps |
| Prefect, Dagster | not recommended here: service/platform oriented, no HPC route found in their docs |

Say why in one or two sentences and leave the decision to the user. Details and sources:
[references/tool-choice.md](references/tool-choice.md).

## Workflow

Copy this checklist and tick it off:

```
- [ ] 1. Inventory the existing scripts: inputs, outputs, parameters, seeds, languages
- [ ] 2. Scaffold from assets/project-template (or adapt the user's repo)
- [ ] 3. Environment: uv init/add, uv lock, commit pyproject.toml + uv.lock + .python-version
- [ ] 4. One rule per step: explicit input/output, params for every config value, log, benchmark
- [ ] 5. Run locally (small data); change one parameter and one script; confirm only the right steps rerun
- [ ] 6. Reports and archiving (snakemake --report, README with data source and commands)
- [ ] 7. Slurm profile: fill from user-supplied cluster facts; dry run locally; user runs it on the cluster
- [ ] 8. Run scripts/check_pipeline.py and fix findings
```

### 1-2. Inventory and scaffold

Copy [assets/project-template](assets/project-template) (a working two-rule workflow:
per-sample simulation, then a summary, with a report entry, logs, benchmarks and a Slurm
profile with placeholders). Replace the example scripts with the user's. Keep the layout:
`workflow/Snakefile`, `workflow/scripts/`, `config/`, `workflow/profiles/`, generated
`results/`, `logs/`, `benchmarks/`. Snakemake finds `workflow/Snakefile` automatically
when run from the project root, so `-s` is not needed. Template contents:

| File | Role |
|---|---|
| `pyproject.toml`, `.python-version`, `.gitignore`, `README.md` | environment declaration (snakemake, Slurm plugin, pygments), interpreter pin, ignores, run instructions |
| `config/config.yaml` | samples, `n`, `seed`, read once in the Snakefile |
| `workflow/Snakefile` | rules `simulate` (one job per sample) and `summarise` (report entry) |
| `workflow/scripts/simulate.py`, `summarise.py` | example steps using `snakemake.params`, `snakemake.log` |
| `workflow/report/summary.rst` | report caption |
| `workflow/profiles/slurm/profile.yaml` | Slurm profile with `<PLACEHOLDER>` values |

### 3. Environment

```bash
uv sync --locked                      # from the committed lock (first time: uv lock)
uv run --locked snakemake --cores 2   # fail instead of silently re-resolving
```

Commit `pyproject.toml`, `uv.lock` and `.python-version`; never `.venv`. Use `--locked`
in scripts and job files so a stale lock fails loudly (`--frozen` skips the check).
Optional `exclude-newer` date pin and other options:
[references/environments-and-pinning.md](references/environments-and-pinning.md).

### 4. Rules: what makes a rerun correct

- **Every value a script depends on must reach the rule through `params:` or `input:`.**
  A script that reads `snakemake.config` directly is not rerun when that config value
  changes (tested: no rerun; the same value passed through `params:` reran the rule).
- Any edit to a script, including a comment, reruns its rule (code trigger).
- Touching a file without changing its content did not trigger a rerun in a local test
  on Windows; content changes did. The mechanism (checksums for small files) and the
  behaviour on a shared filesystem such as NFS are **not verified**; see
  [references/snakemake-slurm.md](references/snakemake-slurm.md) for a test the user can run.
- One writer per output path; derive per-sample seeds from the config seed and the
  wildcard (template does this); give each rule `log:` and `benchmark:`, because the
  benchmark files are what `hpc-resource-allocation` needs to size requests.
- R or shell steps: `script:` supports `.py`, `.R`, `.Rmd` (single HTML output) and Bash,
  and `shell:` runs any command. R packages need their own pinned environment; `hpc-r-code`
  covers R on clusters. Quarto as a rule step is not covered by the Snakemake docs read.

### 5-6. Local run, reports

```bash
uv run --locked snakemake --cores 2
uv run --locked snakemake --cores 2 -n          # dry run: shows which steps would rerun and why
uv run --locked snakemake --report report.html  # needs pygments (a dependency in the template)
```

Prove the incremental behaviour before trusting it: change one config value and one
script and read the `reason:` lines of the dry run.

### 7. Slurm

Use the plugin through a profile: `snakemake --workflow-profile slurm` (reads
`workflow/profiles/slurm/profile.yaml`). Facts and caveats that cost time:

- `--jobs N` (or `jobs:` in the profile) is required for the Slurm executor.
- Use `mem_mb` everywhere; `mem_mb` and `mem_mb_per_cpu` are mutually exclusive.
- `runtime` is in minutes; jobs run in a non-interactive `sh`, so `.bashrc` is not
  sourced (use `precommand`); `uv` must be available on the compute nodes or the profile
  must call it by full path: ask the user to run `which uv; uv --version` there.
- Partition, account, limits and whether the controller may run on a login node come from
  the site documentation, never from memory.
- Details, the cluster-side commands to ask for, and the rerun/NFS test:
  [references/snakemake-slurm.md](references/snakemake-slurm.md). Job-script and resource
  skills: `hpc-job-scripts`, `hpc-resource-allocation`.

### 8. Check

```bash
uv run --no-project --with pyyaml python <skill-dir>/scripts/check_pipeline.py
```

It flags a missing or stale `uv.lock`, a missing `.python-version`, `report()` without
pygments, scripts that read `snakemake.config` (untracked values), run-time `pip install`,
absolute paths, rules without `log:`, and Slurm profile problems (placeholders left,
`mem_mb` with `mem_mb_per_cpu`, no `jobs`, no default `runtime`). It is static: it does
not run Snakemake and cannot see the cluster. The shipped template reports one expected
ERROR until the `<PLACEHOLDER>` values in its profile are replaced.

## Status of the claims in this skill

| Claim | Status |
|---|---|
| uv + Snakemake install, run native on Windows, Python and R `script:` steps, incremental rerun, `--report` (after adding pygments), per-sample params and seeds, logs and benchmarks | tested locally |
| Slurm profile loads and dry-runs (`--workflow-profile slurm -n`) | tested locally; real submission untested |
| `--locked` fails on a stale lock | tested locally |
| Touch-only changes do not rerun; reason for this | observed; mechanism unverified |
| Snakemake rerun behaviour on NFS or with clock skew | untested |
| Prefect, Dagster, Nextflow, pytask statements | read from docs or package metadata, never run |
| Linux, macOS, WSL, conda or container deployment, Quarto as a rule step | not tested |

## Related skills

- `hpc-cluster-docs`: identify the cluster and its official documentation before writing a Slurm profile.
- `hpc-job-scripts`: sbatch scripts, arrays and requeue handling when a single job script is enough or Snakemake's job files need debugging.
- `hpc-python-code`: the Python code inside each step (logging, seeds, atomic writes, CPU counts).
- `hpc-resource-allocation`: sizing `mem_mb` and `runtime` from the benchmark and `sacct` output.
- `hpc-r-code`: R steps and R environments on a cluster.
- `animal-behaviour-tracking-analysis`: a typical pipeline to wrap (DeepLabCut output to metrics to statistics).
- `data-repository-readme`: documenting the code and data deposit that accompanies the pipeline.
- `r-reproducible-pipeline`: the R-centred counterpart (targets, renv, Quarto) and the other side of the "choose the tool" decision.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
