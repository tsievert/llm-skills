# jw_checks.R -- pure text checks used by the headless stages (no network, no files).
#   job-like flag per anchor and per source (s1), profile-derived title prefilter with a reason (s2),
#   deadline extraction from page text (s3). Everything here is a heuristic that decides what is read
#   first or dropped before reading; it never decides relevance. Each function is unit-tested.
# Non-ASCII letters are written as \u escapes so the file reads the same under any locale.

if (!exists("%||%", mode = "function")) `%||%` <- function(a, b) if (is.null(a)) b else a
.never <- "(?!x)x"   # regex that matches nothing (an empty alternative would match everything)
.rx_escape <- function(x) gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x, perl = TRUE)
.has <- function(p, x) grepl(p, x, perl = TRUE)

# ---- s1: vacancy-likeness -----------------------------------------------------------------------
.jl_pat <- paste(c(
  "vacanc", "/jobs?/", "job[-_]?id", "posting", "stelle", "ausschreibung", "vacature", "tjanst", "tj\u00e4nst",
  "rekry", "ledig", "recruit", "postdoc", "lecturer", "researcher", "assistant professor", "tenure",
  "fellowship", "emploi", "offre", "convocatoria", "concurso", "avoin", "haku", "stilling", "ansettelse"),
  collapse = "|")
# stems must start at a word boundary ("offre" must not match "Geoffrey", "stelle" not "Estelle")
.jl_pat <- gsub("(^|\\|)(?=[a-z])", "\\1\\\\b", .jl_pat, perl = TRUE)
# Menu-style link text that must not count as a vacancy
.jl_menu <- paste0("^(apply (to|for)|admission|for (international )?students|news|events?|study|education|",
                   "open university|programmes?)|bachelor|master.s|doctoral programme|exchange")

# Category page: "<job word>/<one slug>/" whose slug just repeats a short link text ("Life Science" ->
# /jobs/life-science/). A vacancy has an id or a longer title in the path; this is the shape of a filter page.
.jl_cat_path <- "/(jobs?|vacanc[a-z]*|careers?|positions?|stellen[a-z]*|vacatures?|ledig[a-z]*)/([a-z0-9%]+(-[a-z0-9%]+)*)/?$"
jw_category_link <- function(text, href) {
  path <- tolower(sub("[?#].*$", "", sub("^https?://[^/]+", "", href)))
  slug <- ifelse(grepl(.jl_cat_path, path, perl = TRUE), sub("^.*/([^/]+)/?$", "\\1", path), NA_character_)
  words <- lengths(strsplit(trimws(text), "\\s+"))
  norm <- gsub("[^a-z0-9]+", "-", tolower(trimws(text)))
  !is.na(slug) & words <= 3 & !grepl("[0-9]", text) & (norm == slug | startsWith(slug, norm) | startsWith(norm, slug))
}

jw_anchor_job_like <- function(text, href, role_hit = FALSE, topic_hit = FALSE) {
  menu <- grepl(.jl_menu, text, ignore.case = TRUE, perl = TRUE) | jw_category_link(text, href)
  !menu & (role_hit %in% TRUE | topic_hit %in% TRUE |
             grepl(.jl_pat, paste(text, href), ignore.case = TRUE, perl = TRUE))
}

# fine / weak (few job-like links, look manually) / nav_only (none: probably a menu page) /
# not_assessed (the page was not read: error, blocked, search engine, non-HTML)
jw_source_flag <- function(status, n_job_like, min_ok = 3) {
  read_ok <- status %in% c("ok", "ok_js_suspect")
  ifelse(!read_ok, "not_assessed", ifelse(n_job_like == 0, "nav_only", ifelse(n_job_like < min_ok, "weak", "fine")))
}

# ---- s2: profile-derived prefilter --------------------------------------------------------------
# Word lists come from job_profile.yml. A profile key becomes a regex through the optional block
# career_search_profile$search_synonyms (key -> regex, any language); a key without an entry falls back to
# its own words ("small_mammals" -> "small mammals"), so a new profile key still works, only more narrowly.
.keys_of <- function(x) if (is.list(x) && !is.null(names(x))) names(x) else as.character(unlist(x))
.term_re <- function(keys, syn) {
  keys <- keys[!is.na(keys) & nzchar(keys)]
  if (!length(keys)) return(.never)
  paste(vapply(keys, function(k) { s <- syn[[k]]; if (is.null(s)) .rx_escape(gsub("_", " ", k)) else s }, ""), collapse = "|")
}

jw_profile_terms <- function(prof) {
  prof <- prof$career_search_profile %||% prof
  an <- prof$animal_systems; sc <- prof$scientific_topics; ts <- prof$target_search
  syn <- prof$search_synonyms %||% list()
  excl_titles <- tolower(unlist(ts$excluded_job_titles)); excl_titles <- excl_titles[nzchar(excl_titles) & !grepl("unpaid", excl_titles)]
  acc <- tolower(gsub("\\s+with .*$", "", unlist(ts$accepted_job_titles)))
  cond <- tolower(gsub("_", " ", .keys_of(ts$conditional_job_titles)))   # e.g. research_assistant: kept, verified later
  role <- paste(c(.rx_escape(acc[nzchar(acc)]), .rx_escape(cond[nzchar(cond)]),
    "researcher", "scientist", "postdoc", "post-doc", "postdoctoral", "post doctoral", "lecturer", "fellow",
    "group leader", "assistant professor", "associate professor", "tenure", "coordinator", "forscher",
    "wissenschaftliche", "wiss\\.? mitarbeiter", "akademische", "tutkija", "forskare", "yliopistonlehtori",
    "universitetslektor", "postdoktor", "onderzoeker", "universitair (hoofd)?docent"), collapse = "|")
  list(
    strong = .term_re(c(.keys_of(an$very_high_fit), .keys_of(an$high_fit), .keys_of(sc$very_high_priority)), syn),
    broad  = .term_re(c(.keys_of(an$medium_fit), .keys_of(sc$high_priority), .keys_of(sc$medium_priority)), syn),
    role = role,
    excl_title = paste(c("zur promotion", "qualifizierungsphase", "\\bph\\.?d\\b", "\\bdoctoral\\b", "doktorand", "doktorrand",
      "v\u00e4it\u00f6skirjatutkija", "promovend", "doctorant", "technician", "technical staff", "laboratory staff",
      "laborant", "\\btekniker", .rx_escape(excl_titles[!grepl("full professor", excl_titles)])), collapse = "|"),
    excl_full_prof = any(grepl("full professor", excl_titles)),
    full_prof_ok = "assistant|associate|tenure|junior|apulaisprofessori|bitr\u00e4dande",
    excl_system = .term_re(.keys_of(an$excluded_as_primary_system), syn),
    excl_central = .term_re(.keys_of(sc$excluded_if_central), syn))
}

# items: data frame with `text` (title or link text); optional `tags`, `descr` (description), `job_like`.
# Returns items with integer `tier` (1 topic word, 2 role or job-like only, NA dropped) and `reason`.
jw_prefilter <- function(items, terms) {
  n <- nrow(items)
  col <- function(nm) if (nm %in% names(items)) ifelse(is.na(items[[nm]]), "", items[[nm]]) else rep("", n)
  ti <- tolower(col("text")); head_txt <- tolower(paste(col("text"), col("tags"))); all_txt <- paste(head_txt, tolower(col("descr")))
  jl <- if ("job_like" %in% names(items)) items$job_like %in% TRUE else rep(FALSE, n)
  why <- rep(NA_character_, n)
  set <- function(cond, msg) { i <- is.na(why) & cond; why[i] <<- msg }
  set(.has(terms$excl_title, ti), "excluded title (PhD, doctoral or technician)")
  if (isTRUE(terms$excl_full_prof))
    set(.has("\\bprofessor|\\bprofessur", ti) & !.has(terms$full_prof_ok, ti) & !.has("lecturer", ti), "full professor")
  set(.has("research assistant", ti) & nzchar(col("descr")) & !.has("ph\\.?d|doctorate|doctoral degree", all_txt),
      "research assistant without PhD requirement")
  strong_head <- .has(terms$strong, head_txt)
  set(.has(terms$excl_system, head_txt) & !strong_head, "excluded system")
  set(.has(terms$excl_central, head_txt), "excluded if central")
  topic <- strong_head | .has(terms$broad, head_txt) | .has(terms$strong, all_txt)
  role  <- .has(terms$role, ti) | jl
  set(!topic & !role, "no role or topic word")
  items$tier <- ifelse(!is.na(why), NA_integer_, ifelse(topic, 1L, 2L))
  items$reason <- ifelse(!is.na(why), why, ifelse(topic, ifelse(strong_head, "topic: strong", "topic: broad"), "role or job-like title only"))
  items
}

# ---- s3: deadline from page text ----------------------------------------------------------------
.jw_mon <- c(january = 1, february = 2, march = 3, april = 4, may = 5, june = 6, july = 7, august = 8,
  september = 9, october = 10, november = 11, december = 12,
  jan = 1, feb = 2, mar = 3, apr = 4, jun = 6, jul = 7, aug = 8, sep = 9, sept = 9, oct = 10, nov = 11, dec = 12,
  januar = 1, "j\u00e4nner" = 1, februar = 2, "m\u00e4rz" = 3, maerz = 3, mai = 5, juni = 6, juli = 7, oktober = 10,
  dezember = 12, "m\u00e4r" = 3, mrz = 3, okt = 10, dez = 12,
  januari = 1, februari = 2, mars = 3, maj = 5, augusti = 8,
  tammikuuta = 1, helmikuuta = 2, maaliskuuta = 3, huhtikuuta = 4, toukokuuta = 5, "kes\u00e4kuuta" = 6,
  "hein\u00e4kuuta" = 7, elokuuta = 8, syyskuuta = 9, lokakuuta = 10, marraskuuta = 11, joulukuuta = 12,
  # French: "mars"/"mai"/"juin"/"juillet"/"octobre"/"novembre" already covered above or share an
  # English/Swedish spelling; only the distinct forms are added here.
  janvier = 1, "f\u00e9vrier" = 2, "f\u00e9vr" = 2, avril = 4, juillet = 7, "ao\u00fbt" = 8, aout = 8,
  septembre = 9, octobre = 10, novembre = 11, "d\u00e9cembre" = 12, "d\u00e9c" = 12, janv = 1,
  # Dutch: "januari"/"februari"/"mei"/"juni"/"juli"/"september"/"oktober"/"november"/"december"
  # already covered above (identical to Swedish/German spellings); "maart"/"mrt"/"augustus" differ.
  maart = 3, mrt = 3, augustus = 8)

# All dates in a string with their positions: 15 November 2026, 15. Nov. 2026, November 15, 2026,
# 15.11.2026 (day first), 2026-11-15. Numeric forms are read day-first, as in the countries searched.
.jw_dates <- function(s) {
  sl <- tolower(s); alt <- paste(names(.jw_mon)[order(-nchar(names(.jw_mon)))], collapse = "|")
  pats <- list(
    dmy = list(paste0("\\b([0-3]?\\d)(?:st|nd|rd|th)?\\.?\\s+(?:of\\s+)?(", alt, ")\\.?,?\\s+(20\\d\\d)"), c(1, 2, 3)),
    mdy = list(paste0("\\b(", alt, ")\\.?\\s+([0-3]?\\d)(?:st|nd|rd|th)?,?\\s+(20\\d\\d)"), c(2, 1, 3)),
    num = list("\\b([0-3]?\\d)[./]([01]?\\d)[./](20\\d\\d)\\b", c(1, 2, 3)),
    iso = list("\\b(20\\d\\d)-([01]\\d)-([0-3]\\d)\\b", c(3, 2, 1)))
  out <- list()
  for (p in names(pats)) {
    m <- gregexpr(pats[[p]][[1]], sl, perl = TRUE)[[1]]
    if (m[1] < 0) next
    cs <- attr(m, "capture.start"); cl <- attr(m, "capture.length"); ord <- pats[[p]][[2]]
    for (i in seq_along(m)) {
      g <- substring(sl, cs[i, ], cs[i, ] + cl[i, ] - 1)
      mm <- if (grepl("^\\d+$", g[ord[2]])) as.integer(g[ord[2]]) else .jw_mon[[g[ord[2]]]]
      d <- as.Date(sprintf("%s-%02d-%02d", g[ord[3]], mm, as.integer(g[ord[1]])), format = "%Y-%m-%d")
      if (!is.na(d)) out[[length(out) + 1]] <- data.frame(pos = m[i], date = d)
    }
  }
  if (!length(out)) return(data.frame(pos = integer(), date = as.Date(character())))
  o <- do.call(rbind, out); o[order(o$pos), ]
}

# "befristet" is deliberately not a cue (it contains "frist" and returned contract end dates).
.jw_cue <- paste0("(?i)(deadline|closing date|closes|apply (by|before|until)|applications? (must|should|are due|until|by|close)|",
  "application due|bewerbungsfrist|bewerbungsschluss|bewerbung(en)? (bis|sp\u00e4testens)|\\bfrist\\b|",
  "hakuaika|haku p\u00e4\u00e4ttyy|viimeinen hakup\u00e4iv\u00e4|ans\u00f6kningstid|sista ans\u00f6kningsdag|ans\u00f6k senast|",
  "date limite|candidater avant|cl\u00f4ture des candidatures|sluitingsdatum|uiterste datum|solliciteren voor)")

# For each cue take the FIRST date that follows it (window characters). deadline = earliest date that lies in
# the future, else the latest past one. Returns list(deadline, verdict, dates, flag).
jw_deadline_from_text <- function(b, today = Sys.Date(), window = 90) {
  b <- if (length(b) == 0 || is.na(b)) "" else b
  k <- gregexpr(.jw_cue, b, perl = TRUE)[[1]]
  ds <- as.Date(character())
  if (k[1] > 0) for (i in k) {
    d <- .jw_dates(substr(b, i, i + window))
    if (nrow(d)) ds <- c(ds, d$date[1])
  }
  if (!length(ds)) return(list(deadline = as.Date(NA), verdict = "no_deadline_found", dates = NA_character_, flag = NA_character_))
  u <- sort(unique(ds)); fut <- u[u >= today]
  dl <- if (length(fut)) min(fut) else max(u)
  flag <- if (length(u) > 1 && any(u < today) && length(fut)) "mixed_past_future" else if (length(u) > 1) "dates_disagree" else NA_character_
  list(deadline = dl, verdict = if (dl < today) "expired" else "open", dates = paste(format(u), collapse = ";"), flag = flag)
}

# Contract plausibility (jw_contracts s3_plausible): a date outside [2020-01-01, today + 3 years] is a parse
# error (a year typo or a copyright date), kept in `dates` for the reader but not used as a deadline.
jw_deadline_row <- function(z, today = Sys.Date()) {
  dl <- z$deadline; v <- z$verdict
  if (!is.na(dl) && (dl < as.Date("2020-01-01") || dl > today + 1095)) { dl <- as.Date(NA); v <- "parse_error" }
  data.frame(deadline = dl, verdict = v, flag = z$flag, dates = z$dates, stringsAsFactors = FALSE)
}

# Visible text of an HTML string (scripts and styles removed), whitespace collapsed.
jw_html_text <- function(h) {
  h <- gsub("(?is)<(script|style|noscript)[^>]*>.*?</\\1>", " ", h, perl = TRUE)
  trimws(gsub("\\s+", " ", gsub("<[^>]+>", " ", h)))
}
