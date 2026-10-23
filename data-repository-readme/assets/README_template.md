# [Dataset title: descriptive, not identical to the paper title, e.g. "Data for: <paper title>"]

<!-- Delete every HTML comment before deposit. Replace every [TODO ...]. If something does not apply, write "Not applicable" instead of deleting the heading, so readers know it was considered. Structure follows Cornell Data Services, UBC/Borealis and Dryad guidance (see references/sources.md in the skill). Borealis minimum tier = title, creators, summary, contact, license, DOI, methodology, related publications, software. Everything else below is its "enhanced" (recommended) tier. -->

This README was generated on [TODO YYYY-MM-DD] by [TODO name] and last updated on [TODO YYYY-MM-DD] by [TODO name].

## 1. General information

- **Title:** [TODO]
- **Summary:** [TODO: 3-6 sentences. Why the data were collected, what was recorded, how it is structured, what it can be used for. Written for a reader outside your subfield. Do not paste the manuscript abstract.]
- **Creators (citation order):** [TODO Name, affiliation, ORCID; role such as author, principal investigator, co-investigator]
- **Contact:** [TODO at least two contacts (Cornell, UBC): name, institution, institutional email; add a project or group address if the person may move. Say who answers enquiries (corresponding author)]
- **Other contributors:** [TODO name, affiliation, role (data collection, software, coordination); ORCID or ROR where possible, or "none beyond the creators"]
- **Persistent identifier (DOI):** [TODO or "pending, will be updated after publication"]
- **Related publication(s):** [TODO full citation with DOI, or "none yet"]
- **Date(s) of data collection:** [TODO YYYY-MM-DD to YYYY-MM-DD; list phases separately; this is not the deposit date]
- **Time period the data cover:** [TODO only if different from collection dates, e.g. historical records; ISO 8601]
- **Location:** [TODO site, coordinates or region, optionally a bounding box; say whether this is where data were collected, where the study population lives, or where the phenomenon occurs; see note on sensitive species in the skill]
- **Funding:** [TODO funder and grant number, or "none"]
- **Keywords:** [TODO 5+, field and method]
- **Language:** English
- **Version and date of this README:** [TODO v1.0, YYYY-MM-DD]

## 2. Sharing and access

- **License:** [TODO full name and version, e.g. CC0 1.0 Universal / CC BY 4.0]
- **Restrictions:** [TODO or "none"]
- **Suggested citation:** [TODO all authors, year, title, repository, version if any, DOI as a resolvable URL]
- **Other locations of these data or code:** [TODO links, or "none"]
- **Related or ancillary datasets:** [TODO links and how they relate, or "none"]
- **Related data collected but not included here:** [TODO or "none"]
- **Sources the data were derived from:** [TODO full citation or link and the role of each source, or "none, all data newly collected"]

## 3. Files and structure

<!-- Every file in the deposit must appear here. Describe relationships (e.g. which script reads which file, which file is raw and which processed). -->

```
[TODO folder tree]
```

| File | Contents | Format | Created (YYYY-MM-DD) | Produced by |
|---|---|---|---|---|
| `[file]` | [TODO] | [csv, UTF-8, comma-separated] | [TODO] | [collected / script `x.R`] |

File naming convention: [TODO pattern and one example, or "Not applicable"]

## 4. Methods

- **Study design and data collection:** [TODO design, instruments, protocol, links to protocols; animal/human ethics approval and permit numbers where relevant]
- **Processing from raw to the files provided:** [TODO steps, exclusions, transformations, order of scripts]
- **Environmental or experimental conditions:** [TODO or "not applicable"]
- **Standards and calibration:** [TODO or "not applicable"]
- **Quality assurance:** [TODO checks performed, how outliers/low-quality records are flagged and what the flag codes mean]
- **Known limitations and caveats:** [TODO]
- **People involved in collection and processing:** [TODO or "see creators"]

## 5. Software and environment

- **To open the data:** [TODO e.g. any text editor or spreadsheet; no proprietary software needed]
- **To reproduce the analysis:** R [TODO version], Python [TODO version], OS [TODO]; packages and versions in `[TODO renv.lock / requirements.txt / sessionInfo.txt]`
- **How to run:** [TODO order of scripts, entry point, expected run time]

## 6. Data dictionary

<!-- One subsection per tabular file. Spell out abbreviations, give units, define categories and codes. State what an empty cell and each missing-value code mean. -->

### `[file.csv]` ([TODO] rows, [TODO] variables)

Missing values: [TODO e.g. "NA = not measured; empty cells do not occur"]

| Variable | Description (full name, definition) | Unit | Type / allowed values |
|---|---|---|---|
| `[col]` | [TODO] | [TODO or none] | [TODO] |

### Abbreviations and codes

<!-- Glossary of abbreviations, acronyms and non-standard terms in the files or this README, including codes for missing, null or not-applicable values (for example -999, NA, ND). Name standard classification schemes with version. -->

| Term / code | Meaning |
|---|---|
| [TODO] | [TODO] |

## 7. Version and changelog

- **Current version:** [TODO v1.0] ([TODO YYYY-MM-DD]); links to earlier versions: [TODO or "none"]
- [TODO YYYY-MM-DD v1.0: first release; for later versions say what changed (errors corrected, variables added, records updated)]
