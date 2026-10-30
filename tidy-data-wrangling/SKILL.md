---
name: tidy-data-wrangling
description: "Reshapes, cleans and checks tabular data in R with the tidyverse (tidyr, dplyr, readr, stringr, lubridate): tidy structure (pivot_longer, pivot_wider, separate_wider, nested or JSON data), importing with explicit column types, messy headers and Excel layouts, recoding, missing-value codes and implicit missing rows, dates, duplicates, joins and keys, and checks on the result. Ships a read-only audit script. Use when the user asks to tidy, clean, reshape, pivot, merge, join, reformat or wrangle a data frame, CSV or spreadsheet, or has wide data, messy column names, inconsistent entries, duplicate rows or join problems. Statistical models belong to mixed-models-glmm or gam-mgcv, DeepLabCut metric tables to animal-behaviour-tracking-analysis, README and data dictionary text to data-repository-readme, and the layout of a whole deposit to reproducible-research-data."
metadata:
  prompt_signals: '\bpivot_longer\b|\bpivot_wider\b|\bseparate_wider_[a-z]+|\bseparate_longer_[a-z]+|\bunnest_wider\b|\bunnest_longer\b|\bclean_names\b|\bget_dupes\b|\bremove_empty\b|\btidyxl\b|\bunpivotr\b|\bread_excel\b|\brecode_values\b|\bfilter_out\b|wide to long|long to wide|messy data|tidy data|\b[Ww]rangl[a-z]*|[Dd]ata [Cc]leaning|[Dd]ata [Tt]idying|\b[Rr]eshaping\b|\b[Cc]lean up data|\b[Cc]lean up my data|\b[Cc]lean up this data|\b[Cc]lean my data|\b[Cc]lean the data|\b[Cc]lean this data'
  file_signals: '\bpivot_longer\b|\bpivot_wider\b|\bseparate_wider_[a-z]+|\bseparate_longer_[a-z]+|\bunnest_wider\b|\bunnest_longer\b|\bclean_names\b|\bget_dupes\b|\bremove_empty\b|\btidyxl\b|\bunpivotr\b|\bread_excel\b|\brecode_values\b|\bfilter_out\b|library\(tidyr\)|library\(janitor\)|library\(readxl\)|\btidyr::|\bjanitor::|\b[Ww]rangl[a-z]*|[Dd]ata [Cc]leaning|[Dd]ata [Tt]idying|[Dd]ata [Pp]reparation|#+ *[Ii]mport(ing)? data|#+ *[Cc]lean(ing)? data|#+ *[Tt]idy|#+ *[Rr]eshap[a-z]+|#+ *[Jj]oin(ing)? tables|#+ *[Jj]oin(ing)? data|#+ *[Mm]issing values|#+ *[Mm]issing data|-+ *[Cc]lean(ing)? data|-+ *[Ii]mport(ing)? data|-+ *[Tt]idy'
---

# Tidy data wrangling (R, tidyverse)

Turns a raw table into one the analysis can use, with every step in a script and the raw file untouched. The
tidy definition: each variable is a column, each observation is a row, each type of observational unit is a table.
"Tidy" depends on the next step: long suits ggplot2 and mixed models, wide can suit a matrix method or a paired
test. Choose the shape for the analysis; do not force long by reflex.

## Standing rules

1. **Raw data stay untouched.** Read from the original, write the cleaned table to a new file (CSV or parquet), and
   keep the script. No hand edits in Excel; if one is unavoidable, record it in the script as a comment.
2. **Look before changing.** Run the audit (below) and show row and column counts, types, sentinel codes, duplicate
   keys and case or whitespace variants before any fix.
3. **Meaning-changing steps are the user's decision.** Dropping rows, merging category spellings, turning `0` or
   `99` into `NA`, imputing, choosing which duplicate to keep, and parsing ambiguous dates (`03/04/21`) are
   questions, not defaults. Batch them into one list with a proposed default each. For an interactive per-decision
   audit the built-in Cleaning mode exists; offer it when the user wants to be asked item by item.
4. **Count after every structural step.** Report rows before and after each filter, join and pivot, and say whether
   the change was expected. A join that changes the row count unexpectedly is the most common silent error.
5. **No silent coercion.** Set `col_types` and `na` at import, convert explicitly, and check for `NA`s created by
   the conversion (`sum(is.na(new)) - sum(is.na(old))`).
6. **Never invent values.** No filling, imputing or "fixing" a number from guesswork; flag it and ask.

## Workflow

1. **Read the file the safe way.** `readr::read_csv(file, col_types = ..., na = c("", "NA", ...))`, `readxl::read_excel(path, sheet, range, skip)`.
   Check `readr::problems()`. Details and layouts that fail here (multi-row headers, notes, pivot tables, colour as
   data): [references/import-and-messy-inputs.md](references/import-and-messy-inputs.md).
2. **Audit.** `source("tidy-data-wrangling/scripts/audit_table.R"); audit_table(df, key = c("id", "visit"))`
   returns name problems, per-column class, `NA`, sentinel, whitespace and case-variant counts, numeric-like
   text columns, number-coded missing values, low-cardinality value tables, empty rows and columns, and key
   duplicates. It is read-only and flags candidates; it cannot tell a real 99 from a code.
3. **Fix names and types.** [references/cleaning-and-types.md](references/cleaning-and-types.md): names, whitespace,
   categories, sentinels, dates and time zones, units, factors.
4. **Reshape to the analysis.** [references/reshaping.md](references/reshaping.md): which column names hide
   variables, `pivot_longer`/`pivot_wider` patterns, `separate_wider_*`, nested lists, one table per unit.
5. **Combine tables.** [references/joins-and-keys.md](references/joins-and-keys.md): prove key uniqueness, set
   `relationship` and `unmatched`, diagnose with `anti_join()`.
6. **Check the result** against rules written before the cleaning (ranges, allowed values, key uniqueness, row
   counts): [references/checks-and-validation.md](references/checks-and-validation.md). Save the checks with the
   script so a re-run fails loudly.
7. **Report.** Say what was changed, what was flagged but left, and the decisions that were the user's.

## Current idioms (tested 2026-10-30 with dplyr 1.2.1, tidyr 1.3.2, readr 2.2.0)

| Use | Instead of |
|---|---|
| `separate_wider_delim()`, `separate_wider_regex()`, `separate_longer_delim()` | `separate()`, `extract()`, `separate_rows()` (superseded) |
| `recode_values()`, `replace_values()`, `case_when()` | `case_match()` (soft-deprecated in dplyr 1.2.0), `recode()` (superseded) |
| `filter_out()` to drop rows, `when_any()`/`when_all()` | negated `filter()` that mishandles `NA` |
| `mutate(.by = g)`, `summarise(.by = g)`, `reframe()` | `group_by()` then `ungroup()` for one-off steps |
| `join_by()` with `relationship` and `unmatched` | `by = c("a" = "b")`, natural joins on shared names |
| `across(.cols, .fns)`, `pick()`, `if_any()`/`if_all()` | `mutate_if`, `mutate_at`, `mutate_all` (superseded) |

Gotchas found in testing: `.by` in `mutate()` groups by the values from before that call, so standardise keys in
one `mutate()` and compute per-key flags (such as `n() > 1`) in the next, or duplicates go undetected. A
blanket column swap or recode must be checked with `count()` afterwards; a half-bad column (here 12 of 14 rows
mislabelled) needs a per-row rule. `recode_values()` takes `unmatched = "error"` (no dot) while `case_when()` takes
`.unmatched`; `validate` masks `dplyr::expr`, so call `validate::validator()` with the prefix.

## Scale and other languages

For tables too big for memory, `dbplyr` (databases), `arrow` (parquet) and `dtplyr` (data.table backend) keep the same dplyr
verbs; they were checked for version only here, not tested. Python (pandas, polars) is not covered; `python-r-interop`
is planned but not written.

## Related skills

- `animal-behaviour-tracking-analysis`: tidy layouts for DeepLabCut metric tables and the statistics on them.
- `data-repository-readme`: data dictionary and README text for a cleaned dataset that is going into a deposit.
- `reproducible-research-data`: what to deposit, with raw and processed data and figure source data.
- `r-reproducible-pipeline`: turning the cleaning script into a re-runnable `targets` pipeline.
- `mixed-models-glmm`: the model step once the data are long and tidy.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. Say briefly why a step was done or
skipped: why this shape for this analysis, why a value was flagged rather than changed, why a join was checked first,
which choices were theirs. Keep each explanation to a sentence or two, name the trade-off, and point to a reference
file for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a
package version or API differs from what it states, or it lacks guidance the task needs, record a generic,
anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is
resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in
the llm-skills repo (`skill-feedback-triage`), not facts.
