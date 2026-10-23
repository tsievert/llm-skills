# Helpers to write lesson entries for the llm-skills feedback loop.
#
# Usage:
#   source("skill-lessons/scripts/lesson_helpers.R")
#   lesson_add(skill = "gam-mgcv", title = "...", type = "bug", symptom = "...", ...)
#   lesson_file()          # a new inbox path for this session
#
# Base R only. The inbox is ~/.posit/lessons/inbox (USERPROFILE on Windows) unless the
# environment variable LESSONS_DIR is set (used for tests).

lesson_types <- c("bug", "missing-guidance", "outdated-fact", "user-correction",
                  "env-difference", "worked-well")
lesson_generality <- c("general", "likely-user-specific", "unsure")
lesson_confidence <- c("high", "medium", "low")

lessons_dir <- function() {
  d <- Sys.getenv("LESSONS_DIR", "")
  if (nzchar(d)) return(d)
  home <- Sys.getenv("USERPROFILE", Sys.getenv("HOME"))
  file.path(home, ".posit", "lessons")
}

lesson_file <- function(project = basename(getwd()), session8 = "manual") {
  project <- gsub("[^A-Za-z0-9._-]", "_", project)
  inbox <- file.path(lessons_dir(), "inbox")
  try(dir.create(inbox, recursive = TRUE, showWarnings = FALSE), silent = TRUE)
  file.path(inbox, sprintf("%s_%s_%s.md", project, format(Sys.time(), "%Y%m%d-%H%M%S"), session8))
}

# Replace obvious identifiers; returns the scrubbed text.
lesson_scrub <- function(x) {
  x <- gsub("[A-Za-z]:[\\\\/](Users|Documents and Settings)[\\\\/][^\\s\"'<>]*", "<path>", x, perl = TRUE)
  x <- gsub("/(home|Users|scratch|work|projappl)/[^\\s\"'<>]*", "<path>", x, perl = TRUE)
  x <- gsub("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", "<email>", x, perl = TRUE)
  x
}

# Patterns that survive scrubbing and still look private; returns a character vector.
lesson_flags <- function(x) {
  checks <- c(
    "possible token or key (32+ alphanumerics)" = "[A-Za-z0-9_-]{32,}",
    "absolute path left" = "(^|[\\s\"'(])([A-Za-z]:[\\\\/]|/(?!<)[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/)",
    "long number (6+ digits, possible ID)" = "(?<![\\d.])\\d{6,}(?![\\d.])"
  )
  hit <- vapply(checks, function(p) any(grepl(p, x, perl = TRUE)), logical(1))
  names(checks)[hit]
}

lesson_add <- function(skill, title, type, symptom, context = "", tried = "",
                       resolution = "unresolved", evidence = "", suggested_change = "unknown",
                       confidence = "medium", generality = "unsure",
                       packages = character(), project = basename(getwd()),
                       session = "manual", file = lesson_file(project, session),
                       repo = NULL, force = FALSE) {
  stopifnot(is.character(skill), length(skill) == 1, nzchar(title), nzchar(symptom))
  type <- match.arg(type, lesson_types)
  confidence <- match.arg(confidence, lesson_confidence)
  generality <- match.arg(generality, lesson_generality)

  # The skill name must be a real skill folder when the repo is known.
  if (is.null(repo)) {
    cand <- c(Sys.getenv("LLM_SKILLS_DIR", ""), getwd())
    repo <- cand[nzchar(cand) & file.exists(file.path(cand, "gam-mgcv", "SKILL.md"))][1]
  }
  if (length(repo) && !is.na(repo) && !file.exists(file.path(repo, skill, "SKILL.md")))
    stop("'", skill, "' is not a skill folder in ", repo, call. = FALSE)

  fields <- list(type = type, symptom = symptom, context = context, tried = tried,
                 resolution = resolution, evidence = evidence,
                 `suggested-change` = suggested_change, confidence = confidence,
                 generality = generality)
  fields <- lapply(fields, function(v) gsub("\\s*\\n\\s*", " ", lesson_scrub(v)))
  title <- lesson_scrub(title)
  flags <- lesson_flags(c(title, unlist(fields)))
  if (length(flags) && !force)
    stop("Entry not written; still looks private: ", paste(flags, collapse = "; "),
         ". Reword it, or set force = TRUE after checking.", call. = FALSE)

  header <- NULL
  if (!file.exists(file)) {
    pk <- vapply(packages, function(p) tryCatch(as.character(utils::packageVersion(p)),
                                                error = function(e) NA_character_), "")
    pk_txt <- if (length(pk)) paste0("{", paste0(names(pk), ": ", ifelse(is.na(pk), "null", paste0("\"", pk, "\"")), collapse = ", "), "}") else "{}"
    sess <- sub(".*_([^_]+)\\.md$", "\\1", basename(file))
    header <- c("---",
      paste0("project: ", gsub("[^A-Za-z0-9._-]", "_", project)),
      paste0("date: ", format(Sys.Date())),
      paste0("session: ", sess),
      sprintf("environment: {os: \"%s\", r: \"%s\", packages: %s}",
              utils::sessionInfo()$running, paste(R.version$major, R.version$minor, sep = "."), pk_txt),
      "---", "")
  }
  block <- c(sprintf("## %s: %s", skill, title),
             paste0("- ", names(fields), ": ", unlist(fields)), "")
  text <- c(header, block)

  # The assistant's R session may not be allowed to write outside the project (the inbox is
  # in the home folder). Then return the text so it can be saved with the `write` tool.
  ok <- tryCatch({
    dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
    cat(text, file = file, sep = "\n", append = TRUE)
    TRUE
  }, error = function(e) FALSE)
  if (ok) {
    message("Lesson recorded in ", file)
  } else {
    message("R could not write to ", file, ". Save the text below there with the `write` ",
            "tool (append if the file exists; the front matter is only needed once).")
    cat(text, sep = "\n")
  }
  invisible(list(file = file, text = text, written = ok))
}
