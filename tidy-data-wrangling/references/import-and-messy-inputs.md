# Import and messy inputs

Sources: R4DS 2e ch. 7 (import), Broman and Woo 2018, Garmonsway "Spreadsheet Munging Strategies" (tidyxl and
unpivotr), janitor docs. `tidyxl` (CRAN 1.0.10) and `unpivotr` (0.6.4) were installed from CRAN and tested on a small generated workbook on 2026-10-30 (one header layout,
one colour fill); other layouts from the book are untested, so test on the user's file.

## Contents

- First read of any file
- Layouts and what to do
- Excel specifics
- Several files or sheets
- Writing the result

## First read of any file

```r
raw <- readr::read_csv(f, col_types = readr::cols(.default = readr::col_character()), na = character())
```

Reading everything as text with no `NA` conversion shows the file as it is. Then audit (`audit_table(raw)`), decide
types and codes, and re-read with explicit `col_types` and `na`. `skip =` drops metadata lines, `comment = "#"`
drops comment lines, `col_names = FALSE` when there is no header. Encoding or delimiter trouble:
`readr::guess_encoding()`, `read_csv2()`, `read_delim()`.

## Layouts and what to do

| Layout | Handling |
|---|---|
| Header not on row 1, notes above | `skip =` / `range =`; or read as text and `janitor::row_to_names(row_number)` |
| Two header rows (group over measure) | read with `col_names = FALSE`, build names from both rows (`paste(fill-down row 1, row 2, sep = "_")`), then pivot with `names_sep` |
| Blank spacer rows and columns, subtotal rows | `janitor::remove_empty(c("rows", "cols"))`; drop totals by an explicit rule and report them; never keep a total next to its parts |
| Merged cells (value only on first row) | `tidyr::fill()` on the group column |
| Several tables on one sheet | read each with `range =`, one table per object |
| Cross-tab / pivot table | `pivot_longer()` after naming the header row(s); complex ones: `tidyxl` + `unpivotr` |
| Colour or bold meaning something | formatting is data here: `tidyxl::xlsx_cells()` + `xlsx_formats()` (not readxl); ask the user what each colour means |
| Units or notes inside cells (`"12 mg"`, `"<0.5"`) | split text and number into columns (`separate_wider_regex()`); a censored value (`<0.5`) needs its own indicator column, not a silent `0.5` |
| Formulas in the raw sheet | read values; flag that totals come from formulas and may be stale |
| One sheet per group or day | `purrr::map()` over `excel_sheets()` with the sheet name as a column |

Broman and Woo's rules describe the target for a new dataset (one thing per cell, rectangle, consistent names, no
colour as data, ISO dates, no calculations in raw files, a data dictionary). When the user controls data entry, give
these as a short list; when the file already exists, do not ask for hand re-entry, write a script.

## Tested tidyxl and unpivotr pattern (2026-10-30, tidyxl 1.0.10, unpivotr 0.6.4)

Two header rows (merged group over week), animals down the left, a title above and a total row below:

```r
cells <- tidyxl::xlsx_cells(path, sheets = "Pivot")
cells |>
  filter(!is_blank, row >= 3, row <= 8) |>          # data block only; excludes title and total row
  unpivotr::behead("up-left", group) |>             # outer, merged header first
  unpivotr::behead("up", wk) |>
  unpivotr::behead("left", animal) |>
  mutate(value = coalesce(as.character(numeric), character))   # mixed numbers and text stay visible
```

- Strip the merged or left-aligned outer header with `"up-left"` first, then the inner one with `"up"`. The other
  order assigned the outer labels to the wrong column and left `NA`s (tested).
- Merged cells are only truly blank when the file was written by Excel or similar; a cell holding `""` is not
  `is_blank`, so `behead()` treats it as a header. Filter `character == ""` out first if you see that.
- For character cells `content` is a shared-string index, not the text; use the `character` and `numeric` columns.
- A text value in a numeric column (`"n/a"`, `-99`) survives as text next to the numbers; recode afterwards, with the
  user's confirmation.
- Colour as data: `fm <- tidyxl::xlsx_formats(path)`; `fill <- fm$local$fill$patternFill$fgColor$rgb`; then
  `cells |> mutate(fill = fill[local_format_id])` (tested: yellow came back as `FFFFFF00`, unformatted as `NA`).
  What a colour means is for the user to say.

## Excel specifics

- `readxl::read_excel(path, sheet = , range = "B3:H200", na = , col_types = "text")`; `excel_sheets()` lists sheets.
- Dates stored as numbers: `janitor::excel_numeric_to_date()`. Dates typed as text in the same column: parse
  separately and list failures.
- Leading zeros and long numeric IDs (scientific notation) are lost when the cell type was number; report if IDs look
  rounded (identical trailing zeros, `e+`).
- Hidden rows, columns and sheets are read as normal data; ask whether they matter.
- Google Sheets: `googlesheets4::read_sheet()` with the same type care.

## Several files or sheets

```r
files <- fs::dir_ls("data/raw", glob = "*.csv")
raw <- readr::read_csv(files, id = "file", col_types = spec_from_first)   # same columns required
janitor::compare_df_cols(!!!purrr::map(files, readr::read_csv, n_max = 5))  # when columns differ
```

Check for the same table with different column order or names before stacking; keep `file` as a provenance column.

## Writing the result

`readr::write_csv()` (UTF-8, ISO dates) for a small table, parquet (`arrow::write_parquet()`) when types must
survive. Write to a new path (for example `data/processed/`); never over the raw file. A data dictionary for the
cleaned table is the job of `data-repository-readme`.
