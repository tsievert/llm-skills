# Find skills whose trigger territory (the YAML description) overlaps, and whether the descriptions hand off.
#
# Usage (from R, working directory anywhere inside the repo):
#   source("github-skill-maintenance/scripts/lint_skills.R")          # for find_repo_root()
#   source("github-skill-maintenance/scripts/check_skill_clashes.R")
#   check_skill_clashes()                 # pairs at or above the threshold
#   check_skill_clashes(threshold = 0.1)  # more sensitive; expect more noise
#   check_skill_clashes(new = "my-skill") # only pairs involving one skill (use for a new or changed skill)
#
# Why descriptions: the assistant chooses a skill from the description alone, so overlap there is what
# causes two skills to load for one request. Bodies are only read after loading.
#
# Score: IDF-weighted cosine similarity of the description words (words that occur in few descriptions
# count more; stop words dropped). 1 = identical vocabulary. Typical unrelated pairs score below 0.05.
# On the 22 skills of 2026-10-23, the real clash pairs scored 0.2 to 0.5; see references/skill-boundaries.md.
#
# Hand-off column: "both" = each description names the other skill, "one" = only one does, "none" = neither.
# Levels: warn  = score >= threshold and handoff "none" (nobody tells the model which one to pick)
#         info  = score >= threshold and handoff "one"
#         ok    = score >= threshold and handoff "both" (listed only with show_ok = TRUE)
# A pair recorded in references/clash-decisions.tsv (decision = "accepted") is skipped with a reason.
# The score is a lexical heuristic; it cannot see meaning. A high score with a hand-off can still be a
# real clash if both skills claim the same verbs for the same object; read the two descriptions.
# Requires: yaml.

check_skill_clashes <- function(repo = find_repo_root(), threshold = 0.15, new = NULL, show_ok = FALSE,
                                decisions = file.path(repo, "github-skill-maintenance/references/clash-decisions.tsv")) {
  dirs <- list.dirs(repo, recursive = FALSE, full.names = TRUE)
  dirs <- dirs[file.exists(file.path(dirs, "SKILL.md"))]
  skills <- basename(dirs)
  desc <- vapply(dirs, function(d) {
    l <- sub("\r$", "", readLines(file.path(d, "SKILL.md"), warn = FALSE, encoding = "UTF-8"))
    e <- which(l == "---")[2]
    y <- tryCatch(yaml::yaml.load(paste(l[2:(e - 1)], collapse = "\n")), error = function(e) NULL)
    if (is.null(y) || is.null(y$description)) "" else y$description
  }, character(1))
  names(desc) <- skills

  stop_w <- c("the", "and", "for", "with", "use", "when", "user", "asks", "that", "this", "from", "into", "not",
              "are", "which", "than", "also", "any", "all", "per", "via", "using", "uses", "skill", "skills",
              "covers", "writes", "reviews", "ships", "including", "mentions", "wants", "how", "why")
  tok <- lapply(desc, function(x) {
    # Skill names in the hand-off sentences are not trigger vocabulary
    for (s in skills) x <- gsub(s, " ", x, fixed = TRUE)
    w <- unique(tolower(unlist(strsplit(x, "[^A-Za-z0-9_.]+"))))
    w[nchar(w) > 2 & !w %in% stop_w]
  })
  n <- length(tok)
  df <- table(unlist(tok))
  wt <- function(t) log(n / as.numeric(df[t]))

  dec <- if (file.exists(decisions)) {
    d <- read.delim(decisions, sep = "\t", stringsAsFactors = FALSE, comment.char = "#")
    d[d$decision == "accepted", c("a", "b", "reason")]
  } else data.frame(a = character(), b = character(), reason = character())
  is_accepted <- function(a, b) any((dec$a == a & dec$b == b) | (dec$a == b & dec$b == a))
  names_other <- function(x, y) grepl(paste0("(^|[^a-z0-9-])", y, "($|[^a-z0-9-])"), desc[[x]], perl = TRUE)

  out <- data.frame(a = character(), b = character(), score = numeric(), handoff = character(),
                    level = character(), shared = character(), stringsAsFactors = FALSE)
  for (p in combn(skills, 2, simplify = FALSE)) {
    if (!is.null(new) && !any(p %in% new)) next
    s <- intersect(tok[[p[1]]], tok[[p[2]]])
    if (!length(s)) next
    sc <- sum(wt(s)) / sqrt(sum(wt(tok[[p[1]]])) * sum(wt(tok[[p[2]]])))
    if (sc < threshold || is_accepted(p[1], p[2])) next
    k <- names_other(p[1], p[2]) + names_other(p[2], p[1])
    ho <- c("none", "one", "both")[k + 1]
    lv <- c("warn", "info", "ok")[k + 1]
    out[nrow(out) + 1, ] <- list(p[1], p[2], round(sc, 3), ho, lv,
                                 paste(head(s[order(-wt(s))], 6), collapse = ", "))
  }
  if (!show_ok) out <- out[out$level != "ok", ]
  out <- out[order(match(out$level, c("warn", "info", "ok")), -out$score), ]
  if (nrow(out) == 0) message("No clash findings at threshold ", threshold, " for ", n, " skill(s).")
  out
}
