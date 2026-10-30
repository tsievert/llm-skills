# Checks on the cleaned table

Sources: Wilson et al. 2017 (record every step, unique ids), Broman and Woo 2018 (validation), `validate` package
(installed 1.1.7; its cookbook page could not be fetched on 2026-10-30, only a local test was run). `pointblank`,
`assertr`, `naniar` and `tidylog` were not evaluated (open items O2 in the ledger).

## Contents

- Write the rules before cleaning
- Plain checks (no extra package)
- `validate` for a rule set
- Row-count log
- What a passing check does not show

## Write the rules before cleaning

Ask the user (or read the data dictionary) for: allowed values per categorical column, plausible ranges, the key,
required columns, expected row count or design (animals by sessions), units. A rule list written after looking at
the cleaned data only confirms the cleaning.

## Plain checks (no extra package)

```r
stopifnot(
  "key is not unique" = !anyDuplicated(df[c("animal_id", "session")]),
  "unexpected group" = all(df$group %in% c("control", "treated")),
  "weight out of range" = all(between(df$weight_g, 5, 60) | is.na(df$weight_g)),
  "missing ids" = !anyNA(df$animal_id)
)
```

Named `stopifnot()` messages make a re-run fail with a readable reason. Design checks:
`df |> count(animal_id) |> count(n, name = "n_animals")` shows how many animals have how many rows.

## `validate` for a rule set

```r
rules <- validate::validator(weight_g >= 5, weight_g <= 60, group %in% c("control", "treated"),
                             is_unique(animal_id, session))
validate::summary(validate::confront(df, rules))     # passes, fails, NA per rule
```

Use the `validate::` prefix because the package masks `dplyr::expr`. Rules can be stored in a YAML file and kept with
the script. Tested only on a toy table.

## Row-count log

Keep a small log in the script so the report can say what each step did:

```r
log_step <- function(df, label) { message(sprintf("%-28s %6d rows %3d cols", label, nrow(df), ncol(df))); df }
raw |> log_step("raw") |> filter_out(is.na(animal_id)) |> log_step("dropped missing id")
```

`tidylog` prints this automatically but is a separate package (CRAN 1.1.0, not tested here).

## What a passing check does not show

A passed range check says nothing about unit mix-ups inside the range, a wrong but valid category, duplicated
subjects under two IDs, or shifted columns. Plot the cleaned values by group and by source file once
(`manuscript-figures-ggplot` is for final figures, not this); a quick histogram per numeric column catches most of
these. Whether missingness is ignorable is a modelling question for the analysis, not a wrangling result.
