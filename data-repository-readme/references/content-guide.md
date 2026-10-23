# Content guide: what goes in each section and why

## Contents

- [Principles](#principles)
- [Section by section](#section-by-section)
- [Do and do not](#do-and-do-not)
- [Field-specific additions (behavioural ecology, tracking, chemistry)](#field-specific-additions)
- [Choosing format, scope and number of READMEs](#format-and-scope)
- [Facts the assistant cannot know](#facts-the-assistant-cannot-know)

The structure follows Cornell, Dryad and Borealis guidance (see `sources.md`). The
"field-specific additions" section is the skill author's suggestion, not repository policy.

## Principles

1. A README must let a stranger interpret the files without the paper. Dryad publishes
   datasets as independent publications, so "see manuscript" is not acceptable.
2. It complements repository metadata (title, authors, license, funding in the deposit
   form); it does not replace it. Fill in both, because the README travels with the
   download while the form drives discovery.
3. Describe, do not persuade. Report limitations and caveats.
4. Write it early and keep it updated (Harvard, UBC advice), then finalise at deposit.
5. Only state what was verified. Anything the files cannot show (definitions, units,
   permits, who collected what) comes from the user.

## Section by section

| Section | Minimum content | Common mistake |
|---|---|---|
| Title, summary | Descriptive title; why, what, structure, possible uses | Title identical to paper title; pasted abstract |
| Creators, contact | Names in citation order, affiliation, ORCID, a contact that outlives a postdoc contract | Personal email only |
| Identifier, related publications | Dataset DOI (or "pending"), full citations with DOI | Forgetting to update after DOI minting |
| License, citation | Full license name and version, suggested citation | "Free to use"; no version |
| Collection | Dates (ISO 8601), place, design, instruments, protocols, ethics/permits | "As described in the paper" |
| Processing | Raw to deposited files, exclusions, order of scripts | Raw files not included and not explained |
| Software | Names and versions (R, Python, packages), OS, lockfile name | Only "R" with no version |
| Files | Every file listed, with relationships and which are raw/processed | Files in the deposit missing from README; README lists files that do not exist |
| Data dictionary | Full variable names, definitions, units, allowed values, missing-value codes, meaning of empty cells | Abbreviations without expansion; units omitted; `-999` unexplained |
| Version and changelog | Version, date, what changed, links to earlier versions | None |
| Header | "Generated on / updated on" with names (Cornell, UBC) | Undated README |

Tiers (Borealis): the minimum is title, creators, summary, contact, license, DOI, methodology, related publications and software, and the rest; funding, geography,
collection dates, time period covered, data sources, contributors, citation, versioning,
abbreviations and the full data dictionary are its "enhanced" tier. Aim for the minimum always and the
enhanced items wherever they apply; `check_readme()` reports missing enhanced items as info only.

## Do and do not

Do (all from the sources unless noted):

- Use Markdown or plain text, with headings, tables and short paragraphs.
- Explain nested structures (sheets in a workbook, objects in an `.rds`/`.RData`, groups in an HDF5 file).
- Explain special formatting such as colour coding in Excel, and scoring keys for categorical data.
- Define the relationship between raw, intermediate and final files and the scripts that link them.
- Provide a clean CSV alongside any formatted Excel file (Dryad).
- Format all READMEs in one project identically (Cornell).

Do not:

- Assume abbreviations, units or scoring keys are understood the same way everywhere (Dryad).
- Paste the manuscript's abstract or methods in place of describing the data (Dryad).
- Include author names, emails or ORCIDs when the target journal uses double-anonymous review (Dryad); add them after acceptance.
- Word reuse conditions as legal demands ("must", "required"), especially under CC0; encourage citation and contact instead (Dryad).
- Include personal data. Human-subjects data must be de-identified; consult the repository policy.

## Field-specific additions

Suggestions for the user's usual data types; adapt to the repository.

- **Animal behaviour trials:** species, strain or origin, sex, age class, housing, number of animals vs number of observations (so readers do not mistake repeated measures for independent samples), unit of replication, trial order and randomisation, observer blinding, arena dimensions, ethics approval number and permit. Give the animal ID column and say whether it is unique across sessions.
- **Video tracking (DeepLabCut and similar):** model version or snapshot, bodyparts, likelihood threshold, frame rate, pixel-to-cm calibration, coordinate origin and y-axis direction, which files are raw `.h5/.csv` and which are cleaned. Say whether raw videos are included and why or why not.
- **Chemistry (GC-MS and similar):** instrument and column, method file, peak-picking settings and software versions, internal standards, units (for example ng per sample), blanks, detection limit and how values below it are coded.
- **Field data and time series:** coordinates and datum, how sites are identified, trapping effort (trap nights), sampling dates in ISO 8601, and whether locations of sensitive or protected species are deliberately generalised (Dryad asks that species data not endanger vulnerable populations).
- **Statistical outputs:** if model objects or results tables are shared, name the script that creates them and the package versions.

## Format and scope

- Name it `README.md` (Dryad wants Markdown) or `README.txt`; place it at the deposit root.
- One README per logical cluster of files (Cornell). For one deposit with several data
  tables, use one README with a data dictionary per table; add sub-folder READMEs only
  if sub-folders are used independently.
- Data README vs software README (Cornell): if the deposit is mainly code, use the
  software README guide; if mainly data with analysis scripts, use the data README and add a
  short "Code and software" section. For GitHub-archived code, consider CITATION.cff.
- Large machine-readable dictionaries: a `data_dictionary.csv` or `datapackage.json`
  can sit next to the README. Keep the README as the human entry point.

## Facts the assistant cannot know

Never fill these by inference; ask the user or leave `[TODO]`:

- variable definitions and units (even if a column is named `mass_g`, confirm),
- missing-value codes and what empty cells mean,
- permits, ethics approvals, funding, grant numbers,
- who collected, processed or analysed what,
- licenses and restrictions (the user, co-authors, funders and repository decide),
- DOIs, citations of related papers (verify with the user; if searching for papers, use the OpenAlex workflow from the user's memory, not general web search),
- whether raw data may legally or ethically be shared.
