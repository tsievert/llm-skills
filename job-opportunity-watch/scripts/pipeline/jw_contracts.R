# jw_contracts.R -- stage output contracts for the staged weekly pipeline.
# One place defines, per stage: the output file, the arrow schema (used both to WRITE and to VALIDATE),
# the row rules (validate package, text form so they can be listed in the report), and the key column.
# Completeness gates (set equality between consecutive stages) are in jw_gates() at the bottom; neither
# arrow nor validate can express them. Needs: arrow, validate (CRAN).

suppressPackageStartupMessages({ library(arrow); library(validate) })

jw_enums <- list(
  source_status = c("ok", "ok_js_suspect", "ok_nav_only", "blocked", "http_error", "error", "non_html", "search_engine"),
  source_flag   = c("fine", "weak", "nav_only", "not_assessed"),
  verdict       = c("open", "expired", "no_deadline_found", "unreadable", "parse_error", "not_checked"),
  decision      = c("rejected_title", "classified"),
  class         = c("A", "B", "C", "D", "E"),
  status        = c("Verified open", "Probably open", "Deadline conflict", "Unresolved", "Expired",
                    "Inaccessible", "Rejected", "Irrelevant", "Network only", "Funding only"),
  track         = c("primary", "fellowship", "supplementary"),
  platform      = c("bluesky", "mastodon", "web"),
  lead_status   = c("lead", "rejected", "verified"),
  query_type    = c("hashtag", "text", "author+tag", "web_keywords")
)

.q <- function(x) paste(deparse(x), collapse = "")
.url_ok <- '!is.na(%s) & grepl("^https?://", %s)'

# today: used for date plausibility; passed so tests and re-validation are deterministic.
jw_contracts <- function(today = Sys.Date()) {
  td <- sprintf('as.Date("%s")', format(today))
  list(
    s1 = list(
      file = "s1_sources.parquet", key = "source_id",
      schema = schema(source_id = string(), url = string(), section = string(), type = string(),
                      status = string(), http = int32(), n_anchors = int32(), n_job_like = int32(),
                      flag = string(), note = string(), checked = date32()),
      rules = c(
        s1_key_unique   = "is_unique(source_id)",
        s1_status_enum  = sprintf("status %%in%% %s", .q(jw_enums$source_status)),
        s1_flag_enum    = sprintf("flag %%in%% %s", .q(jw_enums$source_flag)),
        s1_url          = sprintf(.url_ok, "url", "url"),
        s1_counts       = "is.na(n_anchors) | n_anchors >= 0")),
    # side output of s1: every usable link found on a readable source (s2 diffs it against earlier weeks)
    s1_anchors = list(
      file = "s1_anchors.parquet", key = "href",
      schema = schema(source_id = string(), text = string(), href = string(), job_like = boolean()),
      rules = c(
        s1a_href = sprintf(.url_ok, "href", "href"),
        s1a_text = "!is.na(text) & nchar(text) > 0")),
    s2 = list(
      file = "s2_queue.parquet", key = "item_id",
      schema = schema(item_id = string(), source_id = string(), text = string(), href = string(),
                      tier = int32(), reason = string(), first_seen = date32()),
      rules = c(
        s2_key_unique = "is_unique(item_id)",
        s2_tier       = "tier %in% c(1L, 2L)",
        s2_href       = sprintf(.url_ok, "href", "href"),
        s2_text       = "!is.na(text) & nchar(text) > 0")),
    s3 = list(
      file = "s3_deadlines.parquet", key = "item_id",
      schema = schema(item_id = string(), deadline = date32(), verdict = string(), flag = string(),
                      dates = string()),
      rules = c(
        s3_key_unique   = "is_unique(item_id)",
        s3_verdict_enum = sprintf("verdict %%in%% %s", .q(jw_enums$verdict)),
        s3_plausible    = sprintf('is.na(deadline) | (deadline >= as.Date("2020-01-01") & deadline <= %s + 1095)', td),
        s3_expired_past = sprintf('verdict != "expired" | (!is.na(deadline) & deadline < %s)', td),
        s3_open_future  = sprintf('verdict != "open" | is.na(deadline) | deadline >= %s', td))),
    s4 = list(
      file = "s4_classified.parquet", key = "item_id",
      schema = schema(item_id = string(), decision = string(), opp_id = string(), class = string(),
                      status = string(), track = string(), employer = string(), title = string(),
                      country = string(), contract = string(), deadline = date32(),
                      evidence_url = string(), why = string(), weakest_dimension = string(),
                      near_miss = boolean(), near_miss_rule = string(), notes = string()),
      rules = c(
        s4_key_unique    = "is_unique(item_id)",
        s4_decision_enum = sprintf("decision %%in%% %s", .q(jw_enums$decision)),
        s4_class_enum    = sprintf("is.na(class) | class %%in%% %s", .q(jw_enums$class)),
        s4_status_enum   = sprintf("is.na(status) | status %%in%% %s", .q(jw_enums$status)),
        s4_track_enum    = sprintf("is.na(track) | track %%in%% %s", .q(jw_enums$track)),
        s4_classified_complete = 'decision != "classified" | (!is.na(opp_id) & !is.na(class) & !is.na(status) & !is.na(track))',
        s4_why           = 'decision != "classified" | (!is.na(why) & !is.na(weakest_dimension))',
        s4_verified_open = 'status != "Verified open" | is.na(status) | (!is.na(evidence_url) & grepl("^https?://", evidence_url))',
        s4_near_miss     = "is.na(near_miss) | near_miss == FALSE | !is.na(near_miss_rule)")),
    s5 = list(
      file = "s5_discovery.parquet", key = "lead_id",
      schema = schema(lead_id = string(), platform = string(), query = string(), query_type = string(),
                      text = string(), url = string(), lead_status = string(), note = string(),
                      found = date32()),
      rules = c(
        s5_key_unique  = "is_unique(lead_id)",
        s5_platform    = sprintf("platform %%in%% %s", .q(jw_enums$platform)),
        s5_qtype       = sprintf("query_type %%in%% %s", .q(jw_enums$query_type)),
        s5_lead_status = sprintf("lead_status %%in%% %s", .q(jw_enums$lead_status)),
        s5_url         = sprintf(.url_ok, "url", "url"))),
    ledger = list(
      file = "opportunities.parquet", key = "opp_id",
      schema = schema(opp_id = string(), url = string(), employer = string(), title = string(),
                      country = string(), track = string(), contract = string(), deadline = date32(),
                      class = string(), status = string(), first_week = string(), last_week = string(),
                      notes = string()),
      rules = c(
        ledger_key_unique  = "is_unique(opp_id)",
        ledger_class_enum  = sprintf("class %%in%% %s", .q(jw_enums$class)),
        ledger_status_enum = sprintf("status %%in%% %s", .q(jw_enums$status))))
  )
}

# Build a validator from the text rules and refuse to continue when validate dropped one
# (unsupported syntax is only a warning there, so the rule would silently not run).
jw_make_validator <- function(rules) {
  v <- do.call(validate::validator, stats::setNames(lapply(rules, str2lang), names(rules)))
  if (length(v) != length(rules))
    stop("validate dropped ", length(rules) - length(v), " rule(s); kept: ", paste(names(v), collapse = ", "),
         call. = FALSE)
  v
}

# Coerce a data frame to a schema: add missing columns as NA, drop nothing (extra columns are an
# error), convert each column to the declared type. Returns a data frame in schema order.
jw_coerce <- function(df, sch) {
  nm <- names(sch)
  extra <- setdiff(names(df), nm)
  if (length(extra)) stop("unexpected column(s): ", paste(extra, collapse = ", "), call. = FALSE)
  n <- nrow(df)
  for (cn in setdiff(nm, names(df))) df[[cn]] <- rep(NA, n)
  out <- df[, nm, drop = FALSE]
  for (cn in nm) {
    ty <- sch[[cn]]$type$ToString()
    out[[cn]] <- switch(ty,
      string = as.character(out[[cn]]), int32 = as.integer(out[[cn]]),
      `date32[day]` = as.Date(out[[cn]]), bool = as.logical(out[[cn]]),
      stop("no coercion for type ", ty, call. = FALSE))
  }
  out
}

# ---- completeness gates (set equality between consecutive stages) ---------------------------
# Each returns a data frame of problems (code, severity, message, n); zero rows = passed.
.gp <- function(code, message, n, severity = "error") data.frame(code = code, severity = severity, message = message, n = as.integer(n))
.none <- function() data.frame(code = character(), severity = character(), message = character(), n = integer(), stringsAsFactors = FALSE)

jw_gate_s1 <- function(s1, expected_n) {
  if (is.null(expected_n) || is.na(expected_n)) return(.gp("s1_expected_n_missing", "number of enabled unique links was not recorded at stage start", 1L))
  if (nrow(s1) != expected_n)
    return(.gp("s1_coverage", sprintf("%d source rows for %d expected unique links", nrow(s1), expected_n), abs(nrow(s1) - expected_n)))
  .none()
}

# s3 must have exactly one row for every s2 item.
jw_gate_s3 <- function(s3, s2) .gate_ids("s3_coverage", s3$item_id, s2$item_id, "s2 queue item", "s3 row")

# s4 must decide every s3 candidate that is not expired: one row each, no strangers.
jw_gate_s4 <- function(s4, s3) .gate_ids("s4_coverage", s4$item_id, s3$item_id[s3$verdict != "expired"], "candidate", "s4 row")

.gate_ids <- function(code, have, want, want_label, have_label) {
  out <- .none()
  miss <- setdiff(want, have); extra <- setdiff(have, want); dup <- unique(have[duplicated(have)])
  if (length(miss)) out <- rbind(out, .gp(code, sprintf("%d %s(s) without a %s", length(miss), want_label, have_label), length(miss)))
  if (length(extra)) out <- rbind(out, .gp(code, sprintf("%d %s(s) that match no %s", length(extra), have_label, want_label), length(extra)))
  if (length(dup)) out <- rbind(out, .gp(code, sprintf("%d %s id(s) appear more than once", length(dup), have_label), length(dup)))
  out
}
