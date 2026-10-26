# Thin wrapper around CRediTas for CRediT contributor-role statements.
# CRediTas (CRAN) already does the hard part (template -> table -> statement);
# this file only adds a safe round-trip and a LaTeX output option, which
# CRediTas does not ship.
#
# Workflow:
#   credit_template(authors, "credit.csv")   # once, creates the fill-in CSV
#   ... user fills in 1s in a text editor or spreadsheet, NOT via read.csv() ...
#   tbl <- credit_table("credit.csv")        # safe re-read
#   credit_statement(tbl, "credit_statement.md")                # markdown/text
#   credit_statement(tbl, "credit_statement.tex", format = "latex")

#' Create a CRediT fill-in template (wraps CRediTas::template_create()).
#'
#' @param authors Character vector of author names, in byline order.
#' @param file Path to the CSV to create.
#' @param roles Optional character vector of role names, if the journal wants
#'   a non-standard role list. Defaults to the 14 standard CRediT roles.
credit_template <- function(authors, file, roles = NULL) {
  stopifnot(requireNamespace("CRediTas", quietly = TRUE))
  if (is.null(roles)) {
    CRediTas::template_create(authors = authors, file = file)
  } else {
    CRediTas::template_create(authors = authors, file = file, roles = roles)
  }
  invisible(file)
}

#' Read a filled-in CRediT CSV back in.
#'
#' Wraps CRediTas::template_read(), which already reads with
#' check.names = FALSE internally, so role names like "Writing - original
#' draft" survive. The gotcha this guards against: if you (or a script)
#' re-import the CSV with base read.csv()'s *default* settings and write it
#' back out, R's make.names() mangles those names (spaces/dashes/ampersands
#' become dots), and CRediTas will then treat each mangled string as a role
#' label instead of recognising it. Always edit the CSV directly in a text
#' editor or spreadsheet, or if scripting, use
#' read.csv(file, sep = ";", check.names = FALSE) explicitly.
credit_table <- function(file) {
  stopifnot(requireNamespace("CRediTas", quietly = TRUE))
  CRediTas::template_read(file)
}

#' Write a CRediT statement in markdown/text (via CRediTas) or LaTeX.
#'
#' @param cras_table A table from credit_table()/CRediTas::template_read().
#' @param file Output file path.
#' @param format "markdown" (default, passed through to CRediTas::cras_write()
#'   with markdown = TRUE) or "latex" (this wrapper's own renderer, since
#'   CRediTas only documents text/markdown output).
#' @param by_role If TRUE, group by role ("Conceptualization: Jane Doe, John
#'   Smith.") instead of by author ("Jane Doe: Conceptualization, ..."). Note
#'   CRediTas::cras_write() itself only produces the per-author form; the
#'   per-role form here is a manual re-render from the same table, so both
#'   stay in sync with one source CSV.
#' @param overwrite Passed to CRediTas::cras_write() for the markdown path.
credit_statement <- function(cras_table, file, format = c("markdown", "latex"),
                              by_role = FALSE, overwrite = TRUE) {
  format <- match.arg(format)
  stopifnot(requireNamespace("CRediTas", quietly = TRUE))

  role_cols <- setdiff(names(cras_table), "Authors")
  by_author_list <- lapply(seq_len(nrow(cras_table)), function(i) {
    roles <- role_cols[as.logical(cras_table[i, role_cols])]
    list(author = cras_table$Authors[i], roles = roles)
  })

  if (format == "markdown" && !by_role) {
    CRediTas::cras_write(cras_table, file = file, markdown = TRUE, overwrite = overwrite)
    return(invisible(file))
  }

  if (by_role) {
    by_role_list <- stats::setNames(
      lapply(role_cols, function(r) cras_table$Authors[as.logical(cras_table[[r]])]),
      role_cols
    )
    by_role_list <- Filter(function(x) length(x) > 0, by_role_list)
    lines <- if (format == "latex") {
      vapply(names(by_role_list), function(r) {
        sprintf("\\textbf{%s:} %s.", r, paste(by_role_list[[r]], collapse = ", "))
      }, character(1))
    } else {
      vapply(names(by_role_list), function(r) {
        sprintf("**%s:** %s.", r, paste(by_role_list[[r]], collapse = ", "))
      }, character(1))
    }
  } else {
    # format == "latex", by author
    lines <- vapply(by_author_list, function(a) {
      if (length(a$roles) == 0) return(NULL)
      sprintf("\\textbf{%s:} %s.", a$author, paste(a$roles, collapse = ", "))
    }, character(1))
  }

  writeLines(paste(lines, collapse = " "), file)
  invisible(file)
}
