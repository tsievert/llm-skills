# Read the lessons inbox written by the skill-lessons skill and summarise it per skill.
#
# Usage:
#   source("skill-feedback-triage/scripts/read_lessons.R")
#   L <- read_lessons("path/to/inbox-copy")          # one row per entry
#   U <- read_usage("path/to/usage.tsv", since = triage_watermark())  # skill loads since last run
#   triage_watermark_set(max(U$time))                # after triage: record the new cutoff
#   lesson_overview(L, U)                            # per skill: loads, sessions, entries by type
#   lesson_dupes(L)                                  # candidate duplicates (same skill, similar title)
#   lesson_problems(L)                               # entries that fail validation
#
# Requires: yaml (CRAN). Base R otherwise. The inbox lives outside the project folder, and the
# assistant's R session may not be allowed to read it: copy it into the project first
# (see SKILL.md), then point `dir` at the copy.

lesson_fields <- c("type", "symptom", "context", "tried", "resolution", "evidence",
                   "suggested-change", "confidence", "generality")

read_lessons <- function(dir, repo = NULL) {
  stopifnot(requireNamespace("yaml", quietly = TRUE))
  files <- list.files(dir, pattern = "\\.md$", recursive = TRUE, full.names = TRUE)
  files <- files[!grepl("(^|/)processed/", files)]
  rows <- lapply(files, read_lesson_file)
  out <- do.call(rbind, rows)
  if (is.null(out)) return(empty_lessons())
  if (!is.null(repo)) {
    out$known_skill <- file.exists(file.path(repo, out$skill, "SKILL.md"))
  }
  out
}

empty_lessons <- function() {
  data.frame(file = character(), project = character(), date = character(), session = character(),
             os = character(), r = character(), skill = character(), title = character(),
             type = character(), symptom = character(), context = character(), tried = character(),
             resolution = character(), evidence = character(), suggested_change = character(),
             confidence = character(), generality = character(), stringsAsFactors = FALSE)
}

read_lesson_file <- function(path) {
  x <- readLines(path, warn = FALSE, encoding = "UTF-8")
  meta <- list()
  start <- 1L
  if (length(x) && identical(trimws(x[1]), "---")) {
    close <- which(trimws(x[-1]) == "---")[1] + 1L
    if (!is.na(close)) {
      meta <- tryCatch(yaml::yaml.load(paste(x[2:(close - 1L)], collapse = "\n")),
                       error = function(e) list())
      start <- close + 1L
    }
  }
  body <- x[start:length(x)]
  heads <- grep("^##\\s+[^#]", body)
  if (!length(heads)) return(NULL)
  ends <- c(heads[-1] - 1L, length(body))
  fld <- function(l, k) if (is.null(l[[k]])) NA_character_ else as.character(l[[k]])
  env <- meta$environment
  rows <- Map(function(s, e) {
    h <- sub("^##\\s+", "", body[s])
    skill <- sub(":.*$", "", h)
    title <- trimws(sub("^[^:]*:\\s*", "", h))
    if (!grepl(":", h)) title <- ""
    blk <- body[(s + 1L):e]
    blk <- blk[nzchar(trimws(blk))]
    kv <- regmatches(blk, regexec("^-\\s+([a-z-]+):\\s*(.*)$", blk))
    kv <- Filter(length, kv)
    vals <- setNames(vapply(kv, `[`, "", 3), vapply(kv, `[`, "", 2))
    f <- function(k) if (k %in% names(vals)) vals[[k]] else NA_character_
    data.frame(file = basename(path), project = fld(meta, "project"), date = fld(meta, "date"),
               session = fld(meta, "session"), os = fld(env, "os"), r = fld(env, "r"),
               skill = trimws(skill), title = title, type = f("type"), symptom = f("symptom"),
               context = f("context"), tried = f("tried"), resolution = f("resolution"),
               evidence = f("evidence"), suggested_change = f("suggested-change"),
               confidence = f("confidence"), generality = f("generality"),
               stringsAsFactors = FALSE)
  }, heads, ends)
  do.call(rbind, rows)
}

# `since`: ISO timestamp (e.g. "2026-10-23T15:25:13"); only rows strictly later are kept.
# ISO timestamps sort as text, so no date parsing is needed. NULL keeps everything.
read_usage <- function(file, since = NULL) {
  empty <- data.frame(time = character(), session = character(),
                      project = character(), skill = character())
  if (!file.exists(file) || file.info(file)$size == 0) return(empty)
  u <- utils::read.delim(file, header = FALSE, quote = "", stringsAsFactors = FALSE,
                         col.names = c("time", "session", "project", "skill"))
  if (!is.null(since) && !is.na(since)) u <- u[u$time > since, , drop = FALSE]
  u
}

# Watermark: the usage log is append-only and never truncated, so each triage run records
# the newest usage row it counted. Stored in AGENTS.md as one line
#   - Lessons usage watermark: 2026-10-23T15:25:13
# Use the newest row's time, not the current time, so rows written while triaging are not lost.
triage_watermark <- function(agents = "AGENTS.md") {
  x <- readLines(agents, warn = FALSE)
  m <- regmatches(x, regexec("^- Lessons usage watermark: (\\S+)\\s*$", x))
  m <- Filter(length, m)
  if (length(m)) m[[1]][2] else NULL
}

triage_watermark_set <- function(time, agents = "AGENTS.md") {
  stopifnot(is.character(time), length(time) == 1, grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}$", time))
  x <- readLines(agents, warn = FALSE)
  line <- paste0("- Lessons usage watermark: ", time)
  i <- grep("^- Lessons usage watermark: ", x)
  if (length(i)) x[i[1]] <- line else x <- c(x, "", "## Lessons triage state", line)
  writeLines(x, agents)
  invisible(line)
}

lesson_overview <- function(lessons, usage = NULL) {
  skills <- sort(unique(c(lessons$skill, if (!is.null(usage)) usage$skill)))
  types <- c("bug", "missing-guidance", "outdated-fact", "user-correction",
             "env-difference", "worked-well", "use-case")
  res <- data.frame(skill = skills, stringsAsFactors = FALSE)
  if (!is.null(usage)) {
    res$loads <- as.integer(table(factor(usage$skill, skills)))
    res$sessions <- vapply(skills, function(s) length(unique(usage$session[usage$skill == s])), 1L)
    res$projects <- vapply(skills, function(s) length(unique(usage$project[usage$skill == s])), 1L)
  }
  res$entries <- as.integer(table(factor(lessons$skill, skills)))
  for (t in types) res[[t]] <- as.integer(table(factor(lessons$skill[lessons$type %in% t], skills)))
  res[order(-res$entries), ]
}

# Candidate duplicates: same skill, normalised title distance below `max_dist`.
lesson_dupes <- function(lessons, max_dist = 0.35) {
  out <- list()
  for (s in unique(lessons$skill)) {
    d <- lessons[lessons$skill == s, , drop = FALSE]
    if (nrow(d) < 2) next
    t <- tolower(gsub("[^a-z0-9 ]", "", tolower(d$title)))
    dm <- utils::adist(t) / pmax(outer(nchar(t), nchar(t), pmax), 1)
    idx <- which(upper.tri(dm) & dm <= max_dist, arr.ind = TRUE)
    if (nrow(idx)) out[[s]] <- data.frame(skill = s, a = d$file[idx[, 1]], title_a = d$title[idx[, 1]],
                                          b = d$file[idx[, 2]], title_b = d$title[idx[, 2]],
                                          dist = round(dm[idx], 2), stringsAsFactors = FALSE)
  }
  if (length(out)) do.call(rbind, out) else NULL
}

lesson_problems <- function(lessons) {
  types <- c("bug", "missing-guidance", "outdated-fact", "user-correction", "env-difference", "worked-well", "use-case")
  bad <- function(cond, why) if (any(cond, na.rm = TRUE)) data.frame(file = lessons$file[cond %in% TRUE],
                                                                      skill = lessons$skill[cond %in% TRUE],
                                                                      title = lessons$title[cond %in% TRUE],
                                                                      problem = why, stringsAsFactors = FALSE)
  rbind(bad(!lessons$type %in% types, "type missing or not in the allowed list"),
        bad(is.na(lessons$symptom) | !nzchar(lessons$symptom), "no symptom"),
        # use-case entries describe usage, not a claim, so confidence is optional there
        bad(!lessons$confidence %in% c("high", "medium", "low") & !(lessons$type %in% "use-case" & is.na(lessons$confidence)),
            "confidence invalid"),
        bad(!nzchar(lessons$title), "no title"),
        if ("known_skill" %in% names(lessons)) bad(!lessons$known_skill, "skill folder not found in the repo"))
}
