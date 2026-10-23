# Environments and pinning

- [uv commands](#uv-commands) | [What to commit](#what-to-commit) | [Date pinning](#date-pinning) | [Single scripts](#single-scripts) | [Alternatives](#alternatives) | [Windows notes](#windows-notes) | [Not verified](#not-verified)

Read from the uv documentation (project layout, locking and syncing, scripts pages) on
2026-10-23; the lock behaviour was also tested locally with uv 0.12.5.

## uv commands

| Command | Use |
|---|---|
| `uv init --python 3.12` / `uv add pkg` | create the project, add a direct dependency (updates `pyproject.toml` and `uv.lock`) |
| `uv lock` | resolve and write `uv.lock` |
| `uv lock --check` | fail if `uv.lock` is out of date (same as `--locked`) |
| `uv sync --locked` | install exactly the lock; error if the lock is stale; exact by default (removes extras) |
| `uv run --locked cmd` | run in the project environment with the same stale-lock check; `uv run` alone syncs inexactly and may rewrite the lock |
| `uv run --frozen cmd` | use the lock without checking it is current (skips the safety check) |
| `uv lock --upgrade-package pkg` | deliberate upgrade; new releases never change the lock by themselves |
| `uv sync --no-dev`, `--group NAME`, `--only-group NAME` | dependency groups |
| `uv export -o pylock.toml` | export the PEP 751 format for other tools |

Tested: after editing `pyproject.toml`, both `uv run --locked` and `uv lock --check`
failed with "lockfile needs to be updated"; `uv lock` fixed it.

## What to commit

Commit `pyproject.toml`, `uv.lock` and `.python-version` (the layout page covers the first
two; `.python-version` is recommended in third-party summaries and is what the checker
asks for). Do not commit `.venv/`. The lock is universal (one file for all platforms).
This repo's own `.gitignore` ignores `*.lock`; a project repository must not.

## Date pinning

`exclude-newer` limits resolution to releases before a timestamp. Put it in
`[tool.uv]` of `pyproject.toml` (project) or the script metadata block (single script). It
complements the lock: the lock records what was resolved, the date records the intent and
lets a fresh `uv lock` give a similar environment later. For R, `reticulate::py_require()` has an
`exclude_newer` argument with the same idea.

## Single scripts

PEP 723 inline metadata: `uv init --script x.py --python 3.12`, `uv add --script x.py pkg`,
`uv lock --script x.py` (writes `x.py.lock`), `uv run x.py`. The `dependencies` field must
be present even if empty. Good for one-off helpers, not for the whole pipeline.

## Alternatives

- **conda / mamba / pixi**: needed when non-Python binaries must be pinned (compilers,
  GDAL, R). pixi has a lock file, can combine conda and PyPI packages, and has a task
  runner; the pixi page read says nothing about HPC. A Snakemake pixi plugin exists
  (community, requires Snakemake 10 or later, so not usable with 9.27.1).
- **Per-rule `conda:` environments and containers** in Snakemake (`--sdm conda`,
  `--sdm apptainer`, `--containerize`): the documented route for per-rule software;
  not tested here. There is no documented uv deployment method in Snakemake; use one uv
  project environment for the controller and the steps unless steps need conflicting
  dependencies.
- **Docker/Apptainer image from the lock** (`uv sync --locked` inside the image) for
  archiving; not tested.

## Windows notes

- Native Windows works for the template. The Store `python` stub is not a real Python;
  use uv-managed interpreters (`uv python install 3.12`).
- Run commands through `uv run` so the right interpreter is used.
- Compute nodes are Linux: do not copy a Windows `.venv`; recreate it there from the lock.

## Not verified

Posit Public Package Manager exposes PyPI snapshots too, but the exact index URL form for
uv or pip was not confirmed. `uv` on a cluster (installation location, offline nodes,
cache on shared filesystems) needs the user's cluster facts.
