# Fetch legally available full texts for works found via OpenAlex.
# Order: (1) OA locations listed in OpenAlex (free, publisher/repository),
#        (2) Unpaywall via DOI (free; needs an email), 
#        (3) OpenAlex cached content API (metered, $0.01/file; only if allow_paid = TRUE).
# Never contacts shadow libraries. Writes a manifest so every outcome is traceable.
# Usage: source("fetch_fulltext.R"); fetch_fulltext(c("10.1234/abc", "W2741809807"), outdir = "fulltext")

library(httr2)

.ft_key <- function() Sys.getenv("OPENALEX_API_KEY")

.ft_is_pdf <- function(path) {
  if (!file.exists(path) || file.size(path) < 1000) return(FALSE)
  identical(readBin(path, "raw", 5), charToRaw("%PDF-"))
}

.ft_download <- function(url, dest, query = list()) {
  tryCatch({
    req <- request(url) |>
      req_user_agent("llm-skills-openalex (mailto:research-use)") |>
      req_timeout(60) |> req_retry(max_tries = 2) |>
      req_error(is_error = \(r) FALSE)
    if (length(query)) req <- do.call(req_url_query, c(list(req), query))
    resp <- req_perform(req, path = dest)
    resp_status(resp) == 200 && .ft_is_pdf(dest)
  }, error = function(e) FALSE)
}

# Resolve DOIs / OpenAlex IDs to metadata needed for retrieval
.ft_meta <- function(id) {
  id <- sub("^https?://(dx\\.)?doi\\.org/", "", id)
  path <- if (grepl("^W\\d+$", id)) id else paste0("https://doi.org/", id)
  resp <- request(paste0("https://api.openalex.org/works/", path)) |>
    req_url_query(select = "id,doi,display_name,open_access,locations,has_content,content_urls",
                  api_key = .ft_key()) |>
    req_error(is_error = \(r) FALSE) |> req_perform()
  if (resp_status(resp) != 200) return(NULL)
  resp_body_json(resp)
}

fetch_fulltext <- function(ids, outdir = "fulltext", email = Sys.getenv("UNPAYWALL_EMAIL"),
                           allow_paid = FALSE, pause = 0.5, max_files = 20, confirmed = FALSE) {
  # Guard: a search must never trigger bulk downloads by itself.
  if (length(ids) > max_files && !confirmed)
    stop(length(ids), " works requested (> max_files = ", max_files, "). Show the count to the user, ",
         "get approval, then rerun with confirmed = TRUE.", call. = FALSE)
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
  rows <- lapply(ids, function(id) {
    Sys.sleep(pause)
    m <- .ft_meta(id)
    if (is.null(m)) return(data.frame(input = id, openalex_id = NA, doi = NA, status = "not_found_in_openalex",
                                      source = NA, file = NA, oa_url = NA))
    wid <- sub("https://openalex.org/", "", m$id)
    doi <- sub("https://doi.org/", "", m$doi %||% "")
    dest <- file.path(outdir, paste0(wid, ".pdf"))
    oa_url <- m$open_access$oa_url %||% NA_character_
    done <- function(src) data.frame(input = id, openalex_id = wid, doi = doi, status = "downloaded",
                                     source = src, file = dest, oa_url = oa_url)
    if (.ft_is_pdf(dest)) return(done("already_present"))

    # (1) OA locations listed in OpenAlex
    pdfs <- unique(na.omit(vapply(m$locations %||% list(),
              \(l) if (isTRUE(l$is_oa) && !is.null(l$pdf_url)) l$pdf_url else NA_character_, "")))
    # oa_url may be a landing page; the %PDF check rejects HTML
    for (u in unique(c(pdfs, if (!is.na(oa_url)) oa_url)))
      if (.ft_download(u, dest)) return(done(paste0("oa_location:", u)))

    # (2) Unpaywall
    if (nzchar(doi) && nzchar(email)) {
      r <- request(paste0("https://api.unpaywall.org/v2/", doi)) |>
        req_url_query(email = email) |> req_error(is_error = \(r) FALSE) |> req_perform()
      if (resp_status(r) == 200) {
        j <- resp_body_json(r)
        us <- unique(na.omit(c(j$best_oa_location$url_for_pdf,
                               vapply(j$oa_locations %||% list(), \(l) l$url_for_pdf %||% NA_character_, ""))))
        for (u in setdiff(us, pdfs)) if (.ft_download(u, dest)) return(done(paste0("unpaywall:", u)))
      }
    }

    # (3) OpenAlex cached content (metered)
    cu <- m$content_urls$pdf
    if (isTRUE(m$has_content$pdf) && !is.null(cu)) {
      if (allow_paid) {
        if (.ft_download(cu, dest, list(api_key = .ft_key()))) return(done("openalex_content_api"))
      } else {
        return(data.frame(input = id, openalex_id = wid, doi = doi, status = "available_via_openalex_content_api_not_fetched",
                          source = NA, file = NA, oa_url = oa_url))
      }
    }
    data.frame(input = id, openalex_id = wid, doi = doi,
               status = if (isTRUE(m$open_access$is_oa)) "oa_but_no_direct_pdf" else "no_open_access_copy",
               source = NA, file = NA, oa_url = oa_url)
  })
  out <- do.call(rbind, rows)
  write.table(out, file.path(outdir, "manifest.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
  out
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# --- PDF to text, for screening and keyword search of already downloaded files ---
# Text is cached next to each PDF as .txt (pages separated by a form feed). Scanned PDFs give
# empty text (no OCR here).
ft_text <- function(dir = "fulltext") {
  stopifnot(requireNamespace("pdftools", quietly = TRUE))
  pdfs <- list.files(dir, pattern = "\\.pdf$", full.names = TRUE)
  txts <- sub("\\.pdf$", ".txt", pdfs)
  for (i in seq_along(pdfs)) if (!file.exists(txts[i])) {
    pages <- tryCatch(pdftools::pdf_text(pdfs[i]), error = function(e) character())
    writeLines(paste(pages, collapse = "\f"), txts[i], useBytes = TRUE)
  }
  data.frame(pdf = pdfs, txt = txts, chars = file.size(txts))
}

# Case-insensitive regex search over cached texts; returns file, page, and a context snippet
ft_grep <- function(pattern, dir = "fulltext", width = 80) {
  ft_text(dir)
  res <- lapply(list.files(dir, pattern = "\\.txt$", full.names = TRUE), function(t) {
    pages <- strsplit(paste(readLines(t, warn = FALSE, encoding = "UTF-8"), collapse = "\n"), "\f", fixed = TRUE)[[1]]
    do.call(rbind, lapply(seq_along(pages), function(i) {
      pg <- gsub("\\s+", " ", pages[i])
      m <- gregexpr(pattern, pg, ignore.case = TRUE, perl = TRUE)[[1]]
      if (m[1] == -1) return(NULL)
      data.frame(file = basename(t), page = i,
                 snippet = substring(pg, pmax(1, m - width), m + attr(m, "match.length") + width - 1))
    }))
  })
  do.call(rbind, res)
}
