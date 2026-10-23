# Data and large files

Contents: the decision; the manifest workflow; limits; the alternatives in plain language; tabular data that is tracked.

## The decision (the owner's, 2026-10-23)

Large files do not live in GitHub repositories. They stay on the university servers and are deposited into a data repository from there, or linked. So:

- The repository holds code, small text data, lockfiles and a manifest.
- The data folder is ignored with `data/*` and exceptions (`!data/README.md`, `!data/manifest.tsv`).
- `data/README.md` says where the originals live (server, path, who has access, whether it is backed up, whether it is read-only) and which copy is deposited. Those facts only the user knows; ask, do not guess.
- Git is not a backup. A repository on one laptop is one copy.

## Manifest workflow

```r
source("git-for-research-projects/scripts/audit_repo.R")
data_manifest("//server/share/project/data", "data/manifest.tsv")   # path, bytes, sha256; sorted; no timestamps
# commit data/manifest.tsv
verify_manifest("D:/deposit_copy", "data/manifest.tsv")             # ok, changed, missing (only in manifest), extra (only in folder)
```

- Timestamps are left out on purpose: they change on every copy, so the manifest would differ with identical data.
- Checksums are SHA-256 (`tools::sha256sum()`, base R 4.5 or newer; `digest` is the fallback).
- The point is to prove that the copy that reaches the repository equals the server copy, and that the analysis ran on the same files that are described. A changed row in the manifest also shows when somebody edited "raw" data.
- Protect the originals: mark them read-only on the server if possible. On Windows, the read-only attribute worked for stopping accidental overwrites (tested with `Sys.chmod(f, "444")`), but it is not security.
- `data_manifest()` refuses file names containing tabs or newlines. Names with spaces or non-ASCII characters are accepted, but ASCII lowercase names without spaces are advised by the Turing Way and Dryad.
- Tested: round trip with a changed, a new and a deleted file (statuses `changed`, `extra`, `missing`). Not tested: network drives, very large files (hashing reads the whole file), symlinks.

## Limits to check live

| Where | Limit read on 2026-10-23 |
|---|---|
| GitHub | Warning at 50 MiB, block at 100 MiB, 25 MiB for browser uploads; repository ideally under 1 GB, strongly under 5 GB |
| Zenodo | 100 files and 50 GB per upload (form) |
| Dryad | 10 GB per file recommended, 2 TB per publication through the web interface |

These change; the data-deposit pages must be read again at the time (see `data-repository-readme/references/sources.md`). `audit_repo(large_mb = 50)` flags tracked or about-to-be-added files above the threshold (error from 100 MiB).

## Alternatives in plain language (only if the user asks)

| Tool | What it does | Cost for this setup |
|---|---|---|
| Git LFS | Replaces big files in Git with small pointer files and stores the content on a separate server | Needs a server or paid GitHub quota; GitHub's automatic "Source code" archives hold the pointers, not the files (tested locally: a local `git archive` does include the content) |
| DVC | Keeps pointer files (`.dvc`) in Git and the data in a storage you choose (shared drive, S3, SSH) | A second tool for every collaborator; not tested here |
| DataLad / git-annex | Version control for large files and datasets with many storage backends | Steeper learning curve; people without the tool cannot fetch the content from GitHub; not tested here |
| Plain deposit | Data in Dryad, Zenodo or the institutional repository, referenced in README and manifest | What this skill assumes |

## Small tracked tables

Plain Git is fine for few, small, mostly-CSV files (Turing Way, Wilson et al.). Sort rows and write columns in a fixed order, because reordered rows produce huge diffs. CRAN `git2rdata` 0.5.2 (installed, not tested here) stores data frames as text plus metadata so diffs stay small; consider it only for tables that really change over time.
