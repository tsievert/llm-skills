---
name: git-for-research-projects
description: 'Sets up and audits Git repositories for research analysis projects: .gitignore and .gitattributes starters for R, Python and Quarto, what to commit and what not (large data stay on the server; a tracked manifest with checksums records them), preventing and cleaning up committed secrets with git filter-repo, Windows line endings, repositories inside Syncthing, OneDrive or Dropbox folders, and tagging a release with CITATION.cff for a Zenodo DOI. Use when the user asks about .gitignore, a file wrongly ignored or wrongly tracked, a committed token or password, CRLF or line-ending problems, files rejected by GitHub for size, tagging a paper version, the Zenodo-GitHub integration, CITATION.cff, or whether a project folder is safe to sync. README content belongs to data-repository-readme; choosing a repository and assembling the deposit to reproducible-research-data.'
---

# Git for research projects

Repository hygiene around an analysis project: what goes into Git, what stays out, how to keep
secrets and large data out, and how to tag a version that a paper can cite. It does not cover
the data deposit itself (`reproducible-research-data`: which repository, journal policy, file layout of the deposit) and
does not replace a Git tutorial. `references/sources.md` lists what was read and when.

**Owner's standing decision:** large data are never stored in GitHub repositories. They stay on
the university servers and are deposited or linked from there. So this skill has no Git LFS or
DVC walkthrough (a plain-language comparison is in `references/data-and-large-files.md` if the
user asks). The repository holds code, small text data, lockfiles and a manifest of the data.

## Workflow

1. **Look before changing.** Run the read-only audit from the R console (path relative to the
   skills repo; use the skill's real install path from another project):
   ```r
   source("git-for-research-projects/scripts/audit_repo.R")
   audit_repo("path/to/project")        # data frame: check, level, item, message
   ```
   It checks ignore rules that hide required files (`*.lock` hiding `renv.lock`), negations that
   do nothing, large files, tracked junk (`.RData`, `.venv`), credential-like file names and text
   patterns (values are never printed), CRLF in the index, a missing `.gitattributes`, and
   whether the repository sits in a sync folder. It changes nothing. Findings are heuristics:
   it sees names and patterns, not meaning, so read each one before acting.
2. **Fix in the right order.** Anything that looks like a real secret comes first, and rotating
   the credential comes before any history rewrite ([references/secrets-and-history.md](references/secrets-and-history.md)).
   Then ignore rules, line endings, and last tidying. Show the user the exact change (a diff or
   a list) before editing `.gitignore`, `.gitattributes` or running `git rm --cached`.
3. **Starter files** for a new project: copy [assets/gitignore-research](assets/gitignore-research) to
   `.gitignore` and [assets/gitattributes-research](assets/gitattributes-research) to `.gitattributes`, then adapt
   ([references/ignore-and-attributes.md](references/ignore-and-attributes.md) explains each block). Check the pipeline
   skill in use (`r-reproducible-pipeline`, `python-reproducible-pipeline`) for the files its project must track.
4. **Large or server-held data.** Ignore the data folder with the `data/*` plus `!` pattern, keep
   a tracked manifest, and say in the README where the originals live:
   ```r
   data_manifest("path/to/server/data", "data/manifest.tsv")     # path, bytes, sha256; commit this
   verify_manifest("path/to/copy/to/deposit", "data/manifest.tsv") # ok / changed / missing / extra
   ```
   Details and the reasons for the choices: [references/data-and-large-files.md](references/data-and-large-files.md).
5. **Release.** Tag the commit a paper or deposit refers to, with a `CITATION.cff` that validates:
   ```r
   release_check(".")                      # clean tree, pushed, tag at HEAD, CFF valid and matching
   write_citation_cff("CITATION.cff", title = "...", authors = "Given Family <mail> (ORCID: <https://orcid.org/...>)",
                      version = "1.0.0", date_released = "YYYY-MM-DD", license = "MIT")
   ```
   Workflow, Zenodo integration and pitfalls: [references/releases-and-citation.md](references/releases-and-citation.md).
6. **Report** which checks ran, what was changed (and what was only proposed), and what was not
   possible. Never claim a repository is clean beyond what the audit looked at.

## Rules

- **Never commit, push, tag, rewrite history or force-push for the user without being asked.**
  Commands that rewrite history (`git filter-repo`, `git push --force`) are shown, explained and
  left for the user to run, because they are irreversible for everyone with a clone.
- **Never print, store or log a credential.** Do not write tokens into files, memory files,
  commit messages or R code (the console echoes code into history). Use environment variables
  (`~/.Renviron`, never committed).
- Adding a rule to `.gitignore` does not untrack a file already committed; that needs
  `git rm --cached <file>`, and the old content stays in history.
- A negation (`!file`) under an excluded directory does nothing: write `data/*`, not `data/`.
- `*.lock` also matches `renv.lock` and `uv.lock`. Those must stay tracked (negate them).
- Do not put a working repository into a Syncthing, OneDrive or Dropbox folder if it can be
  avoided; if it already is, say so once, briefly, and let the user decide (see
  [references/windows-and-sync.md](references/windows-and-sync.md)). No lecture.
- GitHub's automatic "Source code" archives are not a data deposit and may omit LFS content;
  build deposit archives with `git archive` from a clean checkout.
- A tracked CSV whose row order changes between runs makes noisy diffs; sort rows when writing,
  or do not track it (it is regenerable output).

## Tested and not tested

Tested on Windows 11 with Git 2.55.0, Git LFS 3.7.1, R 4.6.0, cffr 1.4.2 (2026-10-23): every
check in `audit_repo()` on a scratch repository with seeded defects (ignored lockfiles, negation
under an excluded directory, 60 MiB file, `.Rhistory` tracked, credential-named file added then
removed, token-like assignment, CRLF committed with `autocrlf=false`), no false positive on this
repository apart from the sync-folder finding (true), `data_manifest()` and `verify_manifest()`
round trip (ok, changed, missing, extra), `write_citation_cff()` (valid file, ORCID kept,
invalid SPDX licence and malformed author rejected), `release_check()` before and after tagging,
and `uvx git-filter-repo --sensitive-data-removal --invert-paths --path ...` on a clone.
The tests behind the gotchas (negation, `check-ignore` exit code, `.gitattributes` beating
`autocrlf`, local `git archive` containing LFS content) are in `references/`.
Not tested: Linux or macOS, `git filter-repo` against a real GitHub remote and GitHub Support's
side, gitleaks and pre-commit hooks (not installed), case-collision and long-path behaviour on
Windows, Zenodo-GitHub integration on a real release, `git2rdata`, repositories with submodules,
very large histories (`history = TRUE` runs `git log --all`).

## Related skills

- `r-reproducible-pipeline`: the targets, renv and Quarto project whose lockfiles and `_targets.R` must be tracked and whose store must be ignored.
- `python-reproducible-pipeline`: the uv and Snakemake project, same rules (`uv.lock` tracked, `.snakemake/` and `.venv/` ignored).
- `data-repository-readme`: the README and data dictionary for the deposit; where the originals live goes there.
- `reproducible-research-data`: the deposit as a whole: which repository and journal rules apply, a checksummed staging copy from the server data, pre-upload checks and the data availability statement.
- `hpc-job-scripts`: sbatch and shell scripts must keep LF line endings when they are copied to a cluster.
- `codebase-map`: generates its own `.codemap/` artifacts and adds exactly one line to `.gitignore` for them; general `.gitignore`/repository hygiene beyond that stays here.
- `manuscript-writing-quarto`: structures and lints the Quarto manuscript this repository holds (journal templates, CRediT statement, spelling/bibliography checks).

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were or were not done: why a finding is real or only a heuristic, why a secret is rotated before history is rewritten, why data are ignored but a manifest is tracked, why a history rewrite is left to the user, and why a rule such as `data/*` is written that way. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
