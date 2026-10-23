# Licences, identifiers and FAIR

This is the home of the "Standards" material that used to sit in `data-repository-readme/references/sources.md`. Open the live page before
quoting details. The user decides licences; the assistant lays out the options and the consequences.

## Contents

- Licences
- Identifiers
- FAIR
- Machine-readable companions

## Licences

| Material | Common choices | Notes |
|---|---|---|
| Data | CC0 1.0 or CC BY 4.0 | CC0 gives up attribution rights, so credit relies on citation norms (Turing Way "licensing data"); CC BY keeps attribution as a licence condition. Dryad forces CC0. Dataverse installations often default to CC0. A licence applies to the whole dataset in Dataverse (one licence per dataset, not per file, as seen on another installation) |
| Code | MIT, BSD-3-Clause, Apache-2.0, GPL-3.0-or-later | Use an SPDX identifier (https://spdx.org/licenses/), a LICENSE file at the top level, and the README line |
| Text, figures | CC BY 4.0 | Usually follows the paper's licence |
| Third-party data | Their licence | Check it allows redistribution; if not, cite and give the access route |

Open Data Commons licences (PDDL, ODC-BY, ODbL) cover database rights only; Creative Commons licences are general purpose (Turing Way). Chooser: https://creativecommons.org/choose/ . Wording in the README should encourage citation, not make legal-sounding demands under CC0 (Dryad guidance).

## Identifiers

- **DOI** for the dataset and, separately, for the code archive; the article DOI is never reused for a dataset (Zenodo guidance).
- **ORCID** for each creator (the university roadmaps seen encourage it); **ROR** for organisations; funder and grant IDs in the repository form.
- Dates in ISO 8601 (`YYYY-MM-DD`).
- Related identifiers: link the paper, the code archive and any companion deposit with their relationship (supplement to, is derived from).

## FAIR

The FAIR principles (Wilkinson et al. 2016, read through PMC4792175): findable (persistent identifier, rich metadata), accessible (open protocol, metadata kept even if data are gone), interoperable (open formats, community vocabularies), reusable (licence, provenance, community standards). The go-fair.org page returned nothing to the fetch tool; Zenodo's principles page maps FAIR to repository behaviour: https://about.zenodo.org/principles/ . FAIR is a direction, not a pass mark; say which parts a deposit meets rather than claiming "FAIR".

## Machine-readable companions

Frictionless `datapackage.json` (column types; CRAN `frictionless`), Darwin Core or EML for biodiversity data, CITATION.cff for code (`git-for-research-projects`), `.zenodo.json` only when the CFF is not enough (Zenodo then ignores the CFF). Controlled vocabularies listed by Cornell: ITIS, GCMD keywords, IUPAC Gold Book, Gene Ontology.
