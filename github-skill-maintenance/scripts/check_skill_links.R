# Check that skills reference each other, and that links go both ways.
#
# Usage (from R, working directory anywhere inside the repo):
#   source("github-skill-maintenance/scripts/lint_skills.R")       # for find_repo_root()
#   source("github-skill-maintenance/scripts/check_skill_links.R")
#   check_skill_links()                       # data frame of findings (SKILL.md text only)
#   check_skill_links(scope = "all")          # also count mentions in references/ files
#
# A link is a mention of another skill's name in SKILL.md (description and body). The boilerplate
# sections "Explain the reasoning" and "Capture lessons" are ignored because they name
# skill-lessons / skill-feedback-triage in every skill. "Hub" skills (maintenance and lessons
# tooling) are excluded as sources and targets.
#
# Findings:
#   one-way         A mentions B, B does not mention A. Needs a DECISION, not an automatic edit:
#                   add a backlink to B, or record "no-backlink" with a reason in
#                   references/link-decisions.tsv so the pair is not raised again.
#   unknown-skill   A backticked skill-like name in a "Related skills" / "Next skills" section that is
#                   not a skill in this repo (typo, renamed or not yet written skill).
#   isolated        A skill that neither mentions nor is mentioned by any other skill.
# Requires: base R only.

check_skill_links <- function(repo = find_repo_root(), scope = c("skill", "all"),
                              hubs = c("github-skill-maintenance", "skill-lessons", "skill-feedback-triage"),
                              decisions = file.path(repo, "github-skill-maintenance/references/link-decisions.tsv")) {
  scope <- match.arg(scope)
  dirs <- list.dirs(repo, recursive = FALSE, full.names = TRUE)
  dirs <- dirs[file.exists(file.path(dirs, "SKILL.md"))]
  skills <- basename(dirs)
  rd <- function(p) sub("\r$", "", readLines(p, warn = FALSE, encoding = "UTF-8"))
  heading <- "^#{1,3}[[:space:]]"

  strip_boilerplate <- function(lines) {
    h <- grep(heading, lines)
    drop <- rep(FALSE, length(lines))
    for (i in seq_along(h)) {
      if (grepl("^#{1,3}[[:space:]]*(Explain the reasoning|Capture lessons)", lines[h[i]])) {
        end <- if (i < length(h)) h[i + 1] - 1 else length(lines)
        drop[h[i]:end] <- TRUE
      }
    }
    lines[!drop]
  }
  text_of <- function(d) {
    txt <- strip_boilerplate(rd(file.path(d, "SKILL.md")))
    if (scope == "all") {
      refs <- list.files(d, pattern = "\\.(md|R|py|sh)$", recursive = TRUE, full.names = TRUE)
      refs <- refs[!grepl("/SKILL\\.md$", refs)]
      for (r in refs) txt <- c(txt, rd(r))
    }
    paste(txt, collapse = "\n")
  }
  texts <- setNames(lapply(dirs, text_of), skills)

  mentions <- function(txt, name) grepl(paste0("(^|[^a-z0-9-])", name, "($|[^a-z0-9-])"), txt, perl = TRUE)
  active <- setdiff(skills, hubs)
  # adj[b, a] is TRUE when skill a mentions skill b
  adj <- sapply(active, function(a) sapply(active, function(b) a != b && mentions(texts[[a]], b)))
  dimnames(adj) <- list(active, active)

  dec <- if (file.exists(decisions)) {
    d <- read.delim(decisions, sep = "\t", stringsAsFactors = FALSE, comment.char = "#")
    d[d$decision == "no-backlink", c("from", "to")]
  } else data.frame(from = character(), to = character())

  out <- data.frame(skill = character(), level = character(), check = character(),
                    message = character(), stringsAsFactors = FALSE)
  add <- function(s, lv, ck, m) out[nrow(out) + 1, ] <<- list(s, lv, ck, m)

  for (a in active) for (b in active) {
    if (a == b || !adj[b, a] || adj[a, b]) next
    if (any(dec$from == a & dec$to == b)) next
    add(b, "info", "one-way", sprintf("%s mentions %s, but %s does not mention %s. Add a backlink in %s, or record a no-backlink decision.", a, b, b, a, b))
  }
  for (a in active) {
    if (!any(adj[, a]) && !any(adj[a, ])) add(a, "info", "isolated", "No link to or from any other (non-hub) skill.")
  }
  for (d in dirs) {
    lines <- rd(file.path(d, "SKILL.md"))
    h <- grep(heading, lines)
    for (i in seq_along(h)) {
      if (!grepl("^#{1,3}[[:space:]]*(Related skills|Next skills)", lines[h[i]])) next
      end <- if (i < length(h)) h[i + 1] - 1 else length(lines)
      sec <- paste(lines[h[i]:end], collapse = "\n")
      nm <- unique(gsub("`", "", regmatches(sec, gregexpr("`[a-z0-9]+(-[a-z0-9]+)+`", sec))[[1]]))
      for (n in setdiff(nm, skills)) add(basename(d), "warn", "unknown-skill", sprintf("'%s' in a related-skills section is not a skill in this repo (typo, renamed, or not written yet).", n))
    }
  }
  if (nrow(out) == 0) message("No link findings for ", length(skills), " skill(s).")
  out[order(match(out$level, c("error", "warn", "info")), out$check, out$skill), ]
}
