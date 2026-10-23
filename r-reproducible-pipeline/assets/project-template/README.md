# Analysis pipeline (targets + renv + Quarto)

Everything under `_targets/`, `data/` and `report.html` is regenerated from code, `config/` and raw data.

## First time

```r
renv::init()          # creates renv.lock, .Rprofile, renv/ (commit these, not renv/library)
```

```bash
uv lock --project py  # creates py/uv.lock for the Python steps (commit it)
```

## Run locally

```r
targets::tar_make()        # runs only outdated targets
targets::tar_outdated()    # what would run, and why: tar_visnetwork()
targets::tar_read(coef_table)
```

`PIPELINE_EXECUTOR=local` runs two local workers; unset runs targets one after another.

## Run on a Slurm cluster

Fill the placeholders in `R/controllers.R` and `slurm/run_targets.sbatch` from the site documentation, then:

```bash
mkdir -p logs && sbatch slurm/run_targets.sbatch
```

## Layout

| Path | Content |
|---|---|
| `_targets.R` | the pipeline: a list of targets |
| `R/` | functions (`functions.R`) and the executor choice (`controllers.R`) |
| `py/` | Python step, with its own locked environment (`pyproject.toml`, `uv.lock`) |
| `config/config.yml` | parameters (use descriptive keys; see the file header) |
| `report.qmd` | Quarto report rendered by `tar_quarto()` |

## Reproduce

Commit `_targets.R`, `R/`, `py/` (with `uv.lock`), `config/`, `report.qmd`, `renv.lock`, `.Rprofile`, `renv/activate.R`
and `renv/settings.json`. The `_targets/` store is ignored; to share finished results, commit `_targets/meta/meta` or
deposit the outputs. Record the data source and version here.
