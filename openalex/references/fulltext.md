# Full texts (PDF / TEI XML) from OpenAlex and other legal sources

Checked 2026-10-23 against help.openalex.org/access/fulltext, developers.openalex.org/download/full-text-pdfs and
help.openalex.org/data/works/attributes. Re-check there before relying on prices or limits.

## What OpenAlex offers

- Work fields: `has_content` (`pdf`, `grobid_xml` booleans), `has_fulltext`, `content_urls` (`pdf`, `grobid_xml`; API only, not in the
  snapshot), `open_access.is_oa`, `open_access.oa_url` (best OA URL, may be a landing page), `locations[].pdf_url`.
- Cached copies for 50-60M open-access works at `https://content.openalex.org/works/{W-id}.pdf?api_key=KEY` (`.grobid-xml` for TEI XML).
  Metered: documented as $0.01 per file; the free key allowance covers roughly 100 files per day. Metadata calls are free.
- Find downloadable works: `filter=has_content.pdf:true` (combine with `publication_year`, `topics.id`, licence filters).
- Bulk: official CLI (`pip install openalex-official`, `openalex download --filter ... --content pdf`), up to a few million files; full
  archive sync needs a paid plan.
- Only open-access content. OpenAlex does not provide paywalled papers.

## Workflow

1. Ask the user how many papers and whether spending the metered allowance is acceptable. Default: no paid calls.
2. Use `scripts/fetch_fulltext.R` (`fetch_fulltext(ids, outdir, email, allow_paid = FALSE)`). Input: DOIs or `W` IDs. Order tried:
   OA locations from OpenAlex, then Unpaywall (set `UNPAYWALL_EMAIL` or pass `email`), then the metered content API only if
   `allow_paid = TRUE`. Every file is checked for the `%PDF-` signature, so HTML landing pages are not saved as PDFs.
3. Read `fulltext/manifest.tsv`. Statuses: `downloaded`, `already_present`, `available_via_openalex_content_api_not_fetched`
   (ask before paying), `oa_but_no_direct_pdf` (OA exists but a script cannot reach a PDF; give the user `oa_url`),
   `no_open_access_copy`, `not_found_in_openalex`.
4. Biomedical paper with no usable PDF, or when sections matter: `fetch_epmc_xml(dois, outdir)` looks the DOI up in Europe PMC and saves
   the JATS XML as `<PMCID>.xml` plus `manifest_epmc.tsv`. Statuses: `downloaded`, `already_present`, `not_in_pmc`,
   `not_found_in_europepmc`, `pmc_no_fulltext_xml`. Only PMC records have XML (open-access subset and author manuscripts); other
   papers (most non-biomedical, older paywalled ones) return `not_in_pmc`. Same `max_files` guard; no payment involved.
5. For abstracts-only screening, do not download; abstracts come with the metadata.
6. Report which papers were obtained and from where; never claim to have read a paper that was not retrieved.

## Downloads are opt-in (rule)

Searching, screening and counting never download full texts. Work from metadata and abstracts first. Download only when the user
asks for specific papers or approves a stated count ("N works, M with a free PDF, about $X if the metered API is used"). The script
enforces this: `fetch_fulltext()` stops above `max_files` (default 20) unless called with `confirmed = TRUE` after user approval, and
it never spends metered calls unless `allow_paid = TRUE`. Do not wrap it in a loop that runs after every search.

## Text from PDFs and XML: screening and searching downloaded papers

`oa_ft_text(dir)` converts each PDF in the folder to a cached `.txt` with `pdftools::pdf_text()` (pages separated by a form feed;
skipped if the `.txt` exists). `oa_ft_grep(pattern, dir)` runs a case-insensitive regex over those texts and returns file, page and a
snippet, so claims can be checked against the actual wording (for example a method term or sample size) with a page to cite.

Europe PMC `.xml` files in the same folder are converted too: one "page" per section (title, abstract, each top-level body section), so
the `page` column is a section number there. The helpers are prefixed `oa_` because attaching the GitHub `fulltext` package masks a bare
`ft_text()` (found 2026-10-29).

```r
source("openalex/scripts/fetch_fulltext.R")
res <- fetch_fulltext(c("10.1038/nature12373"), outdir = "fulltext", email = "you@example.org")
oa_ft_grep("sensitiv\\w+ .{0,30}mK", "fulltext")
```

Limits: scanned PDFs return little or no text (no OCR; `pdftools::pdf_ocr_text()` needs tesseract, not tested); two-column layouts
can interleave lines, so quote from the PDF, not the snippet; hyphenated words break across lines; regex hits are leads to read,
not evidence of a finding. Reference lists and abstracts also match, so check the page.

## R packages (CRAN, checked 2026-10-23)

| Package | Use | Notes |
|---|---|---|
| `roadoi` 0.7.3 | Unpaywall client (`oadoi_fetch()`) | Needs an email; same data the script uses |
| `europepmc` 0.4.3 | Europe PMC search and full-text XML for PMC open-access papers | Good for biomedical OA |
| `rcrossref` 1.2.1 | Crossref metadata and licence/full-text links | Links often paywalled |
| `openalexR` 3.1.2 | Metadata; no content download wrapper known | Use httr2 for `content_urls` |
| `fulltext` 2.0 | Not on CRAN (rOpenSci, GitHub only; installed here with user permission) | `ft_links()` works; `ft_get()` writes to fixed cache dirs outside the assistant's permitted paths (blocked on Windows, untested). Masks `ft_text()` |

## Paywalled papers: what not to do and what to do

Shadow libraries such as Sci-Hub are not used by this skill. Fetching paywalled articles from them is copyright infringement in most
jurisdictions and may breach institutional and publisher terms, so the assistant does not build or run tooling for it, and does not
install packages that wrap it. This is a policy choice for the skill; the user can decide separately what to do on their own.

Legal routes for a paper with `no_open_access_copy`:

- Institutional access: the user's library proxy or VPN, then download manually (publishers often block scripted downloads).
- Preprint or accepted manuscript in a repository (the script already checks OpenAlex and Unpaywall locations; also search the title
  on Google Scholar, ResearchGate, institutional repositories, or the author's page).
- Email the corresponding author (OpenAlex `authorships` lists them; ORCID may give contact details).
- Interlibrary loan or the library's document delivery service.
- Text and data mining: some publishers offer TDM APIs with institutional keys (Elsevier, Springer Nature, Wiley); the user needs the
  key from the library. Check the licence before bulk use.
- If only the content is needed, the abstract plus OpenAlex `referenced_works` and citing contexts often suffice for screening.

## Tested

Windows, R 4.6.0, httr2. Three inputs: a paper with an arXiv copy (downloaded via an OpenAlex OA location, valid PDF), a PLOS ONE paper
(OA, but no script-reachable PDF: status `oa_but_no_direct_pdf`), a bogus DOI (`not_found_in_openalex`). Not tested: the Unpaywall step
returning a hit, the metered content API download (`allow_paid = TRUE`), the CLI, bulk runs, Linux/macOS. Also tested: the
`max_files` guard (25 inputs stop with an error before any request), `oa_ft_text()` (50k characters from a downloaded arXiv PDF, with a
harmless poppler xref warning) and `oa_ft_grep()` (hits with page numbers). Not tested: OCR, multi-column layouts, many files.

Added 2026-10-29: `fetch_epmc_xml()` (eLife and Genome Biology papers downloaded as XML; a 1970 Science paper gave `not_in_pmc`; a bogus
DOI gave `not_found_in_europepmc`; rerun gave `already_present`; the `max_files` guard stops 24 inputs). `oa_ft_text()`/`oa_ft_grep()`
on a mixed PDF + XML folder (hits with section numbers). Unpaywall step: API and PDF links verified in isolation, but never the
winning step in a natural run. Not tested: `fulltext::ft_get()`, Europe PMC records with embargoed or non-XML full text.
