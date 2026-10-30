# Cleaning and types

Sources: Broman and Woo 2018 (kbroman.org/dataorg), Wilson et al. 2017 Good Enough Practices, R4DS 2e missing values
and import chapters, lubridate vignette, dplyr 1.2.0 NEWS, janitor docs. Ledger: `research/tidy-data-wrangling-ledger.md`.

## Contents

- Names
- Text values and categories
- Missing values
- Types
- Dates and times
- Duplicates
- Order of operations

## Names

`janitor::clean_names()` gives snake_case and unique names (it is aimed at readr/readxl output). Keep a record of
the old-to-new mapping if the original names carry units or meaning: `tibble(old = names(raw), new = names(clean))`.
Put units in a data dictionary or the name (`weight_g`), never in cells.

## Text values and categories

```r
df |> mutate(group = str_squish(group) |> str_to_lower())
```

Then list the distinct values (`count(df, group)`) and show the user any variants (`ctrl`, `Control`, `control `).
Mapping them is the user's call. Use a lookup, not nested `ifelse`:

```r
df |> mutate(group = recode_values(group, from = c("ctrl", "control"), to = "control", default = group))
df |> mutate(group = recode_values(group, "ctrl" ~ "control", "trt" ~ "treated", unmatched = "error"))
```

`unmatched = "error"` makes new spellings fail loudly. Note `recode_values()` uses `unmatched`, `case_when()` uses
`.unmatched` (dplyr 1.2.x). Use `replace_values()` to change only some values and leave the rest.

## Missing values

1. Name the codes at import: `read_csv(f, na = c("", "NA", "n/a", "-99"))` only for codes the user confirmed.
2. For a code found later: `mutate(x = na_if(x, -99))`. A numeric 99 or 999 may be real (age, score); ask.
3. Explicit `NA` vs implicit (row absent): `complete(id, time)` or `anti_join()` against the expected design to
   show absent rows; `tidyr::fill(col, .direction = "down")` for merged-cell gaps (use `.by` per group).
4. `NA` is not zero. `coalesce(x, 0)` or `replace_na()` only when the user states that absence means zero (counts
   not recorded vs counted zero). `replace_na()` casts the replacement to the column type and errors on loss of
   precision (tidyr >= 1.2.0).
5. Summaries of empty groups give `NaN`, `Inf`, `-Inf`; `group_by(.drop = FALSE)` or `count(.drop = FALSE)` keep
   empty factor levels.
6. Report missingness by column and by group before choosing any handling (`audit_table()$columns`). Whether
   missingness is random is an analysis question; it is not settled by wrangling.

## Types

- Fix at import: `col_types = cols(id = col_character(), date = col_date("%d.%m.%Y"), .default = col_guess())`.
  readr guesses from 1000 rows, so one stray `.` or `five` turns a numeric column into text; `guess_max` or explicit
  types avoid it, `problems()` lists failures.
- IDs are text (leading zeros are lost otherwise); keep one format across tables (`"014025"`).
- Text to number: `readr::parse_number()` drops units and thousands marks but hides what it dropped, so look at the
  non-numeric remainder first: `df |> filter(is.na(as.numeric(x)), !is.na(x)) |> count(x)`.
- Decimal commas: `locale(decimal_mark = ",")` or `read_csv2()`.
- Excel serial dates arrive as numbers: `janitor::excel_numeric_to_date()` or `as.Date(x, origin = "1899-12-30")`.
- Factors: set levels explicitly (`factor(x, levels = ...)` or `forcats::fct_relevel`) when order matters (reference
  level in a model, plot order). Do not convert to factor just to store text.
- Labelled SPSS/Stata/SAS data (`haven`): keep labels with `labelled`, or convert deliberately with
  `haven::as_factor()`.

## Dates and times

- Parse with the order named: `ymd()`, `dmy()`, `ymd_hms(tz = "Europe/Copenhagen")`. Ambiguous `03/04/21` is a
  question for the user; test with values where day > 12 to see which order the file uses.
- Mixed formats in one column: parse in passes (`coalesce(dmy(x), ymd(x))`) and list what failed; do not guess.
- `with_tz()` changes the displayed zone of the same moment; `force_tz()` changes the moment (use only to fix a wrongly
  labelled zone).
- Durations (`ddays()`) are exact seconds, periods (`days()`, `months()`) are calendar units; `jan31 + months(1)`
  is `NA`, `%m+%` rolls back to the month end.
- Write dates as ISO `YYYY-MM-DD` in saved files.

## Duplicates

`janitor::get_dupes(df, id, visit)` or `count(df, id, visit) |> filter(n > 1)`. Identical rows and conflicting rows
(same key, different values) are different problems. Show both; which to keep is the user's decision. `distinct()`
removes silently, so count first.

## Order of operations

import with types and `na` -> names -> whitespace and case -> codes to `NA` -> types and dates -> duplicates ->
reshape -> join -> checks -> write. Counts after each structural step.
