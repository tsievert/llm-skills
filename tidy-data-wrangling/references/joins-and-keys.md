# Joins and keys

Sources: R4DS 2e ch. 19 (joins), dplyr 1.1.0 and 1.2.0 NEWS. Behaviour below was run on dplyr 1.2.1.

## Contents

- Before the join
- The join call
- Diagnosing a join
- Binding and stacking

## Before the join

1. State the key of each table in words (animal, or animal plus session). A key can be several columns.
2. Prove uniqueness on the side that should be unique:
   ```r
   lookup |> count(animal_id) |> filter(n > 1)         # must be empty for a many-to-one join
   filter(x, is.na(animal_id))                         # missing keys never identify anything
   ```
   Passing the check does not prove the key is meaningful; it only shows no duplicates in this file.
3. Normalise key text on both sides (`str_squish()`, case, leading zeros) before joining, or the join drops rows.
4. Same name is not same meaning (`year` of departure vs year of manufacture). Name the keys.

## The join call

```r
x |> left_join(y, by = join_by(animal_id), relationship = "many-to-one", unmatched = "error")
```

- `join_by(a == b)` when names differ; never rely on a natural join on all shared names.
- `relationship` (`"one-to-one"`, `"one-to-many"`, `"many-to-one"`, `"many-to-many"`) turns a wrong assumption
  into an error. Verified: a duplicated key in `y` stops a `"many-to-one"` join with a message naming the row.
- `unmatched = "error"` errors if a row finds no partner (verified: names the row). It must be length 1 in dplyr 1.2.1,
  so it applies to both sides for inner joins; for a left join only `x` rows can be unmatched in the sense that matters.
- Overlapping non-key columns get `.x`/`.y`; set `suffix` or drop one side first.
- Choose the join by the question: `left_join` keeps all of `x`; `inner_join` silently drops unmatched rows (say
  so); `full_join` for reconciliation; `semi_join`/`anti_join` filter without adding columns or duplicating rows.
- Inequality, rolling and overlap joins (`join_by(id, between(date, start, end))`, `closest()`) for date windows.
  Check for overlapping windows, which duplicate rows.

## Diagnosing a join

```r
anti_join(x, y, by = join_by(animal_id)) |> distinct(animal_id)   # in x, not in y
anti_join(y, x, by = join_by(animal_id)) |> distinct(animal_id)   # in y, not in x
nrow(x); nrow(joined)                                             # many-to-one must keep nrow(x)
```

Typical causes of unmatched keys: whitespace, case, leading zeros, a different ID scheme, a real absence. Which one
it is, and what to do with the unmatched rows, is for the user. A many-to-many warning means both sides repeat the
key; usually a missing key column, not a reason to set `relationship = "many-to-many"`.

## Binding and stacking

- Same table in several files: `readr::read_csv(files, id = "file")` or `purrr::list_rbind(..., names_to = "file")`
  keeps the source. Check column names and types first with `janitor::compare_df_cols()`; `bind_rows()` errors on
  incompatible types, which is the useful behaviour.
- `bind_cols()` matches by position only; use a join with a key instead unless the order is guaranteed and checked.
