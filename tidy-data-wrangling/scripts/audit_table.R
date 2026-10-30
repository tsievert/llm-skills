# Read-only audit of a data frame before wrangling. Never modifies the input.
# Usage: source("tidy-data-wrangling/scripts/audit_table.R"); audit_table(df, key = c("id", "visit"))
# Needs: dplyr, tidyr, tibble, stringr (all tidyverse core). Tested with dplyr 1.2.1, tidyr 1.3.2.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
})

# Values that are usually missing-value codes written as data.
sentinel_values <- c("", " ", "NA", "N/A", "n/a", "na", "NULL", "null", "none", "-", "--", ".", "?",
                     "-99", "-999", "-9999", "99", "999", "9999", "missing", "unknown")

audit_table <- function(df, key = NULL, max_levels = 15) {
  stopifnot(is.data.frame(df))
  if (!is.null(key)) stopifnot(all(key %in% names(df)))
  nm <- names(df)

  names_issues <- tibble(
    name = nm,
    problem = case_when(
      nm == "" | is.na(nm) ~ "empty name",
      str_detect(nm, "^\\.\\.\\.\\d+$|^X\\d+$|^X$") ~ "auto-generated name (header row probably misplaced)",
      str_detect(nm, "[^A-Za-z0-9_.]") ~ "spaces, case or symbols (consider janitor::clean_names())",
      str_detect(nm, "[A-Z]") ~ "upper case",
      str_detect(nm, "^[0-9]") ~ "starts with a digit",
      .default = NA_character_
    )
  ) |>
    filter(!is.na(problem))
  dup_names <- nm[duplicated(nm)]
  if (length(dup_names)) {
    names_issues <- bind_rows(names_issues, tibble(name = unique(dup_names), problem = "duplicated name"))
  }

  col_profile <- bind_rows(lapply(seq_along(df), function(i) {
    x <- df[[i]]
    chr <- if (is.character(x) || is.factor(x)) as.character(x) else NULL
    num_like <- if (!is.null(chr)) {
      nn <- chr[!is.na(chr) & !chr %in% sentinel_values]
      if (length(nn)) mean(!is.na(suppressWarnings(as.numeric(nn)))) else NA_real_
    } else NA_real_
    tibble(
      column = nm[i],
      class = paste(class(x), collapse = "/"),
      n_na = sum(is.na(x)),
      n_distinct = n_distinct(x),
      sentinels = if (!is.null(chr)) sum(chr %in% sentinel_values, na.rm = TRUE) else NA_integer_,
      share_numeric_like = round(num_like, 2),
      edge_space = if (!is.null(chr)) sum(chr != str_squish(chr), na.rm = TRUE) else NA_integer_,
      case_variants = if (!is.null(chr)) {
        u <- unique(chr[!is.na(chr)])
        sum(duplicated(str_to_lower(str_squish(u))))
      } else NA_integer_,
      constant = n_distinct(x) <= 1
    )
  }))

  numeric_codes <- bind_rows(lapply(names(df)[vapply(df, is.numeric, logical(1))], function(cn) {
    x <- df[[cn]]
    hits <- x[x %in% c(-99, -999, -9999, 99, 999, 9999)]
    if (!length(hits)) return(NULL)
    tibble(column = cn, code = as.character(unique(hits)), n = length(hits),
           note = "possible missing-value code stored as a number")
  }))

  low_card <- bind_rows(lapply(names(df)[vapply(df, function(x) is.character(x) || is.factor(x), logical(1))], function(cn) {
    x <- as.character(df[[cn]])
    if (n_distinct(x, na.rm = TRUE) > max_levels) return(NULL)
    count(tibble(column = cn, value = x), column, value, sort = TRUE)
  }))

  empty_rows <- sum(rowSums(!is.na(df) & !(as.matrix(df) %in% sentinel_values)) == 0)
  empty_cols <- nm[vapply(df, function(x) all(is.na(x) | as.character(x) %in% sentinel_values), logical(1))]

  key_report <- NULL
  if (!is.null(key)) {
    dupes <- df |> count(across(all_of(key)), name = "n") |> filter(n > 1)
    key_report <- list(
      n_rows = nrow(df),
      n_distinct_keys = nrow(distinct(df, across(all_of(key)))),
      rows_with_na_key = sum(!complete.cases(df[key])),
      duplicated_keys = dupes
    )
  }

  list(
    shape = c(rows = nrow(df), cols = ncol(df)),
    empty_rows = empty_rows,
    empty_cols = empty_cols,
    duplicate_full_rows = sum(duplicated(df)),
    names = names_issues,
    columns = col_profile,
    numeric_codes = numeric_codes,
    low_cardinality_values = low_card,
    key = key_report
  )
}
