# Churn helpers for the triage step "which skills or files need a look". Independent of the lessons inbox.
#   source("skill-feedback-triage/scripts/churn.R")
#   usage_churn_table(usage = U_all)      # one row per skill, ranked by commits since its last rework
#   usage_churn_files("deeplabcut-hpc")   # one row per file, flags files no rework has covered
# Rework log: skill-feedback-triage/references/rework-log.tsv (date, commit, target). A target is a file
# path relative to the repo root, or a folder ending in "/" (all files below it). Append a row in the same
# commit as every rework; without a row the helpers cannot tell a reworked file from an untouched one.

.git_lines <- function(repo, args) {
  suppressWarnings(system2("git", c("-C", shQuote(repo), args), stdout = TRUE, stderr = FALSE))
}

rework_log_read <- function(repo = getwd(),
                            path = file.path(repo, "skill-feedback-triage", "references", "rework-log.tsv")) {
  if (!file.exists(path)) return(data.frame(date = character(), commit = character(), target = character()))
  utils::read.delim(path, colClasses = "character", comment.char = "#")
}

# Latest rework row covering `file` (exact path or folder prefix); NULL when none.
.rework_for <- function(file, log) {
  hit <- log[file == log$target | (endsWith(log$target, "/") & startsWith(file, log$target)), , drop = FALSE]
  if (!nrow(hit)) return(NULL)
  hit[which.max(as.Date(hit$date)), , drop = FALSE]
}

# Commits to `paths` since `commit` (exclusive), or since `date` when the log row has no commit.
.commits_since <- function(repo, paths, row) {
  rng <- if (!is.null(row) && nzchar(row$commit)) paste0(row$commit, "..HEAD") else NULL
  args <- c("log", if (is.null(rng)) paste0("--since=", row$date), rng, "--pretty=format:%h", "--", shQuote(paths))
  length(.git_lines(repo, args))
}

usage_churn_table <- function(repo = getwd(), days = 60, usage = NULL, log = rework_log_read(repo)) {
  skills <- basename(dirname(Sys.glob(file.path(repo, "*", "SKILL.md"))))
  rows <- lapply(skills, function(s) {
    n <- function(d) length(.git_lines(repo, c("log", paste0("--since=", d, ".days"), "--pretty=format:%h", "--", shQuote(s))))
    files <- list.files(file.path(repo, s), recursive = TRUE, full.names = TRUE)
    mine <- log[startsWith(log$target, paste0(s, "/")), , drop = FALSE]
    last <- if (nrow(mine)) mine[which.max(as.Date(mine$date)), , drop = FALSE] else NULL
    data.frame(skill = s, c14 = n(14), c_window = n(days),
               last_rework = if (is.null(last)) NA_character_ else last$date,
               since_rework = if (is.null(last)) NA_integer_ else .commits_since(repo, s, last),
               skill_kb = round(file.size(file.path(repo, s, "SKILL.md")) / 1024, 1),
               tree_kb = round(sum(file.size(files)) / 1024), files = length(files),
               loads = if (is.null(usage)) NA_integer_ else sum(usage$skill == s),
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  # Reworked skills: files no rework covered that are large or edited often (the overlooked ones)
  out$uncovered <- vapply(out$skill, function(s) {
    if (!any(startsWith(log$target, paste0(s, "/")))) return(NA_integer_)
    f <- usage_churn_files(s, repo, days, log)
    sum(is.na(f$reworked) & f$candidate)
  }, integer(1))
  # Never-reworked skills rank by window commits; reworked ones by commits since the rework, so a fresh rework drops down
  out$rank_score <- ifelse(is.na(out$since_rework), out$c_window, out$since_rework)
  out[order(-out$rank_score, -out$c_window), ]
}

# Candidate = a file no rework has covered that is large or edited often, or a covered file edited again since.
usage_churn_files <- function(skill, repo = getwd(), days = 60, log = rework_log_read(repo),
                              big_kb = 6, churn_edits = 3) {
  files <- sub(paste0("^", gsub("\\\\", "/", normalizePath(repo, winslash = "/")), "/"), "",
               gsub("\\\\", "/", list.files(file.path(repo, skill), recursive = TRUE, full.names = TRUE)))
  # One git call for all files (commits per file)
  names_log <- .git_lines(repo, c("log", paste0("--since=", days, ".days"), "--name-only", "--pretty=format:",
                                  "--", shQuote(skill)))
  per_file <- table(names_log[nzchar(names_log)])
  rows <- lapply(files, function(f) {
    edits <- if (f %in% names(per_file)) as.integer(per_file[[f]]) else 0L
    row <- .rework_for(f, log)
    since <- if (is.null(row)) NA_integer_ else .commits_since(repo, f, row)
    kb <- round(file.size(file.path(repo, f)) / 1024, 1)
    data.frame(file = f, kb = kb, edits_window = edits,
               reworked = if (is.null(row)) NA_character_ else row$date, edits_since_rework = since,
               candidate = if (is.null(row)) (kb >= big_kb || edits >= churn_edits) else since >= churn_edits,
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  out[order(-out$candidate, -out$edits_window, -out$kb), ]
}

# Patch gate: run before the triage table on the files the proposed outcomes would edit (one element per
# proposed change, so a file named twice counts twice). Rows marked "rework-or-defer" need a `rework`
# proposal in the table or a recorded deferral; a target already deferred once should not be deferred
# silently again. Deferrals live in references/rework-deferred.tsv (date, target, reason).
rework_deferred_read <- function(repo = getwd(),
                                 path = file.path(repo, "skill-feedback-triage", "references", "rework-deferred.tsv")) {
  if (!file.exists(path)) return(data.frame(date = character(), target = character(), reason = character()))
  utils::read.delim(path, colClasses = "character", comment.char = "#")
}

rework_defer <- function(target, reason, repo = getwd(), date = format(Sys.Date()),
                         path = file.path(repo, "skill-feedback-triage", "references", "rework-deferred.tsv")) {
  stopifnot(nzchar(reason), !grepl("[\t\n]", reason))
  if (!file.exists(path)) writeLines("date\ttarget\treason", path)
  cat(paste(date, target, reason, sep = "\t"), "\n", sep = "", file = path, append = TRUE)
  invisible(rework_deferred_read(repo, path))
}

patch_gate <- function(targets, repo = getwd(), days = 60, log = rework_log_read(repo),
                       deferred = rework_deferred_read(repo), churn_edits = 3) {
  targets <- gsub("\\\\", "/", targets)
  tab <- table(targets)
  files <- names(tab)
  skills <- vapply(strsplit(files, "/", fixed = TRUE), `[`, "", 1)
  info <- do.call(rbind, lapply(unique(skills), usage_churn_files, repo = repo, days = days, log = log))
  out <- data.frame(file = files, skill = skills, proposed = as.integer(tab), stringsAsFactors = FALSE)
  out$skill_proposed <- ave(out$proposed, out$skill, FUN = sum)
  m <- match(out$file, info$file)
  out$kb <- info$kb[m]
  # Edits since the last rework covering the file, or in the window when it was never reworked
  out$file_edits <- ifelse(is.na(info$reworked[m]), info$edits_window[m], info$edits_since_rework[m])
  out$file_edits[is.na(out$file_edits)] <- 0L
  hit <- lapply(out$file, function(f) deferred[f == deferred$target |
                  (endsWith(deferred$target, "/") & startsWith(f, deferred$target)), , drop = FALSE])
  out$deferred_n <- vapply(hit, nrow, 1L)
  out$last_deferral <- vapply(hit, function(h) if (nrow(h)) h$reason[which.max(as.Date(h$date))] else "", "")
  out$verdict <- ifelse(out$file_edits >= churn_edits | out$proposed >= 2 | out$skill_proposed >= 3,
                        "rework-or-defer", "patch")
  out[order(out$verdict, -out$file_edits), ]
}
