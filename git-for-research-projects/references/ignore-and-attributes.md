# .gitignore, .gitattributes and what to commit

Contents: what to commit; pattern traps (all tested); using the starter files; untracking; third-party templates; line endings and `.gitattributes`; archives.

## What to commit and what not

| Commit | Do not commit | Why |
|---|---|---|
| Code, Quarto sources, config, small text data (CSV) | Raw or large data | Raw data are read-only and live on the server; GitHub warns at 50 MiB and blocks at 100 MiB (`data-and-large-files.md`) |
| `renv.lock`, `uv.lock`, `pyproject.toml`, `_targets.R`, `Snakefile` | `.venv/`, `renv/library/`, `_targets/`, `.snakemake/` | The lockfile and the pipeline definition rebuild the rest |
| `README.md`, `LICENSE`, `CITATION.cff`, `data/README.md`, `data/manifest.tsv` | `.RData`, `.Rhistory`, `.Rproj.user/` | Session state is personal and may contain data or tokens |
| `.gitignore`, `.gitattributes` | `.env`, `.Renviron`, `*.pem`, `*.key` | Credentials never belong in a repository |
| `_freeze/` when Quarto renders are expensive | Office files, binary data that change often, regenerable figures and intermediates | Unreadable diffs; they can be rebuilt (Wilson et al. 2017) |

Quarto's documentation says to check `_freeze` into version control so that others can render without recreating the computing environment (read 2026-10-23). The starter file therefore does not ignore it.

## Pattern traps (tested with Git 2.55.0 on 2026-10-23)

| Trap | What happens | Fix |
|---|---|---|
| `*.lock` | Also ignores `renv.lock` and `uv.lock` (and any `a.lock`). This hid a template lockfile in this repository | Add `!renv.lock` and `!uv.lock` after it, or ignore specific lock names |
| `data/` then `!data/keep.csv` | The negation does nothing: a file cannot be re-included if a parent directory is excluded (Git docs) | Write `data/*` then `!data/keep.csv` |
| `git check-ignore -v path` exits 0 | Also for a path matched by a *negation* (the output line starts with `!`) | Use `-q` for "is ignored", or read the printed rule |
| New ignore rule for a tracked file | Nothing: tracked files are never ignored, and `check-ignore` stays silent unless `--no-index` is given | `git rm --cached <file>` (keeps the working copy; old content stays in history) |
| `/*_files/` vs `*_files/` | A leading slash anchors to the `.gitignore` directory | Use the unanchored form for render output in subfolders |
| Trailing `/` | Matches directories only | Intended for directories; omit it to match files too |

`audit_repo()` reports the first three automatically (required-file-ignored, negation-under-excluded-parent, lock-rule). It uses static rules for the negation check, so a pattern with wildcards in the parent (`da*/`) is not caught.

## Using the starter files

- [../assets/gitignore-research](../assets/gitignore-research): R, Python, Quarto, pipeline output, secrets, OS files, and the data pattern (`data/*` plus `!data/README.md`, `!data/manifest.tsv`). Tested in a scratch repository: lockfiles, `data/README.md`, `data/manifest.tsv`, `_freeze/` and `run.sh` were tracked; `.env`, `.Renviron`, `*.pem`, `data/a.csv`, `_targets/` and `.quarto/` were ignored.
- [../assets/gitattributes-research](../assets/gitattributes-research): see below.
- Copy, do not symlink; adapt per project, then run `audit_repo()`.
- `renv::init()` writes `renv/.gitignore` itself; do not duplicate its rules.
- targets creates `_targets/.gitignore` for the `objects/` folder, so one can track `_targets/meta` deliberately; the starter ignores all of `_targets/` as the simpler default (the user may choose otherwise).

## Third-party ignore templates

- CRAN `gitignore` 0.1.8 fetches templates from gitignore.io (toptal): `gitignore::gi_fetch_templates("R")` works (tested, needs internet). The "R" template ignores `.Renviron`, `.Rhistory`, `.RData`, `.Rproj.user/` but also `docs/`, `/cache/` and `rsconnect/`, which may be wanted in a project (a `docs/` folder for GitHub Pages, for example). It has no data rules. Treat it as a starting block, not a policy.
- `usethis::git_vaccinate()` edits the **global** ignore file of the user (`~/.config/git/ignore`). It was not run. Ask first.

## Line endings and `.gitattributes`

- Git for Windows sets `core.autocrlf=true` in the **system** config, not in the user's, so the "LF will be replaced by CRLF" warnings are expected and normally harmless for the index.
- Attributes beat `core.autocrlf` (tested): with `* text=auto` and `*.sh text eol=lf`, a CRLF CSV was normalised to LF in the index and `lf.sh` was checked out with LF.
- Migrating an existing project: add the file, then `git add --renormalize .` and commit once, separately from other changes, so the diff of the line-ending change is isolated.
- Inspect with `git ls-files --eol`: `i/` is the index, `w/` the working tree, `attr/` the rule in force.
- Why it matters here: a shell or sbatch script with CRLF fails on Linux ("bad interpreter"). The `hpc-job-scripts` linter checks scripts for that; `.gitattributes` prevents it at the source.
- `audit_repo()` flags CRLF committed to the index (`eol-index`) and, as info, CRLF only in the working tree.

## Archives

`export-ignore` in `.gitattributes` leaves paths out of `git archive` (tested for a directory and for `.gitattributes` itself). Use it to trim a code deposit. See `releases-and-citation.md` for building the archive.
