# Pipeline resources ledger

Shared research ledger for three planned skills: `python-reproducible-pipeline` (PY), `r-reproducible-pipeline` (R),
`python-r-interop` (IO). Started 2026-10-23. Not a skill (no SKILL.md); working notes, not yet committed.

Legend for "Use": PY / R / IO = skill(s) that could use the resource. Status: **read** = page text read in this session;
**partial** = only part read or the page answered only some questions; **meta** = version/metadata only; **not read** = lead only.
Everything here is from live lookups on 2026-10-23; re-check versions before writing them into a skill (`check_versions()`).

## 1. Shared concerns (where the three skills overlap)

| Concern | PY | R | IO | Note |
|---|---|---|---|---|
| Pinning the environment | uv (`pyproject.toml` + `uv.lock`) | renv (`renv.lock`) | both, plus how Quarto/reticulate find them | Two lockfiles in a mixed project; document which tool owns what |
| "As of date" pinning | `uv ... exclude-newer` | Posit Package Manager snapshot date (to verify) | `reticulate::py_require(exclude_newer=)` | Same idea in three places; lightweight alternative to a lockfile |
| Project layout and config | Snakemake layout (`workflow/`, `config/`, `results/`) | targets `_targets.R`, `_targets/` | one layout for both | Decide one canonical tree |
| Report layer | Quarto, Snakemake `--report` | `tarchetypes::tar_quarto`, Quarto | Quarto with both engines | Quarto picks knitr+reticulate when `{python}` and `{r}` mix |
| HPC execution | Snakemake Slurm executor | crew.cluster, future.batchtools | one workflow calling both | Assistant stays local; cluster facts come from the user (standing rule) |
| Data exchange | parquet via pyarrow/polars/duckdb | arrow, nanoparquet, duckdb | Arrow in-process vs parquet on disk | Prefer parquet files between pipeline steps (to confirm with tests) |
| Cache / skip logic | Snakemake mtime, DVC hashes, pytask hashes | targets hashes | Quarto `freeze`, `cache` | Different invalidation rules; explain in each skill |
| Seeds, logging | existing `hpc-python-code`, `hpc-r-code` | same | | Link, do not duplicate |

## 2. Python workflow and environment tools

Versions from the PyPI JSON API (2026-10-23, `info.version`; release date of the first file listed, so approximate).

| Tool | Version | Requires Python | Use | Status | Key facts / caveats |
|---|---|---|---|---|---|
| Snakemake | 9.27.1 (2026-10-21) | >=3.11 | PY, IO | docs home, deployment, reporting, rules pages read | File-based rule DAG (Make-like), Python DSL. Per-rule `conda:` or `container:` (`--sdm conda`/`apptainer`), `envmodules:` fallback, `--archive`, `--report`. `script:` supports Python, R, R Markdown (single HTML output), Julia, Rust, Bash, `notebook:` for Jupyter. **Quarto not mentioned** on the rules page. Page 154k chars, only first 90k read |
| snakemake-executor-plugin-slurm | 2.8.0 (2026-08-10) | >=3.11 | PY | read (catalog page) | `snakemake --executor slurm`; resources `slurm_partition`, `slurm_account`, `mem_mb` (xor `mem_mb_per_cpu`), `runtime` (minutes), `cpus_per_task`, `gres`, `slurm_extra`. Jobs run in non-interactive sh, so `.bashrc` is not sourced (use `precommand`). Running Snakemake inside a Slurm job warns. Status polling starts 40 s after submission. Login-node use depends on site policy |
| snakemake-storage-plugin-fs | 1.1.3 | >=3.11 | PY | read (as part of the Slurm profile) | Needed for shared-FS profile keys |
| snakedeploy / snakefmt | 0.17.1 / 2.1.0 | >=3.11 | PY | meta | `snakedeploy pin-conda-envs` for pinned conda envs; snakefmt formats Snakefiles. Linting not on the deployment page |
| Snakemake pixi software-deployment plugin | not on PyPI check | n/a | PY, R | search snippet only | Community plugin (cademirch); `software: pixi(workspace=, env=, frozen=, locked=)`; **requires snakemake>=10**, but stable is 9.27.1, so not usable yet. Re-check |
| uv | 0.13.5 (PyPI) | >=3.8 | PY, IO, R (via reticulate) | project layout, sync, scripts pages read | Commit `pyproject.toml`, `uv.lock` (and `.python-version`, per a third-party summary; the layout page did not cover it); never `.venv`. `uv sync --locked` / `uv run --locked` fail if the lock is stale; `--frozen` skips the check; `uv lock --check`. `--exact` removes extras. Dependency groups `--no-dev`, `--only-group`. PEP 723 inline script metadata, `uv lock --script`, `exclude-newer`. `uv export -o pylock.toml` (PEP 751). **Check the PyPI version**: it looked low relative to the docs-era features; confirm with `uv --version` on the machine |
| pixi | PyPI "pixi" 1.0.1 (2020) is a **different, unrelated package** | | PY, R, IO | home page read | The real tool installs from pixi.sh, not PyPI. Lockfile, conda + PyPI deps (via uv), multi-environment, task runner, multi-language (can host R via conda-forge, not confirmed on the page). No HPC statement on the page |
| DVC | 3.67.1 (2026-03-31) | >=3.9 | PY | pipelines page read | `dvc.yaml` stages (`cmd/deps/params/outs`), `dvc.lock` hashes, `params.yaml`, run cache, `dvc repro`. Metrics, remotes, HPC not covered on the page. Overlaps Snakemake; more relevant for large data versioning than orchestration (candidate for `git-for-research-projects`) |
| pytask | 0.6.0 (2026-05-01) | >=3.10 | PY | docs home and comparison page read | Python-function tasks, lazy execution, plugins: pytask-parallel, pytask-r, pytask-latex, pytask-stata; lockfile reference page exists. Comparison page has no targets/DVC entry and no HPC/Slurm statement. Closest Python analogue of targets; unproven on Slurm |
| Prefect | 3.9.0 | >=3.11,<3.16 | PY | meta + one blog | Python flow orchestrator; third-party blog says "flows" vs Dagster "assets". Service-oriented; likely heavy for a single-researcher analysis. Not read from official docs |
| Dagster | 1.13.26 | >=3.10,<3.15 | PY | meta + one blog | Asset-oriented; same caveat |
| Kedro | 1.7.0 | >=3.10 | PY | meta | Data-science project template with a pipeline abstraction; not read |
| Hamilton (sf-hamilton) | 1.90.0 | >=3.10.1 | PY | meta | Function-DAG library; not read |
| Luigi | 3.8.1 | >=3.10,<3.14 | PY | meta | pytask comparison page says development has slowed |
| doit | 0.37.0 | >=3.10 | PY | meta | Generic task runner; not read |
| Nextflow | n/a (not Python) | | PY (as alternative) | search snippets only | Groovy DSL; nf-core ecosystem; third-party comparisons say Snakemake is the usual choice on academic Slurm clusters. Not read from official docs |
| submitit / dask-jobqueue / parsl | 1.5.4 / 0.9.0 (2024-08) / 2026.10.19 | >=3.8 / >=3.10 / >=3.10 | PY | meta | Python-level Slurm submission (function, not file DAG). Complements `hpc-python-code`. dask-jobqueue last release 2024-08 (stale?) |
| papermill / jupytext / marimo / nbstripout | 2.7.0 / 1.19.6 / 0.25.2 / 0.9.1 | >=3.10 / >=3.9 / >=3.10 / >=3.10 | PY, IO | meta | Notebook as parameterised step, notebook-to-text pairing, reactive notebooks, stripping outputs before commit. Not read |
| hydra-core / pydantic-settings | 1.3.7 / 2.16.1 | n/a / >=3.11 | PY | meta | Config handling; not read |
| ruff / pytest / pre-commit / nox / tox | 0.17.2 / 9.1.1 / 4.7.0 / 2026.10.20 / 4.67.1 | | PY | meta | Quality tooling for the pipeline code |
| copier / cookiecutter | 9.19.1 / 2.7.1 | >=3.10 | PY, R | meta | Project templates; copier supports updates from the template |
| mlflow | 3.17.2 | >=3.10 | PY | meta | Experiment tracking; probably out of scope for non-ML analyses |
| pandas / polars / pyarrow / duckdb | 3.1.0 / 2.0.0 / 26.0.0 / 2.0.0 | >=3.11 / >=3.10 / >=3.11 / >=3.11 | PY, IO | meta | pandas 3 is relevant to the known kpms/pandas pin issue in this repo |
| pins | 0.9.2 | >=3.9 | PY, R, IO | meta | Python port of the R `pins` (same board format; R side 1.4.2 on CRAN) |
| pandera / great-expectations | 0.34.1 / 1.24.1 | | PY | meta | Data validation; not read |
| rpy2 / pyreadr | 3.6.9 / 0.5.7 | >=3.9 / n/a | IO | meta | Python embeds R; reading RDS/RData from Python. Not read |

PyPI name collisions found: `pixi` and `reticulate` on PyPI are unrelated to the tools of those names. Never `pip install` them.

## 3. R workflow and environment tools

CRAN versions via `available.packages()` (2026-10-23); "installed" = in the user's current library.

| Package | CRAN | Installed | Use | Status | Key facts / caveats |
|---|---|---|---|---|---|
| targets | 1.12.0 | no | R, IO | manual index + crew chapter read | Make-like, R-only; manual chapters: walkthrough, projects, literate programming (Quarto via tarchetypes), distributed computing (crew), HPC "old way". Manual states it is R-focused; **no Python/non-R target coverage** on the crew page. Python steps would be `format = "file"` targets calling a script or `uv run` (design idea, untested) |
| tarchetypes | 0.14.1 | no | R | meta | `tar_quarto()`, `tar_render()`; not read |
| crew | 1.3.3 | no | R | crew page read | Controllers, `seconds_idle`, `tasks_max`, `seconds_wall`, `crew_controller_group()` |
| crew.cluster | 0.4.0 | no | R | crew page read | Page example uses SGE (`crew_controller_sge`) and says to write a launcher plugin for other schedulers; **Slurm controller not mentioned on that page.** Round 2: the package reference (v0.4.0.9001) does list `crew_controller_slurm()` (lifecycle "maturing"), `crew_options_slurm()` (experimental), `crew_monitor_slurm()`; SGE maturing, PBS and LSF experimental. Only the index was read, not the function help |
| renv | 1.3.1 | yes (1.3.1) | R, IO | Python vignette read | `use_python()` makes a project Python env; **`snapshot()` runs `pip freeze > requirements.txt`, `restore()` runs `pip install -r`** (conda: `environment.yml`). That is weaker than `uv.lock` (no hashes, no universal resolution); a decision point for IO |
| reticulate | 1.47.0 | yes (1.47.0) | IO, R | `py_require` reference + deprecated dependencies vignette read | `py_require(packages, python_version, exclude_newer, action)` builds an ephemeral uv env, used only if no other Python is found earlier in the order of discovery; `RETICULATE_PYTHON="managed"` forces it, `RETICULATE_USE_MANAGED_VENV="no"` disables. `UV_*` env vars apply (offline, index, prerelease). Cache cleared after 120 days by default. After Python initialises, only adding packages works |
| arrow | 25.0.1 | no | IO | Arrow-in-reticulate article read | Zero-copy `r_to_py()` of Arrow Tables, **same process only**; needs pyarrow and an env chosen first. Parquet file exchange not covered on the page |
| nanoparquet / duckdb / parquetize | 0.5.2 / 1.5.6 / 0.5.8 | no | IO | meta | Lighter parquet writers and a shared SQL engine for both languages; not tested |
| pins | 1.4.2 | no | IO | meta | See Python `pins` |
| rix | 0.18.5 | no | R, IO | meta | Nix-based reproducible R environments; heavy; not read |
| quarto (R pkg) | 1.5.1 | no | R, IO | meta | Calls Quarto from R |
| future.batchtools / clustermq | 0.30.0 / 0.10.1 | no | R | meta | Already referenced in `hpc-r-code`; targets recommends crew over these |
| here / withr / config / yaml / usethis / pak / conflicted / testthat | various | mostly yes | R | meta | Project hygiene; `config` for per-environment settings |
| workflowr / orderly / drake / rrtools | 1.7.2 / 2.0.3 / 7.13.11 / not on CRAN | no | R | meta | drake is superseded by targets (targets manual says so). rrtools is not on CRAN (GitHub only: needs user permission to install). workflowr and orderly not assessed |
| box | 1.2.3 | no | R | meta | Module system; not read |

## 4. Quarto (shared PY / R / IO)

| Page | Status | Key facts |
|---|---|---|
| https://quarto.org/docs/projects/code-execution.html | read | `freeze: true/auto` stores results in `_freeze/` (commit it); `cache: true` uses knitr cache or jupyter-cache; incremental `quarto render file` always executes; `execute-dir: project`; `QUARTO_PROJECT_DIR` |
| https://quarto.org/docs/projects/virtual-environments.html | read | Documents venv, conda, renv; the venv section uses `pip freeze` (no uv section on that page). Mixed `{python}` + `{r}` documents use knitr + reticulate and **may pick a different Python than your env**; fix with `RETICULATE_PYTHON` in `.Rprofile`. `renv::use_python()` plus `renv::snapshot()` writes `requirements.txt` |
| https://quarto.org/docs/computations/python.html | not read | Jupyter engine, kernel selection |
| https://quarto.org/docs/projects/scripts.html | not read | Pre/post-render project scripts (could call the pipeline) |

## 5. Design observations to carry into the skills (not yet decisions)

1. Two reasonable PY stacks: **uv + Snakemake** (file-based, Slurm plugin, R scripts supported, reports) versus **uv + pytask** (Python-function style, closer to targets). Snakemake is the safer default on Slurm; pytask has no verified Slurm story. DVC, Prefect, Dagster are likely mismatches (service or data-versioning focus); say so briefly and let the user decide.
2. The same Snakemake could drive R scripts, so `r-reproducible-pipeline` and `python-reproducible-pipeline` should say when to use targets (R-centric) vs Snakemake (mixed or Python-centric). This is the main overlap to resolve in IO.
3. renv's Python integration is `pip freeze`-based. For mixed projects a plausible split is: renv for R, uv for Python, with `RETICULATE_PYTHON` pointing at the uv `.venv`. Needs a tested recipe before writing.
4. `exclude-newer` (uv) and `py_require(exclude_newer=)` give a cheap "as of date" pin; the R analogue (PPM snapshot URL) is not yet researched here.
5. Windows pitfalls already recorded in this repo (blocked `~/.posit` paths from the R session, hdf5r dimension order, pandas pins) apply to IO; Snakemake itself on native Windows was not checked (Linux/WSL is typical).

## 6. Not yet done (candidates for the next research round; round 2 results are in section 8)

- Snakemake: remaining 64k chars of the rules page, `--sdm` details, workflow template repo, Snakemake with uv or venv (no official uv method found; only conda, apptainer, envmodules, community pixi plugin), testing/linting, Windows support.
- Official docs for Prefect, Dagster, Kedro, Hamilton, Nextflow (only meta and third-party comparisons so far).
- crew.cluster reference (Slurm controller), `targets` + external-script patterns, `tar_quarto`.
- Posit Package Manager snapshots for R "as of" pinning (`posit-products` skill may cover it).
- `renv` + uv coexistence; `reticulate::use_virtualenv()` against a uv `.venv`.
- Quarto Python page, Quarto `scripts.html`.
- OpenAlex search (standing rule for literature): reproducibility-in-research-computing papers (e.g. Snakemake, targets, Nextflow publications), for a references file.
- Social search (Bluesky/Mastodon) for practitioner pain points (uv + Snakemake, targets + Python).
- Test on this machine: `uv --version`, a minimal Snakemake run on Windows or WSL, reticulate with a uv `.venv`.
- Install decisions: CRAN packages (targets, tarchetypes, crew, arrow, ...) may be installed without asking; any GitHub/R-universe source (rrtools, Snakemake pixi plugin) needs explicit permission.

## 7. Source URLs fetched

- https://snakemake.readthedocs.io/en/stable/ , .../snakefiles/deployment.html , .../snakefiles/reporting.html , .../snakefiles/rules.html (partial)
- https://snakemake.github.io/snakemake-plugin-catalog/plugins/executor/slurm.html
- https://github.com/cademirch/snakemake-software-deployment-plugin-pixi (search snippet only)
- https://docs.astral.sh/uv/concepts/projects/layout/ , .../concepts/projects/sync/ , .../guides/scripts/
- https://pixi.sh/latest/
- https://dvc.org/doc/start/data-pipelines/data-pipelines
- https://pytask-dev.readthedocs.io/en/stable/ , .../explanations/comparison_to_other_tools.html
- https://books.ropensci.org/targets/ , .../crew.html
- https://rstudio.github.io/reticulate/reference/py_require.html , .../articles/python_dependencies.html
- https://rstudio.github.io/renv/articles/python.html
- https://arrow.apache.org/docs/r/articles/python.html
- https://quarto.org/docs/projects/code-execution.html , .../virtual-environments.html
- Third-party (search results, lower weight): getbruin.com 2026 pipeline-tool comparison, casrai.org Snakemake vs Nextflow, cytogence.com, tasrieit.com (vendor-style blogs; version claims there are not reliable)

## 8. Round 2 (2026-10-23)

### 8.1 Official docs: Prefect, Dagster, Nextflow

| Tool | Source read | Findings | Fit for a single-researcher Slurm analysis |
|---|---|---|---|
| Prefect 3.9.0 | https://docs.prefect.io/v3/get-started (intro only) | Python decorators for flows and tasks, state tracking, retries, result caching, resume from last success; runs locally, deploy to containers, Kubernetes or cloud; UI plus events and automations. Intro does not mention Slurm/HPC, a local-vs-server requirement, or task runners (those pages not read). Docs offer `llms.txt` for assistants | Probably more machinery than needed (server, deployments); Slurm route unverified |
| Dagster 1.13.26 | https://docs.dagster.io/ (overview only; the `getting-started/what-is-dagster` URL returned 404) | Asset-based orchestrator with lineage, asset checks, partitions, webserver/UI, schedules and sensors; Dagster+ is the managed product. Overview does not cover Slurm or whether the daemon is mandatory | Asset-graph idea is attractive but the platform is data-engineering oriented; Slurm route unverified |
| Nextflow | https://www.nextflow.io/docs/latest/overview.html (redirects to Seqera docs; overview only) | Dataflow of processes; each process can run Bash, Perl, Python or R; executors include SLURM, LSF, AWS Batch, Google Cloud Batch; local executor by default; integrates Git, Docker, Conda; language based on Java/Groovy; config in `nextflow.config`. The page shows a static-typing flag for "Nextflow 26.10 or later". Not read: install requirements (Java is on this machine), Windows/WSL status, resume cache | Strong Slurm story, but a second language and JVM; worth it mainly when reusing nf-core pipelines |

Take-away: for a Python-and-R analysis on Slurm, Snakemake remains the lead candidate; Nextflow is the credible alternative; Prefect and Dagster should be mentioned briefly as "not recommended here, and why", as I could not confirm an HPC route from their docs.

### 8.2 crew.cluster

Reference index (v0.4.0.9001): Slurm controller exists, see the corrected `crew.cluster` row in section 3. Still unread: `crew_controller_slurm` help page (arguments such as partition, memory, walltime options).

### 8.3 Local test: uv + Snakemake + Rscript (Windows 11, uv 0.12.5, Snakemake 9.27.1)

Scratch project, Python 3.12, nothing in the repo.

| Check | Result |
|---|---|
| `uv init` then `uv add snakemake` | Installed from the lock without problems; `uv run --locked snakemake --version` gives 9.27.1 |
| Two-rule workflow: `script:` Python writes CSV, `script:` R (`snakemake@input[[1]]`) fits `lm` | Ran natively on Windows via `uv run --locked snakemake -s workflow/Snakefile --cores 2`; `Rscript` was found on PATH; result correct; second run: "Nothing to be done" |
| `config/config.yaml` with seed and n passed to the Python script as `snakemake.config` | Worked |
| `uv add snakemake-executor-plugin-slurm` (2.8.0, with jobstep 0.6.1) | Installs; `--executor slurm -n` first errored "has to be specified ... use --jobs N"; with `--jobs 1 -n -F` the dry run succeeds. Real submission not testable here (no Slurm) |
| Stale lock detection | After editing `pyproject.toml`, `uv run --locked` and `uv lock --check` both fail with "lockfile needs to be updated"; `uv lock` then fixes it |
| Not tested | `--sdm conda/apptainer`, `--report`, `.qmd` rules, WSL, a real cluster, paths with spaces, `uv run` inside a Slurm job, Snakemake `.venv` activation on the compute node (uv must be available there; ask the user) |

Notes: `uv --version` here is 0.12.5 while PyPI lists a newer 0.13.5 (the `uv` PyPI figure in section 2 stays unverified as the "latest"). The default Windows `python` is the Store stub, so only uv-managed Pythons work; relevant for the IO skill.

### 8.4 OpenAlex (R/httr2; authors, venues and DOIs verified via `authorships`, abstracts not read)

Core references found (OpenAlex ID, first authors, venue, year, citations at query time):

| Topic | OpenAlex | Reference | Cites |
|---|---|---|---|
| Snakemake (original) | W2110417468 | Köster & Rahmann, Bioinformatics 2012, https://doi.org/10.1093/bioinformatics/bts480 | 2774 |
| Snakemake (update) | W3122109253 | Mölder et al., F1000Research 2021, https://doi.org/10.12688/f1000research.29032.2 | 1643 |
| Nextflow | W2605897695 | Di Tommaso et al., Nature Biotechnology 2017, https://doi.org/10.1038/nbt.3820 | 3978 |
| targets | W3119281122 | Landau, JOSS 2021, https://doi.org/10.21105/joss.02959 | 238 |
| Reproducible computational research | W2036318837 | Sandve, Nekrutenko, Taylor, PLoS Comput Biol 2013, https://doi.org/10.1371/journal.pcbi.1003285 | 873 |
| Practices | W2963508088 | Wilson, Bryan, Cranston et al., "Good enough practices in scientific computing", PLoS Comput Biol 2017, https://doi.org/10.1371/journal.pcbi.1005510 | 451 |
| Pipelines in field of the user | W3206946405 | Gupte, Beardsworth, Spiegel et al., "A guide to pre-processing high-throughput animal tracking data", J Anim Ecol 2021, https://doi.org/10.1111/1365-2656.13610 | 128 |
| WMS best practices | W2885035632 | Kanterakis, Potamias, Swertz et al., "Creating Transparent and Reproducible Pipelines: Best Practices for Tools, Data, and Workflow Management Systems" (Elsevier book chapter, 2018) | 3 |

Other hits (not assessed): W4401107409 (Rashid et al., Bioinformatics 2024, AssemblyQC), W4396768926 and W4408462184 (workflow management systems and FAIR, 2024 and 2025), W4399266906 (reproducibility challenges of external computational experiments in scientific WMS, 2024), W7208821989 (Plasmodium surveillance workflows, 2026).

Query notes (add to the OpenAlex lessons): `title_and_abstract.search.exact` with unquoted `AND`/`OR` and wildcards returned HTTP 400; the non-exact `title_and_abstract.search:(a OR b) AND (c OR d)` worked, as did `title.search:` with plain words (a `*` wildcard in `title.search` was the other 400 trigger, not confirmed in isolation). Generic reproducibility queries pull in many genomics pipelines, so ecology-specific sources (e.g. W3206946405) are best found by field terms. No papers comparing Snakemake with targets were found in these searches.

### 8.5 Still open after round 2

- Prefect, Dagster: HPC integration pages (task runners, Dask/Ray, Slurm), local-run requirements.
- Nextflow: install requirements, Windows/WSL, resume cache, conda.
- `crew_controller_slurm` help page; `targets` + `tar_quarto`; PPM snapshots for R date pinning.
- Snakemake: remaining rules-page text, `--report` test, Quarto as a step, WSL/Linux run, running `uv run snakemake` inside a Slurm job on the cluster (user must run; assistant works locally only).
- Social search for practitioner pain points; Quarto Python page.
- Reading abstracts of the OpenAlex hits before citing them in a skill.

## 9. Round 3 (2026-10-23): gaps closed from section 8.5

### 9.1 crew.cluster Slurm (reference pages `crew_controller_slurm`, `crew_options_slurm`, v0.4.0.9001; read)

- Recommended pattern: `crew_controller_slurm(workers=, seconds_idle=, tasks_max=, options_cluster = crew_options_slurm(...))`. The old per-argument form (`slurm_partition`, `slurm_memory_gigabytes_required`, `slurm_cpus_per_task`, `slurm_time_minutes`, `slurm_log_output`, `script_lines`, ...) is deprecated.
- `crew_options_slurm()` fields: `verbose`, `command_submit` (default `Sys.which("sbatch")`), `script_directory` (default `tempdir()`; the page says this may not work on some systems and suggests `tools::R_user_dir("crew.cluster", "cache")`), `script_lines` (e.g. `"module load R"`), `log_output`/`log_error` (default `/dev/null`, i.e. **no worker logs unless set**; `%A` = job ID), `memory_gigabytes_required` (`--mem`), `memory_gigabytes_per_cpu` (`--mem-per-cpu`), `cpus_per_task`, `time_minutes` (`--time`), `partition` (comma list allowed), `n_tasks` (`--ntasks`, 0 omits).
- `seconds_wall` is a soft wall time passed to mirai, **not** the Slurm limit; set `time_minutes` for that. Crashed workers are not retried automatically, but targets retries them (`crashes_max` default 5).
- Lifecycle: controller "maturing", options "experimental". Implication for the R skill: pin crew.cluster, set `log_output`, and tell the user the submit command and options must come from their cluster docs (assistant runs locally only).

### 9.2 Prefect (task-runner and prefect-dask pages; read)

- Built-in runners: `ThreadPoolTaskRunner` (default) and `ProcessPoolTaskRunner`. Dask and Ray are extras (`prefect[dask]`, `prefect[ray]`); calling a task directly runs it in the main thread.
- `DaskTaskRunner` accepts `cluster_class` (import path, class or factory) plus `cluster_kwargs`, or `address=` for an existing cluster. The page's example is a cloud cluster; **Slurm and dask-jobqueue are not mentioned**. A `dask_jobqueue.SLURMCluster` as `cluster_class` is plausible by analogy but unconfirmed by Prefect's docs; dask-jobqueue's last release is 2024-08 (section 2).
- Pages did not say whether a Prefect server is needed for local runs. Verdict stays: not recommended for this skill; mention as an option with unverified HPC route.

### 9.3 Dagster (installation and run-executors pages; read)

- Python >= 3.10 (3.13 recommended); install with `uv add dagster dagster-webserver dagster-dg-cli`, or `uvx create-dagster@latest project NAME`. Pages do not say whether webserver or daemon is required to run assets locally.
- Executors: in-process, multiprocess (default is multi-or-in-process), Dask, Celery, Docker, Kubernetes, ECS, Celery variants. **No Slurm or HPC executor; pipes and subprocess launching not on that page.** Executor system is "pluggable" but custom executors are poorly documented.
- Verdict: not a fit for Slurm-based analysis without custom work.

### 9.4 Nextflow (install and cache-and-resume pages; read)

- Platforms: POSIX systems, Windows only through WSL. Requires Bash 3.2+ and Java 17 up to 26 (Java below 17 dropped in 25.04). Install: self-installing launcher (`curl -s https://get.nextflow.io | bash`), Conda (`bioconda::nextflow`, the docs warn of outdated versions and Java conflicts), or a standalone offline distribution. Note: this machine has JDK 26 and 27 on PATH; 27 is beyond the documented range.
- Resume: task cache in `.nextflow/cache` (LevelDB) plus per-task directories under `work/`; both must be kept. The task hash covers session ID, task name, container, modules/Conda/Spack environment, CPU architecture, inputs, script, referenced globals. Default file hashing uses path, mtime and size; `'lenient'` ignores mtime and is the documented fix for **NFS timestamp problems** (relevant on shared HPC filesystems). Typical invalidators: renamed process, changed environment or script, non-deterministic channel merges, processes that modify their own inputs.
- Compare Snakemake: file existence and mtime-based (reruns triggered by mtime, code and params with `--rerun-triggers`; not verified from the docs in this round).

### 9.5 Still open

- Prefect: whether a server is required locally; `prefect-dask` reference; dask-jobqueue SLURMCluster in practice.
- Dagster: webserver/daemon requirement, pipes.
- Snakemake `--rerun-triggers` and mtime behaviour on NFS (the Nextflow NFS caveat has a Snakemake analogue to check).
- Not yet done from section 8.5: `targets` + `tar_quarto`, PPM snapshots, Snakemake `--report`/Quarto step/WSL tests, social search, Quarto Python page, reading abstracts of the OpenAlex hits.

## 10. Round 4 (2026-10-23): rerun triggers, tar_quarto, PPM snapshots, `--report`

### 10.1 Snakemake rerun triggers and shared filesystems

Docs (CLI page, read): `--rerun-triggers` accepts `code`, `input`, `mtime`, `params`, `software-env`; all five are the default ("guarantees results consistent with workflow code and configuration"). `--rerun-incomplete`, `--touch` (marks outputs up to date, loses provenance, last resort), `--latency-wait` (default 5 s), `--consider-ancient`, `--trust-io-cache`, `--max-inventory-time` (inventory "can be slow on network file systems"), `--wait-for-files`, `--shared-fs-usage` (e.g. `persistence software-deployment sources source-cache` with a cluster executor and `--default-storage-provider fs`), `--cache` (central output cache keyed by steps, parameters, software). The page has no NFS section as such.

Local tests (Snakemake 9.27.1, Windows, dry runs with `-n`, scratch project):

| Change | Result |
|---|---|
| `touch` an intermediate or external input (content unchanged, mtime newer than output), default triggers and `--rerun-triggers mtime` | **Nothing to be done** |
| Change the input content (mtime and content) | Rerun, reason "Updated input files" (also with `--rerun-triggers mtime`) |
| Edit an R script (comment only) | Rerun of that rule, reason "Code has changed since last execution" (any code change, even a comment) |
| Change a config value read inside the script via `snakemake.config` | **No rerun**: config values are not tracked unless the rule lists them in `params:` |
| Same value passed via `params: n=config["n"]` | Rerun, reason "Params have changed since last execution" |
| `--list-input-changes` | Listed files whose inputs changed (output format: file names only) |

Interpretation (partly hypothesis): in 9.x a pure mtime change appears to be ignored when the input content is unchanged. `--max-checksum-file-size` (default 1 MB, "compute the checksum during DAG computation and job postprocessing only for files smaller than the threshold") exists and fits this, but I did not test it directly or find the docs sentence that states the mechanism. Implication for NFS: Nextflow documents mtime problems and a `lenient` fix, but Snakemake's behaviour on a real NFS with skewed timestamps is **untested here**; the checksum route may protect small files only (files above the threshold are not checksummed). Needs a Linux/NFS test or a user-run check on the cluster.

Practical rules to carry into the skill: put every config value a script depends on into `params:` (or pass the config file as an `input:`); expect any code edit, including comments, to rerun; use `--touch` only deliberately.

### 10.2 `tar_quarto()` (tarchetypes reference page; read)

Signature (first args): `tar_quarto(name, path = ".", output_file = NULL, working_directory = NULL, extra_files = character(0), execute = TRUE, execute_params = list(), cache = NULL, cache_refresh = FALSE, debug = FALSE, quiet = TRUE, quarto_args = NULL, pandoc_args = NULL, profile = NULL, ...)`; `tar_quarto_raw()` for programmatic names. Dependencies are found from `tar_load()`/`tar_read()` calls in active R chunks (not the `_raw` forms; not hidden inside user functions or `contains(...)` selectors). The target is `format = "file"` and returns rendered documents plus sources, from YAML front matter or `_quarto.yml`; `tar_quarto_files()` lists them; `extra_files` tracks more. `path` can be a single file or a project; non-default `working_directory` requires setting `store` in `tar_read()`. `cache` uses knitr cache or jupyter-cache. The page says nothing about Python chunks and `tar_read()`; **dependency detection is R-only**, so a Python chunk that reads a file produced by a target must be declared via `extra_files` or an R-side `tar_read()` (design note, untested).

### 10.3 Posit Package Manager snapshots for R "as of" pinning (search results from docs.posit.co, pak and pkgcache; not fetched in full, the `docs.posit.co/rspm/user/get-started/` URL gave 404)

- Public Package Manager (P3M) mirrors CRAN, Bioconductor and PyPI with date snapshots on every business day; CRAN snapshots start 2017-10-10. A date URL without a snapshot is served from the nearest older snapshot (never older than the oldest or newer than the newest).
- R: `options(repos = c(CRAN = "https://packagemanager.posit.co/cran/2026-01-15"))`; Windows gets binaries via the same URL; Linux binaries use `.../cran/__linux__/<distro>/<date>` (and a `bin/linux/<distro>-<arch>/<r-version>` form on newer servers). Frozen URLs can be made immutable ("Lock Package Data", extra suffix in the URL). `pak::ppm_snapshots()` lists snapshots; `pak` and `pkgcache` use `PKGCACHE_PPM_URL`/`PKGCACHE_PPM_REPO`. Bioconductor: set `BioC_mirror` to the P3M bioconductor URL.
- Posit's own migration post recommends renv for new reproducible work; snapshots are the lightweight alternative or a complement (renv can restore from a snapshot URL).
- Python side: P3M also serves PyPI date snapshots (release notes mention date aliases for PyPI); the exact uv/pip index URL form was **not confirmed**. uv's own `exclude-newer` (section 2) and `reticulate::py_require(exclude_newer=)` are the verified date-pin routes.
- Not verified: current URL format of the PyPI snapshot repository, interaction of snapshot URLs with `renv.lock` `Repositories`.

### 10.4 Snakemake `--report` (local test)

- First attempt failed: "Python package pygments must be installed to create reports" (the `uv add snakemake` environment lacks it); after `uv add pygments`, `snakemake --report report.html` produced a ~3 MB self-contained HTML containing the caption text from `report(..., caption=..., category=...)`. Rules that run `script:` get their code embedded ("Loading script code for rule ..."). Implication: list `pygments` as an explicit dependency (and check for other report extras) in any skill recipe.
- Not tested: opening the HTML in a browser, `.zip` reports for large outputs, Quarto or notebook outputs inside reports.

### 10.5 Still open

- NFS or skewed-mtime behaviour of Snakemake on Linux (user-run test); direct test of `--max-checksum-file-size`.
- P3M PyPI snapshot URL for uv/pip; renv with a snapshot repository.
- Prefect: local server requirement; Dagster: webserver/daemon requirement; `prefect-dask` reference.
- Social search, Quarto Python page, abstracts of the OpenAlex hits, WSL run of the Snakemake test.

## 11. Round 5 (2026-10-23): R-specific research for `r-reproducible-pipeline`

Focus: targets, tarchetypes, crew, renv, Quarto. Installed from CRAN this round (allowed): targets 1.12.0, tarchetypes 0.14.1, crew 1.3.3, crew.cluster 0.4.0, qs2 0.3.1, gittargets 0.0.7, quarto (R pkg) 1.5.1. Already present: renv 1.3.1, pak, visNetwork. Quarto CLI is the RStudio-bundled one.

### 11.1 Docs read (targets manual, https://books.ropensci.org/targets/)

| Page | Facts for the skill |
|---|---|
| walkthrough.html | `_targets.R` (loads packages, `tar_option_set()`, `tar_source()`, returns a list of `tar_target()`), `R/functions.R`, `_targets/` store (objects in `_targets/objects/`; path configurable via `_targets.yaml`). Functions: `use_targets()` (>= 0.12.0), `tar_manifest()`, `tar_visnetwork()`, `tar_make()` (runs in a new external R process, only outdated targets), `tar_read()`/`tar_load()`, `tar_outdated()`, `tar_cue()`, `tar_config_set()`. Page does not say what to commit and does not describe hashing |
| projects.html | One folder = one pipeline + one renv library + one Git repo; layout `.Rprofile`, `renv/`, `_targets.R`, `_targets.yaml`, `R/`, `data/`. Functions in `R/`, loaded with `tar_source()`. Multiple pipelines only if they share goals (`tar_config_set(script=, store=, project=)`, `TAR_PROJECT`). **Commit code, renv setup and config; do not commit the whole `_targets/` store; optionally commit `_targets/meta/meta`** (needed to check status and read targets). Page does not mention `here` or working-directory rules |
| random.html | `tar_option_set(seed = n)`; each target gets its own deterministic seed from its **name** and the global seed (readable in `tar_meta()`); `seed = NA` disables seeding and makes targets always outdated unless `cue = tar_cue(seed = FALSE)`; `tarchetypes::tar_rep()` gives replicate seeds in a `tar_seed` column. Page does not cover parallel pitfalls or `set.seed()` inside functions |
| literate-programming.html | Reports are targets that mostly display upstream results; `tar_quarto()` (tarchetypes >= 0.6.0.9000) handles single documents and whole Quarto projects, finds dependencies by static analysis of literal `tar_read()`/`tar_load()` calls; `execute_params` for one parameter set, `tar_quarto_rep()` for many. Keep computation out of the report |
| performance.html | Default format RDS; `qs` for any data; `feather` needs arrow; **parquet not mentioned on this page**; `format = "file"` for data too large for memory; `memory = "transient"` plus `garbage_collection`; avoid millions of tiny targets (batch with `tar_rep()`); monitoring `tar_poll()`, `tar_progress()`, `tar_watch()`; crew for distributed work, `storage`/`retrieval = "worker"` need workers that can read the store, `deployment = "main"` for cheap targets |
| debugging.html | `tar_option_set(error = "null")`; `tar_meta(fields = error/warnings, complete_only = TRUE)`; `tar_load_globals()` then `tar_load()` to reproduce; `tar_make(callr_function = NULL, use_crew = FALSE, as_job = FALSE)` plus `browser()`/`debug` option (restart R afterwards, can corrupt results); workspaces saved on error (`tar_workspaces()`, `tar_workspace()`, `workspace_on_error`); `tar_traceback()` |
| hpc.html ("old way") | `tar_make_clustermq()` and `tar_make_future()` still documented; footnote warns against several concurrent `tar_make()` calls on one store (probably breaks it). The page does **not** say where the main process should run or how `tar_make()` runs inside a Slurm job (open: ask the user how their site wants it; the usual pattern is main process in a batch job or on a login node, workers via crew.cluster; not verified from docs) |
| files.html | HTTP 404 (URL guessed); file tracking is covered on projects/walkthrough pages only |

Renv (https://rstudio.github.io/renv/articles/renv.html, reference/lockfiles.html): `init()`, `snapshot()`, `restore()`, `install()`, `update()`, `history()`/`revert()`. Commit `renv.lock`, `.Rprofile`, `renv/settings.json`, `renv/activate.R` (renv writes a `.gitignore` for the library). Lockfile: `R` (Version, Repositories), `Packages` (Version, Source, Repository, Hash, Remote* fields), optional `Python` block (Version, Type, Name); JSON, hand-editable; `lockfile_modify(repos=, remotes=)` exists. Snapshot types: implicit (default; packages found by `dependencies()`), explicit (DESCRIPTION), all, custom. renv does **not** manage the R version (suggests `rig`), pandoc, system libraries or compilers (suggests Docker), and binaries that vanish fall back to source builds. Not covered on the read pages: `status()`, cache location, Bioconductor details. In implicit mode, packages used only inside `_targets.R` or `R/` are detected by static scanning of `library()`/`pkg::` calls; packages named only in `tar_option_set(packages = ...)` as strings may be missed (**hypothesis, untested**; check with `renv::dependencies()`).

Quarto `scripts.html` (read): `pre-render`/`post-render` project scripts may be any shell command (`make prepare` given as an example); run in the project directory; env vars `QUARTO_PROJECT_RENDER_ALL` etc. Possible hook to run `Rscript -e 'targets::tar_make()'` before rendering (design idea, untested). Pre-render scripts cannot change the project directory or type.

P3M docs: the `docs.posit.co/rspm/admin/...` URL returned only "Redirect" and the PyPI setup page is a JS app (no text). The PyPI snapshot URL form is therefore **still unconfirmed**. `pak::ppm_snapshots()` works (3-row head shown: 2017-10-10, 2017-10-11, 2017-10-12 ...); `pak::ppm_repo()` does not exist (not an export).

### 11.2 Local tests (Windows 11, R 4.6.0, targets 1.12.0, tarchetypes 0.14.1, crew 1.3.3, uv 0.12.5, Quarto from RStudio)

Scratch pipeline in the git-ignored `tmp-examples/tgt/` (deleted afterwards): config file, a Python script run through `system2("uv", c("run","--no-project","python", ...))`, `format = "file"` targets for config, Python script and CSV output, `lm`, a random target, and `tar_quarto()` with an R chunk calling `tar_read(fit)`. Eight targets.

| Test | Result |
|---|---|
| First run | 8 completed; Quarto report 6.8 s; the `uv run` Python step works under `tar_make()` (callr) |
| Rerun | 8 skipped |
| `touch` config file (content unchanged) | Nothing outdated (targets uses content hash for file targets) |
| Comment-only change in `R/functions.R` | Nothing outdated (comments ignored) |
| Add an unused function to `R/functions.R` | Nothing outdated (only used functions count) |
| Comment appended to the Python script (declared as a file target) | `py_script` and its dependant `sim_csv` re-ran, but **`dat`, `fit`, `report` skipped** because the output CSV hash was unchanged |
| Change `n_obs` 20 to 30 in config | Outdated: `cfg_file`, `cfg`, `sim_csv`, `dat`, `fit`, `report` (`noise` and `py_script` not) |
| Change the body of the used function `fit_model` | Outdated: `fit` and `report` only |
| Delete `_targets/`, rebuild only `noise` | Identical random numbers (seed from target name and global seed) |
| `crew::crew_controller_local(workers = 2)` set in `tar_option_set(controller=)` | Pipeline ran to completion (7 completed, 1 skipped) |
| `crew.cluster::crew_controller_slurm(...)` with `crew_options_slurm(partition, cpus_per_task, memory_gigabytes_required, time_minutes, log_output, script_lines, script_directory)` | **Constructed without error** (no `sbatch` here, `Sys.which("sbatch")` empty), class `crew_class_controller`; no job submitted. `crew_options_slurm()` formals: `verbose, command_submit, command_terminate, script_directory, script_lines, log_output, log_error, memory_gigabytes_required, memory_gigabytes_per_cpu, cpus_per_task, time_minutes, partition, n_tasks` |
| Warnings seen | "package built under R version 4.6.1" only (harmless here, but `tar_meta(fields = warnings)` shows them on the report target) |

Findings and gotchas:

1. **YAML 1.1 trap:** R `yaml::read_yaml()` read the key `n: 20` as `FALSE: 20` (the key `n` means "no"). Python run then failed with a confusing argument error. Use descriptive keys (`n_obs`), or quote keys; applies to any config shared between R and Python (`y`, `n`, `yes`, `no`, `on`, `off`, `NO` for Norway codes). Also check with `str(cfg)`.
2. `tar_make(reporter = "summary")` is deprecated since targets 1.10.1.9010; use `"balanced"`, `"verbose"` or `"timestamp"`.
3. `tar_quarto()` needs the CRAN package `quarto` (error "The package "quarto" is required" otherwise).
4. The Python script is only tracked if it is declared as a `format = "file"` target **and** passed to the function that calls it (the target `py_script` above). This was the design; the negative case (script not declared, edit not detected) is expected from the model but was **not tested**.
5. Hash-based file tracking means: no spurious reruns from mtime changes, unlike Snakemake's mtime-sensitive default (compare section 10.1); useful to explain when users choose between the tools. NFS behaviour of targets was not tested.
6. R's session guard blocks `dir.create()` into the assistant scratch directory (`%TEMP%/p-cmmwB5/...`); use the git-ignored `tmp-examples/` in the project for R-driven tests.
7. `dir.create()` is not vectorised (an error "invalid 'path' argument" when given several paths); trivial but it cost one run.

### 11.3 OpenAlex (R/httr2, authors checked from the returned fields, abstracts not read)

Free-text `search=` queries for R pipelines returned unrelated highly cited papers (NumPy, phyloseq, SciPy); filter-based queries returned almost nothing. Usable finds: renv software record W4399636582 (Ushey, "renv: Project Environments", 2019, 69 citations, venue empty, so it is a software citation); W4409740950 (Hillemann et al. 2025, "Code review in practice: A checklist for computational reproducibility and collaborative research", 1 citation, not assessed). Already in section 8.4 and reusable for the R skill: targets JOSS paper W3119281122, Sandve et al. W2036318837, Wilson et al. W2963508088, Gupte et al. W3206946405. No peer-reviewed comparison of targets with Snakemake or Nextflow found. Retrieval note: `title.search:` with several words works; `title_and_abstract.search.exact` with `OR` of two quoted phrases matched "renv" as a substring of unrelated words (virology hits); do not use it for short tokens.

### 11.4 Design observations for `r-reproducible-pipeline` (not decisions)

1. Default stack: **renv + targets + tarchetypes (`tar_quarto`) + Quarto**, config in YAML read by one `config` target, seed in `tar_option_set(seed=)`. Python steps as file targets that call `uv run` (tested pattern above); mixed projects point to `python-reproducible-pipeline` (Snakemake) or to the planned `python-r-interop`.
2. When to prefer Snakemake over targets: Python-centric or many non-R tools, or the user already works with it; when targets: mostly R, functions as units, per-target hashing, `tar_quarto`. Tell the user the rerun semantics differ (hash vs mtime plus code/params triggers).
3. HPC: crew.cluster Slurm controller plus `tar_make()` in one batch job (or on a login node if the site allows) is the likely route; **how the main process is started is not documented in the pages read** (ask the user to check their site docs and to run test commands; the assistant stays local). Always set `log_output`, `time_minutes`, `script_directory`; `seconds_wall` is not the Slurm limit (section 9.1).
4. Provide a starter template (`assets/project-template/`) analogous to the Python skill's, plus a static checker (e.g. `scripts/check_targets_project.R`) for: missing renv.lock, `_targets/` committed, no seed, unquoted/ambiguous YAML keys, non-file targets reading files, `reporter = "summary"`, `setwd()` in functions. Checks must be tested on a seeded-defect copy before claiming them.
5. Version claims to re-check before writing: targets 1.12.0, tarchetypes 0.14.1, crew 1.3.3, crew.cluster 0.4.0 (CRAN, 2026-10-23), renv 1.3.1.

### 11.5 Still open after round 5

- `renv::init()`/`snapshot()` on a targets project (does implicit snapshot find packages used in `_targets.R`, including `tar_option_set(packages=)`?), renv + Quarto chunks, `renv` + uv `.venv` with `RETICULATE_PYTHON`. Not run because `init()` restarts the user's session; needs a separate Rscript process or user consent.
- A `tar_quarto()` report with a Python chunk (knitr + reticulate picking the right Python); the Quarto Python page is still unread.
- Undeclared-script negative test; `tar_make()` inside a real Slurm job; crew.cluster job submission; NFS behaviour; Linux/macOS.
- `tarchetypes` factories (`tar_map`, `tar_rep`, `tar_files`), `tar_resources_*`, dynamic branching: only read via the performance and literate-programming pages; not tested.
- targets data-store formats on this machine: `qs2`, arrow/parquet (arrow not installed; installing from CRAN is allowed).
- P3M PyPI snapshot URL; renv `Repositories` with a snapshot URL (restore behaviour).
- Prefect, Dagster, social search, remaining Snakemake items (see 10.5).

## 12. Skill build (2026-10-23): `r-reproducible-pipeline`

Closes part of 11.5: `renv::init()` on a targets project ran in a `callr` subprocess; implicit snapshot recorded 64 packages but missed `quarto`
(fixed by a never-run `_dependencies.R` with `library(quarto)`); the pipeline then ran inside the renv project library with `renv::status()$synchronized`
TRUE. The lockfile recorded the user's configured repository (`packagemanager.posit.co/cran/latest`), so a dated URL must be set before `init()` to be recorded.
Template findings: depending on the whole `config` list invalidated every dynamic branch when a sample was added (use one small target per setting; then only new
branches ran); `tar_seed()` is deprecated (use `tar_seed_get()`); CRLF vs LF rewrite of a file target reruns dependants. Hazard: copying an renv project onto itself
truncated shared-cache entries (63 repaired from the installed library, verified with `diff -r`). Still open: items in 11.5 that concern real Slurm, NFS, Python chunks in
reports, `tar_map`/`tar_rep`, and P3M snapshot restore. The skill's sources are in `r-reproducible-pipeline/references/sources.md`.
