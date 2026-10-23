# Repositories: what to check and what was read

Facts below were read on 2026-10-23 and change. Treat them as a map and as the questions to ask, then open the live page
(workflow steps 2 and 3). If a page cannot be fetched, say so and ask the user to paste the relevant text; do not fill the gap from memory.

## Contents

- Questions that decide the repository
- Dryad
- Zenodo
- Figshare
- Institutional archives: institution discovery, Aarhus (ERDA, DeiC Dataverse, LOAR) and ULiège as worked examples
- Versions, DOIs and what cannot be undone
- Testing an upload safely (Zenodo sandbox)
- Large files and linked data

## Questions that decide the repository

1. Does the journal name a repository, require a DOI, or exclude some (Behavioral Ecology does not accept GitHub alone)? See `journal-policies.md`.
2. Data and code together, or data only? Dryad hosts code through Zenodo; Zenodo takes both; Dryad is data-first.
3. Size and file count against the live limits (below).
4. Cost and who pays (changed in 2026 for Dryad, see `journal-policies.md`).
5. Licence forced by the repository (Dryad: CC0).
6. Personal data or protected-species locations: many institutional archives forbid personal data (ERDA does).
7. Longevity and a DOI that the journal will accept as "permanent public repository". An institutional file archive without a DOI or
   metadata may not meet the journal's wording; ask the journal or check its list.

## Dryad

Read: https://datadryad.org/help/requirements/files (2026-10-23).

- Accepts all research data but only files compatible with a CC0 waiver. Code and software can go through Dryad and are then hosted on Zenodo (released with the dataset).
- No personally identifying information. CSV, TSV or ODF preferred for tables; README in Markdown. RAR is not accepted.
- Recommended maximum 10 GB per file; 2 TB per publication through the web interface.
- README guidance: `data-repository-readme` (`references/sources.md`).
- Fees: see `journal-policies.md` (2026 changes). A fee decision belongs to the user.

## Zenodo

Read: https://help.zenodo.org/ docs "Create new upload" and the GitHub integration pages (2026-10-23).

- Up to 100 files and 50 GB per upload through the form. Embargo and restricted access exist.
- After publishing, files can be changed only within 45 days; metadata any time. Zenodo's own pages disagree on file edits (the about-records page says files cannot be modified), so confirm on the live page before publishing.
- A reserved DOI is lost if the draft is deleted.
- Each published version gets its own DOI and there is a concept DOI that always points to the latest version. Do not reuse the article DOI for a supporting dataset.
- GitHub integration: a release of a public repository is archived and gets a DOI. If a `.zenodo.json` file exists Zenodo uses only it and ignores `CITATION.cff`. Git side: `git-for-research-projects`.
- Sandbox for tests: https://sandbox.zenodo.org (separate account and token from production).

## Figshare

Read only as guidance pages for READMEs (`data-repository-readme` sources). **File size and quota limits, curation steps and fees were not established.** Title, description, keywords and licence are mandatory form fields; read the live "best practice" and upload pages before advising on limits. The user already publishes "Data for: ..." entries there, so ask what worked before.

## Institutional archives

### Institution discovery (do this at trigger time, before recommending anything)

The user's own list is incomplete. At Aarhus, ERDA was the service first named, yet the AU Library page lists other places (Pure, Zenodo, Figshare, LOAR),
and a national DeiC Dataverse exists that also serves Aarhus (see below). The same will be true elsewhere. Method:

1. Ask for every institution involved: current, previous and collaborating, and the country.
2. Search the web for each (fresh searches, not memory): "`<institution>` research data repository", "`<institution>` library data publishing DOI",
   "`<institution>` Dataverse" (or Figshare, Zenodo community, Pure), and "`<country>` national research data repository". Open the library or
   research-data-management page, not only search snippets.
3. Query the registry: `source("reproducible-research-data/scripts/find_repositories.R")`, then `re3data_search_many(c("<institution>", "<city>", "<national platform>"))` and
   `re3data_info("<id>")` for the interesting ones (DOI system, upload restriction, versioning, licence, last update). re3data search is fuzzy (an "Aarhus" query returned unrelated
   hits) and incomplete (the DeiC Dataverse did not appear in the queries tried on 2026-10-23, while the ULiège Dataverse did), so it supplements the web search and never replaces it.
4. Make a table: option | named by user? | what it is | DOI | who may deposit and current access status | limits | source and date. Mark what is established and what is not.
5. Flag conflicts and status uncertainty (for example a national platform whose rollout to a university is unclear) and ask the library or the local data-management support.
6. Ask whether the journal accepts each option as a "permanent public repository". A file archive without DOI or metadata may not meet that wording.
7. Let the user choose. Treat an institutional copy as the original and the public repository as the published copy unless the user says otherwise (see "Large files").

### Aarhus University: worked example (read 2026-10-23)

| Option | What it is | Status of the evidence |
|---|---|---|
| ERDA | AU file archive for **open** research data; frozen read-only archives; no personal or confidential data (details below) | Portal and user guide read; **DOI not established** |
| DeiC Dataverse (https://dataverse.deic.dk/) | National Danish repository; each university has its own Dataverse collection; DOIs, licence, reuse terms, curation by the university; the KU library says datasets stay online at least 10 years after publication | DeiC pages and user guide read as excerpts. Limits stated in the user guide: **1 GB per file, 100 files per dataset**, zip files are unpacked, files are open by default, a **Private URL** lets editors and reviewers see a draft without an account. **Access status for AU is unclear:** the DeiC service page (excerpt about 326 days old) said only the University of Copenhagen could publish and other universities were still reviewing agreements (sent October 2024); a Roskilde University page (42 days old) says all Danish universities will get access in 2026. A DeiC-hosted demo exists for training. AU's own research-data pages (112 days old) mention "Dataverse" (as Harvard Dataverse) but the AU Library page does not list DeiC Dataverse. Ask AU Library or the local anchor point whether AU researchers can publish there now |
| LOAR (https://loar.kb.dk/) | Library Open Access Repository run with the Royal Danish Library; the AU Library lists it as a storage service for Danish research data (CC licence expected); re3data lists Aarhus University among its institutions, DOI and handle, versioning yes, upload by registration | AU Library page read; re3data entry updated 2024-01-09; upload conditions and limits not read |
| Pure (https://pure.au.dk/) | AU registration system for publications, projects and data; a register, not a data repository | AU Library page |
| Zenodo, Figshare, Mendeley Data, Harvard Dataverse | General repositories named on AU Library or AU research-support pages (Zenodo 50 GB per dataset; AU page excerpts also give 2.5 GB per file and 1 TB total for Harvard Dataverse and 10 GB per dataset for another service; read the live pages) | Excerpts only; read the live pages |
| Dryad | Not named on the AU pages seen; often the journal-preferred choice in ecology | See the Dryad section |

The lesson for the skill: a user who says "we use ERDA" may have a national Dataverse, a library repository and a journal-preferred repository that fit the journal better. Report them all and let the user decide with the library's answer on access.

### ERDA, Aarhus University (read: AU guidance portal and the ERDA user guide, version 8, April 2026)

- Sources: https://medarbejdere.au.dk/en/administration/it/guides/datastorage/erda-guidance-portal ; user guide https://erda.au.dk/public/au-erda-user-guide.pdf (a 33-page PDF; read with `pdftotext`, the fetch tool shows only binary); ERDA front page https://erda.au.dk/.
- Purpose: storing, sharing and archiving **research data that can be open**. It is **not** for personal data, data certain to be patented, confidential or third-party IP material, strategically sensitive data, export-controlled data, or anything that must be protected from unauthorised access; the guide points those to SIF instead.
- Frozen archives: the guide describes "Archives" where you create a named archive with author and description, pick files from ERDA or upload, choose whether it is publicly available, preview, and **finalize**, which "permanently freezes" it. Archiving copies the files; the working files stay editable. The portal calls this the easiest way to publish permanently as read-only.
- **DOI: not established.** The ERDA front-page text mentions publication "with AU DOIs", but the portal page and the user guide (searched for "doi") do not describe a DOI procedure, and a Roskilde University report says an ERDA file archive "offers neither identification (DOI), metadata, licensing" (that report concerns the Copenhagen ERDA and is older). Ask AU Library or the local anchor point whether a frozen archive gets a DOI, and whether the journal accepts it. If not, ERDA is storage and archive for the originals, and a repository with a DOI (DeiC Dataverse if open to AU, LOAR, Zenodo, Dryad) is the published copy.
- Access and transfer: SFTP (the guide gives `io.erda.au.dk` port 2222 for mounted access), WebDAVS, rsync and HTTPS; ssh keys for transfers; web upload handles single files, so zip or tar folders first. The guide recommends 2-factor authentication for mounted access.
- Names: certain characters are rejected in file names (the portal lists `< > { | } * ? [ ]`); `check_deposit()` flags them.
- Limits and backup (portal): no enforced space quotas, contact the administrators for several terabytes; snapshots every 15 minutes kept 8 days on the primary site, daily copy to a secondary site (more than 14 km away), secondary snapshots kept 30 days; individual files cannot be recreated by administrators from replication. Treat ERDA as storage plus archive, not as your only copy of irreplaceable raw data unless AU confirms its backup terms.
- Accounts expire unless renewed (AU users extended at login or by sign-up; external users renew yearly). A permanent deposit should not depend on an account staying alive: ask who owns an archive after the depositor leaves.

### ULiège (University of Liège): worked example (read: search excerpts, re3data entry and the home page excerpt; most pages blocked)

- ULiège Dataverse (https://dataverse.uliege.be/, "ULiège Open Data Repository"): described as the institutional open research data repository (FAIR). A sample dataset citation on the home page shows DOI prefix `10.58119/ULG`. Login is needed to add data.
- re3data entry (r3d100014621, last updated 2026-03-30): DOI as PID system, CC licences, **upload restricted to institutional membership**, versioning yes. A registry entry can lag behind the repository; confirm on the repository's pages.
- ORBi (https://orbi.uliege.be/) is the institutional repository for **publications** (DSpace, since 2008), a different system. Papers go to ORBi, datasets to the Dataverse. The library's Dataverse page (https://lib.uliege.be/fr/uliege-dataverse) returned only a short purpose text; its `/en/` URL returned 404.
- The Open Science roadmap (2023-2028) commits the university to a Dataverse for datasets with structured metadata, permanent identifiers and licences, and encourages ORCID.
- **Not established for ULiège:** file size limits, curation or review before publication, default licence, rules on personal data, how versions work. Ask the library (the Dataverse page lists a contact) or have the user paste the deposit guide.
- General Dataverse behaviour seen on **other** installations (verify for ULiège before using): a DOI is reserved at draft time and activated at publication; a draft can be shared by a private link; a licence applies to the whole dataset (CC0 is a common default); files cannot be deleted after publication without deleting the dataset (and its DOI); adding files after publication creates a new version. Limits differ per installation; do not carry them over.
- Also check for national platforms in Belgium or the Federation Wallonia-Brussels, and Zenodo or Dryad if the journal prefers them (same method as above).

## Versions, DOIs and what cannot be undone

- Publishing is effectively permanent: files and DOIs stay citable. Stage, check, get the user's explicit go-ahead, and let the user press the button.
- Fix a mistake as a new version (Zenodo, Dataverse) or within the repository's correction window; do not rely on deletion.
- After minting: put the DOI in the paper's data availability statement, the README, `CITATION.cff` and the related-publication field. Update the README header date.
- Journals with anonymous review may need a private reviewer link or an anonymised citation until acceptance (see Behavioral Ecology in `journal-policies.md`).

## Testing an upload safely (Zenodo sandbox)

Tested 2026-10-23 with zen4R 0.10.6 against the sandbox, nothing published:

- Pass the explicit URL so the target is visible: `ZenodoManager$new(url = "https://sandbox.zenodo.org/api", token = Sys.getenv("ZENODO_SANDBOX_TOKEN"))`. With `sandbox = TRUE` this version pointed at `zenodo-rdm-qa.web.cern.ch`, the same backend.
- Create a draft (`ZenodoRecord$new()`, `setTitle`, `setResourceType("dataset")`, `setDescription`, `addCreator(name = "Family, Given")`, `setLicense("cc0-1.0")`), then `depositRecord(rec, publish = FALSE)`, `uploadFile(path, record = draft)`, read back with `getDepositionById(id)`, and delete the draft with `deleteRecord(id)`.
- Gotchas: an `affiliation` string that is not in Zenodo's vocabulary gave a 404; `setUploadType` is deprecated; the sandbox DOI prefix `10.5072` is not a real DOI. Publishing in the sandbox and version behaviour were not tested.
- **Never put a token in code, files, memory or commits.** Read it from `~/.Renviron` as `ZENODO_SANDBOX_TOKEN`. Never publish to the production site for the user; the user does that in the web form.
- zen4R is on CRAN. `deposits` (rOpenSci) is not on CRAN, so installing it needs the user's permission.

## Large files and linked data

Owner's decision: large files stay on the university server and are deposited from there; they are not stored in GitHub. The deposit is assembled with `stage_deposit()` from the server copy, and the manifest proves the uploaded copy equals the server copy. The README says where the original lives and which copy is deposited.

Whether a repository accepts an external link instead of an upload is **not established** and is not needed to build or use this skill. A link is not a preserved copy and can break; a journal that demands archiving will usually need the files themselves. Use a link only for very large secondary files, with a stated reason, if the repository and journal allow it.
