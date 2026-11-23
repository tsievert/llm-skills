# jw_social.R -- social-search tag ledger (state/social_tags.tsv). Loaded by jobwatch.R.

# One row per (platform, tag). Columns: platform, tag, query_type (hashtag / text / author+tag / web_keywords),
# first_used, last_used, n_runs, n_hits, n_useful, last_useful, posts_per_month, status (candidate / keep /
# retired), note. "Useful" = led to a verified opportunity or a new link the user accepted; the assistant
# counts it, the user may overrule status. `tag` holds a combined key as free text for query_type
# "author+tag" (for example "<author handle> + #<tag>"), since a job-bot account is best queried by author
# plus its own tag vocabulary, not by tag alone.
.jw_tag_cols <- c("platform", "tag", "query_type", "first_used", "last_used", "n_runs", "n_hits", "n_useful",
                  "last_useful", "posts_per_month", "status", "note")

.jw_tag_query_types <- c("hashtag", "text", "author+tag", "web_keywords")

jw_tags_read <- function() {
  x <- .tsv_read(jw_state("social_tags.tsv"))
  if (is.null(x)) x <- as.data.frame(setNames(rep(list(character()), length(.jw_tag_cols)), .jw_tag_cols))
  # Migrate an older file written before a column was added (e.g. query_type, posts_per_month):
  # fill it with NA and reorder, rather than assuming the file matches .jw_tag_cols exactly.
  for (cn in setdiff(.jw_tag_cols, names(x))) x[[cn]] <- NA_character_
  x <- x[, .jw_tag_cols]
  for (cn in c("n_runs", "n_hits", "n_useful")) x[[cn]] <- as.integer(x[[cn]])
  x$posts_per_month <- suppressWarnings(as.numeric(x$posts_per_month))
  x
}

# Record one search: hits = posts returned and screened as job-relevant; useful = how many led to
# something verified. Creates the row if the tag is new (status "candidate"). query_type and
# posts_per_month are optional; posts_per_month is overwritten with the latest estimate (a rough guide
# to recognise low-volume tags, not accumulated across runs).
jw_tags_record <- function(platform, tag, hits = 0L, useful = 0L, note = NA_character_,
                            query_type = NA_character_, posts_per_month = NA_real_) {
  stopifnot(platform %in% c("bluesky", "mastodon", "web"))
  if (!is.na(query_type)) stopifnot(query_type %in% .jw_tag_query_types)
  tag <- sub("^#", "", tag)
  x <- jw_tags_read(); now <- jw_now()
  i <- which(x$platform == platform & tolower(x$tag) == tolower(tag))
  if (!length(i)) {
    x[nrow(x) + 1, ] <- list(platform, tag, query_type, now, now, 0L, 0L, 0L, NA, posts_per_month,
                              "candidate", note)
    i <- nrow(x)
  }
  x$last_used[i] <- now; x$n_runs[i] <- x$n_runs[i] + 1L
  x$n_hits[i] <- x$n_hits[i] + as.integer(hits); x$n_useful[i] <- x$n_useful[i] + as.integer(useful)
  if (useful > 0) x$last_useful[i] <- now
  if (!is.na(note)) x$note[i] <- note
  if (!is.na(query_type)) x$query_type[i] <- query_type
  if (!is.na(posts_per_month)) x$posts_per_month[i] <- posts_per_month
  .tsv_write(x[, .jw_tag_cols], jw_state("social_tags.tsv")); invisible(x)
}

# Suggest status changes; never applies them. Keep: >= 1 useful hit. Retire candidates: >= min_runs runs, none useful.
jw_tags_review <- function(min_runs = 4) {
  x <- jw_tags_read()
  x$suggestion <- ifelse(x$status == "retired", NA,
    ifelse(x$n_useful >= 1 & x$status != "keep", "keep",
    ifelse(x$n_useful == 0 & x$n_runs >= min_runs, "retire", NA)))
  x[!is.na(x$suggestion), ]
}

# Change a status (keep / retire / candidate) after the user agrees; backs up first.
jw_tags_set_status <- function(platform, tag, status, confirmed = FALSE) {
  if (!confirmed) stop("Show the proposed change to the user and call again with confirmed = TRUE.")
  stopifnot(status %in% c("keep", "retired", "candidate"))
  p <- jw_state("social_tags.tsv"); .jw_backup(p)
  x <- jw_tags_read(); i <- which(x$platform == platform & tolower(x$tag) == tolower(sub("^#", "", tag)))
  if (!length(i)) stop("tag not in ledger")
  x$status[i] <- status; .tsv_write(x[, .jw_tag_cols], p); invisible(x)
}
