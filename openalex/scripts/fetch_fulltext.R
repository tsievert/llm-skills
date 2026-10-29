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
    ok <- resp_status(resp) == 200 && .ft_is_pdf(dest)
    # req_perform(path =) writes whatever came back (often an HTML landing page); never leave it as .pdf
    if (!ok) unlink(dest)
    ok
  }, error = function(e) { unlink(dest); FALSE })
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

# --- Europe PMC: full-text XML (JATS) for biomedical open-access papers ---
# Complements fetch_fulltext(): structured sections, no PDF layout problems. Only works for records
# in PMC (open-access subset or author manuscripts); others get status "not_in_pmc". Needs the CRAN
# packages europepmc and xml2. Writes <PMCID>.xml plus manifest_epmc.tsv.
# Usage: fetch_epmc_xml(c("10.7554/eLife.04711"), outdir = "fulltext")
fetch_epmc_xml <- function(dois, outdir = "fulltext", pause = 0.5, max_files = 20, confirmed = FALSE) {
  stopifnot(requireNamespace("europepmc", quietly = TRUE), requireNamespace("xml2", quietly = TRUE))
  if (length(dois) > max_files && !confirmed)
    stop(length(dois), " works requested (> max_files = ", max_files, "). Get approval, then rerun with ",
         "confirmed = TRUE.", call. = FALSE)
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
  rows <- lapply(dois, function(d) {
    Sys.sleep(pause)
    d <- sub("^https?://(dx\\.)?doi\\.org/", "", d)
    row <- function(status, pmcid = NA_character_, file = NA_character_)
      data.frame(doi = d, pmcid = pmcid, status = status, file = file)
    hit <- tryCatch(suppressMessages(europepmc::epmc_search(paste0("DOI:", d), limit = 1)),
                    error = function(e) NULL)
    if (is.null(hit) || nrow(hit) == 0) return(row("not_found_in_europepmc"))
    # Records outside PMC have no pmcid column, or an NA value
    pmcid <- if ("pmcid" %in% names(hit)) hit$pmcid[1] else NA_character_
    if (is.na(pmcid)) return(row("not_in_pmc"))
    dest <- file.path(outdir, paste0(pmcid, ".xml"))
    if (file.exists(dest)) return(row("already_present", pmcid, dest))
    x <- tryCatch(europepmc::epmc_ftxt(pmcid), error = function(e) NULL)
    if (is.null(x)) return(row("pmc_no_fulltext_xml", pmcid))
    xml2::write_xml(x, dest)
    row("downloaded", pmcid, dest)
  })
  out <- do.call(rbind, rows)
  write.table(out, file.path(outdir, "manifest_epmc.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
  out
}

# --- Text from downloaded files, for screening and keyword search ---
# Prefixed oa_ because attaching the fulltext package masks a bare ft_text().
# PDFs: text cached next to each file as .txt, pages separated by a form feed. Scanned PDFs give
# empty text (no OCR here). Europe PMC XML: one "page" per section (title, abstract, then each
# top-level body section), so the page column of oa_ft_grep() is a section number there.
oa_ft_text <- function(dir = "fulltext") {
  pdfs <- list.files(dir, pattern = "\\.pdf$", full.names = TRUE)
  bad <- pdfs[!vapply(pdfs, function(p) identical(readBin(p, "raw", 5), charToRaw("%PDF-")), NA)]
  if (length(bad)) warning("Skipping ", length(bad), " .pdf file(s) without a %PDF- signature (HTML?): ",
                           paste(basename(bad), collapse = ", "), call. = FALSE)
  src <- c(setdiff(pdfs, bad), list.files(dir, pattern = "\\.xml$", full.names = TRUE))
  txts <- sub("\\.(pdf|xml)$", ".txt", src)
  for (i in seq_along(src)) if (!file.exists(txts[i])) {
    pages <- if (grepl("\\.pdf$", src[i])) {
      stopifnot(requireNamespace("pdftools", quietly = TRUE))
      tryCatch(pdftools::pdf_text(src[i]), error = function(e) character())
    } else {
      stopifnot(requireNamespace("xml2", quietly = TRUE))
      x <- xml2::read_xml(src[i])
      c(xml2::xml_text(xml2::xml_find_first(x, "//article-title")),
        xml2::xml_text(xml2::xml_find_all(x, "//abstract | //body/sec")))
    }
    writeLines(paste(pages, collapse = "\f"), txts[i], useBytes = TRUE)
  }
  data.frame(source = src, txt = txts, chars = file.size(txts))
}

# Case-insensitive regex search over cached texts; returns file, page, and a context snippet
oa_ft_grep <- function(pattern, dir = "fulltext", width = 80) {
  oa_ft_text(dir)
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
