# Sources and status

Contents: read for this skill; read only as excerpts; not read; how to check for changes.

Dates are 2026-10-23. Underlying notes with more detail: `research/data-and-git-ledger.md` in the llm-skills repository.

## Read (page text)

| Source | Used for |
|---|---|
| Agent Skills specification and Anthropic best practices | Skill structure |
| https://git-scm.com/docs/gitignore | Pattern rules, negation under an excluded parent |
| https://git-scm.com/docs/gitattributes (read earlier in the research round) | `text=auto`, `eol`, `export-ignore`, `--renormalize` |
| https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository | Rotate first, filter-repo 2.47+, force push, Support, forks |
| https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github | 50 MiB warning, 100 MiB block |
| GitHub Docs: referencing and citing content; about CITATION files | Zenodo integration, CITATION.cff display |
| Zenodo docs: GitHub and software, CITATION.cff, `.zenodo.json`, create new upload | Precedence of `.zenodo.json`, limits, 45 days |
| Dryad file requirements | Limits |
| https://quarto.org/docs/projects/code-execution.html | `_freeze` is meant to be committed |
| Turing Way (version control, research data management, compendia) | Layout and practices |
| Wilson et al. 2017 (PLOS CB); Perez-Riverol et al. 2016 (PLOS CB) | What not to track; tags and releases |
| Git LFS man page; Syncthing docs on ignoring files | Pointers; `.stignore` |
| CRAN packages: cffr, gitignore, git2rdata, gert, usethis (descriptions, `gitignore` and `cffr` run) | Helpers |

## Read only as search excerpts

GitHub Docs on LFS objects in archives (pointers by default); Syncthing forum and web posts on Git in synced folders. Re-read before relying on the exact wording.

## Not read or blocked

Happy Git with R chapters beyond the index; Turing Way `vcs-workflow`, `vcs-checklist`; Springer and OUP pages (blocked); Software Heritage. No gitleaks, pre-commit or DVC documentation was read.

## How to look for changes

- GitHub Docs search for "removing sensitive data": the `--sensitive-data-removal` flag and minimum version are recent and may move.
- `uvx git-filter-repo --help` for the installed version; `git --version`; `git lfs version`.
- Zenodo docs pages "GitHub integration" and "Upload": limits and the 45-day rule.
- `check_versions()` in `github-skill-maintenance` for cffr and other package claims.
