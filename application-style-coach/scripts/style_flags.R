# Read-only style flags for academic application documents (English).
# Usage: source("<skill-dir>/scripts/style_flags.R"); f <- style_flags("<path or text>"); style_flags_summary(f)
# Requires: stringi. Optional: xml2 (.docx) and pdftools (.pdf). Never writes to the input file.
# Flags are prompts for a conversation, not verdicts: every hit needs the user's judgement.

read_application_text <- function(path) {
  stopifnot(length(path) == 1)
  if (!file.exists(path)) return(path)  # treat as literal text
  ext <- tolower(tools::file_ext(path))
  if (ext == "docx") {
    if (!requireNamespace("xml2", quietly = TRUE)) stop("Install xml2 to read .docx files.")
    td <- tempfile(); dir.create(td); on.exit(unlink(td, recursive = TRUE))
    utils::unzip(path, "word/document.xml", exdir = td)
    x <- xml2::read_xml(file.path(td, "word/document.xml")); ns <- xml2::xml_ns(x)
    p <- xml2::xml_find_all(x, "//w:p", ns)
    txt <- vapply(p, function(n) paste(xml2::xml_text(xml2::xml_find_all(n, ".//w:t", ns)), collapse = ""), "")
  } else if (ext == "pdf") {
    if (!requireNamespace("pdftools", quietly = TRUE)) stop("Install pdftools to read .pdf files.")
    txt <- unlist(strsplit(paste(pdftools::pdf_text(path), collapse = "\n"), "\n"))
  } else {
    txt <- readLines(path, warn = FALSE, encoding = "UTF-8")
    # Drop YAML front matter and fenced code so only prose is checked
    fence <- grepl("^\\s*(```|~~~)", txt)
    txt <- txt[cumsum(fence) %% 2 == 0 & !fence]
    if (length(txt) && grepl("^---\\s*$", txt[1])) {
      end <- which(grepl("^(---|\\.\\.\\.)\\s*$", txt))[2]
      if (!is.na(end)) txt <- txt[-seq_len(end)]
    }
  }
  txt <- gsub("\\s+", " ", txt)
  txt[nzchar(trimws(txt))]
}

.flag_lists <- list(
  hedge = c("may potentially", "I hope to", "I would like to", "I believe", "I feel", "somewhat", "a little",
            "helped with", "assisted with", "was involved in", "tried to", "perhaps", "kind of", "sort of",
            "a small contribution", "modest", "just", "only"),
  inflation = c("world-leading", "world-class", "groundbreaking", "ground-breaking", "pioneering", "revolutionary",
                "unique", "outstanding", "excellent", "passionate", "extremely", "state-of-the-art",
                "cutting-edge", "best", "unparalleled", "transformative", "significant impact", "strong track record",
                "extensive experience", "highly"),
  vague_quantity = c("several", "numerous", "many", "various", "a number of", "a lot of", "multiple"),
  generic_opener = c("I am writing to", "I am excited to", "I would like to apply", "I am applying for the position",
                     "please find attached", "to whom it may concern"),
  generic_phrase = c("leverage", "spearhead", "tapestry", "delve", "realm of", "testament to", "navigate the landscape",
                     "in today's", "fast-paced", "dynamic environment", "team player", "foster", "underscore",
                     "pivotal", "vibrant", "showcase", "multifaceted", "moreover", "furthermore", "additionally",
                     "in conclusion", "it is important to note", "I look forward to the opportunity"),
  status = c("in preparation", "under review", "submitted", "forthcoming", "in press", "accepted", "to be submitted",
             "under revision", "in revision"),
  metrics = c("h-index", "impact factor", "JIF", "JUFO", "quartile", "Q1", "citations", "citation count", "i10"),
  sensitive = c("pregnan", "maternity", "paternity", "parental leave", "family leave", "illness", "health", "religio",
                "married", "my children", "my husband", "my wife", "political")
)

.word_hits <- function(txt, words, type) {
  out <- list()
  for (w in words) {
    pat <- paste0("(?<![\\w-])", stringi::stri_replace_all_regex(w, "([.\\-])", "\\\\$1"),
                  if (grepl("[a-z]$", w, ignore.case = TRUE) && !grepl("(pregnan|religio)", w)) "(?![\\w-])" else "")
    for (i in seq_along(txt)) {
      m <- stringi::stri_locate_all_regex(txt[i], pat, case_insensitive = TRUE)[[1]]
      if (!is.na(m[1, 1])) for (k in seq_len(nrow(m))) {
        s <- max(1, m[k, 1] - 40); e <- min(nchar(txt[i]), m[k, 2] + 40)
        out[[length(out) + 1]] <- data.frame(para = i, type = type, match = substr(txt[i], m[k, 1], m[k, 2]),
                                             context = substr(txt[i], s, e), stringsAsFactors = FALSE)
      }
    }
  }
  if (length(out)) do.call(rbind, out) else NULL
}

#' Flag style issues in an application document.
#' @param x Path to .txt/.md/.qmd/.docx/.pdf, or a literal string.
#' @param max_words Optional word limit from the call, to compare the word count against.
#' @param long_sentence Sentence length (words) above which a sentence is flagged.
#' @return data.frame(para, type, match, context); attribute "words" holds the word count.
style_flags <- function(x, max_words = NULL, long_sentence = 40) {
  stopifnot(requireNamespace("stringi", quietly = TRUE))
  txt <- read_application_text(x)
  res <- list()
  for (nm in names(.flag_lists)) res[[nm]] <- .word_hits(txt, .flag_lists[[nm]], nm)

  sent <- lapply(txt, function(p) stringi::stri_split_boundaries(p, type = "sentence")[[1]])
  for (i in seq_along(sent)) {
    s <- trimws(sent[[i]]); n <- stringi::stri_count_words(s)
    long <- which(n > long_sentence)
    for (j in long) res[[length(res) + 1]] <- data.frame(para = i, type = "long_sentence",
      match = paste(n[j], "words"), context = substr(s[j], 1, 90), stringsAsFactors = FALSE)
    starts_i <- grepl("^I\\b", s)
    runs <- rle(starts_i)
    if (any(runs$values & runs$lengths >= 3)) res[[length(res) + 1]] <- data.frame(para = i, type = "repeated_opener",
      match = "3+ sentences start with 'I'", context = substr(paste(s, collapse = " "), 1, 90), stringsAsFactors = FALSE)
  }

  full <- paste(txt, collapse = " ")
  pat_extra <- c(not_only_but_also = "\\bnot only\\b.{1,80}\\bbut also\\b", em_dash = "\u2014")
  for (nm in names(pat_extra)) {
    n <- length(unlist(regmatches(full, gregexpr(pat_extra[[nm]], full, ignore.case = TRUE))))
    if (n > if (nm == "em_dash") 2 else 0) res[[length(res) + 1]] <- data.frame(para = NA_integer_,
      type = "generic_phrase", match = sprintf("%s x%d", nm, n),
      context = "Pattern common in boilerplate; ask whether the user's own wording would be plainer.",
      stringsAsFactors = FALSE)
  }
  acr <- unique(unlist(regmatches(full, gregexpr("\\b[A-Z]{2,6}s?\\b", full))))
  skip <- c("CV", "PhD", "USA", "UK", "EU", "PDF", "ORCID", "TENK", "RCF", "AI", "PI", "MSc", "BSc", "II", "III", "IV")
  for (a in setdiff(acr, skip)) {
    first <- regexpr(paste0("\\b", a, "\\b"), full)
    defined <- grepl(paste0("\\(", a, "\\)"), substr(full, 1, first + nchar(a)))
    if (!defined) res[[length(res) + 1]] <- data.frame(para = NA_integer_, type = "undefined_acronym",
      match = a, context = substr(full, max(1, first - 30), first + 30), stringsAsFactors = FALSE)
  }

  fmts <- c(iso = "\\b\\d{4}-\\d{2}-\\d{2}\\b", dotted = "\\b\\d{1,2}\\.\\d{1,2}\\.\\d{4}\\b",
            slash = "\\b\\d{1,2}/\\d{4}\\b|\\b\\d{1,2}/\\d{1,2}/\\d{2,4}\\b",
            monthyear = "\\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\\.? \\d{4}\\b",
            yearrange = "\\b(19|20)\\d{2}\\s*[-\u2013]\\s*((19|20)?\\d{2}|present)\\b")
  found <- names(fmts)[vapply(fmts, function(p) grepl(p, full, ignore.case = TRUE), TRUE)]
  if (length(setdiff(found, "yearrange")) > 1) res[[length(res) + 1]] <- data.frame(para = NA_integer_,
    type = "mixed_date_formats", match = paste(setdiff(found, "yearrange"), collapse = " + "),
    context = "Several date formats are used; pick one (TENK asks for consistent dates).", stringsAsFactors = FALSE)

  n_words <- sum(stringi::stri_count_words(txt))
  I_n <- length(unlist(regmatches(full, gregexpr("\\bI\\b", full))))
  we_n <- length(unlist(regmatches(full, gregexpr("\\b[Ww]e\\b", full))))
  res[[length(res) + 1]] <- data.frame(para = NA_integer_, type = "info",
    match = sprintf("%d words; 'I' x%d; 'we' x%d", n_words, I_n, we_n),
    context = if (!is.null(max_words)) sprintf("limit %d words: %s", max_words,
      if (n_words > max_words) "OVER" else "within") else "no word limit given", stringsAsFactors = FALSE)

  out <- do.call(rbind, Filter(Negate(is.null), res))
  attr(out, "words") <- n_words
  out
}

style_flags_summary <- function(flags) {
  tab <- sort(table(flags$type), decreasing = TRUE)
  print(tab)
  invisible(tab)
}
