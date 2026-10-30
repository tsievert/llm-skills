# Reshaping to tidy form

Sources: R4DS 2e ch. 5, tidyr pivot and rectangling vignettes, tidyr 1.3.2 NEWS (see `research/tidy-data-wrangling-ledger.md`).
Patterns below were run on tidyr 1.3.2.

## Contents

- Is it tidy? Four questions
- Wide to long
- Long to wide
- Splitting one column
- Nested and list columns
- Several units in one table

## Is it tidy? Four questions

1. Does any column name contain a value (a week, a dose, a year, `sp_m_014`)? Then pivot longer.
2. Does any column name contain two or more variables? Pivot longer with a split (`names_sep` or `names_pattern`).
3. Does one column hold several variables or units (`"12 mg"`, `"ctrl_A"`)? Split it.
4. Does the table mix observational units (animals and sessions repeated on every row)? Split into tables and join
   when needed.

Pivoting changes shape, never values. Compare `nrow` and the sum of a value column before and after.

## Wide to long

```r
# Values in column names: wk1, wk2, ...
df |> pivot_longer(starts_with("wk"), names_to = "week", names_prefix = "wk",
                   names_transform = as.integer, values_to = "rank", values_drop_na = TRUE)

# Two variables in the name: sp_m_014 -> dx, sex, age
df |> pivot_longer(-id, names_to = c("dx", "sex", "age"), names_pattern = "(.*)_(.)_(.*)")

# One measurement type per prefix, one index in the suffix: dob_c1, name_c1, dob_c2 ...
df |> pivot_longer(-fam, names_to = c(".value", "child"), names_sep = "_", values_drop_na = TRUE)
```

`values_drop_na = TRUE` only when the `NA` is structural (the child does not exist), not when it is a real missing
measurement. Say which it is.

## Long to wide

```r
df |> pivot_wider(id_cols = id, names_from = condition, values_from = value)
```

- If cells are not unique, tidyr warns and returns list-columns. Find them first:
  `df |> summarise(n = n(), .by = c(id, condition)) |> filter(n > 1)`. Then decide: a data error, a missing key
  column (add `trial`), or a deliberate summary (`values_fn = mean`, user's choice).
- `pivot_wider()` makes implicit missing rows explicit `NA`. `names_expand = TRUE` and `id_expand = TRUE` add
  combinations that never occur.
- Several `values_from` columns give `value_cond` names; control with `names_glue = "{condition}_{.value}"`.
- Wide is the right target for paired tests, matrices and some multivariate methods; keep a long copy for plotting.

## Splitting one column

```r
df |> separate_wider_delim(code, delim = "_", names = c("group", "site"))
df |> separate_wider_regex(code, c(group = "[a-z]+", "_", n = "\\d+", "_", site = "."))
df |> separate_longer_delim(tags, delim = ";")      # one value per row
```

The `separate_wider_*` functions error when a piece count differs; use `too_few = "align_start"` or `too_many =
"merge"` only after looking at the offending rows (`"debug"` adds diagnostic columns). Convert types afterwards
(`readr::parse_number()`, `as.integer()`), because pieces are text.

## Nested and list columns

For JSON or API output: `jsonlite::read_json()` (not `fromJSON()`, which simplifies and hides structure), wrap in
`tibble(x = ...)`, then:

| Elements are | Use |
|---|---|
| attributes of one thing (become columns) | `unnest_wider()` |
| observations (become rows) | `unnest_longer()` |
| a few fields several levels deep | `hoist()` |

Pitfalls: `unnest_wider()` fails on a name that already exists as a column (`names_sep = "_"` or drop the outer one);
empty-string placeholders become empty rows in `unnest_longer()`; parse dates and numbers explicitly afterwards;
`unnest_wider()` on unnamed elements needs `names_sep`. Repeat until `select(where(is.list))` is empty.

## Several units in one table

When a descriptor repeats on every row (animal sex, site coordinates), keep one table per unit and join:

```r
animals <- raw |> distinct(animal_id, sex, cage)           # check: n_distinct(animal_id) == nrow(animals)
sessions <- raw |> select(animal_id, session, date, score)
```

If `distinct()` returns more rows than animals, the descriptor is inconsistent across rows: a data error to show the
user, not to resolve silently.
