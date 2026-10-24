# rn_web.R -- get a recipe from a web page: JSON-LD first, microdata second, page text last,
# plus picture candidates and a safe image download.
# Source with: source("<web-fetching-r skill-dir>/scripts/polite_fetch.R") first, then
# source("<skill-dir>/scripts/rn_web.R", encoding = "UTF-8")
# Needs: httr2, xml2, rvest, jsonlite (cld2 optional). Read-only towards sites: one request at a
# time, identifying user agent, no logins, no bot-wall workarounds. The actual fetch (rate
# limiting, retry, user agent) is the web-fetching-r skill's polite_fetch.R (pf_*); this file only
# adds recipe-specific parsing.

if (!exists("pf_fetch_html", mode = "function")) {
  stop("rn_web.R needs the web-fetching-r skill's polite_fetch.R sourced first: ",
       'source("<web-fetching-r skill-dir>/scripts/polite_fetch.R")')
}

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a

# Language detection helper (also defined in rn_profile.R; kept here so this file works alone).
if (!exists(".rn_detect_lang", mode = "function")) {
  .rn_detect_lang <- function(text) {
    if (!requireNamespace("cld2", quietly = TRUE) || !nzchar(trimws(text))) return(NA_character_)
    cld2::detect_language(text)
  }
}

RN_USER_AGENT <- pf_user_agent("recipe-notes-formatter", "personal recipe collection; polite, one request at a time", "1.0")
RN_MIN_SECONDS <- 1.5   # pause between requests, so a site is never hammered

#' Fetch a page. Never throws on HTTP errors; look at $status and $problem.
#' @return list(url, status, content_type, html, problem)
rn_fetch_html <- function(url, timeout = 25) {
  r <- pf_fetch_html(url, RN_USER_AGENT, min_interval = RN_MIN_SECONDS, timeout = timeout,
                      max_tries = 2, retry_on = c(429L, 503L))
  list(url = r$url, status = r$http, content_type = r$content_type,
       html = if (is.na(r$html)) NULL else r$html, problem = r$problem)
}

# ---- JSON-LD ------------------------------------------------------------------------------

.rn_parse_jsonld <- function(txt) {
  txt <- sub("^\ufeff", "", trimws(txt))
  txt <- gsub("^/\\*\\s*<!\\[CDATA\\[\\s*\\*/|/\\*\\s*\\]\\]>\\s*\\*/$", "", txt)
  parse <- function(s) tryCatch(jsonlite::fromJSON(s, simplifyVector = FALSE), error = function(e) NULL)
  out <- parse(txt)
  # Known failure on real sites: raw newlines or tabs inside strings make the JSON invalid.
  if (is.null(out)) out <- parse(gsub("[\\x00-\\x1f]", " ", txt, perl = TRUE))
  out
}

#' All JSON-LD blocks of a page as R lists (NULL entries are blocks that could not be parsed).
rn_jsonld_blocks <- function(html) {
  doc <- xml2::read_html(html)
  nodes <- xml2::xml_find_all(doc, "//script[@type='application/ld+json']")
  lapply(xml2::xml_text(nodes), .rn_parse_jsonld)
}

.rn_has_type <- function(x, type) {
  t <- x[["@type"]]
  !is.null(t) && any(unlist(t) == type)
}

#' Find every object of type Recipe anywhere in a parsed JSON-LD structure (@graph, arrays, nesting).
rn_find_recipe_nodes <- function(x) {
  out <- list()
  walk <- function(n) {
    if (is.list(n)) {
      if (!is.null(names(n)) && .rn_has_type(n, "Recipe")) out[[length(out) + 1]] <<- n
      for (el in n) walk(el)
    }
  }
  walk(x)
  out
}

.rn_decode <- function(x) {
  x <- as.character(x)
  need <- grepl("&[#A-Za-z0-9]+;", x)
  if (any(need)) {
    x[need] <- vapply(x[need], function(s) {
      tryCatch(xml2::xml_text(xml2::read_html(paste0("<p>", s, "</p>"))), error = function(e) s)
    }, "", USE.NAMES = FALSE)
  }
  x
}
.rn_clean <- function(x) trimws(gsub("[\\s\u00a0]+", " ", .rn_decode(x), perl = TRUE))

.rn_text_of <- function(el) {
  if (is.null(el)) return(NA_character_)
  if (is.character(el) || is.numeric(el)) return(.rn_clean(el[1]))
  if (is.list(el)) {
    for (k in c("text", "name", "@value")) if (!is.null(el[[k]])) return(.rn_text_of(el[[k]]))
  }
  NA_character_
}

.rn_image_urls <- function(img) {
  if (is.null(img)) return(character())
  if (is.character(img)) return(img)
  if (is.list(img) && !is.null(names(img))) {
    u <- img[["url"]] %||% img[["contentUrl"]]
    return(if (is.null(u)) character() else .rn_image_urls(u))
  }
  if (is.list(img)) return(unlist(lapply(img, .rn_image_urls)))
  character()
}

#' ISO 8601 duration ("PT1H15M", "P0DT45M", "PT90M") to whole minutes; NA when unparseable.
rn_iso_minutes <- function(x) {
  x <- as.character(x %||% NA_character_)[1]
  m <- regmatches(x, regexec("^P(?:(\\d+)D)?(?:T(?:(\\d+)H)?(?:(\\d+)M)?(?:(\\d+)S)?)?$", x))[[1]]
  if (length(m) != 5) return(NA_real_)
  v <- suppressWarnings(as.numeric(ifelse(m[2:5] == "", "0", m[2:5])))
  round(v[1] * 1440 + v[2] * 60 + v[3] + v[4] / 60)
}

# recipeInstructions -> list(list(name, steps)). Handles plain text, HowToStep, HowToSection.
.rn_instructions <- function(ins) {
  if (is.null(ins)) return(list())
  if (is.character(ins)) {
    steps <- .rn_clean(unlist(strsplit(paste(ins, collapse = "\n"), "\n+")))
    return(list(list(name = NULL, steps = steps[nzchar(steps)])))
  }
  groups <- list(); loose <- character()
  for (el in ins) {
    if (is.character(el)) { loose <- c(loose, .rn_clean(el)); next }
    if (is.list(el) && .rn_has_type(el, "HowToSection")) {
      sub_steps <- unlist(lapply(el$itemListElement, .rn_text_of))
      groups[[length(groups) + 1]] <- list(name = .rn_text_of(el$name), steps = sub_steps[!is.na(sub_steps)])
    } else {
      t <- .rn_text_of(el)
      if (!is.na(t)) loose <- c(loose, t)
    }
  }
  if (length(loose)) groups <- c(list(list(name = NULL, steps = loose[nzchar(loose)])), groups)
  groups
}

#' Indices of ingredient lines that look like group headings ("Kanelfyllning"): no digit or
#' fraction, at most four words, and the next line starts with a quantity. Candidates only:
#' "salt" has no digit either, so the assistant decides.
rn_heading_candidates <- function(ingredients) {
  has_qty <- function(s) grepl("^\\s*(\\d|[\u00bd\u2153\u2154\u00bc\u00be\u215b])", s)
  which(vapply(seq_along(ingredients), function(i) {
    s <- ingredients[i]
    i < length(ingredients) && !grepl("\\d|[\u00bd\u2153\u2154\u00bc\u00be\u215b]", s) &&
      lengths(strsplit(trimws(s), "\\s+")) <= 4 && has_qty(ingredients[i + 1]) && !has_qty(s)
  }, TRUE))
}

#' Turn confirmed heading lines into ingredient groups, and split flat direction steps at the
#' same headings. Call it with the indices the assistant (or user) confirmed; the default trusts
#' every candidate. Directions that already come grouped (HowToSection) are left alone.
#' @return x with $ingredient_groups and $direction_groups added.
rn_apply_headings <- function(x, idx = x$heading_candidates) {
  ing <- x$ingredients
  if (!length(idx)) {
    x$ingredient_groups <- list(list(name = NULL, items = ing))
    x$direction_groups <- x$directions
    return(x)
  }
  ends <- c(idx[-1] - 1L, length(ing))
  groups <- list()
  if (idx[1] > 1) groups[[1]] <- list(name = NULL, items = ing[1:(idx[1] - 1L)])
  for (i in seq_along(idx)) {
    if (ends[i] > idx[i]) groups[[length(groups) + 1]] <- list(name = ing[idx[i]], items = ing[(idx[i] + 1L):ends[i]])
  }
  x$ingredient_groups <- groups
  heads <- tolower(ing[idx])
  if (length(x$directions) == 1 && is.null(x$directions[[1]]$name)) {
    dg <- list(); cur <- list(name = NULL, steps = character())
    for (s in x$directions[[1]]$steps) {
      if (tolower(s) %in% heads) {
        if (length(cur$steps)) dg[[length(dg) + 1]] <- cur
        cur <- list(name = s, steps = character())
      } else cur$steps <- c(cur$steps, s)
    }
    if (length(cur$steps)) dg[[length(dg) + 1]] <- cur
    x$direction_groups <- dg
  } else x$direction_groups <- x$directions
  x
}

# ---- picture candidates -------------------------------------------------------------------

#' Candidate pictures for a page, best first: JSON-LD image(s), og:image, twitter:image, image_src.
rn_image_candidates <- function(html, jsonld_images = character(), base_url = NA_character_) {
  doc <- xml2::read_html(html)
  meta <- function(xp, attr = "content") {
    n <- xml2::xml_find_all(doc, xp)
    if (length(n)) xml2::xml_attr(n, attr) else character()
  }
  og <- meta("//meta[@property='og:image' or @property='og:image:secure_url']")
  tw <- meta("//meta[@name='twitter:image' or @property='twitter:image']")
  is <- meta("//link[@rel='image_src']", "href")
  cand <- rbind(
    data.frame(url = jsonld_images, source = rep("jsonld", length(jsonld_images)), stringsAsFactors = FALSE),
    data.frame(url = og, source = rep("og:image", length(og)), stringsAsFactors = FALSE),
    data.frame(url = tw, source = rep("twitter:image", length(tw)), stringsAsFactors = FALSE),
    data.frame(url = is, source = rep("image_src", length(is)), stringsAsFactors = FALSE))
  cand <- cand[!is.na(cand$url) & nzchar(cand$url), , drop = FALSE]
  if (!nrow(cand)) return(cand)
  if (!is.na(base_url)) cand$url <- xml2::url_absolute(cand$url, base_url)
  cand <- cand[!duplicated(cand$url), , drop = FALSE]
  rownames(cand) <- NULL
  cand
}

#' Visible main text of a page (article or main or body, without scripts, navigation, footers).
#' Tier 3 fallback when a page has no recipe markup; the assistant structures it.
rn_page_text <- function(html, max_chars = 20000) {
  doc <- xml2::read_html(html)
  for (xp in c("//script", "//style", "//nav", "//header", "//footer", "//aside", "//form", "//noscript")) {
    for (n in xml2::xml_find_all(doc, xp)) xml2::xml_remove(n)
  }
  root <- xml2::xml_find_first(doc, "//article")
  if (inherits(root, "xml_missing")) root <- xml2::xml_find_first(doc, "//main")
  if (inherits(root, "xml_missing")) root <- xml2::xml_find_first(doc, "//body")
  txt <- rvest::html_text2(root)
  txt <- gsub("\n{3,}", "\n\n", txt)
  substr(txt, 1, max_chars)
}

# ---- the extraction entry point -------------------------------------------------------------

#' Extract a recipe from HTML. Returns the raw values (not unit-converted, not tag-mapped):
#' tier = "jsonld" | "microdata" | "none". With tier "none", use $page_text and structure it by hand.
rn_extract_recipe <- function(html, url = NA_character_) {
  doc <- xml2::read_html(html)
  flags <- character()
  blocks <- rn_jsonld_blocks(html)
  if (any(vapply(blocks, is.null, TRUE))) flags <- c(flags, "a JSON-LD block could not be parsed")
  nodes <- unlist(lapply(blocks, rn_find_recipe_nodes), recursive = FALSE)
  page_lang <- xml2::xml_attr(xml2::xml_find_first(doc, "/html"), "lang")
  page_lang <- if (is.na(page_lang)) NA_character_ else tolower(substr(page_lang, 1, 2))
  og_title <- xml2::xml_attr(xml2::xml_find_first(doc, "//meta[@property='og:title']"), "content")

  if (length(nodes)) {
    r <- nodes[[1]]
    ing <- .rn_clean(unlist(lapply(r$recipeIngredient %||% r$ingredients, .rn_text_of)))
    ing <- ing[!is.na(ing) & nzchar(ing)]
    yields <- unlist(r$recipeYield)
    servings <- suppressWarnings(as.numeric(regmatches(as.character(yields[1]), regexpr("\\d+", as.character(yields[1])))))
    tot <- rn_iso_minutes(r$totalTime)
    if (is.na(tot)) { p <- rn_iso_minutes(r$prepTime); c <- rn_iso_minutes(r$cookTime)
      if (!is.na(p) || !is.na(c)) tot <- sum(p, c, na.rm = TRUE) }
    author <- r$author
    author <- if (is.list(author) && !is.null(names(author))) .rn_text_of(author$name)
              else if (is.list(author)) .rn_text_of(author[[1]]$name) else .rn_text_of(author)
    out <- list(
      tier = "jsonld", title = .rn_text_of(r$name) %||% og_title, description = .rn_text_of(r$description),
      ingredients = ing, heading_candidates = rn_heading_candidates(ing),
      directions = .rn_instructions(r$recipeInstructions),
      servings = if (length(servings) && !is.na(servings)) servings else NA_real_,
      yield_text = if (length(yields)) as.character(yields[1]) else NA_character_,
      time = tot, author = author,
      category = paste(unlist(r$recipeCategory), collapse = ", "), cuisine = paste(unlist(r$recipeCuisine), collapse = ", "),
      keywords = paste(unlist(r$keywords), collapse = ", "),
      lang = tolower(substr(.rn_text_of(r$inLanguage) %||% page_lang %||% NA_character_, 1, 2)),
      source = url, jsonld_images = .rn_image_urls(r$image))
  } else {
    # Microdata fallback (itemprop attributes). Rare today, cheap to try.
    ing_n <- xml2::xml_find_all(doc, "//*[@itemprop='recipeIngredient' or @itemprop='ingredients']")
    if (length(ing_n)) {
      steps_n <- xml2::xml_find_all(doc, "//*[@itemprop='recipeInstructions']//li | //*[@itemprop='recipeInstructions'][not(.//li)]")
      ing <- .rn_clean(xml2::xml_text(ing_n))
      out <- list(tier = "microdata", title = .rn_clean(xml2::xml_text(xml2::xml_find_first(doc, "//*[@itemprop='name']"))) %||% og_title,
                  description = NA_character_, ingredients = ing, heading_candidates = rn_heading_candidates(ing),
                  directions = list(list(name = NULL, steps = .rn_clean(xml2::xml_text(steps_n)))),
                  servings = NA_real_, yield_text = NA_character_, time = NA_real_, author = NA_character_,
                  category = "", cuisine = "", keywords = "", lang = page_lang, source = url, jsonld_images = character())
      flags <- c(flags, "microdata only: check quantities, times and servings by hand")
    } else {
      return(list(tier = "none", title = og_title %||% xml2::xml_text(xml2::xml_find_first(doc, "//title")),
                  page_text = rn_page_text(html), lang = page_lang, source = url,
                  image_candidates = rn_image_candidates(html, character(), url),
                  flags = c(flags, "no recipe markup found: structure the page text by hand and mark confidence lower")))
    }
  }
  if (is.na(out$lang) || !nzchar(out$lang)) {
    txt <- paste(unlist(lapply(out$directions, `[[`, "steps")), collapse = " ")
    out$lang <- .rn_detect_lang(txt)
  }
  out$image_candidates <- rn_image_candidates(html, out$jsonld_images, url)
  if (length(out$heading_candidates)) {
    flags <- c(flags, paste0("possible ingredient group headings at lines ", paste(out$heading_candidates, collapse = ", "),
                             ": '", paste(out$ingredients[out$heading_candidates], collapse = "', '"), "'"))
  }
  out$flags <- flags
  out
}

# ---- matching a note to an online recipe ----------------------------------------------------------

#' Share of the note's ingredient words that also occur on a candidate page (0 to 1). Use it to
#' accept or reject an online match before taking its picture: the user's rule is "match the recipe
#' to something online", so a weak match gets no picture and a flag. Compare in the same language
#' (different languages score low by design). Quantities, units and common prep words are ignored.
#' @param a,b character vectors of ingredient lines (note, candidate).
rn_ingredient_overlap <- function(a, b) {
  stop_words <- c("cups", "cup", "tablespoon", "tablespoons", "teaspoon", "teaspoons", "ounce", "ounces", "pound",
                  "pounds", "gram", "grams", "litre", "liter", "pinch", "finely", "chopped", "sliced", "diced", "fresh",
                  "large", "small", "medium", "optional", "divided", "plus", "more", "about", "esslöffel", "teelöffel",
                  "prise", "matsked", "tesked", "kryddmått", "ruokalusikka", "teelusikka", "ca.", "gehackt", "gehackte")
  tok <- function(x) {
    x <- tolower(unlist(x))
    x <- gsub("[\\d.,/\u00bd\u2153\u2154\u00bc\u00be()\\-]+", " ", x, perl = TRUE)
    w <- unlist(strsplit(x, "[^\\p{L}]+", perl = TRUE))
    unique(setdiff(w[nchar(w) >= 4], stop_words))
  }
  ta <- tok(a); tb <- tok(b)
  if (!length(ta)) return(0)
  length(intersect(ta, tb)) / length(ta)
}

# ---- picture download ---------------------------------------------------------------------------

.rn_image_ext <- function(content_type) {
  ct <- tolower(sub(";.*$", "", content_type %||% ""))
  switch(ct, "image/jpeg" = "jpg", "image/jpg" = "jpg", "image/png" = "png", "image/webp" = "webp",
         "image/gif" = "gif", "image/avif" = "avif", NA_character_)
}

#' Download a picture into dir (usually output/images). Checks status, content type and size,
#' never overwrites (numbered name). Returns list(file, path, bytes, md5, content_type) or stops.
rn_download_image <- function(url, dir, stem, max_bytes = 8e6, referer = NULL) {
  .rn_polite()
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  req <- httr2::request(url) |> httr2::req_user_agent(RN_USER_AGENT) |> httr2::req_timeout(40) |>
    httr2::req_error(is_error = function(r) FALSE)
  if (!is.null(referer)) req <- httr2::req_headers(req, Referer = referer)
  resp <- httr2::req_perform(req)
  if (httr2::resp_status(resp) != 200) stop("image request returned status ", httr2::resp_status(resp), call. = FALSE)
  ext <- .rn_image_ext(httr2::resp_content_type(resp))
  if (is.na(ext)) stop("not a supported image type: ", httr2::resp_content_type(resp), call. = FALSE)
  body <- httr2::resp_body_raw(resp)
  if (length(body) > max_bytes) stop("image is larger than ", max_bytes, " bytes", call. = FALSE)
  safe <- rn_safe_filename(stem)
  path <- file.path(dir, paste0(safe, ".", ext)); k <- 2L
  while (file.exists(path)) { path <- file.path(dir, paste0(safe, " (", k, ").", ext)); k <- k + 1L }
  writeBin(body, path)
  list(file = basename(path), path = path, bytes = length(body), md5 = unname(tools::md5sum(path)),
       content_type = httr2::resp_content_type(resp))
}
