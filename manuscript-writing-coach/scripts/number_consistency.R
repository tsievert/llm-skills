# Read-only check: which numbers in a manuscript's abstract do not appear in its body?
# Reports findings only; it never edits the manuscript. A hit is a question for the author
# ("is this the same estimate, rounded, or a different one?"), not a verdict.
#
# Usage:
#   source("<skill-dir>/scripts/number_consistency.R")
#   r <- mc_abstract_numbers("C:/path/to/paper.qmd")      # or a literal text string
#   mc_abstract_summary(r); r[r$status != "found", ]
#   # abstract pasted separately (e.g. a journal form): mc_abstract_numbers(body_text, abstract = "...")
#
# Reads .qmd/.Rmd/.md/.tex/.txt. For .docx or .pdf, render or export to text first (the script
# does not parse them). Inline R (`r ...`) is not evaluated: run it on the rendered .md output
# (quarto render --to gfm) when abstract or body numbers come from inline code.
# Needs the `yaml` package only when the abstract sits in the YAML header.

# ---- reading and splitting ---------------------------------------------------------------------

mc_read_lines <- function(x) {
  if (length(x) == 1L && !grepl("\n", x, fixed = TRUE) && nzchar(x) && file.exists(x)) {
    readLines(x, warn = FALSE, encoding = "UTF-8")
  } else {
    if (length(x) == 1L && !grepl("\n", x, fixed = TRUE) && grepl("^[A-Za-z]:[\\\\/]|^~|\\.(qmd|Rmd|md|tex|txt)$", x)) {
      warning("`", x, "` looks like a path but does not exist; reading it as literal text.", call. = FALSE)
    }
    unlist(strsplit(x, "\r?\n"))
  }
}

mc_split_yaml <- function(lines) {
  if (length(lines) > 1L && trimws(lines[1]) == "---") {
    end <- which(trimws(lines[-1]) %in% c("---", "..."))[1]
    if (!is.na(end)) return(list(yaml = lines[2:end], body = lines[-seq_len(end + 1L)]))
  }
  list(yaml = character(), body = lines)
}

mc_yaml_abstract <- function(yaml_lines) {
  if (!length(yaml_lines)) return(NULL)
  if (!requireNamespace("yaml", quietly = TRUE)) {
    warning("Package 'yaml' is not installed, so a YAML `abstract:` cannot be read; ",
            "install it from CRAN or pass `abstract =` explicitly.", call. = FALSE)
    return(NULL)
  }
  y <- tryCatch(yaml::yaml.load(paste(yaml_lines, collapse = "\n")), error = function(e) NULL)
  a <- if (is.list(y)) y$abstract else NULL
  if (is.character(a) && length(a) == 1L && nzchar(trimws(a))) a else NULL
}

.mc_section_names <- "(introduction|background|methods?|materials and methods|results?|discussion|conclusions?|key ?words?)"

# Abstract as a heading section ("# Abstract", "Abstract", \begin{abstract}); returns list(text, idx) or NULL
mc_heading_abstract <- function(lines) {
  s <- grep("\\\\begin\\{abstract\\}", lines)
  e <- grep("\\\\end\\{abstract\\}", lines)
  if (length(s) && length(e) && e[1] >= s[1]) {
    return(list(text = paste(lines[s[1]:e[1]], collapse = "\n"), idx = s[1]:e[1]))
  }
  h <- grep("^\\s*(#{1,6}\\s*)?abstract\\s*:?\\s*(\\{.*\\})?\\s*$", lines, ignore.case = TRUE)
  if (!length(h)) return(NULL)
  nxt <- grep(paste0("^\\s*(#{1,6}\\s|\\\\(sub)*section\\b|", .mc_section_names, "\\s*:?\\s*$)"),
              lines, ignore.case = TRUE)
  nxt <- nxt[nxt > h[1]]
  end <- if (length(nxt)) nxt[1] - 1L else length(lines)
  if (end <= h[1]) return(NULL)
  list(text = paste(lines[(h[1] + 1L):end], collapse = "\n"), idx = h[1]:end)
}

# Drop fenced code, HTML comments and the reference list; keep prose lines
mc_prose_lines <- function(lines) {
  fence <- grepl("^\\s*(```|~~~)", lines)
  keep <- (cumsum(fence) %% 2L == 0L) & !fence
  lines <- lines[keep]
  head_ref <- grep("^\\s*#{1,6}\\s*(references|bibliography|literature cited)\\s*$", lines, ignore.case = TRUE)
  if (length(head_ref)) {
    nxt <- grep("^\\s*#{1,6}\\s", lines)
    nxt <- nxt[nxt > head_ref[1]]
    drop <- head_ref[1]:(if (length(nxt)) nxt[1] - 1L else length(lines))
    lines <- lines[-drop]
  }
  txt <- gsub("(?s)<!--.*?-->", " ", paste(lines, collapse = "\n"), perl = TRUE)
  unlist(strsplit(txt, "\n", fixed = TRUE))
}

# Remove text whose digits are not findings: citations, links, figure/table numbers, years in references
mc_clean_text <- function(txt) {
  txt <- gsub("`[^`]*`", " ", txt)
  txt <- gsub("\\[[^]]*@[^]]*\\]", " ", txt)
  txt <- gsub("@[A-Za-z][A-Za-z0-9:._-]*", " ", txt)
  txt <- gsub("\\[\\d+(\\s*[,\u2013-]\\s*\\d+)*\\]", " ", txt)
  txt <- gsub("https?://\\S+|doi:\\S+|10\\.\\d{4,}/\\S+", " ", txt)
  txt <- gsub("\\]\\([^)]*\\)", "]", txt)
  txt <- gsub(paste0("\\b(Figs?\\.?|Figures?|Tables?|Eqs?\\.?|Equations?|Sections?|Appendix|Supplementary)\\s+",
                     "(Figures?\\s+|Tables?\\s+)?S?\\d+[A-Za-z]?(\\s*[-\u2013,&]\\s*S?\\d+[A-Za-z]?)*"), " ", txt, ignore.case = TRUE)
  txt <- gsub("^\\s*\\|?[\\s:|-]+\\|?\\s*$", " ", txt, perl = TRUE)
  paste(txt, collapse = " ")
}

# ---- numbers ------------------------------------------------------------------------------------

.mc_num_pattern <- "(?<![\\w.])[-\u2212]?(?:\\d+(?:,\\d{3})*(?:\\.\\d+)?|\\.\\d+)(?!\\d)"

mc_extract_numbers <- function(txt, ignore_years = TRUE, width = 40) {
  m <- gregexpr(.mc_num_pattern, txt, perl = TRUE)[[1]]
  if (m[1] == -1L) {
    return(data.frame(raw = character(), value = numeric(), decimals = integer(),
                      percent = logical(), context = character(), stringsAsFactors = FALSE))
  }
  raw <- regmatches(txt, list(m))[[1]]
  start <- as.integer(m)
  end <- start + attr(m, "match.length") - 1L
  clean <- gsub("\u2212", "-", gsub(",", "", raw, fixed = TRUE), fixed = TRUE)
  value <- as.numeric(clean)
  decimals <- ifelse(grepl("\\.", clean), nchar(sub(".*\\.", "", clean)), 0L)
  percent <- substring(txt, end + 1L, end + 1L) == "%"
  year <- ignore_years & decimals == 0L & !percent & value >= 1900 & value <= 2100
  ctx <- trimws(substring(txt, pmax(1L, start - width), pmin(nchar(txt), end + width)))
  out <- data.frame(raw = raw, value = value, decimals = as.integer(decimals), percent = percent,
                    context = ctx, stringsAsFactors = FALSE)
  out[!year & !is.na(value), , drop = FALSE]
}

# ---- main -----------------------------------------------------------------------------------------

#' Compare abstract numbers with body numbers (read-only).
#'
#' @param x Path to a manuscript text file, or the text itself.
#' @param abstract Optional abstract text. If NULL it is taken from a YAML `abstract:`,
#'   an "Abstract" heading or a LaTeX abstract environment (in that order).
#' @param ignore_years Skip four-digit integers from 1900 to 2100 (usually citation years).
#' @return A data frame with one row per abstract number: `status` is
#'   "found" (same value in the body), "rounded_match" (the body has the same value with more
#'   decimals), "pct_vs_proportion" (45% in the abstract, 0.45 in the body, or the reverse), or
#'   "missing" (no matching value in the body). `weak` marks single-digit integers, which match
#'   by chance in almost any body.
mc_abstract_numbers <- function(x, abstract = NULL, ignore_years = TRUE) {
  lines <- mc_read_lines(x)
  if (!length(lines)) stop("No text to read.", call. = FALSE)
  parts <- mc_split_yaml(lines)
  body_lines <- parts$body
  source_of_abstract <- "argument"

  if (is.null(abstract)) {
    abstract <- mc_yaml_abstract(parts$yaml)
    source_of_abstract <- "yaml"
    if (is.null(abstract)) {
      h <- mc_heading_abstract(body_lines)
      if (!is.null(h)) {
        abstract <- h$text
        body_lines <- body_lines[-h$idx]
        source_of_abstract <- "heading"
      }
    }
  }
  if (is.null(abstract)) {
    stop("No abstract found (looked for a YAML `abstract:`, an 'Abstract' heading and a LaTeX ",
         "abstract environment). Pass it explicitly with `abstract = \"...\"`.", call. = FALSE)
  }

  all_text <- paste(c(lines, ""), collapse = "\n")
  if (grepl("`r\\s", all_text)) {
    warning("Inline R code (`r ...`) found: its values are not evaluated here. ",
            "For a reliable comparison, render to markdown first and run this on the output.",
            call. = FALSE)
  }

  abs_txt <- mc_clean_text(mc_prose_lines(unlist(strsplit(abstract, "\r?\n"))))
  body_txt <- mc_clean_text(mc_prose_lines(body_lines))
  a <- mc_extract_numbers(abs_txt, ignore_years)
  b <- mc_extract_numbers(body_txt, ignore_years)

  if (!nrow(a)) {
    out <- data.frame(abstract_number = character(), status = character(), weak = logical(),
                      n_in_body = integer(), abstract_context = character(),
                      body_context = character(), stringsAsFactors = FALSE)
  } else {
    tol <- 1e-9
    res <- lapply(seq_len(nrow(a)), function(i) {
      v <- a$value[i]; d <- a$decimals[i]
      exact <- which(abs(b$value - v) < tol)
      rounded <- which(b$decimals > d & abs(round(b$value, d) - v) < tol)
      pct <- if (a$percent[i]) which(abs(b$value - v / 100) < tol & !b$percent) else
        which(b$percent & abs(b$value / 100 - v) < tol)
      status <- if (length(exact)) "found" else if (length(rounded)) "rounded_match" else
        if (length(pct)) "pct_vs_proportion" else "missing"
      hit <- switch(status, found = exact, rounded_match = rounded, pct_vs_proportion = pct, integer())
      data.frame(abstract_number = paste0(a$raw[i], if (a$percent[i]) "%" else ""),
                 status = status,
                 weak = d == 0L && abs(v) < 10,
                 n_in_body = length(hit),
                 abstract_context = a$context[i],
                 body_context = if (length(hit)) b$context[hit[1]] else NA_character_,
                 stringsAsFactors = FALSE)
    })
    out <- do.call(rbind, res)
  }
  attr(out, "abstract_source") <- source_of_abstract
  attr(out, "n_body_numbers") <- nrow(b)
  attr(out, "abstract_words") <- length(strsplit(trimws(abs_txt), "\\s+")[[1]])
  out
}

mc_abstract_summary <- function(r) {
  cat("Abstract taken from:", attr(r, "abstract_source"), "| abstract words:", attr(r, "abstract_words"),
      "| numbers in abstract:", nrow(r), "| numbers in body:", attr(r, "n_body_numbers"), "\n")
  if (nrow(r)) print(table(status = r$status, weak = r$weak))
  invisible(r)
}
