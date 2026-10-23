---
name: reproducible-research-data
description: 'Plans and checks the data and code deposit for one paper: what to deposit (raw and processed data, code, environment lockfiles, figure source data), folder layout and file names, licences and identifiers, which repository (Dryad, Zenodo, Figshare, institutional or national repositories, found by searching the institution, not only a stated list), what the target journal requires and when (at submission or at acceptance), data availability statements, a checksummed staging copy, and a pre-upload check script. Use when the user asks to prepare, assemble, check or publish a data and code deposit, whether a journal or repository accepts their data, a data availability statement, or what to put in the archive for a paper. The README and data dictionary belong to data-repository-readme, Git hygiene, tags and CITATION.cff to git-for-research-projects, and the re-runnable workflow to the pipeline skills.'
---

# Reproducible research data (the deposit for one paper)

This skill covers the deposit as a whole and the decisions around it. It does not write the README (that is `data-repository-readme`),
does not manage the Git repository (`git-for-research-projects`), and does not build the workflow that regenerates the results
(`r-reproducible-pipeline`, `python-reproducible-pipeline`). Repository and journal rules change, so every answer about them comes from
the live page, read in this session; the references only say what to look for and what was read on 2026-10-23.

**Owner's standing decisions:** large files stay on the university servers and are deposited from there (not stored in GitHub);
the assistant never uploads or publishes; whether a repository accepts a link instead of an upload is not needed here.

## Workflow

1. **Establish the case.** Ask in one batched question: paper and target journal(s) in submission order, whether the deposit is needed at submission or on acceptance, data types, whether any
   data are personal, confidential, third-party or locate sensitive species, where the originals live (server path or share), whether code is part of the deposit, **which institution(s) the
   authors belong to (current, previous, collaborating)**, and which repository the user prefers (if any). Do not guess missing answers.
2. **Discover the options; do not rely on the user's list.** Users usually know one institutional service (for example a file archive) and miss others (a national or institutional data
   repository with DOIs). Take the institution(s) from step 1 and search for everything it and its country offer: the library or research-data-management pages, national platforms,
   and the registry (`scripts/find_repositories.R`, re3data; incomplete, so also run web searches). Method and a worked example (Aarhus has ERDA, LOAR, a national DeiC Dataverse,
   Zenodo and Figshare pages; ERDA was the only one named at first) are in "Institution discovery" in [references/repositories.md](references/repositories.md). Present a table of what the user named and
   what else turned up, with source and access conditions, and let the user choose. Where sources disagree or the access status is unclear (rollout, agreements, eligibility), say so and ask the library.
3. **Read the live policies (do not skip).** Open the journal's data and code policy and the candidate repositories' file and limit pages
   (URLs in [references/journal-policies.md](references/journal-policies.md) and [references/repositories.md](references/repositories.md)).
   ERDA, the DeiC Dataverse and the ULiège Dataverse are worked examples there with what was and was not established.
   If a page cannot be fetched, say which and ask the user to paste the text. Name every page opened.
4. **Decide the contents and layout** with the table and tree in [references/contents-and-layout.md](references/contents-and-layout.md). Show the user the
   included/excluded list and the reason for each exclusion before anything is copied.
5. **Licences and identifiers** from [references/licences-and-identifiers.md](references/licences-and-identifiers.md). The user chooses; say what each choice implies
   (for example CC0 versus CC BY, repository-forced terms).
6. **Stage and check.** From the R console (path relative to the skills repo; use the skill's install path from another project):
   ```r
   source("reproducible-research-data/scripts/check_deposit.R")
   stage_deposit("path/to/source", "path/to/new-staging-folder")   # copies, verifies every file by sha256, writes MANIFEST.tsv
   check_deposit("path/to/new-staging-folder", repo = "dryad")      # or "zenodo", "figshare", "generic"
   ```
   `stage_deposit()` refuses a destination that exists and is not empty and refuses folders that contain each other (a copy onto itself can
   truncate files). `check_deposit()` flags junk and version-control folders, credentials and secret-looking text, hard-coded personal paths,
   odd file names, empty files, non-UTF-8 text, proprietary or binary formats, a missing README, code without a lockfile, size and count limits
   of the chosen repository profile, duplicates, and manifest mismatches. It returns findings, it fixes nothing; the limits in its profiles were
   read on 2026-10-23 and must be confirmed live. Findings are heuristics: read each one.
7. **README and code archive.** Hand the README to `data-repository-readme` and the Git side (tag, CITATION.cff, a clean `git archive` export) to
   `git-for-research-projects`. Run the clean-clone test described in `contents-and-layout.md` and report what happened.
8. **Statement.** Draft the data availability statement from [assets/data-availability-statements.md](assets/data-availability-statements.md) for the
   journal's wording; the user approves the text, and no DOI is inserted before it exists. The checklist is in [assets/deposit-checklist.md](assets/deposit-checklist.md).
9. **Publish (user's action) and close the loop.** The user presses publish. Then record the DOI in the paper, README, CITATION.cff and
   related-publication field, and check the uploaded files against the manifest.
10. **Report:** pages read (with dates) and pages that failed, checks run, findings left open, what is the user's decision, what was not tested.

## Rules

- **Never upload, publish, submit or pay for anything for the user.** A published deposit and its DOI are effectively permanent. A test goes to the Zenodo sandbox only,
  with the user's explicit permission, using a token from `ZENODO_SANDBOX_TOKEN` in `~/.Renviron`.
- **Never print, store or write a credential** (code, files, memory, commit messages, console history). If a token appears in the chat, tell the user to revoke it.
- **Policies come from live pages.** Do not state a limit, fee, deadline or journal rule from memory or from this skill's references as if current. Say what was read and when.
- **The user's list of repositories is a starting point, not the whole picture.** Always search the institution's and country's offer (step 2) and report what the user did not mention, including options that conflict with what they said; never drop a user-named option silently either.
- **Never invent** DOIs, licences, permit numbers, funding or author details. Unknowns stay `[TODO]` and go in the report.
- **Personal data and sensitive locations:** stop and ask; the decision (remove, aggregate, restrict, metadata only) is the user's.
- Stage from a clean export or a server copy, never from the live working folder (`.git`, caches, `.Renviron` end up in it). Do not copy a folder onto itself.
- A repository without a DOI or metadata may not satisfy a journal's "permanent public repository"; say so instead of assuming.
- The assistant's R session may not write outside the project, and cannot read the user's Zenodo or institutional logins; the user performs web steps.

## Reference files

- [references/repositories.md](references/repositories.md): Dryad, Zenodo, Figshare, institution discovery (method plus Aarhus and ULiège as worked examples: ERDA, LOAR, DeiC Dataverse, ULiège Dataverse), versions and DOIs, the Zenodo sandbox sequence, large files.
- `scripts/find_repositories.R`: `re3data_search()`, `re3data_search_many()` and `re3data_info()` query the re3data registry (keyless, read-only) for repositories by institution, city or country platform.
- [references/journal-policies.md](references/journal-policies.md): Oecologia, Behavioral Ecology and Sociobiology, Ecosphere, Behavioral Ecology, Computers and Electronics in Agriculture (search excerpts; read the live pages), timing, statement forms.
- [references/contents-and-layout.md](references/contents-and-layout.md): what to deposit, layout, names, formats, raw data, personal data, clean-clone test, splitting.
- [references/licences-and-identifiers.md](references/licences-and-identifiers.md): licences, DOI/ORCID/ROR, FAIR, machine-readable companions.
- [assets/data-availability-statements.md](assets/data-availability-statements.md) and [assets/deposit-checklist.md](assets/deposit-checklist.md).

## Tested and not tested

Tested on Windows 11 with R 4.6.0 (2026-10-23): `check_deposit()` on a scratch deposit with seeded defects (RAR file, missing README, token-like
assignment, secret-named file, personal path, empty file, Latin-1 CSV, space and non-ASCII names, `.git` folder, duplicates, code without lockfile);
`stage_deposit()` refusals (same folder, destination inside source, source inside destination, non-empty destination), a successful copy with
verification and manifest, and manifest tamper detection through `check_deposit()`. The Zenodo sandbox sequence in `repositories.md` was run with
zen4R 0.10.6 (nothing published). `find_repositories.R` was run against the live re3data API for Aarhus, Liège and Danish national queries (entries, fields, 404 handling;
it found LOAR and the ULiège Dataverse but not the DeiC Dataverse, and its search is fuzzy). The ERDA user guide (version 8) was read in full text; the DeiC
Dataverse pages and the ULiège Dataverse were seen only as search excerpts, a user-guide excerpt and a home-page excerpt. Not tested: re3data XML for entries with unusual
fields, rate limits, the web-search part of institution discovery as an automated step (it is done by the assistant), Aarhus' current DeiC Dataverse status, case-only name collisions (NTFS cannot create them), Linux or macOS, network drives and SFTP-mounted ERDA, very large trees
(whole files are hashed), the clean-clone procedure end to end, a real publication on any repository, Figshare limits, any journal's current page
(blocked on 2026-10-23), the `read_only` option beyond the Windows flag.

## Related skills

- `data-repository-readme`: the README and data dictionary for the deposit; repository README pages and templates.
- `git-for-research-projects`: the Git side of the code archive: ignore rules, secrets, tags, CITATION.cff, and the manifest of server-held data.
- `r-reproducible-pipeline`: the targets, renv and Quarto project that the clean-clone test runs.
- `python-reproducible-pipeline`: the uv and Snakemake counterpart.
- `manuscript-figures-ggplot`: figure source data that belong in the deposit.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were or were not done: why a policy page was read live instead of trusting the references, why a file is excluded, why a licence or repository is the user's choice, why staging copies and verifies instead of reusing the working folder, why the assistant does not publish, and what each check can and cannot see. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
