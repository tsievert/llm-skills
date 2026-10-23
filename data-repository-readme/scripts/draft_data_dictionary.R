# Draft the factual parts of a README from the files on disk.
# Base R only. It reports what can be MEASURED (type, missing count, range,
# example values). Definitions, units and missing-value codes cannot be
# measured: they are left as [TODO] for the data owner. Never fill them by guessing.
#
# Usage:
#   source("data-repository-readme/scripts/draft_data_dictionary.R")
#   inventory_files("path/to/deposit")                  # file list with sizes, rows, cols
#   dd <- draft_data_dictionary("path/to/deposit/file.csv")
#   cat(dictionary_to_markdown(dd), sep = "\n")         # paste into the README

inventory_files <- function(dir, recursive = TRUE, exclude = "^README") {
  f <- list.files(dir, recursive = recursive, full.names = TRUE)
  f <- f[!file.info(f)$isdir]
  f <- f[!grepl(exclude, basename(f), ignore.case = TRUE)]
  rel <- sub(paste0("^", normalizePath(dir, winslash = "/"), "/?"), "",
             normalizePath(f, winslash = "/"))
  out <- data.frame(file = rel, ext = tolower(tools::file_ext(f)),
                    size_kb = round(file.size(f) / 1024, 1),
                    n_rows = NA_integer_, n_cols = NA_integer_,
                    stringsAsFactors = FALSE)
  for (i in seq_along(f)) {
    if (out$ext[i] %in% c("csv", "tsv", "txt")) {
      d <- tryCatch(.read_table(f[i]), error = function(e) NULL)
      if (!is.null(d)) { out$n_rows[i] <- nrow(d); out$n_cols[i] <- ncol(d) }
    }
  }
  out
}

.read_table <- function(path) {
  first <- readLines(path, n = 1, warn = FALSE)
  sep <- if (grepl("\t", first)) "\t" else if (lengths(regmatches(first, gregexpr(";", first))) >
    lengths(regmatches(first, gregexpr(",", first)))) ";" else ","
  utils::read.table(path, header = TRUE, sep = sep, quote = "\"", comment.char = "",
                    stringsAsFactors = FALSE, check.names = FALSE,
                    na.strings = c("NA", ""), fill = TRUE)
}

draft_data_dictionary <- function(path, max_examples = 4) {
  d <- .read_table(path)
  iso <- "^\\d{4}-\\d{2}-\\d{2}([T ]\\d{2}:\\d{2}(:\\d{2})?)?$"
  rows <- lapply(names(d), function(nm) {
    x <- d[[nm]]
    nn <- x[!is.na(x)]
    nonISO <- is.character(nn) && any(grepl("^\\d{1,2}[./-]\\d{1,2}[./-]\\d{2,4}$", nn))
    type <- if (is.numeric(nn) && all(nn == round(nn))) "integer"
            else if (is.numeric(nn)) "numeric"
            else if (is.logical(nn)) "logical"
            else if (length(nn) && all(grepl(iso, nn))) "date/time (ISO 8601)"
            else if (nonISO) "date (NOT ISO 8601, or mixed formats)"
            else if (length(unique(nn)) <= 12) "categorical"
            else "text"
    rng <- if (type %in% c("integer", "numeric")) paste(signif(range(nn), 5), collapse = " to ")
           else if (type == "categorical") paste(sort(unique(nn)), collapse = ", ")
           else paste(utils::head(unique(nn), max_examples), collapse = ", ")
    data.frame(variable = nm, type = type, n_missing = sum(is.na(x)),
               range_or_levels = rng,
               suspicious = if (is.character(nn) && any(nn %in% c("-999", "-99", "999", "9999", "99999", "NULL", "na", "N/A", "n/a", "."))) "possible missing-value code"
                            else if (is.numeric(nn) && any(nn %in% c(-999, -99, 999, 9999))) "possible missing-value code"
                            else if (nonISO) "convert dates to YYYY-MM-DD"
                            else "",
                    stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  out$definition <- "[TODO: full name and definition]"
  out$unit <- "[TODO: unit or 'none']"
  attr(out, "n_rows") <- nrow(d)
  attr(out, "file") <- basename(path)
  out
}

dictionary_to_markdown <- function(dd) {
  esc <- function(s) gsub("\\|", "/", s)
  hdr <- c(sprintf("#### `%s` (%d rows, %d variables)", attr(dd, "file"), attr(dd, "n_rows"), nrow(dd)),
           "",
           "| Variable | Type | Unit | Definition | Missing (n) | Range / levels |",
           "|---|---|---|---|---|---|")
  body <- sprintf("| `%s` | %s | %s | %s | %d | %s |",
                  dd$variable, dd$type, dd$unit, dd$definition, dd$n_missing, esc(dd$range_or_levels))
  c(hdr, body, "", paste0("Flags for the data owner: ",
    if (any(dd$suspicious != "")) paste(sprintf("`%s`: %s", dd$variable[dd$suspicious != ""], dd$suspicious[dd$suspicious != ""]), collapse = "; ") else "none"))
}
