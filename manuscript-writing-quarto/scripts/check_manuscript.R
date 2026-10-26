# Flags-only checks for a Quarto manuscript, modelled on the Morrison-Lab/qmt
# CI pattern (spell check, link check, BibTeX DOI check, non-standard
# characters). Nothing here edits prose or the .bib file; it only reports.
#
# Usage:
#   source("manuscript-writing-quarto/scripts/check_manuscript.R")
#   spell_check_manuscript("paper.qmd", ignore = c("Quarto", "glmmTMB"))
#   check_bib_duplicates("references.bib")
#   check_non_standard_chars("paper.qmd")

#' Spell-check one or more .qmd/.Rmd files, skipping code chunks.
#'
#' Wraps spelling::spell_check_files(), which already parses by extension and
#' checks only text fields (code chunks, YAML metadata and chunk options are
#' ignored) -- so a typo inside a code comment will NOT be caught here; that
#' is a lint-the-prose tool, not a code linter.
#'
#' @param files Character vector of file paths.
#' @param ignore Character vector of words to treat as correctly spelled
#'   (package names, jargon, author names). Grows with the project; keep it
#'   in version control alongside the manuscript, not in this script.
#' @param lang Hunspell dictionary, e.g. "en_US" or "en_GB".
spell_check_manuscript <- function(files, ignore = character(), lang = "en_US") {
  stopifnot(requireNamespace("spelling", quietly = TRUE))
  spelling::spell_check_files(files, ignore = ignore, lang = lang)
}

#' Find duplicate BibTeX cite keys in a .bib file.
#'
#' Read-only: reports duplicates and a count of entries missing a `doi`
#' field, but never rewrites the .bib (per the skill's standing rule -- the
#' bibliography is user-owned).
#'
#' @param bib_file Path to a .bib file.
check_bib_duplicates <- function(bib_file) {
  lines <- readLines(bib_file, warn = FALSE)
  key_lines <- grep("^@\\w+\\{", lines, value = TRUE)
  keys <- sub("^@\\w+\\{\\s*([^,]+),.*", "\\1", key_lines)
  dupes <- keys[duplicated(keys)]
  n_entries <- length(keys)
  n_with_doi <- length(grep("^\\s*doi\\s*=", lines, ignore.case = TRUE))
  list(
    n_entries = n_entries,
    duplicate_keys = unique(dupes),
    entries_with_doi_field = n_with_doi,
    note = "DOI field count is a coarse proxy (counts `doi =` lines); it does not validate that the DOI resolves."
  )
}

#' Flag curly quotes, em/en dashes and other non-ASCII punctuation.
#'
#' These often creep in from pasted text and can break LaTeX/BibTeX builds or
#' look inconsistent across a manuscript. Flags only; the user decides
#' whether to keep or normalise each one (a curly quote may be intentional).
#'
#' @param file A single .qmd/.Rmd/.md file.
check_non_standard_chars <- function(file) {
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  pattern <- "[\u2018\u2019\u201C\u201D\u2013\u2014\u2026]"
  hits <- grep(pattern, lines)
  if (length(hits) == 0) {
    return(data.frame(line = integer(0), text = character(0)))
  }
  data.frame(line = hits, text = lines[hits], row.names = NULL)
}
