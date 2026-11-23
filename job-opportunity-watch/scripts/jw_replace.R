# jw_replace.R -- model-free part of finding a replacement for a dead or moved link. Loaded by jobwatch.R.

.tokens <- function(u) {
  p <- tolower(sub("^https?://[^/]+", "", utils::URLdecode(sub("[?#].*$", "", u))))
  t <- unlist(strsplit(p, "[^a-z0-9]+")); unique(t[nchar(t) >= 3 & !t %in% c("www", "html", "htm", "php", "aspx")])
}

.get_text <- function(url, timeout = 20, max_bytes = 6e6) {
  resp <- pf_perform(url, jw_ua, timeout = timeout, max_tries = 1)$response
  if (is.null(resp) || resp_status(resp) >= 400) return(NULL)
  b <- resp_body_raw(resp); if (length(b) > max_bytes) return(NULL)
  if (length(b) > 2 && b[1] == as.raw(0x1f) && b[2] == as.raw(0x8b)) b <- tryCatch(memDecompress(b, "gzip", asChar = FALSE), error = function(e) raw())
  .clean(rawToChar(b))
}

# Model-free candidates for a dead or moved link: parent paths and the home page, vacancy-like URLs from the site's
# sitemaps, and vacancy-like links on the home page. Scored by token overlap with the old URL; only candidates that
# answer (HTTP below 400) are kept. Returns a data frame (url, via, score, http, final_url) of at most
# `max_candidates` rows, empty if none. The assistant judges the candidates; nothing is written.
jw_find_replacement <- function(url, max_candidates = 8, verbose = TRUE) {
  root <- sub("^(https?://[^/]+).*$", "\\1", url)
  old <- .tokens(url); cand <- list()
  add <- function(u, via) if (length(u)) cand[[length(cand) + 1]] <<- data.frame(url = u, via = via)
  # 1. parent paths
  segs <- strsplit(sub("^https?://[^/]+/?", "", sub("[?#].*$", "", url)), "/")[[1]]
  segs <- segs[nzchar(segs)]
  if (length(segs) > 1) add(vapply(rev(seq_len(length(segs) - 1)), function(k) paste0(root, "/", paste(segs[1:k], collapse = "/"), "/"), ""), "parent")
  add(paste0(root, "/"), "home")
  # 2. sitemaps
  rb <- .get_text(paste0(root, "/robots.txt"))
  sm <- if (!is.null(rb)) trimws(sub("(?i)^sitemap:", "", grep("(?i)^sitemap:", strsplit(rb, "\r?\n")[[1]], value = TRUE, perl = TRUE), perl = TRUE)) else character()
  sm <- unique(c(sm, paste0(root, c("/sitemap.xml", "/sitemap_index.xml", "/sitemap.xml.gz"))))
  locs <- unique(unlist(lapply(sm[seq_len(min(length(sm), 4))], .sitemap_locs)))
  if (verbose) message("sitemap URLs read: ", length(locs))
  locs <- locs[grepl(.job_url_re, tolower(locs))]
  add(utils::head(locs, 400), "sitemap")
  # 3. job-like links on home page
  for (pg in unique(c(paste0(root, "/"), if (length(segs) > 1) paste0(root, "/", segs[1], "/")))) {
    p <- tryCatch(jw_probe_one(pg), error = function(e) NULL)
    if (!is.null(p$anchors) && nrow(p$anchors)) {
      a <- p$anchors[grepl(.job_url_re, tolower(paste(p$anchors$text, p$anchors$href))), ]
      add(a$href, "homepage-link")
    }
  }
  if (!length(cand)) return(data.frame())
  d <- do.call(rbind, cand); d <- d[!duplicated(jw_key(d$url)) & jw_key(d$url) != jw_key(url), ]
  d$score <- vapply(d$url, function(u) length(intersect(old, .tokens(u))) + 2 * grepl(.job_url_re, tolower(u)) +
                      (if (u == paste0(root, "/")) -3 else 0) +
                      # deep pages are usually single vacancies, not the listing
                      -0.3 * length(strsplit(sub("^https?://[^/]+/?", "", sub("[?#].*$", "", u)), "/")[[1]]), 0)
  d <- d[order(-d$score), ]
  d <- utils::head(d, max_candidates * 2)
  # keep only candidates that answer; record the final URL
  ok <- lapply(seq_len(nrow(d)), function(i) {
    r <- pf_perform(d$url[i], jw_ua, timeout = 15, max_tries = 1)$response
    if (is.null(r)) NULL else data.frame(d[i, ], http = resp_status(r), final_url = r$url)
  })
  out <- do.call(rbind, ok); if (is.null(out)) return(data.frame())
  out <- out[out$http < 400, ]; utils::head(out, max_candidates)
}
