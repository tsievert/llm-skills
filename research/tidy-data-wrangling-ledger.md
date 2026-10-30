# Research: `tidy-data-wrangling` (planned skill; research round 2026-10-30)

Working name: `tidy-data-wrangling`. Status: research done, skill drafted the same day (see section 6). Source statuses:
read / partial / blocked / search / meta / not researched. Source-quality rules from `AGENTS.md` applied (no commercial,
LLM-like or US-tuned sources used).

## 1. Requirements

| # | Requirement |
|---|---|
| R1 | (2026-10-30, user) Draft a tidy-data-wrangling skill with `create-skill`, after a research round, with a clash check against existing skills. |
| R2 | (2026-10-30, assistant reading, to confirm) R / tidyverse first; base `\|>` pipe; Python/pandas out of scope for now. |
| R3 | (2026-10-30, assistant reading, to confirm) Territory = reshaping, cleaning, types, missing values, joins/keys, nested data, messy spreadsheets, validation of the result. Not modelling, not plotting, not README/data dictionary text, not pipelines. |

## 2. Sources

| # | Source | Status | Used for |
|---|---|---|---|
| S1 | https://agentskills.io/specification.md | read | frontmatter limits (description 1024, name 64), body under 500 lines, references one level deep |
| S2 | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices.md | read | third-person description, degrees of freedom, validate-fix loops, TOC in references over 100 lines |
| S3 | https://r4ds.hadley.nz/data-tidy.html | read | tidy rules, pivot_longer/wider patterns, `.value`, list-cols from duplicate cells |
| S4 | https://tidyr.tidyverse.org/articles/pivot.html | read | `names_pattern`, `names_sep`, `.value`, `names_transform`, `values_fn`, `unused_fn`, manual specs |
| S5 | https://www.jstatsoft.org/article/view/v059i10 (Wickham 2014, Tidy Data) | partial (abstract only) | definition: variable = column, observation = row, observational unit = table |
| S6 | https://kbroman.org/dataorg/ (Broman and Woo 2018, Am Stat 72:2-10) | read (site); tandfonline article blocked 403 | 13 spreadsheet-layout rules (consistent, ISO dates, no empty cells, one thing per cell, rectangle, dictionary, no calculations, no colour as data, names, backups, validation, plain text) |
| S7 | https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1005510 (Wilson et al. 2017, Good Enough Practices) | read | save raw data read-only, create analysis-friendly data, script every step, unique ids, recode -99 to NA |
| S8 | https://dplyr.tidyverse.org/news/index.html | partial (first 90 000 of 252 299 chars) | dplyr 1.2.0 (2026-02-03): `filter_out()`, `when_any/all`, `recode_values()`, `replace_values()`, `replace_when()`, `.unmatched`; `case_match()` soft-deprecated; `recode()` superseded; `.by`/`reframe()` stable; joins `relationship`, `unmatched`, `join_by()` |
| S9 | https://tidyr.tidyverse.org/news/index.html | read | tidyr 1.3.2 (2025-12-19); `separate_wider_*`/`separate_longer_*` supersede `separate()`/`extract()`/`separate_rows()`; `replace_na()` casts to column type; `fill(.by)`; `pivot_wider(names_expand, id_expand, unused_fn)` |
| S10 | https://tidyr.tidyverse.org/articles/rectangle.html | read | `unnest_wider` (attributes), `unnest_longer` (observations), `hoist` (few deep fields); duplicate-name and empty-string pitfalls |
| S11 | https://sfirke.github.io/janitor/ | read | `clean_names`, `remove_empty`, `get_dupes`, `tabyl`, `row_to_names`, `compare_df_cols`, `convert_to_date`; aimed at readr/readxl data |
| S12 | https://nacnudus.github.io/spreadsheet-munging-strategies/ (Garmonsway) | read (index) | `tidyxl` + `unpivotr` for pivot-table layouts, multi-row headers, formatting-as-data, notes in cells; work in progress, CC BY-NC-SA |
| S13 | https://r4ds.hadley.nz/joins.html | read | primary/foreign/compound keys, uniqueness check with `count() \|> filter(n > 1)`, `anti_join()` diagnosis, `join_by()`, `relationship`, `unmatched = "error"`, natural-join trap (`year`) |
| S14 | https://r4ds.hadley.nz/missing-values.html | read | explicit vs implicit NA, `fill`, `coalesce`, `na_if`, `complete`, `.drop = FALSE`, empty-group summaries (NaN, Inf) |
| S15 | https://r4ds.hadley.nz/data-import.html | read | `col_types`, `problems()`, `na =`, 1000-row guess, `skip`, `id = "file"` |
| S16 | https://dplyr.tidyverse.org/articles/colwise.html | read | `across`, `pick`, `if_any/if_all`; pitfalls with `where(is.numeric)` picking up created columns; `_if/_at/_all` superseded |
| S17 | https://lubridate.tidyverse.org/articles/lubridate.html | read | ymd family, `with_tz` vs `force_tz`, period vs duration, `%m+%`, month-end NA since 1.3.0 |
| S18 | https://cran.r-project.org/web/packages/validate/vignettes/cookbook.html | blocked (network error) | not read; `validate` is installed (1.1.7), test locally if used |
| S19 | https://naniar.njtierney.com/articles/getting-started-w-naniar.html | blocked (empty result) | not read; `naniar` not installed (CRAN 1.1.0) |
| S20 | `pointblank`, `assertr`, `tidylog`, `cleanepi`, `dlookr`, `visdat` (CRAN) | meta (versions only) | candidates, not evaluated; none installed |
| S21 | Python/pandas/polars tidy-data equivalents | not researched | out of scope (R2) |
| S22 | `data.table`/`duckdb`/`arrow` for large data | not researched beyond versions | one-line pointer only; `dtplyr`, `dbplyr` installed |

## 3. Package versions on this machine (2026-10-30, `available.packages()`)

Installed = CRAN latest for: tidyr 1.3.2, dplyr 1.2.1, tibble 3.3.1, readr 2.2.0, readxl 1.6.0, janitor 2.2.1, lubridate 1.9.5,
stringr 1.6.0, forcats 1.0.1, purrr 1.2.2, validate 1.1.7, skimr 2.2.2, vctrs 0.7.3, tidyselect 1.2.1, haven 2.5.5, labelled 2.16.1,
dtplyr 1.3.3, dbplyr 2.6.0. Not installed (CRAN): tidyxl 1.0.10, unpivotr 0.6.4, naniar 1.1.0, pointblank 0.12.4, assertr 3.0.1,
tidylog 1.1.0, visdat 0.6.1, cleanepi 1.1.2, clock 0.7.4.

## 4. Facts that shape the skill

- Tidy = variable per column, observation per row, observational unit per table (S5, S3). "Tidy" depends on the analysis: long for ggplot2
  and mixed models, sometimes wide for a matrix method or a paired test (S3 key points). Say so; do not force long.
- Use `separate_wider_*`, not `separate()` (superseded, S9). Use `recode_values()`/`replace_values()` in dplyr >= 1.2.0, not
  `case_match()` (soft-deprecated) or `recode()` (superseded) (S8). Underscored dplyr verbs are defunct (S8).
- Joins: check key uniqueness first, set `relationship` and `unmatched`, name keys with `join_by()` (S13, S8).
- Missing values: sentinel codes at import (`na =`), then `na_if`; implicit NAs via `complete()` or anti-join (S14, S15).
- Messy spreadsheets: formatting-as-data and multi-row headers need `tidyxl`/`unpivotr`; do not hand-edit the source (S6, S7, S12).
- Raw data stay untouched; every step in a script (S7).

## 5. Open research items

| # | Item | Status |
|---|---|---|
| O1 | Read the `validate` cookbook and decide whether the skill uses `validate` (installed) or only base/`stopifnot`/`dplyr` checks | partial (see log) |
| O2 | Evaluate `pointblank`, `assertr`, `naniar`, `tidylog` (install from CRAN is allowed) | open |
| O3 | Read the rest of dplyr news (offset 90000) for 1.2.1 and older items | open |
| O4 | Wickham 2014 full text (three tidy rules in detail, five messy patterns) | open (abstract only) |
| O5 | `tidyxl`/`unpivotr` hands-on test | partial (one layout, 2026-10-30) |
| O6 | Python/pandas variant (`python-r-interop` is planned, not written) | open |
| O7 | Live trigger test and a real messy file test | open |

## 6. Log

- 2026-10-30: research round (S1-S22 above). Local code tests and the skill draft follow in the same turn; results appended below.
- 2026-10-30 (later): Skill drafted (`tidy-data-wrangling/`: SKILL.md, five references, `scripts/audit_table.R`). Snippets verified locally except `tidyxl`/`unpivotr`, `tidylog`, `pointblank`. See HISTORY.md.
- 2026-10-30 (later): installed `tidyxl` 1.0.10 and `unpivotr` 0.6.4 (and `openxlsx` 4.2.9 to build the test workbook) from CRAN. Tested on a generated workbook (merged two-row header, title, total row, colour fill): `behead("up-left", group)` must come before `behead("up", wk)`; `""` cells are not blank so `behead()` treats them as headers; `character`/`numeric` columns, not `content`; `xlsx_formats()` fill lookup works. Closes O5 for one layout only. Added to `references/import-and-messy-inputs.md`.
- 2026-10-30 (later): Cleaning mode comparison on a 14-row sample built from the tested workbook (`tmp-examples/clean_sample.R`, git-ignored). Same audit evidence (via `audit_table.R`) fed seven AskUser decisions (swapped columns, names, case/space, -99 and n/a, outlier 210, ambiguous date, duplicate key); all answered, script written and re-run (identical result). Findings: (1) the audit script plus counts exposed the swapped Group/wk columns; (2) my first cleaning code swapped blanket and broke rows 13-14, caught only by a post-step `count()`; (3) `mutate(.by = keys)` groups by pre-mutation values, so the duplicate flag found nothing until split into a second `mutate()`. Both added to SKILL.md gotchas.
- 2026-10-30 (later): proxy trigger test. 22 queries in `github-skill-maintenance/assets/trigger-queries-tidy-data-wrangling.json` (10 should-trigger incl. 2 Cleaning-mode-style, 12 near misses incl. pandas and a plain ggplot boxplot), 3 subagent runs with shuffled order that saw only `catalog.md` (33 repo + 12 built-in names and descriptions). Result: 30/30 should-trigger picks, 0/36 false triggers, near misses all went to the expected neighbour or none (66/66 on the expected outcome). Limits: descriptions only, queries written by the skill's author, three runs of one model, no with/without comparison. Then added `metadata.prompt_signals` and `file_signals` (function names and package loads; see `skill-trigger-hook.md`); synthetic hook payloads and lint pass.
