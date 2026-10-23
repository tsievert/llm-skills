# What goes into a deposit, and how to lay it out

Sources read 2026-10-23: Turing Way (Research Compendia, RDM storage and checklist, licensing for data), Wilson et al. 2017
"Good enough practices in scientific computing", the Dryad file requirements page. Marwick et al. 2017 and Noble 2009 were not read.

## Contents

- Decide what is deposited
- Layout
- File names
- Formats
- Raw data
- Personal data and sensitive locations
- Clean-clone test
- Deposit size and splitting

## Decide what is deposited

| Part | Deposit? | Notes |
|---|---|---|
| Data the paper's numbers come from (raw or the earliest shareable form) | Yes | Raw if it can be shared; otherwise the earliest form that can, with the processing code |
| Processed data and model inputs | Yes if they are small or hard to regenerate | Otherwise regenerate with the pipeline and say so |
| Source data for each figure and table | Yes | Often the cheapest way to let readers check a plot |
| Analysis code (scripts, Quarto, pipeline definition) | Yes where the journal or repository wants it | Journal table in `journal-policies.md` |
| Environment: `renv.lock`, `uv.lock`, `pyproject.toml`, `sessionInfo()` output, OS and tool versions | Yes | From the pipeline skills; `check_deposit()` warns when code has none |
| Regenerable intermediates, caches, `_targets/`, `.snakemake/`, `.venv/` | No | Rebuilt by the pipeline |
| Credentials, tokens, `.Renviron`, `.env` | Never | |
| Third-party data | Only with permission; otherwise cite and give the access route | State the licence in the README |
| Personal data, unpublished sensitive locations | Not without a decision (below) | |
| Manuscript, reviewer correspondence | No | |

Ask the user for each excluded item why it is excluded; the README should say so (`data-repository-readme`: "Not included" section).

## Layout

One folder per paper, sorted by who writes the files (Turing Way compendium idea):

```
deposit/
  README.md          human-written, top level, stands alone
  LICENSE            code licence (data licence is in the README and repository form)
  data/              raw/ and processed/ as separate folders; raw is read-only
  code/              scripts or the pipeline project; relative paths only
  figures-source/    tables behind each figure, if not produced by code
  environment/       lockfiles and the session-info text
  MANIFEST.tsv       written by stage_deposit(): path, bytes, sha256
```

Keep it flat enough to describe in the README in a short tree. Journal rules may override (for example Behavioral Ecology wants data as CSV and a README describing each file).

## File names

Lowercase, ASCII, hyphen or underscore, no spaces, ISO date first when a date is in the name (`2026-03-14_trial-01.csv`), no personal data in names, and the convention written in the README (Turing Way). `check_deposit()` flags spaces, non-ASCII, characters that ERDA rejects (`< > { | } * ? [ ]` plus a few more), paths over 150 characters and case-only differences.

## Formats

Open, plain, documented: CSV or TSV (UTF-8, one header row, no merged cells), plain text, JSON, parquet where size matters; images as PNG or TIFF; README in Markdown. Replace cryptic codes (`-99`) with `NA` or document them. Excel, SPSS, Stata and MATLAB files are flagged as info: keep one only with a reason. R or Python binary objects (`.rds`, `.pkl`) need an open-format copy of the data that matter. Dryad: CSV, TSV or ODF preferred, no RAR.

## Raw data

Keep raw data read-only and in more than one place (Wilson 2017, Turing Way). The Windows read-only flag works as a guard against accidental edits (tested; not a security measure): `stage_deposit(..., read_only = TRUE)` sets it on the staged copy. Processing is recorded in scripts, not in the files.

## Personal data and sensitive locations

Stop and ask before staging anything that contains: names or contact details of people (observers, landowners), video or images of people, exact coordinates of protected or sensitive species, or data under a third-party agreement. Options the user decides: remove or aggregate (round coordinates, drop identifiers), restricted or embargoed access in the repository with a stated access route, or deposit a metadata-only record. Some archives forbid personal data outright (ERDA does). The assistant does not decide what is anonymous enough.

## Clean-clone test

Reproducibility is only shown by running the deposit somewhere clean. Scratch folder outside the project:

1. Export the code from Git: `git clone` or `git archive` of the tagged commit (not the working folder; `git-for-research-projects`).
2. Place the staged data where the code expects it (config path, not a hard-coded one).
3. Restore the environment from the lockfile: `renv::restore()`, or `uv sync --locked`.
4. Run the single documented command (`targets::tar_make()`, `snakemake --cores 1`, `quarto render`). See `r-reproducible-pipeline` or `python-reproducible-pipeline`.
5. Compare the headline numbers and tables with the paper (tolerance, not byte equality; plots and timestamps differ).
6. Record date, OS, R and Python versions, runtime, and anything that had to be fixed. Put the fix in the code, then repeat.

The steps follow from the pipeline skills' tested behaviour (locked environments, seeds that reproduce); the combined clean-clone run was **not tested** end to end for this skill.

## Deposit size and splitting

Check totals against the live repository limits (`repositories.md`). Bundle many small files into a documented zip when a count limit applies (Zenodo: 100 files per upload through the form). Split very large raw data into a separate deposit with its own DOI and cross-reference it (related identifiers); keep the analysis deposit small enough to download and run.
