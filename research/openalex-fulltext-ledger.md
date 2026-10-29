# openalex full-text ledger

Skill: `openalex` (`references/fulltext.md`, `scripts/fetch_fulltext.R`).

## Requirements
| # | Requirement | Date |
|---|---|---|
| 1 | Check whether OpenAlex offers full-text/PDF pulls and what alternatives exist | 2026-10-29 |
| 2 | Test the Unpaywall step and the Europe PMC XML route on real papers; install the GitHub `fulltext` package to test it (permission given) | 2026-10-29 |

## Test round 2026-10-29 (Windows, R 4.6.0)
| Test | Result |
|---|---|
| `fetch_fulltext()` on 5 DOIs, Unpaywall email set | 3 downloaded via OpenAlex OA locations (Genome Biol, PLOS ONE, arXiv copy); eLife -> `available_via_openalex_content_api_not_fetched`; Science 1970 -> `no_open_access_copy` |
| Unpaywall API in isolation (3 DOIs) | API works; URLs for Genome Biol (publisher + bioRxiv) and PLOS ONE (publisher) downloaded as valid PDFs; a Sussex repository URL failed (not a PDF) |
| Unpaywall data quality | eLife `url_for_pdf` was a `.bib` link, not a PDF; the `%PDF-` check correctly rejected it. Unpaywall rarely beats OpenAlex locations (same underlying data) |
| Gap | Step 2 never was the winning step in a natural run, because step 1 already found the PDF where Unpaywall did |
| `roadoi::oadoi_fetch()` | works, returns `best_oa_location` / `oa_locations` list-columns |
| `europepmc::epmc_search("DOI:...")` + `epmc_ftxt(pmcid)` | works for eLife (PMC4302267, 20 `sec` nodes, title extracted) and DESeq2 found PMC4302049; Science 1970 returned no `pmcid` column (non-PMC records lack it: guard with `"pmcid" %in% names()`) |
| `fulltext` 2.0 (GitHub, ropensci; already installed) | `ft_links()` ran; `ft_get()` blocked: it writes to hardcoded cache dirs (`AppData/Local/Cache/R/fulltext`, `fulltext_storr`) outside the assistant's permitted paths. `cache_options_set(path=)` on Windows prepends the cache root even to absolute paths. Not a package failure per se, a sandbox limit; untested beyond `ft_links()` |
| Name clash | `library(fulltext)` masks our `ft_text()` (and possibly other `ft_*`); the script's helper names collide |

## Open items
- DONE 2026-10-29: renamed to `oa_ft_text`/`oa_ft_grep`.
- DONE 2026-10-29: `fetch_epmc_xml()` added, XML supported in `oa_ft_text()`; tested on 4 DOIs.
- Test `ft_get` if the user allows the fulltext cache dirs.
- Unpaywall as winning step: needs an artificial case (strip OpenAlex `pdf_url`).
