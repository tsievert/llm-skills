# Lint the skills in this repo against the Agent Skills spec and the repo's own rules.
#
# Usage (from R, working directory anywhere inside the repo):
#   source("github-skill-maintenance/scripts/lint_skills.R")
#   lint_skills()                      # all skills, returns a data frame of findings
#   lint_skills(skills = "gam-mgcv")   # one skill
#
# Requires: yaml (CRAN). Optional: bash on PATH for `bash -n` syntax checks.
# Levels: "error" = breaks the spec or a standing rule, "warn" = likely problem,
# "info" = worth a look. Spec limits: https://agentskills.io/specification

lint_skills <- function(repo = find_repo_root(), skills = NULL) {
  stopifnot(requireNamespace("yaml", quietly = TRUE))
  dirs <- list.dirs(repo, recursive = FALSE, full.names = TRUE)
  dirs <- dirs[file.exists(file.path(dirs, "SKILL.md"))]
  if (!is.null(skills)) dirs <- dirs[basename(dirs) %in% skills]
  out <- lapply(dirs, lint_one_skill)
  res <- do.call(rbind, c(list(new_findings()), out))
  res <- res[order(match(res$level, c("error", "warn", "info")), res$skill), ]
  rownames(res) <- NULL
  if (nrow(res) == 0) message("No findings for ", length(dirs), " skill(s).")
  res
}

find_repo_root <- function(start = getwd()) {
  d <- normalizePath(start, winslash = "/")
  repeat {
    if (dir.exists(file.path(d, ".git"))) return(d)
    parent <- dirname(d)
    if (parent == d) stop("No git repository found above ", start)
    d <- parent
  }
}

new_findings <- function(skill = character(), level = character(),
                         check = character(), message = character()) {
  data.frame(skill = skill, level = level, check = check, message = message,
             stringsAsFactors = FALSE)
}

# Frontmatter keys: spec fields plus the Posit Assistant extras
# (https://assistant.posit.co/docs/features/skills/).
allowed_keys <- c("name", "description", "license", "compatibility", "metadata",
                  "allowed-tools", "argument-hint", "user-invocable",
                  "disable-model-invocation")

split_frontmatter <- function(lines) {
  if (length(lines) < 3 || trimws(lines[1]) != "---") return(NULL)
  end <- which(trimws(lines[-1]) == "---")[1] + 1
  if (is.na(end)) return(NULL)
  list(yaml = paste(lines[2:(end - 1)], collapse = "\n"),
       body = lines[(end + 1):length(lines)], body_start = end + 1)
}

lint_one_skill <- function(dir) {
  skill <- basename(dir)
  f <- new_findings()
  add <- function(level, check, msg) {
    f[nrow(f) + 1, ] <<- list(skill, level, check, msg)
  }
  raw <- readLines(file.path(dir, "SKILL.md"), warn = FALSE, encoding = "UTF-8")
  fm <- split_frontmatter(raw)
  if (is.null(fm)) {
    add("error", "frontmatter", "SKILL.md has no closing '---' frontmatter block.")
    return(f)
  }
  meta <- tryCatch(yaml::yaml.load(fm$yaml), error = function(e) e)
  if (inherits(meta, "error")) {
    add("error", "frontmatter", paste("YAML does not parse:", conditionMessage(meta)))
    return(f)
  }

  # --- name ---
  nm <- meta$name
  if (is.null(nm) || !nzchar(nm)) {
    add("error", "name", "Missing name.")
  } else {
    if (nchar(nm) > 64) add("error", "name", "Longer than 64 characters.")
    if (!grepl("^[a-z0-9]+(-[a-z0-9]+)*$", nm))
      add("error", "name", "Must be lowercase letters, digits, single hyphens; no leading/trailing hyphen.")
    if (!identical(nm, skill)) add("error", "name", sprintf("name '%s' does not match folder '%s'.", nm, skill))
    if (grepl("anthropic|claude", nm)) add("warn", "name", "Contains a reserved word (best-practices guide).")
  }

  # --- description ---
  # In a plain (unquoted) YAML scalar, " #" starts a comment, so text such as
  # "Covers #SBATCH directives" is silently cut off at that point.
  dl <- grep("^description:", strsplit(fm$yaml, "\n")[[1]], value = TRUE)
  if (length(dl)) {
    val <- trimws(sub("^description:", "", dl[1]))
    if (nzchar(val) && !grepl("^[\"'>|]", val) && grepl("\\s#", val))
      add("error", "description", "Unquoted description contains ' #': YAML treats the rest as a comment and truncates it. Quote the value or reword.")
  }
  d <- meta$description
  if (is.null(d) || !nzchar(trimws(d))) {
    add("error", "description", "Missing or empty description.")
  } else {
    d <- gsub("\\s+", " ", trimws(d))
    if (nchar(d) > 1024) add("error", "description", sprintf("%d characters (limit 1024).", nchar(d)))
    if (nchar(d) > 950 && nchar(d) <= 1024) add("info", "description", sprintf("%d characters, close to the 1024 limit.", nchar(d)))
    if (grepl("<[A-Za-z/][^>]*>", d)) add("error", "description", "Contains XML-like tags.")
    if (grepl("\\bI (can|will|am|help)\\b|\\b[Mm]y\\b|\\b[Yy]ou (can|will)\\b", d)) add("warn", "description", "Not third person (best-practices guide).")
    if (!grepl("\\b[Uu]se (when|for|first|this)\\b|\\bwhen\\b", d))
      add("warn", "description", "No explicit 'Use when ...' trigger wording.")
  }

  # --- other frontmatter ---
  unk <- setdiff(names(meta), allowed_keys)
  if (length(unk)) add("warn", "frontmatter", paste("Unknown keys:", paste(unk, collapse = ", ")))
  if (!is.null(meta$compatibility) && nchar(meta$compatibility) > 500)
    add("error", "frontmatter", "compatibility longer than 500 characters.")
  if (!is.null(meta$metadata)) {
    ok <- is.list(meta$metadata) && all(vapply(meta$metadata, function(x) is.character(x) && length(x) == 1, logical(1)))
    if (!ok) add("warn", "frontmatter", "metadata values must be strings (quote numbers, e.g. version: \"1.0\").")
  }

  # --- file_signals (opt-in content trigger for scripts/skill-file-signal-hook.sh; see
  # research/skill-trigger-hooks-ledger.md section 6) ---
  fs <- meta$metadata$file_signals
  if (!is.null(fs)) {
    if (!is.character(fs) || length(fs) != 1) {
      add("error", "file_signals", "metadata.file_signals must be a single '|'-separated string, not a YAML list.")
    } else {
      compiled <- tryCatch({ grepl(fs, "", perl = FALSE); TRUE }, error = function(e) e)
      if (inherits(compiled, "error"))
        add("error", "file_signals", paste("Does not compile as an extended regex:", conditionMessage(compiled)))
      alts <- strsplit(fs, "\\|")[[1]]
      short <- alts[nchar(gsub("[^A-Za-z0-9_]", "", alts)) < 4 & !grepl("\\\\b", alts)]
      if (length(short))
        add("warn", "file_signals", paste("Alternative(s) with little specificity (risk of matching incidental text):", paste(short, collapse = ", ")))
    }
  }

  # --- size ---
  n_body <- length(fm$body)
  if (n_body > 500) add("error", "size", sprintf("Body is %d lines (limit 500); move detail to references/.", n_body))
  else if (n_body > 400) add("info", "size", sprintf("Body is %d lines; approaching the 500-line limit.", n_body))

  body <- paste(fm$body, collapse = "\n")

  # --- links and paths ---
  if (grepl("(scripts|references|assets)\\\\", body)) add("warn", "paths", "Backslash path in SKILL.md; use forward slashes.")
  links <- regmatches(body, gregexpr("\\]\\((?!https?:|#|mailto:)[^)\\s]+\\)", body, perl = TRUE))[[1]]
  links <- sub("#.*$", "", gsub("^\\]\\(|\\)$", "", links))
  ticks <- regmatches(body, gregexpr("`((scripts|references|assets)/[^`\\s]+)`", body, perl = TRUE))[[1]]
  ticks <- gsub("`", "", ticks)
  # Strip trailing punctuation and skip glob/placeholder paths.
  cand <- unique(c(links, ticks))
  cand <- cand[!grepl("[*<>{}]", cand)]
  for (p in cand) {
    if (!file.exists(file.path(dir, p))) add("error", "links", sprintf("Referenced path does not exist: %s", p))
  }
  # Bundled files never mentioned in SKILL.md
  files <- list.files(dir, recursive = TRUE, full.names = FALSE)
  files <- files[grepl("^(references|scripts|assets)/", files) &
                   !grepl("(^|/)(__pycache__|\\.venv)/|\\.(pyc|png|jpg|jpeg|gif|pdf|h5|rds|RData)$", files)]
  for (p in files) {
    if (!grepl(p, body, fixed = TRUE) && !grepl(basename(p), body, fixed = TRUE) &&
        !grepl(dirname(p), body, fixed = TRUE))
      add("warn", "orphan", sprintf("Bundled file never mentioned in SKILL.md: %s", p))
  }

  # --- reference files ---
  for (p in files[grepl("^references/.*\\.md$", files)]) {
    ref <- readLines(file.path(dir, p), warn = FALSE, encoding = "UTF-8")
    if (length(ref) > 100 && !any(grepl("^#+\\s*(table of )?contents|^- \\[.*\\]\\(#", head(ref, 25), ignore.case = TRUE)))
      add("info", "reference-toc", sprintf("%s has %d lines and no table of contents near the top.", p, length(ref)))
    nested <- regmatches(ref, regexpr("\\]\\((references/|\\./)[^)]+\\.md\\)", ref))
    if (length(nested)) add("info", "nesting", sprintf("%s links to other reference files; keep references one level deep from SKILL.md.", p))
  }

  # --- repo standing rules (AGENTS.md) ---
  if (!any(grepl("^#+\\s*Explain the reasoning", fm$body)))
    add("error", "repo-rule", "Missing section 'Explain the reasoning (teaching rule)'.")
  if (!identical(skill, "skill-lessons") && !any(grepl("^#+\\s*Capture lessons", fm$body)))
    add("error", "repo-rule", "Missing section 'Capture lessons (self-improvement rule)' (see skill-lessons).")
  script_files <- files[grepl("^(scripts|assets)/", files)]
  is_hpc <- grepl("^hpc-|-hpc$", skill) || any(vapply(script_files, function(p) {
    any(grepl("^\\s*#SBATCH\\s", readLines(file.path(dir, p), warn = FALSE)))
  }, logical(1)))
  if (is_hpc && !any(grepl("^#+\\s*Where this skill runs", fm$body)))
    add("error", "repo-rule", "HPC-related skill without a 'Where this skill runs' section.")

  # --- scripts: line endings, shebang, syntax, secrets ---
  for (p in script_files) {
    path <- file.path(dir, p)
    bytes <- readBin(path, "raw", file.size(path))
    if (as.raw(13) %in% bytes && grepl("\\.(sh|sbatch|py)$", p))
      add("error", "scripts", sprintf("%s has CRLF in the working copy (check `git ls-files --eol`; the index may be LF but a copied file breaks on Linux nodes).", p))
    txt <- readLines(path, warn = FALSE, encoding = "UTF-8")
    if (grepl("\\.(sh|sbatch)$", p) && !grepl("^#!", txt[1]))
      add("warn", "scripts", sprintf("%s has no shebang line.", p))
    if (grepl("\\.(sh|sbatch)$", p) && nzchar(Sys.which("bash"))) {
      st <- suppressWarnings(system2("bash", c("-n", shQuote(path)), stdout = FALSE, stderr = FALSE))
      if (!identical(st, 0L)) add("error", "scripts", sprintf("%s fails `bash -n` syntax check.", p))
    }
    if (any(grepl("(api[_-]?key|token|secret|password)\\s*[:=]\\s*['\"][A-Za-z0-9_\\-]{16,}['\"]", txt, ignore.case = TRUE, perl = TRUE)))
      add("error", "secrets", sprintf("%s looks like it contains a literal credential.", p))
  }
  f
}
