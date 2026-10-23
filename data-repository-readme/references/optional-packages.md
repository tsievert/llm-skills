# Optional CRAN packages: what was tested and what is worth using

Tested on 2026-10-23 (Windows, R 4.6.0) on a synthetic 30-row trial table and a copy with one
non-ISO date, using frictionless 1.3.0, skimr 2.2.2, dataspice 1.1.1 and codebook 0.10.1.
Nothing here is required; the skill's base-R helpers cover the basics. Re-test after major
releases.

| Package | Useful for a README? | Verdict |
|---|---|---|
| `skimr` | Fast QA summary of every column | Use for QA in step 3; does not write Markdown |
| `frictionless` | Validates data against explicit column types; writes `datapackage.json` | Use as an optional check and companion file |
| `dataspice` | schema.org JSON-LD and an HTML landing page | Rarely; not a README; has bugs (below) |
| `codebook` | Codebooks for labelled, survey-style data | Not suited to a Markdown README |

## skimr

`skim(df)` gives, per column: type, `n_missing`, `complete_rate`, string min/max length, `empty`,
`n_unique`, numeric mean, sd, quantiles, and a small histogram. It exposed `-999` as the minimum of
`latency_s` (min -999, mean -26), which is how a missing-value code shows up. Returns a data frame
(`as.data.frame(skim(df))`). It does not know definitions or units.

Custom checks work with `skim_with()` (tested):

```r
library(skimr)
my_skim <- skim_with(
  character = sfl(not_iso = ~ sum(!grepl("^\\d{4}-\\d{2}-\\d{2}$", .x) & .x != "")),
  numeric   = sfl(n_code999 = ~ sum(.x %in% c(-999, -99), na.rm = TRUE)))
as.data.frame(my_skim(df))[, c("skim_variable", "n_missing", "character.not_iso", "numeric.n_code999")]
```

Limit: `not_iso` counts every non-date string column (IDs, sites), so read it only for date columns.

## frictionless

Dryad runs a tabular data checker built on the Frictionless framework on uploaded CSV/XLSX/TSV
files (Dryad submission walkthrough, https://datadryad.org/help/submission_steps/submission), so
running it locally previews that check.

Tested:

- `create_package() |> add_resource("trials", "file.csv")` infers column names and types only
  (string, number, date). It does not record missing counts, ranges or units.
- Schema fields can be edited by hand (`description`, a `unit` entry, `missingValues`).
  After `schema$missingValues <- c("", "-999")`, `read_resource()` returned the `-999` as `NA`
  (2 NAs instead of 1), so a missing-value code can be declared once and honoured.
- Validation: on a file with one `05/05/2020` among ISO dates, type inference silently chose
  `string`. After forcing the column to `date`, `read_resource()` returned `NA` for that row and
  warned about parsing issues, with `problems()` listing them. So set types explicitly to get a check.
- `write_package(p, dir)` writes `datapackage.json` and copies the CSV. `check_package()` exists
  (not exercised beyond existence).

Recommended use: after drafting the dictionary, build a package with explicit types, read each
resource, and show any `problems()`. A `datapackage.json` is an optional machine-readable companion;
the README stays the human entry point. Check with the user before adding extra files to a deposit.

## dataspice

Workflow: `create_spice()` makes `data/metadata/{access,attributes,biblio,creators}.csv`;
`prep_attributes()` and `prep_access()` fill file and variable names; the user fills descriptions
and units; `write_spice()` writes `dataspice.json` (schema.org Dataset); `build_site()` writes
`docs/index.html`. Tested end to end; it works, but:

- A given name of `T` was written to the JSON as `true` (logical), and `jsonlite` reads it back as
  `TRUE`. Single-letter or `T`/`F`/`NA`-like values need checking in the JSON.
- `contentUrl` was `null` and the bounding box `"NA NA NA NA"` when left empty; `build_site()`
  warns about coercion with empty coordinates.
- It requires you to maintain four CSV files by hand and targets a web page and Google Dataset
  Search, not a repository README. Dryad, Zenodo and Figshare already collect most of these fields in
  their forms.

Verdict: skip unless the user wants a self-hosted landing page or schema.org metadata.

## codebook

`codebook_table(df)` returns a data frame with `name`, `label`, `data_type`, `n_missing`,
`complete_rate`, `n_unique`, `empty`, `min`, `median`, `max`, `mean`, `sd`, `hist`, `unit`. Labels and units
are read from the `label` and `unit` attributes (set with `var_label<-`); without them the columns
are `NA`. It reports min/max, so `-999` is visible, but it does not flag it. `metadata_jsonld()`
and `compact_codebook()` (about 14 s) return HTML/knitr output meant for R Markdown or Quarto
reports, not Markdown. It is designed for survey data with value labels, scales and reliabilities.
For this skill, `codebook_table()` is a possible alternative to `draft_data_dictionary()` only if
the data already carry labels; otherwise no gain.
