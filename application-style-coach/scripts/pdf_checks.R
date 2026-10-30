# Read-only checks of a final application PDF (the export target).
# Usage: source("<skill-dir>/scripts/pdf_checks.R"); pdf_checks("<file.pdf>", max_pages = 2, max_mb = 5)
# Requires: pdftools. Never modifies the file. Findings are prompts: compare them with the call.

#' @param path PDF file.
#' @param max_pages,max_mb Limits from the call (NULL = not given).
#' @param expect_size Expected paper size label ("A4" or "Letter"); NULL to skip.
#' @return data.frame(check, status, detail) with status ok / check / info.
pdf_checks <- function(path, max_pages = NULL, max_mb = NULL, expect_size = "A4") {
  if (!requireNamespace("pdftools", quietly = TRUE)) stop("Install pdftools to run PDF checks.")
  stopifnot(file.exists(path))
  add <- function(check, status, detail) data.frame(check = check, status = status, detail = detail,
                                                    stringsAsFactors = FALSE)
  out <- list()
  info <- pdftools::pdf_info(path)
  mb <- file.size(path) / 1024^2
  out$pages <- add("pages", if (!is.null(max_pages) && info$pages > max_pages) "check" else "ok",
                   sprintf("%d page(s)%s", info$pages, if (!is.null(max_pages)) sprintf(" (limit %d)", max_pages) else ""))
  out$size <- add("file size", if (!is.null(max_mb) && mb > max_mb) "check" else "ok",
                  sprintf("%.2f MB%s", mb, if (!is.null(max_mb)) sprintf(" (limit %.1f MB)", max_mb) else ""))

  ps <- pdftools::pdf_pagesize(path)
  label <- vapply(seq_len(nrow(ps)), function(i) {
    w <- ps$width[i]; h <- ps$height[i]
    if (abs(w - 595) < 6 && abs(h - 842) < 6) "A4" else if (abs(w - 612) < 6 && abs(h - 792) < 6) "Letter" else
      sprintf("%.0fx%.0f pt", w, h)
  }, "")
  out$paper <- add("paper size", if (!is.null(expect_size) && any(label != expect_size)) "check" else "ok",
                   paste(unique(label), collapse = ", "))

  fonts <- pdftools::pdf_fonts(path)
  if (nrow(fonts)) {
    noemb <- fonts$name[!fonts$embedded]
    out$fonts <- add("fonts embedded", if (length(noemb)) "check" else "ok",
                     if (length(noemb)) paste("not embedded:", paste(unique(noemb), collapse = ", "))
                     else paste(length(unique(fonts$name)), "font(s), all embedded"))
  } else out$fonts <- add("fonts embedded", "check", "no fonts found (scanned image or outlines only?)")

  txt <- pdftools::pdf_text(path)
  empty <- which(nchar(trimws(txt)) < 20)
  out$text <- add("selectable text", if (length(empty)) "check" else "ok",
                  if (length(empty)) paste("little or no text on page(s):", paste(empty, collapse = ", "))
                  else "text found on every page")

  out$encrypt <- add("encryption", if (isTRUE(info$encrypted) || isTRUE(info$locked)) "check" else "ok",
                     if (isTRUE(info$encrypted) || isTRUE(info$locked)) "encrypted or locked" else "none")

  meta <- c(title = info$keys$Title, author = info$keys$Author, creator = info$keys$Creator,
            producer = info$keys$Producer)
  meta <- meta[nzchar(meta)]
  out$meta <- add("metadata", "info",
                  if (length(meta)) paste(names(meta), meta, sep = ": ", collapse = " | ") else "no title/author fields")

  words <- sum(lengths(strsplit(trimws(txt), "\\s+")))
  out$words <- add("word count", "info", sprintf("about %d words in total", words))

  out$note <- add("not checked", "info",
                  "layout by eye (fonts, margins, headings), link targets, and the call's exact file name")
  do.call(rbind, out)
}
