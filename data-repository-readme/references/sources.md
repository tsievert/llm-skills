# Sources and how to re-check them

Requirements differ per repository and change over time. Last checked: 2026-10-23.
Treat this file as a map of where to look, not as the rule. Always open the live page for
the repository or journal the user is targeting (workflow step 1 in `SKILL.md`) and let it
override anything here.

## Contents

- [Generic guidance (repository-independent)](#generic-guidance)
- [Repository-specific guidance](#repository-specific-guidance)
- [Standards a README should point to](#standards) (moved)
- [What was verified and what was not](#verified)
- [How to look for changes](#how-to-look-for-changes)

## Generic guidance

| Source | URL | Authoritative for |
|---|---|---|
| Cornell Data Services, "Writing READMEs for Research Data" | https://data.research.cornell.edu/data-management/sharing/readme/ | The most widely copied structure: general information, data and file overview, sharing and access, methodology, data-specific information (variables, units, missing codes). Templates: https://hdl.handle.net/1813/116815.2 (data), https://hdl.handle.net/1813/116816.3 (software). Cornell also separates a "software README": https://data.research.cornell.edu/data-management/sharing/writing-readmes-for-research-code-software/ |
| UBC "Create a README File" (Borealis minimum and enhanced elements) | https://ubc-library-rc.github.io/rdm/content/03_create_readme.html | A defined minimum of nine elements: author/creator, title, description, contact, license, DOI, research methodology, related publications, software/tools with versions. Notes that the README complements, not replaces, repository metadata. |
| Harvard Biomedical Data Management, "README Files" | https://datamanagement.hms.harvard.edu/collect-analyze/documentation-metadata/readme-files | Short plain-language rationale, minimum vs comprehensive README, start early and update. |
| Figshare best practice and Figshare+ guide | https://info.figshare.com/user-guide/best-practice-for-managing-your-outputs-on-figshare/ and https://info.figshare.com/user-guide/figshare-plus-user-guide/ | What a Figshare README should cover, title advice (do not make it identical to the paper title), machine-readable license requirement. |
| Smithsonian Figshare README template | https://confluence.si.edu/pages/viewpage.action?pageId=163154628 | Compact list including citation format, license, file list, data dictionary, code installation notes. |

### What the template files themselves add (read in full 2026-10-23)

Files read: Cornell data README template (CC0; https://ecommons.cornell.edu/server/api/core/bitstreams/755feeed-908c-4a27-818c-63377efde1b8/content),
Cornell software README template (https://ecommons.cornell.edu/server/api/core/bitstreams/6fc917d4-301f-4883-8df4-8eac9fad7fe6/content),
UBC template and sample (https://ubc-library-rc.github.io/rdm/content/exercise_files/README_template_v02.txt and `README_sample_v02.txt`),
and the Borealis working-group report (Final_Report.pdf in https://doi.org/10.5683/SP3/CJ5X5O, March 2026, text extracted with `pdftotext`).
The plain `ecommons.cornell.edu/bitstreams/<id>/download` links return HTTP 405 to the fetch tool; the REST path above worked with `curl`.

New or sharper points compared with the web pages alone:

- Header line "README generated on [date] by [name]" (Cornell, UBC), with an "updated on" part (UBC).
- At least two contacts (Cornell, UBC), and who answers enquiries.
- Cornell data template: links/relationships to ancillary datasets, related data collected but not included, whether the data derive from another source, environmental/experimental conditions, people involved, number of variables and rows per file, specialised formats and abbreviations.
- Borealis defines two tiers. Minimum (nine): author/creator, title, description, contact, license, DOI, methodology, related publications, software/tools. Enhanced (thirteen, "should be included where available and applicable"): variable list/data dictionary (name, description, unit, data type, permitted values, missing codes), file list/directory (incl. naming conventions), data collection and processing, abbreviations/codes (including -999, NA, ND), contributors with roles (ORCID/ROR), date of collection, funding (agency, award title, number), geographic coverage (note what the location refers to), recommended citation (all authors, year, title, repository, version, DOI as resolvable URL), data sources (full citation and role), time period covered (distinct from collection date), version information.
- The Borealis report says the README should align with but not be limited to repository metadata fields, and should let users interpret data without inspecting every file.
- Cornell software template: version (semantic), size, installation, usage with expected output, tests, known issues, limitations, license file, contributors and roles. See `assets/README_software.md`.
- The UBC sample uses encouraging wording ("Feel free to contact ...") rather than legal demands.

Not obtainable: the Borealis `.xlsx` data dictionary and the 20 analysed example READMEs (not downloaded).

## Repository-specific guidance

| Repository | URL | What to check |
|---|---|---|
| Dryad: README help | https://datadryad.org/help/submission_steps/readme | Required README; the four generator sections (data description, files and variables, code and software, access information); Markdown. |
| Dryad: good data practices | https://datadryad.org/help/guides/best_practices | Details to include; do not include identifying information for double-anonymous review; CC0 requirement. |
| Dryad: author blog on README quality | https://blog.datadryad.org/2023/10/18/for-authors-creating-a-readme-for-rapid-data-publication/ | The Do/Do not list (no "see manuscript", do not paste abstract/methods, avoid legally phrased attribution demands, define hierarchy of nested contents). Dated 2023-10-18, so confirm it still matches the help pages. |
| Dryad: README template | https://datadryad.org/docs/README.md | Read in full 2026-10-23. Title, a link to the dataset on Dryad, a brief summary, then three or four sections: "Description of the data and file structure" (relationships between files, missing-data codes, abbreviations; assume readers new to the field), "Sharing/Access information" (other locations, sources the data derive from), "Code/Software" (optional; scripts, software with versions including packages, workflow order). It has no author, contact, license or funding section: those are entered in the submission form. `assets/README_dryad.md` mirrors these headings. |
| Dryad: file requirements | https://datadryad.org/help/requirements/files | CC0 compatibility, accepted formats, size limits, PII rules. Limits change; read the live page. |
| Zenodo: record metadata | https://help.zenodo.org/docs/deposit/about-records/ and https://help.zenodo.org/docs/deposit/describe-records/ | Which fields live in the form (title, creators, description, license, keywords, funding) and are therefore not to be duplicated only in the README. Zenodo's own pages disagree on file edits after publication (the about-records page says files cannot be modified, the create-upload page mentions a 45-day window), so finish and check the README before publishing and confirm the current rule. |
| Zenodo: Ghent University guide | https://onderzoektips.ugent.be/en/tips/00002267/ | Practical advice: description is not the paper abstract; use a README for file organisation. Secondary source. |
| Figshare | see above | Title, description, keywords, license are mandatory form fields; README is an uploaded file. |
| Others (OSF, Mendeley Data, institutional repositories such as ERDA or a Dataverse (see `reproducible-research-data`), domain repositories such as GBIF, ENA, Movebank, MorphoSource) | search "[repository] README requirements" and the repository's help centre | Domain repositories often require metadata standards instead of or in addition to a README (for example Darwin Core, EML, MIAME). Ask the user. |

## Standards

The README itself needs only: dates as ISO 8601 (`YYYY-MM-DD`; Cornell and UBC both recommend it), the licence named in full with its version, ORCID for people and ROR for organisations where known, and the
dataset DOI once it exists. The broader material (licence choice, identifiers, FAIR, controlled vocabularies, machine-readable companions
such as `datapackage.json` and CITATION.cff) moved to the `reproducible-research-data` skill,
`references/licences-and-identifiers.md`. Repository limits, institutional archives (ERDA, ULiège Dataverse) and journal data policies are
in its `references/repositories.md` and `references/journal-policies.md`; this file keeps only the README pages of the repositories.

## Verified

Read on 2026-10-23: Cornell page (content and template links), Dryad help pages and blog
(via search excerpts and page fetches), UBC/Borealis page, Harvard page, Figshare guides,
Zenodo help, the Dryad template file itself (https://datadryad.org/docs/README.md; the
guessed URL `README-template.md` returns 404, so use the linked one), the Cornell data and software
template files, the UBC template and sample, and the Borealis report. Not verified: the Borealis
spreadsheet and example READMEs, the FAIR principles page, and any journal-specific data policy. Journal policies (data
availability statements, double-blind rules, mandatory repositories) must be read from the
journal's instructions for authors.

## How to look for changes

1. Open the target repository's README help page and compare headings with `assets/README_template.md`.
2. Open the repository's file-requirements page for license, formats, size, PII rules.
3. If the user names a journal, find its data availability policy (journal "instructions for authors" or the publisher's research-data policy page).
4. Search the web for "[repository] README guidance" restricted to the last year, and look at the dates on help pages and blogs.
5. Record in the reply which pages were opened and their date; if a page could not be read, say so.
6. If the live guidance contradicts this skill, follow the live guidance and tell the user so the skill can be updated.
