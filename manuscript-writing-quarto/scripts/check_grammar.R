# Grammar/style checking for .qmd/.Rmd manuscripts via LanguageTool, wrapped by
# the GitHub package LanguageToolR (installed with the user's explicit
# permission; see references/linting-checklist.md for why this needed asking
# and spell_check_manuscript() in check_manuscript.R for the CRAN-only
# spelling path that needs no such permission).
#
# One-time setup (downloads ~240 MB):
#   remotes::install_github("nevrome/LanguageToolR")
#   LanguageToolR::lato_quick_setup(path = "~")   # or any writable folder
#
# Requires a 64-bit Java on PATH. Flags only; never rewrites the manuscript.

#' Build the LanguageTool executable string, with the JDK XML-limit fix.
#'
#' LanguageTool 6.5's bundled grammar.xml trips the entity-size guard added in
#' recent JDKs (confirmed on OpenJDK 26/27: "Could not activate rules" /
#' "JAXP00010004" without this flag). `-Djdk.xml.totalEntitySizeLimit=0`
#' removes the limit; LanguageTool's own grammar files are trusted input, not
#' attacker-controlled XML, so disabling the guard for this one process is
#' low-risk. If a future LanguageTool release fixes this upstream, the flag is
#' harmless to keep.
#'
#' @param lt_dir Path to the unpacked `LanguageTool-<version>` folder (the
#'   folder `lato_quick_setup()` creates, containing
#'   `languagetool-commandline.jar`).
lt_executable <- function(lt_dir) {
  jar <- file.path(lt_dir, "languagetool-commandline.jar")
  if (!file.exists(jar)) {
    stop("languagetool-commandline.jar not found in ", lt_dir,
         " -- run LanguageToolR::lato_quick_setup() first.")
  }
  sprintf('java -Djdk.xml.totalEntitySizeLimit=0 -jar "%s"', jar)
}

#' Extract just the prose from a .qmd/.Rmd file (code chunks and YAML front
#' matter removed), so LanguageTool is not run over R code and chunk options.
#'
#' Unlike spelling::spell_check_files() (which does this internally),
#' LanguageToolR::languagetool(input_file = ...) checks the raw file verbatim,
#' so it WILL flag nonsense inside code chunks if given the file directly
#' (confirmed by testing). This function reuses spelling's own two internal,
#' unexported chunk/front-matter helpers rather than re-implementing
#' knitr-pattern detection; being unexported, they could change in a future
#' spelling release without a deprecation warning -- re-check after a
#' spelling update if this starts erroring (tested against spelling 2.3.2).
#'
#' @param path Path to a .qmd/.Rmd/.md file.
qmd_prose_lines <- function(path) {
  stopifnot(requireNamespace("spelling", quietly = TRUE))
  lines <- spelling:::remove_chunks(path)
  parts <- spelling:::partition_yaml_front_matter(lines)
  parts$body
}

#' Grammar/style-check one manuscript file's prose with LanguageTool.
#'
#' @param file Path to a .qmd/.Rmd/.md file.
#' @param lt_dir Path to the unpacked LanguageTool-<version> folder.
#' @param language LanguageTool language code, e.g. "en-US" or "en-GB".
#' @param ... Passed on to LanguageToolR::languagetool() (e.g.
#'   `disabled_rules =` to silence a rule the project doesn't want).
#' @return A tibble of matches (message, sentence, rule_id, ...), or an empty
#'   result if nothing was flagged. Nothing is written back to `file`.
check_grammar <- function(file, lt_dir, language = "en-US", ...) {
  stopifnot(requireNamespace("LanguageToolR", quietly = TRUE))
  prose <- qmd_prose_lines(file)
  prose <- prose[nzchar(trimws(prose))]
  if (length(prose) == 0) {
    return(prose)
  }
  LanguageToolR::languagetool(
    prose,
    executable = lt_executable(lt_dir),
    language = language,
    ...
  )
}
