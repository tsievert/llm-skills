# Linting and proofreading checklist

Everything here flags; nothing rewrites prose or the `.bib` file automatically. Modelled on the
`Morrison-Lab/qmt` starter template's CI checks (spell check, link check, R lint, BibTeX DOI validation,
non-standard-character check), adapted into on-demand R functions in `scripts/check_manuscript.R` rather than
GitHub Actions, since this skill runs interactively in RStudio, not in CI.

## Spelling

```r
source("manuscript-writing-quarto/scripts/check_manuscript.R")
spell_check_manuscript("paper.qmd", ignore = c("Quarto", "glmmTMB", "hunspell"))
```

Wraps `spelling::spell_check_files()`, which parses by file extension and checks only text fields; code
chunks, YAML metadata and chunk options are skipped (confirmed by testing: a typo inside an R comment inside
a code chunk was not flagged). That means this is a prose spell-checker, not a code linter — a typo in a
variable name or comment needs a different tool. Keep the `ignore` list (package names, jargon, author
names, acronyms) in a tracked file next to the manuscript so it grows with the project instead of being
retyped per call.

## Grammar

```r
source("manuscript-writing-quarto/scripts/check_grammar.R")
check_grammar("paper.qmd", lt_dir = "path/to/LanguageTool-6.5")
```

Wraps `LanguageTool` (Java, GPL, https://languagetool.org) via the GitHub package `LanguageToolR`
(`nevrome/LanguageToolR`, "inactive" but stable) — installed with the user's explicit permission, since it
is not on CRAN (repo working rule). One-time setup, confirmed working on Windows with OpenJDK 26/27:

```r
remotes::install_github("nevrome/LanguageToolR")
LanguageToolR::lato_quick_setup(path = "~")   # downloads LanguageTool-6.5, ~240 MB
```

Two gotchas found while testing, both handled by `check_grammar.R` so the user doesn't have to:

- **JDK entity-size limit.** On a current JDK (confirmed on OpenJDK 26/27), LanguageTool 6.5's bundled
  `grammar.xml` fails to load with `Could not activate rules` / `JAXP00010004` unless the command line adds
  `-Djdk.xml.totalEntitySizeLimit=0`. This is a JDK XML-hardening default, not a LanguageTool bug;
  `lt_executable()` always adds the flag. Re-test if a future LanguageTool release changes this.
- **Code chunks are not skipped by `LanguageToolR::languagetool(input_file = ...)`.** Unlike
  `spelling::spell_check_files()`, feeding it a raw `.qmd` file checks the R code and chunk delimiters
  verbatim and produces false positives (confirmed by testing: it flagged the literal text
  ```` ```{r} ```` and code inside it). `check_grammar()` strips code chunks and YAML front matter first via
  `qmd_prose_lines()`, which reuses `spelling`'s own internal (unexported) chunk/front-matter detection
  rather than re-implementing knitr-pattern parsing — tested against `spelling` 2.3.2; re-check after a
  `spelling` update since unexported functions carry no API guarantee.

Flags only, like every other check here; the user decides what to change. LanguageTool's checks are
heuristic and will have false positives on domain jargon and statistical phrasing — read each flag rather
than acting on all of them.

## Bibliography (never auto-edited)

```r
check_bib_duplicates("references.bib")
```

Reports duplicate cite keys and a coarse count of entries with a `doi =` field (it does not resolve DOIs
against Crossref — that would need a network call and is a reasonable next step if the user wants stronger
validation, akin to `qmt`'s `check-bibliography-dois` Action). The `.bib` file is user-owned; report
findings and let the user fix them.

## Non-standard characters

```r
check_non_standard_chars("paper.qmd")
```

Flags curly quotes, em/en dashes and ellipsis characters, which often arrive via pasted text and can look
inconsistent across a manuscript or trip up some LaTeX/BibTeX toolchains. Flags only — a curly quote may be
intentional (e.g. inside a quoted passage); the user decides whether to normalise each hit.

## Links

Not yet implemented as a script (no CRAN package evaluated for this; `qmt`'s link check runs as a GitHub
Action using a generic markdown-link-checker, not an R tool). Note it as a gap if the user asks for a
pre-submission link check, rather than guessing a tool.

## Pre-submission pass (suggested order)

1. `spell_check_manuscript()` on every `.qmd`/`.Rmd` file that will ship.
2. `check_grammar()` on the same files, if LanguageTool is set up (ask the user first; it is a GitHub install).
3. `check_bib_duplicates()` on the `.bib` file.
4. `check_non_standard_chars()` on every `.qmd`/`.Rmd` file.
5. Manually confirm cross-references and figure/table numbering in the rendered output (Pandoc docx output
   especially, since it is the format most likely to lose cross-references for some journal templates).
