# Releases, tags, CITATION.cff and Zenodo

Contents: tags and when to tag; pre-release checks; CITATION.cff with cffr; Zenodo integration; archives; deposit decisions.

## Tags

- Tag the commits that other documents refer to: submission, revision, acceptance, deposit. Use annotated tags with a message: `git tag -a v1.0.0 -m "Submitted version"` and push them (`git push origin v1.0.0`). Tags are not pushed by an ordinary `git push`.
- Semantic or date-based versions are both fine; be consistent and put the same string into `CITATION.cff` (`version`), the README and the paper.
- Perez-Riverol et al. 2016 recommend tags per release, one DOI per release (Zenodo or Figshare), and a README, LICENSE and a citation file in the repository.

## Pre-release checks

```r
source("git-for-research-projects/scripts/audit_repo.R")
release_check(".")                 # or release_check(".", tag = "v1.0.0")
audit_repo(".")                    # secrets, ignored required files, large files
```

`release_check()` is read-only and reports: uncommitted or untracked changes; commits not pushed (or no upstream); tag missing or not at HEAD; missing LICENSE or README; both `.zenodo.json` and `CITATION.cff`; CFF failing the schema; CFF `version` differing from the tag; `date-released` not `YYYY-MM-DD`. Tested before tagging (errors) and after (tag check passes).

## CITATION.cff with cffr

```r
write_citation_cff("CITATION.cff",
  title = "Project title", version = "1.0.0", date_released = "YYYY-MM-DD", license = "CC-BY-4.0",
  type = "dataset",       # or "software"
  authors = c("Given Family <mail> (ORCID: <https://orcid.org/0000-0000-0000-0000>)", "Other Person"))
```

What the helper handles (all tested with cffr 1.4.2, 2026-10-23):

- `cffr::cff()` needs `cff_version` and `message` to validate; the helper sets both.
- `authors` must go through one vectorised `as_cff_person()` call (a list of separate calls produced nested, invalid author entries), and only the format `Name <mail> (ORCID: <https://orcid.org/...>)` keeps the ORCID. A bare `(https://orcid.org/...)` is dropped without a warning.
- `cff_write(validate = TRUE)` once wrote an invalid file silently, so the helper validates the written file and prints `instancePath` and `message` of each schema error before failing. An invalid SPDX licence (`GPL3`, correct is `GPL-3.0-only`) and a malformed author were both rejected.
- `date-released` must be ISO; YAML reads an unquoted key `n` as FALSE (same trap as in config files).
- The user, not the assistant, supplies authors, ORCIDs, licence and title. Never infer them.
- GitHub shows "Cite this repository" from a root `CITATION.cff` (APA and BibTeX only). `preferred-citation` points to a paper instead; `type: dataset` gives a data citation string.

## Zenodo-GitHub integration

Facts from the Zenodo and GitHub docs (read 2026-10-23); check the current pages before the first release:

- Log in to Zenodo with GitHub and switch the repository on. Each **published GitHub release** (not a bare tag) is archived and gets a new DOI, plus a concept DOI for all versions. Public repositories only.
- **If `.zenodo.json` exists, Zenodo uses only it and ignores `CITATION.cff` entirely.** Keep one of them. `.zenodo.json` is needed for grants, communities, related identifiers and contributor roles.
- Zenodo supports a subset of the CFF schema (title, version, license, type, abstract, authors with ORCID, keywords). It points to `cffconvert` for validation.
- Release archives are Software records, also archived in Software Heritage. Failed releases show errors on the Zenodo GitHub page.
- Files in a published Zenodo record can be changed for 45 days; metadata at any time. Re-read the page: another Zenodo page words this differently.
- Do not reuse the article DOI for a dataset.
- The assistant never creates a release, publishes a record or uploads to Zenodo. Publishing is effectively permanent. If a Zenodo API test is wanted, use the sandbox first and only with explicit permission, and never write the token anywhere (read it from an environment variable such as `ZENODO_SANDBOX_TOKEN`).

## Archives

- GitHub's automatic "Source code (zip/tar.gz)" archives contain LFS **pointers** by default, and none of the ignored data. They are not a data deposit.
- Build a code archive locally from a clean checkout of the tag: `git archive --format=zip --prefix=project-v1.0.0/ -o project-v1.0.0.zip v1.0.0`. Tested: it honours `export-ignore` and sets the UTF-8 flag for non-ASCII names. A local `git archive` contains real LFS content if the objects are present (`git lfs fetch --all` first on a fresh clone; not tested).
- Run the pipeline from that clean checkout with the lockfiles (`renv::restore()`, `uv run --locked`) to confirm the deposit rebuilds. That test belongs to the pipeline skills.

## Decisions that are the user's

Which repository (Dryad, Zenodo, institutional), which licence for code and for data, whether the code lives on GitHub with a Zenodo DOI or inside the data deposit, and what the journal requires at submission or at acceptance. The assistant lays out the trade-offs and the facts above, then asks.
