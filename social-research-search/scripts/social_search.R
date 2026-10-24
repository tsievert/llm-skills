# Keyless, read-only search of public Bluesky posts and Mastodon hashtag timelines.
# Requires: httr2. Usage: source("<web-fetching-r skill-dir>/scripts/polite_fetch.R") first, then
# source("<skill-dir>/scripts/social_search.R")
#   bsky_search("mgcv", sort = "latest", since = "2026-01-01", max_posts = 100)
#   masto_tag("rstats", instances = c("mastodon.social", "fosstodon.org"))
#   social_search("gratia", tags = "rstats")   # both platforms, one data frame
# Both return a data.frame with the same columns (see COLUMNS below). The HTTP request/retry
# pipeline comes from the web-fetching-r skill's polite_fetch.R (pf_perform()); this file only
# adds the Bluesky/Mastodon query shapes and response parsing.

library(httr2)

if (!exists("pf_perform", mode = "function")) {
  stop("social_search.R needs the web-fetching-r skill's polite_fetch.R sourced first: ",
       'source("<web-fetching-r skill-dir>/scripts/polite_fetch.R")')
}

# Bluesky: api.bsky.app answers searchPosts without login; public.api.bsky.app returns 403.
BSKY_HOST <- "https://api.bsky.app"
BSKY_PAGE_MAX <- 100      # documented maximum for searchPosts `limit`
MASTO_PAGE_MAX <- 40      # documented maximum for the tag timeline `limit`
REQUEST_PAUSE <- 0.5      # seconds between requests, to stay polite to public servers
USER_AGENT <- "social-research-search skill (R httr2; read-only)"

COLUMNS <- c("platform", "source", "created_at", "author", "text", "url",
             "likes", "reposts", "replies", "lang", "id")

.empty <- function() {
  df <- as.data.frame(setNames(rep(list(character()), length(COLUMNS)), COLUMNS))
  df$likes <- df$reposts <- df$replies <- integer()
  df$created_at <- as.POSIXct(character(), tz = "UTC")
  df
}

.get_json <- function(url, query = list()) {
  # Returns parsed JSON, or NULL with a warning when the server refuses (401/403/404).
  r <- pf_perform(url, USER_AGENT, timeout = 30, max_tries = 3,
                   retry_on = c(429, 500, 502, 503), query = query)
  if (!is.null(r$error)) {
    warning(sprintf("%s -> %s", url, conditionMessage(r$error)), call. = FALSE)
    return(NULL)
  }
  resp <- r$response
  if (resp_status(resp) >= 400) {
    warning(sprintf("%s -> HTTP %s: %s", url, resp_status(resp),
                    substr(gsub("\\s+", " ", resp_body_string(resp)), 1, 120)), call. = FALSE)
    return(NULL)
  }
  Sys.sleep(REQUEST_PAUSE)
  resp_body_json(resp)
}

.strip_html <- function(x) {
  x <- gsub("<br\\s*/?>|</p>", "\n", x)
  x <- gsub("<[^>]+>", "", x)
  x <- gsub("&amp;", "&", x, fixed = TRUE)
  x <- gsub("&lt;", "<", x, fixed = TRUE)
  x <- gsub("&gt;", ">", x, fixed = TRUE)
  x <- gsub("&quot;", "\"", x, fixed = TRUE)
  x <- gsub("&#39;", "'", x, fixed = TRUE)
  trimws(x)
}

.parse_time <- function(x) {
  # ISO 8601 with Z or +hh:mm offsets and up to nanosecond fractions -> POSIXct (UTC)
  x <- sub("Z$", "+0000", x)
  x <- sub("([+-][0-9]{2}):([0-9]{2})$", "\\1\\2", x)
  x <- sub("(\\.[0-9]{6})[0-9]+", "\\1", x)
  as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%OS%z", tz = "UTC")
}

.num <- function(x) if (is.null(x)) NA_integer_ else as.integer(x)
.chr <- function(x) if (is.null(x) || length(x) == 0) NA_character_ else as.character(x[[1]])

#' Search Bluesky posts.
#' @param q Query text (matching is fuzzy, quotes do not force an exact phrase). Restrict to an account with `author`,
#'   and to hashtags with `tag`.
#' @param sort "latest" (newest first; best for monitoring) or "top" (engagement-ranked).
#' @param since,until ISO date or datetime (e.g. "2026-01-01"); bounds on createdAt.
#' @param lang ISO 639-1 code, e.g. "en".
#' @param tag Character vector of hashtags (without #); posts must have ALL of them.
#' @param author Handle or DID to restrict to one account.
#' @param max_posts Stop after this many posts (paginates with the cursor).
bsky_search <- function(q, sort = "latest", since = NULL, until = NULL, lang = NULL,
                        tag = NULL, author = NULL, max_posts = 100) {
  # The `cursor` parameter returns 403 without login (tested 2026-10-23), so pages beyond the first
  # are fetched by moving `until` back to the oldest post seen. This needs sort = "latest".
  out <- list()
  seen <- character()
  repeat {
    query <- list(q = q, sort = sort, limit = min(BSKY_PAGE_MAX, max_posts - length(seen)),
                  since = since, until = until, lang = lang, author = author)
    if (!is.null(tag)) query$tag <- tag  # repeated parameter for multiple tags
    query <- Filter(Negate(is.null), query)
    res <- .get_json(paste0(BSKY_HOST, "/xrpc/app.bsky.feed.searchPosts"), query)
    posts <- Filter(\(p) !p$uri %in% seen, res$posts)
    if (length(posts) == 0) break
    seen <- c(seen, vapply(posts, \(p) p$uri, ""))
    out <- c(out, lapply(posts, function(p) {
      rkey <- sub(".*/", "", p$uri)
      data.frame(
        platform = "bluesky", source = "bsky.app",
        created_at = .parse_time(.chr(p$record$createdAt)),
        author = .chr(p$author$handle),
        text = .chr(p$record$text),
        url = sprintf("https://bsky.app/profile/%s/post/%s", p$author$handle, rkey),
        likes = .num(p$likeCount), reposts = .num(p$repostCount), replies = .num(p$replyCount),
        lang = .chr(p$record$langs), id = p$uri, stringsAsFactors = FALSE)
    }))
    if (length(seen) >= max_posts || sort != "latest") break
    # Oldest post becomes the new upper bound (rounded up to the second so ties are not skipped)
    oldest <- min(.parse_time(vapply(posts, \(p) p$record$createdAt, "")), na.rm = TRUE)
    until <- format(oldest + 1, "%Y-%m-%dT%H:%M:%SZ")
  }
  if (length(out) == 0) return(.empty())
  do.call(rbind, out)
}

#' Read Mastodon hashtag timelines from one or more instances.
#' Each instance only shows posts it has seen via federation, so use several instances and
#' de-duplicate (done here via the canonical `uri`).
#' @param tag Hashtag without #.
#' @param instances Hostnames of instances that allow unauthenticated hashtag timelines.
#' @param any,all Extra hashtags (OR / AND) to combine with `tag`.
#' @param max_posts Maximum posts per instance (paginates with max_id).
masto_tag <- function(tag, instances = c("mastodon.social", "fosstodon.org", "mstdn.science"),
                      any = NULL, all = NULL, only_media = FALSE, max_posts = 80) {
  out <- list()
  for (inst in instances) {
    max_id <- NULL
    n <- 0
    repeat {
      query <- list(limit = min(MASTO_PAGE_MAX, max_posts - n), max_id = max_id,
                    only_media = if (only_media) "true" else NULL)
      if (!is.null(any)) query[["any[]"]] <- any
      if (!is.null(all)) query[["all[]"]] <- all
      query <- Filter(Negate(is.null), query)
      posts <- .get_json(sprintf("https://%s/api/v1/timelines/tag/%s", inst, tag), query)
      if (length(posts) == 0) break
      out <- c(out, lapply(posts, function(p) {
        data.frame(
          platform = "mastodon", source = inst,
          created_at = .parse_time(.chr(p$created_at)),
          author = .chr(p$account$acct),  # no domain for local accounts
          text = .strip_html(.chr(p$content)),
          url = .chr(p$url),
          likes = .num(p$favourites_count), reposts = .num(p$reblogs_count),
          replies = .num(p$replies_count),
          lang = .chr(p$language), id = .chr(p$uri), stringsAsFactors = FALSE)
      }))
      n <- n + length(posts)
      max_id <- posts[[length(posts)]]$id
      if (n >= max_posts) break
    }
  }
  if (length(out) == 0) return(.empty())
  res <- do.call(rbind, out)
  res <- res[!duplicated(res$id), ]
  res[order(res$created_at, decreasing = TRUE), ]
}

#' Convenience wrapper: Bluesky text search for `q` plus Mastodon hashtag timeline(s).
#' @param tags Mastodon hashtags (default: `q` with spaces removed, lower case).
#' @param ... Passed to bsky_search().
social_search <- function(q, tags = gsub("\\s+", "", tolower(q)), max_posts = 50, ...) {
  bsky <- bsky_search(q, max_posts = max_posts, ...)
  masto <- do.call(rbind, lapply(tags, masto_tag, max_posts = max_posts))
  res <- rbind(bsky, if (is.null(masto)) .empty() else masto)
  res[order(res$created_at, decreasing = TRUE), ]
}
