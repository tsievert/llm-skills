# renv and "as of" pinning

Contents: workflow; what to commit; what renv does not cover; implicit snapshot gaps (tested);
the shared cache hazard; date pinning with Posit Package Manager; Python alongside renv.

## Workflow

```r
renv::init()       # project library, renv.lock, .Rprofile that activates it at each R start
renv::snapshot()   # record the library in renv.lock after adding or updating packages
renv::restore()    # install exactly what the lockfile records (new machine, new clone)
renv::status()     # is the library consistent with the lockfile and the project code?
```

Run `init()` and test runs in a subprocess when automating (`callr::r(function(p) renv::init(project = p, restart = FALSE), args = list(path))`);
interactive `init()` restarts the session. Inside the project library a test run of the whole
template (`renv::load(".")` then `tar_make()`) worked, and `renv::status()$synchronized` was TRUE.

Commit `renv.lock`, `.Rprofile`, `renv/activate.R`, `renv/settings.json`; not `renv/library`.
The lockfile is JSON: R version, `Repositories`, one record per package (version, source,
hash, remote fields), optional `Python` block. `renv::lockfile_modify(repos = )` edits it.

## What renv does not cover

The R version itself (use rig or a container), pandoc and Quarto versions, system libraries
and compilers (Docker, Nix via `rix`), binaries that disappear (fall back to source builds).
Record R, Quarto and uv versions in the README.

## Implicit snapshot gaps (tested)

`renv::init()` uses the "implicit" snapshot: packages found by scanning code (`library()`,
`pkg::`). In the template this found `targets`, `tarchetypes`, `crew`, `crew.cluster`, `yaml`
and others, but **missed `quarto`**, which `tar_quarto()` needs at run time. Fix: a never-run
file `_dependencies.R` with `library(quarto)`. Then 64 packages were recorded. The checker
compares packages used in code and reports with `renv.lock` and warns on gaps; it cannot see
packages that only a dependency loads dynamically. After every dependency change run
`renv::status()`.

## The shared cache hazard

renv links project libraries to a global cache (default
`%LOCALAPPDATA%/R/cache/R/renv/cache` on Windows). **Writing through a project library writes
into the cache.** Copying a project onto itself with `file.copy(recursive = TRUE)` truncated 63
cached packages (including older ones used by other projects). Repair that worked: for each
damaged `pkg/version/hash`, copy the same version from the installed library back, then
`diff -r` both. Rule: never copy or move `renv/library`; copy source files and let `init()` or
`restore()` rebuild.

## Date pinning with Posit Package Manager (P3M)

`options(repos = c(CRAN = "https://packagemanager.posit.co/cran/2026-01-15"))` serves CRAN as of
that date (snapshots start 2017-10-10; Windows and Linux binaries through the same URL family,
Linux uses `.../cran/__linux__/<distro>/<date>`). `pak::ppm_snapshots()` lists snapshot dates
(tested: returns a table starting 2017-10-10). The lockfile written in the test recorded
`https://packagemanager.posit.co/cran/latest` because that was the user's configured
repository: a lockfile records whatever `getOption("repos")` was at snapshot time, so set the
dated URL before `renv::init()` if the date should be recorded. Not verified: restore behaviour
with a snapshot URL, and the P3M PyPI snapshot URL form (use uv's `exclude-newer` for Python).

## Python alongside renv

renv can record a `Python` block and `snapshot()` writes `requirements.txt` via `pip freeze`;
that is weaker than `uv.lock` (no hashes, no universal resolution). This skill keeps Python in
its own uv project (`py/`) and runs it through `uv run --locked`. For a single mixed Quarto
document that uses reticulate, set `RETICULATE_PYTHON` explicitly; not tested here.
