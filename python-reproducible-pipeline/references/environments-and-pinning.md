# Environments and pinning

- [uv commands](#uv-commands) | [What to commit](#what-to-commit) | [Date pinning](#date-pinning) | [Single scripts](#single-scripts) | [Alternatives](#alternatives) | [Windows notes](#windows-notes) | [uv/Python not found by the assistant's shell](#uvpython-not-found-by-the-assistants-shell) | [Not verified](#not-verified)

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

## Shared-cache hazard (uv)

With `--link-mode hardlink` (uv's default on Windows and Linux; macOS clones) a file in `.venv` and the copy in the uv cache are
the same file. Tested 2026-10-23 with uv 0.12.5 on Windows: truncating a venv file emptied the cache copy too (2 links, 34,703 bytes
to 0), which would damage every project that uses that package. Never copy over, truncate or overwrite `.venv`; delete and recreate
it from the lock (`uv sync --locked`). For tests that may write into environments, set `UV_CACHE_DIR` to a scratch folder or use
`--link-mode copy`. The same class of problem was seen with renv (see `r-reproducible-pipeline`).

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

## uv/Python not found by the assistant's shell

The assistant's `bash` tool is not the user's RStudio console: it has no R, no `reticulate`,
and no project environment of its own. It just inherits whatever PATH the child process gets
from its parent (RStudio, or whatever spawned the IDE). On Windows this causes one specific,
confusing failure: `uv`/`python` were installed (visible in a fresh terminal, `where uv` works
there) but the assistant's `bash` calls still report "command not found".

**Cause**: installing a program updates the user's or system's PATH environment variable
(registry on Windows), but a process that was already running — RStudio, and therefore every
`bash` child process it spawns — keeps the PATH snapshot it started with. It does not re-read
the registry. Opening a new standalone terminal picks up the change because that terminal is a
new process; RStudio does not, until RStudio itself is restarted.

**Diagnose** (ask the assistant to run this, or run it yourself in the same kind of shell):

```bash
which uv; which python   # or: where uv; where python
echo "$PATH" | tr ':' '\n' | grep -iE "python|\\.local|appdata"
```

If `uv`/`python` are missing from `bash` but a separate terminal window sees them, this is the
stale-PATH case, not a missing install. Fixes, in order of preference:

1. **Restart RStudio** (the simplest fix; the new process re-reads the environment).
2. If a restart isn't possible right now, call the tool by its full path as a workaround
   (e.g. `~/.local/bin/uv` on Windows after the official installer, or `python
   -m venv`/`py -3.12` for a Windows Python launcher) rather than assuming it is simply absent.
3. Do not try to "fix" this by writing to `~/.bashrc`/`~/.bash_profile`: Git Bash invoked
   non-interactively (as the `bash` tool does) does not source them, so edits there are silent
   until a shell that does source them is used — this looked plausible as a cause and was ruled
   out in testing (see below).

Tested 2026-10-24 (Windows 11, Git Bash via the `bash` tool): in a working session, `uv` and
`python` resolved via `/c/Users/<user>/.local/bin` and
`/c/Users/<user>/AppData/Local/Microsoft/WindowsApps`, both inherited from the Windows user
PATH; there was no `~/.bashrc`/`~/.bash_profile` at all, and the shell was confirmed
non-interactive, non-login (so profile-sourcing was not the mechanism here). The
restart-reinherits-PATH explanation is standard Windows process behaviour, not independently
reproduced against the specific failing project; treat it as the leading hypothesis and confirm
with the `which`/`where` check above before assuming a restart is needed.

## Not verified

Posit Public Package Manager exposes PyPI snapshots too, but the exact index URL form for
uv or pip was not confirmed. `uv` on a cluster (installation location, offline nodes,
cache on shared filesystems) needs the user's cluster facts.
