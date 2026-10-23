---
name: data-repository-readme
description: 'Writes and reviews README files for research data deposits (Dryad, Zenodo, Figshare, OSF, institutional repositories): looks up the target repository''s current README requirements online, drafts the README from a template, builds a data dictionary skeleton from the actual files, and lints the result for missing sections, undocumented files, placeholders and non-ISO dates. Use when the user asks for a README, data dictionary, codebook, or documentation for a dataset, data deposit, "Data for: ..." entry or supplementary data archive, or wants a README checked before upload. Choosing the repository, journal policy and the whole deposit belong to reproducible-research-data; Git hygiene, secrets and release tagging to git-for-research-projects.'
---

# Data repository README

Repository requirements change, so this skill gives a workflow and a template, and sends
you to the live guidance every time. `references/sources.md` lists where to look and what
was verified on 2026-10-23.

## Workflow

1. **Establish the target.** Ask which repository (Dryad, Zenodo, Figshare, OSF, institutional,
   domain-specific), which journal (data policy, double-anonymous review?), and whether the
   deposit is mostly data or mostly code. If unknown, use the generic structure and say so.
   Deciding *where* to deposit, what to include or which licence belongs to `reproducible-research-data`; settle it there and return with the target.
2. **Currency check (do not skip).** Open the repository's current README and file-requirement
   pages (URLs in [references/sources.md](references/sources.md)) with `webfetch` or
   `web_search`; for a journal, open its data policy. Compare their headings, mandatory
   elements, license rules, format rules and size limits with
   [assets/README_template.md](assets/README_template.md). Where they differ, follow the live
   page and adapt the template. In the reply, name the pages opened and any that failed to load.
   This is not a literature search, so the OpenAlex rule does not apply here; use OpenAlex only if
   you need to look up the user's related papers.
3. **Inspect the files.** From the R console:
   ```r
   source("data-repository-readme/scripts/draft_data_dictionary.R")  # path relative to the skills repo
   inventory_files("path/to/deposit")
   dd <- draft_data_dictionary("path/to/deposit/file.csv")
   cat(dictionary_to_markdown(dd), sep = "\n")
   ```
   Use the skill's actual install path if the working directory is a different project. The helper
   reports type, missing counts, ranges and flags (possible missing-value codes such as `-999`,
   non-ISO dates). It cannot know definitions or units; those stay `[TODO]`.
4. **Ask for what the files cannot tell you** (see "Facts the assistant cannot know" in
   [references/content-guide.md](references/content-guide.md)): variable meanings and units,
   missing-value codes, ethics/permits, funding, license, contact, related papers, collection
   methods. Ask in one batched question; do not invent answers.
5. **Draft** `README.md` in the deposit folder from the template, adapted per step 2. Keep the same
   section order if the user has other READMEs (consistency is a Cornell recommendation). Leave
   `[TODO ...]` where information is missing rather than guessing.
6. **Check:**
   ```r
   source("data-repository-readme/scripts/check_readme.R")
   check_readme("path/to/deposit/README.md", dir = "path/to/deposit", double_blind = FALSE)
   ```
   Fix errors (placeholders, undocumented files), review warnings. Findings are heuristics: the
   checker cannot tell whether a statement is true, and its section patterns are keyword guesses.
   Re-read the README against the live repository page once more.
7. **Report** what was drafted, what remains `[TODO]` and is the user's to fill, which sources were
   consulted (with the date), and which checks were not possible (for example template files that
   could not be opened).

## Rules

- Never fabricate definitions, units, permits, DOIs, citations, funding or license terms.
  Mark unknowns `[TODO]` and list them in the reply.
- The README must stand alone. No "see manuscript", no pasted abstract.
- Dates as `YYYY-MM-DD`. Software names with versions (`sessionInfo()`, `renv.lock`, `uv.lock`).
- If the journal is double-anonymous, omit names, emails and ORCIDs until acceptance (Dryad guidance).
- Avoid legal-sounding conditions ("must cite"); encourage citation instead (Dryad guidance).
- Do not upload, publish or submit anything for the user (deposit rules: `reproducible-research-data`). Publishing to Zenodo or Figshare is
  permanent in practice; the user decides.
- Personal data or sensitive-species locations: flag and ask before including them (what may be deposited: `reproducible-research-data`).
- If a file in the deposit is not in the README, either document it or tell the user it should be
  removed from the deposit.

## Optional CRAN helpers

All four were installed and tested on 2026-10-23 (details in
[references/optional-packages.md](references/optional-packages.md)). The skill's own helpers use base R,
so nothing has to be installed. Worth using: `skimr` 2.2.2 for column QA (shows `-999` codes), and
`frictionless` 1.3.0 to validate tables against explicit column types (Dryad runs the same framework
on uploads) and to write an optional `datapackage.json`. Not recommended: `dataspice` 1.1.1 (not a
README tool; wrote a given name `T` as `true`) and `codebook` 0.10.1 (HTML reports for labelled survey
data). CRAN installs are allowed; GitHub or R-universe installs need the user's permission.

## Reference files

- [references/sources.md](references/sources.md): URLs of README guidance and repository README pages (licences, identifiers, FAIR, limits and journal policies moved to `reproducible-research-data`),
  what was verified, and how to look for changes. Read this at step 2.
- [references/content-guide.md](references/content-guide.md): what each section needs, do/do not, field
  additions for behavioural ecology, tracking and chemistry data, and what the assistant must never infer.
- [references/optional-packages.md](references/optional-packages.md): tested results for skimr, frictionless,
  dataspice, codebook, with code.
- [assets/README_template.md](assets/README_template.md): full Markdown template (Cornell/Borealis style, tiers
  marked) with `[TODO]` placeholders. [assets/README_dryad.md](assets/README_dryad.md): four-section variant that
  mirrors Dryad's template; use it for Dryad deposits and run `check_readme(..., profile = "dryad")`.
  [assets/README_software.md](assets/README_software.md): variant for deposits that are mainly code (Cornell
  software template structure).

## Tested and not tested

The Dryad, Cornell (data and software), UBC and Borealis template material was read in full on 2026-10-23
(see `references/sources.md`). Tested on Windows with R 4.6.0 on a synthetic deposit with seeded defects: `inventory_files`,
`draft_data_dictionary` (flags `-999`, mixed date formats), `dictionary_to_markdown`, and
`check_readme` (placeholders, undocumented and ghost files, non-ISO dates, "see manuscript", legal wording,
undefined abbreviation, double-blind identifiers); found and fixed two bugs in the first run. Not
tested: Excel, HDF5 or RData inputs (the dictionary helper reads delimited text only), non-English READMEs,
large files (the whole table is read into memory), a real submission to any repository, and the
template against each repository's own template files.

## Related skills

- `animal-behaviour-tracking-analysis`: the typical behavioural data (DLC outputs, per-animal metrics) to document in a deposit.
- `manuscript-figures-ggplot`: figures that use the same column labels as the data dictionary.
- `python-reproducible-pipeline`: a pinned, re-runnable workflow (uv lock, Snakemake) to deposit with the data so the results can be regenerated.
- `r-reproducible-pipeline`: the R counterpart (targets, renv lockfile, Quarto report) to deposit with the data.
- `reproducible-research-data`: the deposit as a whole: what to deposit, which repository and journal rules apply (and when), licences and identifiers, a checksummed staging copy and pre-upload checks.
- `git-for-research-projects`: the repository side of a deposit: what stays out of Git, a checksum manifest of server-held data, tagging a version and CITATION.cff.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were or were not done: why a repository page was consulted, why a field was left `[TODO]` instead of inferred, why a checker finding is a heuristic, and why a choice such as license or deposit scope is theirs. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference (for example `references/sources.md`) for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
