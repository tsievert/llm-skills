# Analysis pipeline

Snakemake workflow managed with uv. Everything under `results/` is regenerated from code, `config/` and raw data.

## Run locally

```bash
uv sync --locked                 # create .venv from uv.lock (first time: `uv lock`, then commit uv.lock)
uv run --locked snakemake --cores 2
uv run --locked snakemake --report report.html
```

`workflow/Snakefile` is found automatically when you run from this directory.

## Run on a Slurm cluster

Fill in `workflow/profiles/slurm/profile.yaml` from the site's documentation, then from a login node
(check the site's policy on running the Snakemake controller there):

```bash
uv sync --locked
uv run --locked snakemake --workflow-profile slurm
```

## Layout

| Path | Content |
|---|---|
| `workflow/Snakefile`, `workflow/scripts/` | rules and the scripts they run |
| `config/config.yaml` | parameters; values a script uses are passed through `params:` |
| `workflow/profiles/` | execution profiles (Slurm) |
| `results/`, `logs/`, `benchmarks/` | generated; not committed |

## Reproduce

Commit `pyproject.toml`, `uv.lock`, `.python-version`, `config/` and `workflow/`. Record the data source and version here.
