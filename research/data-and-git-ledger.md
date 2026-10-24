# Data deposit and Git ledger

Research ledger for two planned skills, `reproducible-research-data` (RRD) and `git-for-research-projects` (GIT), and for refactoring
the existing `data-repository-readme` (README). Started 2026-10-23. Working notes, not a skill (no SKILL.md). Same conventions as
`pipeline-resources-ledger.md`: status **read** = page text read in this session, **partial** = only part answered, **blocked** =
fetch failed, **search** = only a search excerpt, **meta** = version or metadata only. Versions are dated 2026-10-23; re-check with
`check_versions()` before writing them into a skill.

## 1. Scope and overlap map

| Topic | README (exists) | RRD (planned) | GIT (planned) | Pipeline skills (exist) |
|---|---|---|---|---|
| README text and data dictionary for a deposit | owns | links | | |
| Repository choice (Dryad, Zenodo, Figshare, institutional), journal data policy, data availability statement | currently in `sources.md` (repository pages) | owns the decision and the statement | | |
| What goes into the deposit (raw, processed, code, environment, figures), folder layout, file names, formats | partly (`content-guide.md`) | owns | | `renv.lock`, `uv.lock`, `_targets.R`, Snakefile come from here |
| Licences, identifiers (DOI, ORCID, ROR), FAIR | `sources.md` "Standards" | owns | CITATION.cff basics | |
| Personal data, sensitive species locations | rule in SKILL.md | owns | | |
| Manifest and checksums, clean-clone test, archive build | | owns | `git archive` mechanics | the pipelines are what the clean clone runs |
| Version control hygiene (`.gitignore`, `.gitattributes`, commits, tags, large files, secrets, history rewrite) | | links | owns | lockfile rules referenced |
| GitHub release to Zenodo DOI, CITATION.cff, `.zenodo.json` | mentioned | decides when to use it | owns the Git side | |
| Cloud-sync folders containing repositories | | | owns | |

Overlap with README is real but narrow: README is the single artefact (README.md plus dictionary); RRD is the whole deposit and the
decisions around it. Section 7 lists the proposed split.

## 2. Sources

| Source | Status | What it gave |
|---|---|---|
| Turing Way, Guide for Reproducible Research (https://book.the-turing-way.org/reproducible-research/reproducible-research.html) | read (index) | Chapter list: Version Control, Licensing, Research Data Management, Reproducible Environments, Research Compendia, Code Review, CI. Definition: reproducibility = data and code available to rerun the analysis. CC-BY 4.0 |
| Turing Way, RDM chapter, `rdm-storage`, `rdm-checklist` | read | Storage: 2-3 copies on at least 2 media in different places; file names lowercase, ISO date first, no spaces or special characters, hyphens within chunks and underscores between, no personal data in names, convention documented in README. The page does **not** cover formats, read-only raw data or versioning of data. Checklist (individual): do not touch raw data, keep a read-only copy; data management plan; document with the data; reuse existing standards |
| Turing Way, Research Compendia (`.../compendia`) | read | Definition (Marwick et al.): conventional folder structure, separate data / methods / output, specify the environment. Three-way sort: read-only (raw data, metadata), human-generated (code, paper, README), project-generated (clean data, figures). Example tree has `data_raw/`, `data_clean/`, `code/`, `figures/`, `paper`, `Dockerfile`, `Makefile`, `LICENSE`, `CITATION`. rrtools not mentioned on the page |
| Turing Way, `vcs` index, `vcs-git-in-research`, `vcs-data` | read | Git alone is not enough for research data; plain Git is fine only while files are few, small and mostly CSV. Tool descriptions: DVC, Git LFS (centralised, needs a server or paid service), git-annex (distributed), submodules (hard), DataLad (git-annex based; newcomers on GitHub cannot fetch annexed content without the tools). Pages `vcs-workflow`, `vcs-checklist` not read |
| Turing Way, `licensing-data` | read | CC0 relinquishes attribution (reliance on citation norms); Open Data Commons licences (PDDL, ODC-BY, ODbL) cover database rights only; CC licences are general-purpose |
| Wilson et al. 2017, Good enough practices in scientific computing (PLOS CB, fetched page) | read | Six categories. Data: keep raw data read-only and backed up in more than one place; open machine-readable formats; replace cryptic codes (`-99` to `NA`); record processing in scripts; submit to a DOI repository. Project: one directory per project, `doc/ data/ results/ src/ bin/`. **Version control: do not track binary or office files, CSVs whose row order changes, raw data, regenerable intermediates, large files (100 MB GitHub limit; Git LFS called "not yet mature enough" in 2017), restricted data, passwords or keys** |
| Perez-Riverol et al. 2016, Ten simple rules for Git and GitHub (PLOS CB, fetched page) | read | Small incremental commits, do not track derived files; semantic versioning tags; short-lived feature branches; Zenodo or Figshare DOI per release; LICENSE, README, CITATION file. Page does not discuss secrets or data repositories |
| GitHub Docs, About large files | read | Warning at 50 MiB, hard block at 100 MiB, 25 MiB for browser uploads; repository ideally under 1 GB, strongly under 5 GB; use releases for large binaries; Git is not a backup |
| GitHub Docs, Managing Git LFS objects in archives (search excerpt) | search | **By default GitHub source archives (zip, tarball) contain only LFS pointer files**; admins can include LFS objects; not for an external LFS server; a community thread reports that with the option on the tarball had the files but the zip did not (2021, may be outdated) |
| GitHub Docs, Referencing and citing content | read | Zenodo integration: log in with GitHub, toggle the repository on, each new release archives the repository and gets a new DOI; public repositories only; add a licence |
| GitHub Docs, About CITATION files | read | `CITATION.cff` in the root of the default branch gives a "Cite this repository" box (APA and BibTeX only); `preferred-citation` redirects to a paper; `type: dataset` gives a data citation string; other `CITATION*` files are linked, not parsed |
| Zenodo docs: GitHub and Software, CITATION.cff, `.zenodo.json`, Archive a release | read | **If `.zenodo.json` exists Zenodo uses only it and ignores `CITATION.cff` entirely.** `.zenodo.json` is needed for grants, communities, related identifiers, contributor roles. A subset of the CFF schema is supported (title, version, license, type, abstract, authors with ORCID, keywords). Release archive is a Software record also archived in Software Heritage; failed releases show errors in the Zenodo GitHub page; Zenodo points to `cffconvert` for validation |
| Zenodo docs, Create new upload | read | Up to 100 files and 50 GB per upload; after publishing, **files can only be changed within 45 days**, metadata any time; reserved DOI is lost if the draft is deleted; restricted files and embargo supported; sandbox at sandbox.zenodo.org. Do not reuse the article DOI for a supporting dataset |
| Dryad, File requirements | read | Accepts all research data but only files compatible with CC0; code and software can be uploaded through Dryad and are then hosted on Zenodo (time-released with the dataset); no PII; CSV, TSV or ODF preferred for tables, README in Markdown; RAR not accepted; recommended maximum 10 GB per file, 2 TB per publication through the web interface |
| Springer Nature data policy types (search excerpts) | search | Legacy types 1 to 4 (encouraged; evidence encouraged; availability statement required = type 3, now the standard; peer review of data required). Statement templates: dataset in named repository with persistent link; not public because [reason] but available on request; on request; not applicable; included in the article. Community repositories are mandatory for some data types. Journal pages for Oecologia, Behavioral Ecology and Sociobiology **not read** (fetch returned a client challenge) |
| Ecosphere author guidelines, OUP Behavioral Ecology, Alston and Rick 2021 full text | blocked (403) | Not read. Alston and Rick (W3124249310, Bulletin of the ESA) is the ecology-specific beginner's guide: obtain the text through the OpenAlex full-text route (`openalex/references/fulltext.md`) before the skill cites any detail |
| FAIR principles (Wilkinson 2016, PMC4792175) | read | F1 to F4, A1, A1.1, A1.2, A2, I1 to I3, R1, R1.1 to R1.3 (licence, provenance, community standards). The go-fair.org page returns nothing to the fetch tool (also in the README skill) |
| git-scm docs: gitignore, gitattributes | read | See section 4 |
| GitHub Docs, Removing sensitive data from a repository | read | Rotate the credential first; `git filter-repo` 2.47 or newer with `--sensitive-data-removal`; force push, then GitHub Support to purge cached views and pull-request refs; forks keep the data; commit hashes and signatures change |
| Git LFS man page | read | Pointer files, clean and smudge filters, pre-push upload; commands track, migrate, ls-files, prune. No limitations stated on the page |
| Syncthing docs, Ignoring files (v2.1.0) | read | `.stignore` must sit at the folder root, is never synced, first matching pattern wins, `!` negation, `(?d)` deletes ignored files that block a directory removal, `#include` |
| Syncthing forum threads and web posts on Git in synced folders (search excerpts) | search | Maintainer view: Git repositories are not independent files, concurrent edits are "merged" by Syncthing into an inconsistent repository; use fetch and push instead; one safe case: the repository is used on only one device and the sync is a backup. Git LFS maintainer: cloud sync services (OneDrive, Dropbox) are known to corrupt Git repositories because they sync file by file. MATLAB and others show a warning for OneDrive folders |
| Happy Git with R (happygitwithr.com) | partial (index only) | Table of contents only (chapters on install, PAT, SSH, workflows, "Burn it all down", "Resetting"). No statement on cloud-sync folders found on the page read |
| CRAN pages: zen4R, rdryad; deposits docs | read | See section 5 |

## 3. Local tests (Windows 11, Git 2.55.0.windows.5, git-lfs 3.7.1, R 4.6.0), scratch repos in git-ignored `tmp-examples/gt/` (deleted afterwards)

| Test | Result |
|---|---|
| Pattern `*.lock` in `.gitignore` | Ignores `renv.lock`, `uv.lock` and `a.lock` alike (reproduces the template lockfile incident). Fix `!uv.lock` and `!renv.lock` after it: both tracked, other `*.lock` still ignored |
| `data/` then `!data/raw.csv` | **Negation has no effect** (parent directory excluded). `data/*` then `!data/raw.csv` works |
| `git check-ignore -v` on a path matched by a negation | Prints `file:line:!pattern path` and **exits 0**, so exit 0 does not mean "ignored"; use `-q`, `git status --ignored`, or look for the leading `!` |
| `git check-ignore` on an already tracked file | Reports nothing (exit 1) because tracked files are not ignored; `--no-index` shows the matching rule. A new ignore rule never untracks a file |
| Windows default line endings | `core.autocrlf=true` is set in the **system** config (`C:/Program Files/Git/etc/gitconfig`), not in the user config; this is the source of the "LF will be replaced by CRLF" warnings. `git ls-files --eol` shows index and working-tree endings per file |
| `.gitattributes` `* text=auto` plus `*.sh text eol=lf` and `git add --renormalize .` | Index stays LF, `lf.sh` checked out with LF despite autocrlf; a CSV with CRLF in the working tree is normalised to LF in the index. Attributes beat `core.autocrlf` |
| LFS: `git lfs track "*.bin"`, commit, `git archive` | `git lfs ls-files` shows the file; **a local `git archive` contains the real 300 kB content** (smudge runs), whereas GitHub-generated archives contain pointers by default (docs). So a deposit zip built locally is complete; the GitHub "Source code (zip)" is not |
| `.gitattributes` with `tests/ export-ignore` and `.gitattributes export-ignore` | Both left out of the archive; works for trimming a code deposit |
| `git filter-repo` | Not installed (`git filter-repo` unknown); `uvx` 0.12.5 is available, so `uvx git-filter-repo` is a possible route (not run) |
| Read-only flag: `Sys.chmod(f, "444")` | `file.access(f, 2)` returns -1 and `writeLines` fails with "Permission denied"; the Windows read-only attribute works for protecting raw data from accidental overwrite (not a security measure) |
| Hashes | `tools::sha256sum()` and `md5sum()` exist in R 4.6.0 (sha256sum is in base R since 4.5) |
| ZIP with a non-ASCII file name (`Thorbj\u00f6rn_data.csv`) | `zip::zip` (3.0.2) and `git archive --format=zip` both set the UTF-8 flag; names decode correctly in Python. ASCII-only names are still advised (Turing Way, Dryad) |
| `cffr` 1.4.2 (CRAN, installed) on a **non-package** project | Works: `cff(...)` with `as_cff_person("Name <mail> (https://orcid.org/...)")` for authors, `cff_write()`, `cff_validate(path)`, `as_bibentry()`. See gotchas below |
| `zen4R` 0.10.6 (CRAN, installed) | Installed only; no API call made (needs a Zenodo token; calls could publish). Not tested |
| Repository integrity check on this repo | `git fsck` clean, no `*sync-conflict*` files, no `.stversions` entries for `llm-skills`, no stale `.git/*.lock` |

### Gotchas worth putting in the skills

1. **`*.lock` ignores `renv.lock` too.** A generic "lock files" rule in `.gitignore` silently removes the lockfiles the pipeline skills require. Use `!renv.lock`, `!uv.lock`, or ignore specific lock names only.
2. **Negation under an excluded directory does nothing**; write `dir/*`, not `dir/`.
3. **`git check-ignore -v` exit code 0 is not proof of ignoring** when the matching rule is a negation.
4. `.gitignore` is not retroactive: tracked files stay tracked (`git rm --cached`).
5. **`cffr::cff()` needs `cff_version` to validate**; `cff_write(validate = TRUE, verbose = FALSE)` wrote an invalid file (missing `message` and `authors`) without error. Always run `isTRUE(cff_validate(path, verbose = FALSE))` afterwards; the validation attribute `errors` is huge, print `attr(v, "errors")[, c("instancePath", "message")]`. cffr caught a non-ISO `date-released` and a non-SPDX licence (`GPL3`) in a deliberately broken file. If `.zenodo.json` exists Zenodo ignores the CFF, so do not keep both unless intended.
6. `as_cff_person()` expects one string per person; passing a base-R `person()` inside a plain list produced a nested, invalid `authors` entry.
7. YAML trap from the pipeline ledger (key `n` read as FALSE) also applies to CFF and config files.
8. GitHub archives and LFS: pointers by default; local `git archive` is complete if the LFS objects are present locally (`git lfs fetch --all` first on a fresh clone; not tested).
9. Zenodo post-publication file edit window (45 days) vs the Zenodo `about-records` wording noted in the README skill; both claims are from Zenodo docs, so the skill should say "check the current page before publishing".

## 4. Facts from git docs (read)

- `.gitignore` source precedence: command line, then `.gitignore` files (deeper wins), then `.git/info/exclude`, then `core.excludesFile` (default `~/.config/git/ignore`). Last matching pattern within one level wins. Trailing `/` matches directories only.
- `.gitattributes`: `text=auto` normalises text to LF in the index; `eol=lf` or `eol=crlf` set the working-tree ending; `binary` = `-diff -merge -text`; `core.safecrlf` warns on irreversible conversion; recommended migration `echo "* text=auto" > .gitattributes; git add --renormalize .`; `export-ignore` for `git archive`.
- `usethis` 3.2.2 exports `git_vaccinate()` (adds common files to the **global** ignore; not run, it edits the user's global config), `use_git_ignore`, `use_git_config`, `use_github_release`, `use_git_hook`, `use_citation`. `gert` 2.5.0 exports `git_ls`, `git_tag_create`, `git_tag_list`, `git_tag_push`, `git_status`, `git_ignore_path_is_ignored` (returned FALSE for the negated file, TRUE for an ignored sibling; consistent with `-q`), `git_archive_zip`, `git_stat_files`.

## 5. Packages and tools

| Tool | CRAN | Status | Note |
|---|---|---|---|
| cffr 1.4.2 | yes | installed, tested | CITATION.cff from R, validation against the CFF 1.2.0 JSON schema (needs `jsonvalidate`); `cff_gha_update()` and `cff_git_hook_install()` exist (not tested); docs say it targets packages, works for plain projects with `cff()` |
| zen4R 0.10.6 | yes | installed, not tested | Zenodo REST client (depositions, DOIs, upload); stores tokens with `keyring`. Any call that publishes is permanent; if tested, use the sandbox with the user's explicit permission |
| rdryad 1.0.0 (2020) | yes | page read | Search and download only (Solr, OAI-PMH, fetch); **no submission**; old |
| deposits | **no** (rOpenSci r-universe or GitHub, version 0.2.1.068) | page read, not installed | Zenodo, Zenodo sandbox and Figshare, with a sandbox option; non-CRAN, so installing needs the user's permission |
| codemetar 0.3.7 | yes | not installed | CodeMeta JSON for R packages; probably not needed for analysis projects |
| precommit 0.4.3 | yes | not installed | R wrapper around the Python `pre-commit` framework; needs Python; pre-commit itself is not installed here |
| gert 2.5.0, usethis 3.2.2, gh 1.6.1, gitcreds, credentials, renv, fs, digest, here | yes | installed | Enough for hooks, tags, ignore checks and checksums without new dependencies |
| workflowr 1.7.2, pins 1.4.2 | yes | not installed | Different jobs (website from analyses; versioned data boards); not obviously needed |
| rrtools | no (GitHub only) | not installed | Marwick's compendium scaffold; GitHub install requires permission; the skill can describe the layout without it |
| Git LFS 3.7.1 | n/a | installed, tested | See section 3 |
| DVC, DataLad, git-annex, gitleaks, pre-commit | n/a | not installed | Judged from docs only |

## 6. OpenAlex (R/httr2, title searches; authors checked from the returned authorships; abstracts not read)

| Work | OpenAlex ID | Year | Citations | Use |
|---|---|---|---|---|
| Wilson et al., Good enough practices in scientific computing | W2963508088 (duplicate record W2507622755) | 2017 | 451 | Practices for data, project layout, version control (page read) |
| Noble, A quick guide to organizing computational biology projects | W2140503409 | 2009 | 95 | Project layout; **page not read** |
| Marwick et al., Packaging data analytical work reproducibly using R (and friends) | W4245161709 (preprints W2749102981, W4249988402) | 2017 | 108 | Research compendium; not read |
| Alston and Rick, A beginner's guide to conducting reproducible research | W3124249310 | 2021 | 81 | Ecology audience; full text blocked, not read |
| Wilkinson et al., The FAIR Guiding Principles | W2302501749 (addendum W2966562087) | 2016 | 18275 | FAIR list read via PMC |
| Sandve et al., Ten simple rules for reproducible computational research | W2036318837 | 2013 | 873 | Already in the pipeline ledger |
| Perez-Riverol et al., Ten simple rules for taking advantage of Git and GitHub | W2557994837 | 2016 | 231 | Page read |
| Hillemann et al., Code review in practice: a checklist for computational reproducibility | W4409740950 | 2025 | 1 | Preprint, not assessed |
| Nuest et al., CODECHECK | W3151240889 | 2021 | 27 | Independent execution of the code behind an article; not read |
| Rule et al., Ten simple rules for reproducible research in Jupyter notebooks | W2897352125 | 2018 | 18 | Not read; relevant only if notebooks are used |

Not searched: ecology-specific data-sharing studies (for example how often code and data are archived in behavioural ecology journals); do this before the skill makes any claim about field practice.

## 7. Proposed split and refactor (design observations, not decisions)

**`reproducible-research-data` (new): the deposit as a whole, for one paper.**

1. Decide what is deposited: raw, processed, code, environment (lockfiles from the pipeline skills), figures' source data; what is excluded and why (personal data, protected-species coordinates, licence-restricted third-party data).
2. Layout and names: compendium sort into read-only, human-written and generated; ASCII lowercase names; raw data read-only (Windows read-only flag tested); open formats (Dryad list).
3. Licences and identifiers: data CC0 or CC-BY, code MIT or similar, repository-forced terms (Dryad CC0); ORCID, ROR, funder IDs.
4. Where to deposit: Dryad (data) plus Zenodo (code, also via Dryad), Zenodo alone, institutional; journal policy and data availability statement text (Springer templates read only as search excerpts; journal pages need to be read live each time).
5. Build and check: manifest with sha256 and sizes, file-name and format checks, size limits against the live repository page, clean-clone run of the pipeline (what the pipeline skills' `--locked` rules are for), `git archive` for the code archive, README via `data-repository-readme`.
6. Publish and maintain: DOI and version semantics, 45-day Zenodo window, CITATION.cff or `.zenodo.json`, update the data availability statement and the paper's references. The assistant never uploads or publishes; zen4R or deposits only with sandbox first and explicit permission.
7. Candidate scripts (to be written and tested): `make_manifest()` (path, size, sha256, class by extension), `check_deposit()` (non-ASCII or space in names, forbidden formats, large files, missing README, lockfiles present, secret-looking files, calls `check_readme()`), CITATION.cff helper around cffr with the validation pitfall handled.

**`git-for-research-projects` (new): repository hygiene around analysis projects.**

1. Starter files: `.gitignore` for R, Python, Quarto, Positron or RStudio; `.gitattributes` for line endings (this repo already has one for `*.sh`, `*.py`, `*.md`); what to commit (code, small text data, lockfiles, config, README) and what not (binary and office files, raw large data, regenerable output, `.Rproj.user`, `.RData`, `.venv`, `_targets/`, secrets).
2. Habits: small commits with a reason, tag at submission, revision, acceptance and deposit; semantic or date tags; a branch only for risky changes.
3. Large files decision table: under about 50 MiB plain Git; many or large files: keep data out of Git and deposit them (Dryad, Zenodo), or Git LFS (GitHub archives omit objects by default, quota), or DVC or DataLad (not tested here); Git is not a backup.
4. Secrets: prevention (`.Renviron` ignored, tokens via environment), detection (filename checks; gitleaks not installed), response (rotate first, then `git filter-repo`, force push, GitHub Support; forks keep the data).
5. Windows and cross-platform: system `core.autocrlf=true`, `.gitattributes`, `git ls-files --eol`, `core.longpaths`, case-insensitive paths (not tested).
6. Sync folders: do not put a working Git repository in a OneDrive, Dropbox or Syncthing folder; push and pull instead. See section 8: **this applies to the user's own setup**.
7. Releases: tag, GitHub release, Zenodo integration, CITATION.cff, `.zenodo.json` precedence; LFS caveat.
8. Candidate script: `audit_repo()` (ignored files that the project requires, `*.lock` rule, tracked large files, CRLF mix via `git ls-files --eol`, missing `.gitattributes` or `.gitignore`, repository inside a sync folder by looking for `.stfolder`, `.dropbox`, OneDrive in the path, committed `.RData` or `.Rproj.user`). Overlaps `github-skill-maintenance` only in commit steps.

**`data-repository-readme` refactor (proposal).**

- Keep it as the README-and-dictionary specialist; its workflow, scripts and assets are tested and stay.
- Move generic material out to RRD: the "Standards" section (identifiers, licences, FAIR) and the general rules (do not upload, personal data, sensitive locations, journal policy check). In README keep one-line pointers.
- Rename nothing; add "Related skills" links to RRD and GIT, and have step 1 ("Establish the target") say that choosing the repository belongs to RRD.
- `content-guide.md` keeps README sections and the field-specific additions; the CITATION.cff mention moves to RRD and GIT.
- `sources.md` stays (repository README pages), plus links to RRD's repository and journal-policy sources, to avoid two copies of the same URLs.
- Decision for the user: one combined skill versus three. Recommendation: three, because triggers differ (a README request versus a "prepare my deposit" request versus a Git problem) and the README skill is already tested; the cost is cross-links, covered by `check_skill_links()`.

## 8. Findings about the user's own setup (facts observed, not acted on)

- `C:/Users/thorb/Sync_Home_Work` is a **Syncthing folder** (`.stfolder`, `.stversions` present, `syncthingtray` on the PATH) with **no `.stignore`** at its root. It contains **seven Git repositories**, including this one (`llm-skills`, `01-2026_Aarhus_odor`, `06-2026_GAM_course/*` two clones, `au-section-08-2026`, `dlc-pig-method-paper`, `entreprenauts_anomaly_tracker`). If another device syncs the same folder, their `.git` directories are synced too, which Syncthing's maintainers and Git LFS's maintainer advise against. No damage found in `llm-skills` (fsck clean, no conflict files), and I cannot see from here whether a second device is attached. Options for the user to weigh: keep as is and only edit on one device at a time; ignore `.git` (or whole repositories) in `.stignore` and rely on `git push` and `git pull`; or move repositories out of the sync folder. A `.stignore` is per device and never synced.
- An empty directory `llm-skills/file4b984174891` exists (created 2026-10-23 14:31, untracked because Git ignores empty directories). Origin unknown; left in place.
- `core.autocrlf=true` comes from the Git for Windows system config; this repo's `.gitattributes` fixes endings only for `*.sh`, `*.py`, `*.md`. The `.gitignore` and `uv.lock` CRLF warnings seen earlier are therefore expected, and harmless for the index.
- Fixed earlier today: the `*.lock` rule that excluded the template `uv.lock` (see AGENTS.md log).

## 9. Open items and not done

- Not read: Springer journal pages for Oecologia and Behavioral Ecology and Sociobiology, Ecosphere and Behavioral Ecology author instructions (all blocked), Alston and Rick full text, Noble 2009, Marwick 2017, Happy Git chapters on workflows and "Burn it all down", Turing Way pages `vcs-workflow`, `vcs-checklist`, `rdm-metadata`, `rdm-sharing`, `rdm-fair`, Software Heritage, Dryad "Good data practices" refreshed, Figshare current limits, institutional repository of the user (Jyvaskyla or Aarhus; ask).
- Not tested: zen4R and any repository API (needs a token, sandbox first, user permission), `git filter-repo` (not installed), gitleaks, `precommit`, DVC, DataLad, LFS on GitHub itself (quota, archive option), `git lfs fetch --all` on a fresh clone then `git archive`, case collisions on Windows, long paths, symlinks, `cff_gha_update()` and `cff_git_hook_install()`, Linux and macOS.
- Questions for the user before building: (1) one combined skill or three (section 7); (2) which repositories and journals matter most (Dryad, Figshare, Zenodo, institutional; Oecologia, Behavioral Ecology and Sociobiology, Ecosphere), so the policy research targets those; (3) whether to test Zenodo through the sandbox with a token; (4) whether another device syncs `Sync_Home_Work`, and what to do about `.git` inside it; (5) whether DVC or DataLad deserve hands-on coverage or only a decision table (recommendation: decision table).

## 10. Round 2 (2026-10-23): user decisions, journal policies, Zenodo sandbox

**User decisions:** (1) three skills (RRD, GIT, README refactored); (2) target repositories Dryad, Figshare, Zenodo, institutional; target journals
Oecologia, Behavioral Ecology and Sociobiology, Ecosphere, Behavioral Ecology and **Computers and Electronics in Agriculture (CEA)**; (3) Zenodo
test strictly in the **sandbox** with the user's token; (4) Syncthing is not a focus (keep it as one short hazard note in GIT, no more);
(5) DVC, DataLad and friends need a plain-language explanation first (given in the chat reply; decision table only in the skill unless the user asks otherwise).

### 10.1 Journal data policies (search excerpts, not full pages; **always re-read the live page**, excerpt ages in brackets are the search tool's)

| Journal | What the excerpts say | Status |
|---|---|---|
| Oecologia (Springer) | Follows the Springer Nature research data policy: sharing strongly encouraged, a **Data Availability Statement is required** for original research; datasets as Supplementary Information only after reading the research data policy; repositories preferred. Instructions for Authors is a PDF | search excerpt of `link.springer.com/journal/442/submission-guidelines`; page itself blocked earlier |
| Behavioral Ecology and Sociobiology (Springer) | An editorial announces **mandatory data deposition** in repositories for publications with data, and strongly recommends supplementing source code; defers to the Instructions for Authors for recommended repositories | search excerpt of a library copy of the editorial (year not visible); journal page not read |
| Ecosphere (ESA) | ESA Open Research Policy: all underlying data and novel statistical code must be in a permanent public repository **on acceptance**, complete enough to replicate tables, graphs and statistics; ESA staff verify before release; Dryad recommended, fee coverage up to 10 GB for material curated after 2026-01-01; a Zenodo DOI is accepted for GitHub material (sentence cut off in the excerpt); data and code are not uploaded as supporting files for most article types. An older ESA page says public data were not strictly required for Ecology and Ecosphere and is marked "site has moved", so it is outdated | search excerpts of `esa.org/publications/data-policy/` (age about 2094 days by the tool), a 2026 third-party guide, and the old `esapubs.org` page |
| Behavioral Ecology (OUP) | **Raw data must be archived in a permanent public repository**; GitHub is not acceptable (no DOI, files can be altered); a link is required **at submission** and the repository is screened (data files as **CSV** plus a comprehensive README describing each file) before review; code is **not required** but welcome; citation in the references must be anonymised; follow Whitlock 2011 best practices; a data editor reviews the repository again before production; **from 2026-01-01 the journal no longer pays Dryad fees** (billed on acceptance); the paper is not published until the Dryad repository is published | search excerpt of `academic.oup.com/beheco/pages/information_for_authors` and an editorial on the data editor (2025) |
| Computers and Electronics in Agriculture (Elsevier) | **Option C** of Elsevier's research data guidelines: authors are **required** to deposit research data in a relevant repository, cite and link it in the article, or state why data cannot be shared; a **data statement at submission** is required; "research data" explicitly includes software, code, models and protocols; the aims and scope also say reuse of existing public datasets is treated as preliminary work. Elsevier's general policy page (read) encourages Mendeley Data and data availability statements; the page with the option definitions returned 404 | search excerpt of the ScienceDirect guide for authors (tool age 855 days) plus Elsevier policy page read in full |

Consequences for the skills: the same deposit often has to satisfy different rules (Behavioral Ecology wants data and README at **submission**, Ecosphere on **acceptance**,
CEA at **submission** as a statement, Springer journals a statement); Behavioral Ecology wants CSV and does not need code, Ecosphere and CEA want code too; GitHub alone is never
sufficient where a DOI is required; double-blind or anonymised citation rules matter for Behavioral Ecology (the README skill already omits names for double-anonymous journals).
Dryad costs changed in 2026 (journal-paid options ended at least for Behavioral Ecology, ESA coverage up to 10 GB), so cost is a decision for the user each time.
Open: read each journal's own page live (Playwright-free fetch was blocked for Springer, OUP and Wiley pages, so ask the user to paste the current text if a fetch fails), check
whether CEA co-submission of data via Data in Brief or Mendeley Data applies, and confirm the Behavioral Ecology and Sociobiology rule and its date.

### 10.2 Zenodo sandbox test: **not completed, token rejected**

- `zen4R` 0.10.6 `ZenodoManager$new(sandbox = TRUE, token = ..., logger = NULL)`: `checkUserAuthentication()` failed with HTTP 403 "Permission denied" on `user/records`. Methods exist for drafts, upload, versions and deletion (`depositRecord`, `uploadFile`, `publishRecord`, `depositRecordVersion`, `deleteRecord`, `reserveDOI` and more). `keyring_backend` defaults to `"env"`.
- Direct `httr2` probe, host `sandbox.zenodo.org` only: `user/records` 403 and `deposit/depositions` 403 with the bearer token, while the public `records` endpoint returned 200 (129,985 records). So the host is reachable, and the token is not accepted for authenticated calls. Likely causes (not distinguishable from the response): the token was created on zenodo.org instead of sandbox.zenodo.org (the two sites have separate accounts and tokens), or it lacks scopes (`deposit:write`, `deposit:actions` needed for create and publish; `deposit:read` for listing). No request was sent to the production site. The token was used in memory only: not written to any file, not stored by keyring, not committed.
- Security note: the token was pasted into the chat and appears in the R console history; it should be revoked in the sandbox account and replaced by one stored in `~/.Renviron` as `ZENODO_SANDBOX_TOKEN` (never in project files).
- Still to test once a working sandbox token exists: create a draft, set metadata, upload a small file, read it back, delete the draft (never publish except in the sandbox, and only if the test needs the version DOI behaviour); record the actual `zen4R` call sequence and gotchas; compare with a plain `httr2` route.

### 10.3 Zenodo sandbox test: **completed** with a working sandbox token (later in round 2)

The second token (created on sandbox.zenodo.org, original revoked by the user) authenticated. Used in memory only; nothing was written to disk or committed; only `sandbox.zenodo.org` was contacted.

| Step | Result |
|---|---|
| `ZenodoManager$new(sandbox = TRUE, token = ...)` | Connects, **but in zen4R 0.10.6 `sandbox = TRUE` points at `https://zenodo-rdm-qa.web.cern.ch/api`**, not `sandbox.zenodo.org`. Both hosts returned the same newest record id (625586), so they are the same backend, but the skill should pass `url = "https://sandbox.zenodo.org/api"` explicitly (zen4R then sets `sandbox` TRUE itself) so the target is visible in the code |
| Build a record | Works with `ZenodoRecord$new()`, `setTitle`, `setResourceType("dataset")` (`setUploadType` is deprecated), `setDescription`, `addCreator(name = "Family, Given")`, `setLicense("cc0-1.0")`. `addCreator(firstname, lastname, affiliation = "None")` failed with a 404 on the affiliation lookup (an affiliation string must match Zenodo's ROR-based vocabulary, or be omitted). `setAccessRight()` does not exist in this version |
| `zen$depositRecord(rec, publish = FALSE)` | Draft created (id 625588), DOI reserved (`10.5072/...` is the sandbox prefix, not a real DOI) |
| `zen$uploadFile(path, record = draft)` | Upload completed for a tiny CSV; a harmless warning "No bucket link for record" appears; progress bar noise |
| Read back | `zen$getDepositionById(id)` works and shows state `draft`; `record$getFiles()` does **not** exist (not a method), so the file list call still needs the right accessor (untested) |
| `zen$deleteRecord(id)` | Draft deleted, account back to 0 depositions. **Nothing was published**, so the 45-day edit window, new-version DOIs and concept DOI behaviour are still untested |

Gotchas for the skill: use the explicit sandbox URL; affiliations and creators need the new vocabulary-aware API; a draft deletion loses the reserved DOI (matches the docs); keep the token in an environment variable (`ZENODO_SANDBOX_TOKEN`) and pass it in code, never in project files; the console echoes the code, so a token typed literally into code ends up in R history.

### 10.4 User decision on large files (2026-10-23)

Large files will **not** live in GitHub repositories. They stay on the university servers and are either added from there to a data repository (deposited) or linked. Consequences:

- GIT skill: no Git LFS or DVC walkthrough; the repository holds code, small text data and lockfiles; data folders are ignored with the `dir/*` plus `!` pattern (negation under an excluded parent does nothing); a tracked manifest (path, size, sha256) records what the ignored data are; check for accidental large files with a size scan.
- RRD skill: the deposit assembles files from the server, so the manifest and checksum step matters more (the copy that reaches the repository can be verified against the server copy); the README must say where the original lives and which copy is deposited; check each repository's real limits live (Zenodo 50 GB and 100 files per upload through the form, Dryad 10 GB per file recommended and 2 TB per publication through the web interface, both read 2026-10-23).
- "Linked" data: which of Dryad, Figshare, Zenodo and the institutional repository allow an external link instead of an upload is **not established yet** (Zenodo's form takes files; related identifiers can point elsewhere; a link is not a preserved copy and may break). To check before the skill claims anything; a journal that demands archiving (Behavioral Ecology, Ecosphere, CEA) will usually need an actual deposit or an established domain repository, so linking is probably only acceptable for very large secondary files with a stated reason.
- Open: how the user's university server is reached from the analysis machine (mapped drive, SFTP) and whether it is backed up; whether the server copy is read-only; which institutional repository applies (Jyvaskyla or Aarhus).

## 11. Round 4 (2026-10-23): institutional archives and the build of `reproducible-research-data`

User decisions: external links are not a hard requirement; institutional questions are answered when the skill is used; research with Aarhus (ERDA) and Liège
as examples; fetch failures are handled at trigger time. The README refactor was done in the same session.

| Source | Status | What it gave |
|---|---|---|
| AU guidance portal for ERDA (medarbejdere.au.dk, `.../erda-guidance-portal`) | read | Open research data only (no personal, patentable, confidential, strategic or export-controlled data; SIF instead); frozen archives for permanent read-only publication, workgroup shares, share links; replication (15-minute snapshots kept 8 days, secondary site over 14 km daily, kept 30 days); no enforced quota; single-file transfer; rejected file-name characters; accounts expire. **No DOI procedure on the page** |
| ERDA user guide v8, April 2026 (`erda.au.dk/public/au-erda-user-guide.pdf`) | read via `curl` and `pdftotext -layout` (fetch tool returns binary) | Archive form (name, author, description, choose files, public yes/no, preview, finalize "permanently freezes"); copy not move; SFTP `io.erda.au.dk:2222`, WebDAVS, rsync, HTTPS, ssh keys; 2-factor recommended for mounting; the text has no "DOI" at all |
| ERDA front-page snippet (`erda.au.dk/about-snippet.html`) | search excerpt | "archiving and publication with AU DOIs" (wording copied from the Copenhagen page); conflicts with the guide, so DOI status is open |
| Roskilde University report (rucforsk.ruc.dk) | search excerpt | Says the (Copenhagen) ERDA is a file archive without DOI, metadata or licensing; older and about another ERDA instance |
| AU Library data-management pages | search excerpts | Names Zenodo (50 GB per dataset) and Mendeley Data as general repositories; Pure registers data |
| ULiège Dataverse (`dataverse.uliege.be`) | search excerpt of the home page | Institutional open research data repository (FAIR); sample citation with DOI prefix `10.58119/ULG` (ULiège Open Data Repository); login to add data; fetch of the page failed ("Network error") |
| ULiège Open Science site and Science Roadmap 2023-2028 | search excerpts | ORBi is the publications repository (DSpace, 2008); Dataverse for datasets with metadata, PIDs, licences; ORCID encouraged; a work-data storage system is promised |
| `lib.uliege.be/fr/uliege-dataverse` | search excerpt (FR); `/en/` returns 404 | Short purpose text only |
| Generic Dataverse guides and other installations (recherche.data.gouv.fr, Polytechnique Montréal, Dataverse docs) | search excerpts | CC0 default; DOI reserved at draft and activated at publication; private URL; cannot delete files after publication without deleting the dataset; **limits differ per installation, so none were carried over to ULiège** |

Not established: ERDA DOI behaviour; ULiège Dataverse eligibility, size limits, curation, licence default, versioning; whether either archive satisfies a given journal's "permanent public repository" wording; Figshare limits; any live journal page. These are written into `reproducible-research-data/references/repositories.md` as open questions for trigger time.

Local tests: see the Log entry in `HISTORY.md` (check_deposit and stage_deposit on a scratch deposit). Gotchas found: the session guard blocks creating a file named `.Renviron` even in a scratch folder (test with another secret-like name); NTFS cannot create case-only name pairs, so that check is untested; `list.files(all.files = TRUE)` returns the whole `.git` tree, so junk directories are collapsed to one finding and dropped from later checks; reading only the first 1 MB for the UTF-8 test needs the last 3 bytes dropped to avoid a false positive on a split multibyte character.

### 11.1 Follow-up: Aarhus has more than ERDA (user correction, same day)

| Source | Status | What it gave |
|---|---|---|
| AU Library data-management page (`library.au.dk/en/researchers/datamanagement`) | read (fetch) | "Selected general repositories": Pure, Zenodo, Figshare (free or institutional account), LOAR; points to re3data; **no Dataverse and no ERDA mentioned** |
| AU research-data-management page (`medarbejdere.au.dk/en/research-data-management`) | search excerpt | Names Dataverse (Harvard Dataverse figures: 2.5 GB per file, 1 TB), Zenodo (50 GB per dataset) and Mendeley Data |
| DeiC Dataverse service pages (`deic.dk/.../deic-dataverse`) and user guide | search excerpts | National Danish repository; universities have their own collections; DOIs; curation by the university; WAYF login; use requires agreements between the university and DeiC; excerpt (about 326 days old) said only Copenhagen could publish and others were reviewing agreements sent in October 2024; user guide: 1 GB per file, 100 files per dataset, auto-unzip, MD5 duplicate check, Private URL for reviewers, files open by default |
| KU Library tools page, Roskilde library guide (42 days old), DeiC FAIR pages | search excerpts | Datasets online at least 10 years after publication; all Danish universities offered DeiC Dataverse in 2026; a demo installation exists for training |
| re3data API (`/api/beta/repositories?query=`, `/repository/<id>`) | tested | Keyless XML. LOAR entry lists Aarhus University among its institutions (DOI and handle, versioning yes, last update 2024-01-09). ULiège Dataverse entry r3d100014621: DOI, CC licences, upload restricted to institutional membership, versioning yes, updated 2026-03-30. No DeiC Dataverse hit in the queries tried; "Aarhus" query returns unrelated entries |

Open: AU's current DeiC Dataverse access (ask AU Library or the local anchor point); whether an ERDA frozen archive gets a DOI; LOAR upload conditions and limits; ULiège Dataverse limits and curation.
Skill consequence: institution discovery is a mandatory workflow step, with re3data as a supplement to web search (`reproducible-research-data/scripts/find_repositories.R`).
