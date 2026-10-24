#' codebase-map: generate .codemap/{INVENTORY.md,CODEMAP.md,DEPENDS.tsv} for one
#' RStudio project, add them to .gitignore, and point to them from AGENTS.md/DATABOT.md.
#' Base R only (tools, utils) -- no package dependencies, so it never needs an install
#' step before a hook can call it. See references/ in this skill for the full design.
#'
#' Usage (interactive):   source("build_codemap.R"); build_codemap(".")
#' Usage (CLI, for the hook): Rscript build_codemap.R <project_root>

norm_slashes <- function(p) gsub("\\\\", "/", p)

# ---- project root -----------------------------------------------------------

find_project_root <- function(start = ".") {
  start <- norm_slashes(suppressWarnings(normalizePath(start, mustWork = FALSE)))
  cur <- start
  for (i in 1:12) {
    if (length(list.files(cur, pattern = "\\.Rproj$")) > 0) return(cur)
    parent <- norm_slashes(dirname(cur))
    if (identical(parent, cur)) break
    cur <- parent
  }
  NULL
}

# ---- file walk ----------------------------------------------------------

exclude_dir_pattern <- "(^|/)(\\.git|\\.codemap|renv|\\.quarto|tmp-examples|node_modules|__pycache__|\\.Rproj\\.user|\\.venv|_targets)(/|$)"

scan_files <- function(root) {
  files <- norm_slashes(list.files(root, recursive = TRUE, full.names = TRUE,
                                    pattern = "\\.(R|py|sh|md|qmd|Rmd)$"))
  rel <- vapply(files, function(p) sub(root, "", p, fixed = TRUE), character(1))
  rel <- sub("^/", "", rel)
  files[!grepl(exclude_dir_pattern, rel)]
}

# Case matters for R: its own extension is conventionally uppercase. Lowercase the
# extension for comparison AND use the lowercase label in the dispatch below -- doing
# the dispatch on the un-lowercased extension (or lowercasing only one side) silently
# drops every .R file into "other" with no error. (Found the hard way; see
# references/language-rules.md.)
lang_of <- function(path) {
  ext <- tolower(tools::file_ext(path))
  switch(ext, r = "R", py = "python", sh = "shell",
         md = "markdown", qmd = "quarto", rmd = "rmarkdown", "other")
}

# ---- heading extraction ------------------------------------------------------

# Leading AND trailing decorative runs must both be stripped before the lazy capture,
# or the engine extends the capture through the leading dashes to reach the only valid
# stopping point (just before the trailing run). See references/language-rules.md.
PAT_DASH_HEADING <- "^\\s*#+\\s*[-=#]*\\s*(.*?)\\s*[-=#]{4,}\\s*$"
PAT_PY_DEFCLASS  <- "^\\s*(def |class )"
PAT_MD_HEADING   <- "^#{1,6}\\s+.*$"

extract_headings <- function(lang, lines) {
  out <- list()
  for (i in seq_along(lines)) {
    ln <- lines[i]
    if (lang %in% c("R", "python", "shell", "quarto", "rmarkdown")) {
      m <- regmatches(ln, regexec(PAT_DASH_HEADING, ln, perl = TRUE))[[1]]
      if (length(m) == 2 && nzchar(trimws(m[2]))) {
        out[[length(out) + 1]] <- list(line = i, text = trimws(m[2]))
        next
      }
    }
    if (lang == "python" && grepl(PAT_PY_DEFCLASS, ln)) {
      out[[length(out) + 1]] <- list(line = i, text = trimws(ln))
      next
    }
    if (lang %in% c("markdown", "quarto", "rmarkdown") && grepl(PAT_MD_HEADING, ln)) {
      out[[length(out) + 1]] <- list(line = i, text = trimws(ln))
    }
  }
  out
}

# ---- dependency extraction ---------------------------------------------------

# One capturing group each. Extract with gregexpr()+regmatches() (not regexpr(), which
# only returns the first match per line and silently undercounts a line with several
# calls on it) then re-apply the pattern to each isolated match with sub() to pull out
# just the group -- so DEPENDS.tsv's target column holds a clean path/name, not
# "source(\"x.R\"" fragments. See references/language-rules.md.
extract_mode <- function(lines, pattern, mode) {
  hits <- regmatches(lines, gregexpr(pattern, lines, perl = TRUE))
  rows <- list()
  for (i in seq_along(lines)) {
    for (m in hits[[i]]) {
      cap <- sub(pattern, "\\1", m, perl = TRUE)
      rows[[length(rows) + 1]] <- list(line = i, raw = trimws(m), capture = cap, mode = mode)
    }
  }
  rows
}

PAT_R_SOURCE  <- "source\\(\\s*[\"']([^\"']+)[\"']"
PAT_R_HERE    <- "\\bhere::here\\(([^)]*)\\)"
PAT_R_LIBRARY <- "\\b(?:library|require)\\(\\s*[\"']?([A-Za-z0-9._]+)[\"']?\\s*\\)"
PAT_PY_IMPORT <- "^\\s*import\\s+([A-Za-z0-9_.]+)"
PAT_PY_FROM   <- "^\\s*from\\s+(\\.*[A-Za-z0-9_.]*)\\s+import"
PAT_SH_SOURCE <- "^\\s*(?:source|\\.)\\s+([^\\s;]+)"
PAT_INC_QUOTE <- "#include\\s*\"([^\"]+)\""
PAT_INC_ANGLE <- "#include\\s*<([^>]+)>"

extract_deps_raw <- function(lang, lines) {
  # Blank out pure-comment lines before matching (but keep the vector the same length,
  # so line numbers stay correct) -- otherwise a documentation example written as a
  # comment, e.g. `# source("<skill-dir>/scripts/x.R")`, is indistinguishable from a
  # real call and shows up as a spurious "unresolved" dependency row. Found while
  # testing against this repo's own `jobwatch.R`, which has exactly that kind of
  # comment. A trailing inline comment on a real code line is unaffected (the line
  # doesn't start with '#' so it isn't blanked).
  if (lang %in% c("R", "python", "shell", "quarto", "rmarkdown")) {
    lines <- ifelse(grepl("^\\s*#", lines), "", lines)
  }
  rows <- list()
  add <- function(x) rows[[length(rows) + 1]] <<- x
  run_r <- function() {
    for (r in extract_mode(lines, PAT_R_SOURCE, "r_source")) add(r)
    for (r in extract_mode(lines, PAT_R_HERE, "r_here")) add(r)
    for (r in extract_mode(lines, PAT_R_LIBRARY, "package")) add(r)
  }
  run_py <- function() {
    for (r in extract_mode(lines, PAT_PY_IMPORT, "py_import")) add(r)
    for (r in extract_mode(lines, PAT_PY_FROM, "py_import")) add(r)
  }
  run_sh <- function() {
    for (r in extract_mode(lines, PAT_SH_SOURCE, "sh_source")) add(r)
  }
  # Quarto/R Markdown can embed a chunk of any engine; there's no cheap way to know
  # which without parsing fence headers, so run every language's patterns over the
  # whole file (deliberate, documented trade-off -- see references/language-rules.md).
  if (lang == "R") run_r()
  if (lang == "python") run_py()
  if (lang == "shell") run_sh()
  if (lang %in% c("quarto", "rmarkdown")) { run_r(); run_py(); run_sh() }
  if (lang != "markdown") {
    for (r in extract_mode(lines, PAT_INC_QUOTE, "inc_quote")) add(r)
    for (r in extract_mode(lines, PAT_INC_ANGLE, "package")) add(r)
  }
  rows
}

# ---- resolution / classification ---------------------------------------------

resolve_under_root <- function(abspath, root) {
  ap <- norm_slashes(abspath)
  if (startsWith(ap, paste0(root, "/"))) {
    list(kind = "file-internal", target = sub(paste0(root, "/"), "", ap, fixed = TRUE))
  } else {
    list(kind = "file-external", target = ap)
  }
}

try_resolve_path <- function(file_abs, root, raw) {
  raw <- trimws(raw)
  if (!nzchar(raw)) return(list(kind = "unresolved", target = raw))
  candidates <- c(file.path(dirname(file_abs), raw), file.path(root, raw))
  if (grepl("^([A-Za-z]:)?/", raw)) candidates <- c(raw, candidates)
  for (cand in candidates) {
    p <- tryCatch(norm_slashes(normalizePath(cand, mustWork = FALSE)), error = function(e) NA)
    if (!is.na(p) && file.exists(p)) return(resolve_under_root(p, root))
  }
  list(kind = "unresolved", target = raw)
}

classify_dep <- function(file_abs, root, row) {
  switch(row$mode,
    package  = list(kind = "package", target = row$capture),
    r_source = try_resolve_path(file_abs, root, row$capture),
    sh_source = try_resolve_path(file_abs, root, row$capture),
    inc_quote = try_resolve_path(file_abs, root, row$capture),
    r_here = {
      args <- strsplit(gsub("[\"']", "", row$capture), ",")[[1]]
      args <- trimws(args)
      args <- args[nzchar(args)]
      if (!length(args)) return(list(kind = "unresolved", target = row$capture))
      p <- tryCatch(norm_slashes(normalizePath(do.call(file.path, c(list(root), as.list(args))),
                                                mustWork = FALSE)), error = function(e) NA)
      if (!is.na(p) && file.exists(p)) resolve_under_root(p, root)
      else list(kind = "unresolved", target = row$capture)
    },
    py_import = {
      mod <- row$capture
      if (!nzchar(mod)) return(list(kind = "unresolved", target = row$capture))
      first_seg <- strsplit(sub("^\\.+", "", mod), "\\.")[[1]][1]
      if (!nzchar(first_seg)) return(list(kind = "unresolved", target = row$capture))
      rel_py <- paste0(first_seg, ".py")
      candidates <- c(file.path(dirname(file_abs), rel_py), file.path(root, rel_py),
                       file.path(dirname(file_abs), first_seg), file.path(root, first_seg))
      for (cand in candidates) {
        p <- tryCatch(norm_slashes(normalizePath(cand, mustWork = FALSE)), error = function(e) NA)
        if (!is.na(p) && file.exists(p)) return(resolve_under_root(p, root))
      }
      list(kind = "package", target = first_seg)
    },
    list(kind = "unresolved", target = row$capture)
  )
}

# ---- artifact writers ---------------------------------------------------

write_inventory <- function(root, inv, out_path) {
  ts <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
  lines <- c(sprintf("# Codebase inventory - %s", basename(root)), "",
             sprintf("Generated %s by the `codebase-map` skill. %d files, %d lines scanned.",
                      ts, nrow(inv), sum(inv$lines)),
             "Regenerate: keep editing the project -- it updates itself via a hook.", "")
  inv$dir <- ifelse(dirname(inv$path) == ".", "(root)", dirname(inv$path))
  for (d in unique(inv$dir)) {
    sub_df <- inv[inv$dir == d, , drop = FALSE]
    sub_df <- sub_df[order(-sub_df$lines), ]
    lines <- c(lines, sprintf("## %s/", d), "",
               "| File | Language | Lines | Description |", "|---|---|---|---|")
    for (i in seq_len(nrow(sub_df))) {
      r <- sub_df[i, ]
      lines <- c(lines, sprintf("| %s | %s | %d | %s |", r$path, r$lang, r$lines,
                                 gsub("\\|", "\\\\|", r$first_heading)))
    }
    lines <- c(lines, "")
  }
  writeLines(lines, out_path)
}

write_codemap <- function(ledger, out_path) {
  writeLines(ledger, out_path)
}

write_depends <- function(deps, out_path) {
  if (!nrow(deps)) {
    writeLines("file\tkind\ttarget\traw", out_path)
    return(invisible())
  }
  deps <- deps[order(deps$file, deps$target), ]
  write.table(deps, out_path, sep = "\t", quote = FALSE, row.names = FALSE)
}

# ---- .gitignore -----------------------------------------------------------

ensure_gitignored <- function(root) {
  if (!dir.exists(file.path(root, ".git"))) return(invisible(FALSE))
  gi <- file.path(root, ".gitignore")
  existing <- if (file.exists(gi)) readLines(gi, warn = FALSE) else character(0)
  if (any(trimws(existing) == ".codemap/")) return(invisible(FALSE))
  writeLines(c(existing, "", "# codebase-map skill artifacts (auto-generated, do not commit)",
               ".codemap/"), gi)
  invisible(TRUE)
}

# ---- AGENTS.md / DATABOT.md pointer ---------------------------------------

ensure_memory_pointer <- function(root, n_files, n_lines) {
  target <- NULL
  for (cand in c("DATABOT.md", "AGENTS.md")) {
    if (file.exists(file.path(root, cand))) { target <- file.path(root, cand); break }
  }
  if (is.null(target)) target <- file.path(root, "AGENTS.md")
  ts <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
  block <- c(
    "<!-- codemap:start -->",
    "## Codebase map (auto-generated by the `codebase-map` skill -- do not hand-edit)",
    "",
    sprintf("This project has machine-generated navigation aids in `.codemap/`, refreshed automatically as files change (%d files, %d lines as of %s):",
            n_files, n_lines, ts),
    "",
    "- `.codemap/INVENTORY.md` -- every scanned file with language, line count and a one-line description. Start here for an overview.",
    "- `.codemap/CODEMAP.md` -- a greppable heading ledger (`path:line: heading`). Grep this for a keyword before reading a long file in full.",
    "- `.codemap/DEPENDS.tsv` -- file-to-file and file-to-package dependency edges (`file-internal`, `file-external`, `package`, `unresolved`). Check this before editing a file other files may depend on.",
    "<!-- codemap:end -->"
  )
  existing <- if (file.exists(target)) readLines(target, warn = FALSE) else character(0)
  start_i <- which(trimws(existing) == "<!-- codemap:start -->")
  end_i   <- which(trimws(existing) == "<!-- codemap:end -->")
  if (length(start_i) == 1 && length(end_i) == 1 && end_i > start_i) {
    new_content <- c(existing[seq_len(start_i - 1)], block,
                      if (end_i < length(existing)) existing[(end_i + 1):length(existing)] else character(0))
  } else {
    new_content <- c(existing, if (length(existing)) "" else NULL, block)
  }
  writeLines(new_content, target)
  invisible(target)
}

# ---- state ------------------------------------------------------------

write_state <- function(root, n_files, max_lines, total_lines, qualifies, first_build) {
  state_path <- file.path(root, ".codemap", ".state.json")
  ts <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
  json <- sprintf(
    '{"last_build": "%s", "file_count": %d, "total_lines": %d, "max_lines": %d, "qualifies": %s, "first_build": %s}',
    ts, n_files, total_lines, max_lines, tolower(qualifies), tolower(first_build))
  writeLines(json, state_path)
}

# ---- orchestrator ---------------------------------------------------------

#' @param root project directory (or any directory inside it -- the .Rproj is located
#'   automatically). Falls back to `root` itself if no .Rproj is found (useful for
#'   testing on a non-RStudio folder), but the skill's intended scope is RStudio
#'   projects (see references/).
#' @param file_count_threshold,max_lines_threshold self-trigger thresholds (see
#'   references/triggering-and-updating.md).
build_codemap <- function(root = ".", file_count_threshold = 15, max_lines_threshold = 300,
                           quiet = FALSE) {
  found_root <- find_project_root(root)
  root <- if (!is.null(found_root)) found_root else norm_slashes(normalizePath(root, mustWork = FALSE))

  # Opt-out: a project that doesn't want this (e.g. one that already has its own
  # elaborate hand-maintained AGENTS.md and doesn't want it auto-edited -- see
  # references/triggering-and-updating.md) can drop an empty `.codemapignore` file at
  # its root. Checked here too, not just in the hook, so a direct call behaves the same
  # way as the hook-triggered one.
  if (file.exists(file.path(root, ".codemapignore"))) {
    if (!quiet) cat("codebase-map: .codemapignore present, skipping", root, "\n")
    cat("CODEMAP_QUALIFIES=0\nCODEMAP_FIRST_BUILD=0\n")
    return(invisible(list(root = root, skipped = TRUE)))
  }

  files <- scan_files(root)
  inv_rows <- list()
  ledger <- character(0)
  dep_rows <- list()

  for (f in files) {
    lang <- lang_of(f)
    txt <- tryCatch(readLines(f, warn = FALSE, encoding = "UTF-8"), error = function(e) character(0))
    n <- length(txt)
    rel_path <- sub(root, "", f, fixed = TRUE); rel_path <- sub("^/", "", rel_path)

    heads <- extract_headings(lang, txt)
    first_head <- if (length(heads)) heads[[1]]$text else ""
    inv_rows[[length(inv_rows) + 1]] <- data.frame(
      path = rel_path, lang = lang, lines = n, first_heading = first_head,
      stringsAsFactors = FALSE)
    for (h in heads) ledger <- c(ledger, sprintf("%s:%d: %s", rel_path, h$line, h$text))

    for (row in extract_deps_raw(lang, txt)) {
      cls <- classify_dep(f, root, row)
      dep_rows[[length(dep_rows) + 1]] <- data.frame(
        file = rel_path, kind = cls$kind, target = cls$target, raw = row$raw,
        stringsAsFactors = FALSE)
    }
  }

  inv <- if (length(inv_rows)) do.call(rbind, inv_rows) else
    data.frame(path = character(), lang = character(), lines = integer(),
               first_heading = character(), stringsAsFactors = FALSE)
  deps <- if (length(dep_rows)) do.call(rbind, dep_rows) else
    data.frame(file = character(), kind = character(), target = character(),
               raw = character(), stringsAsFactors = FALSE)

  n_files <- nrow(inv)
  max_lines <- if (n_files) max(inv$lines) else 0L
  total_lines <- sum(inv$lines)
  qualifies <- n_files > file_count_threshold || max_lines > max_lines_threshold

  # Self-triggering means the artifacts should not appear at all until the project
  # earns them. But once `.codemap/` exists (the project qualified at some earlier
  # build), keep refreshing it even if a later build dips back under threshold --
  # flapping the directory in and out of existence as files come and go is worse than
  # a stale-but-harmless map (documented trade-off, see references/).
  already_exists <- dir.exists(file.path(root, ".codemap"))
  first_build <- qualifies && !already_exists
  should_write <- qualifies || already_exists

  if (should_write) {
    dir.create(file.path(root, ".codemap"), showWarnings = FALSE)
    write_inventory(root, inv, file.path(root, ".codemap", "INVENTORY.md"))
    write_codemap(ledger, file.path(root, ".codemap", "CODEMAP.md"))
    write_depends(deps, file.path(root, ".codemap", "DEPENDS.tsv"))
    ensure_gitignored(root)
    ensure_memory_pointer(root, n_files, total_lines)
    write_state(root, n_files, max_lines, total_lines, qualifies, first_build)
  }

  if (!quiet) {
    cat(sprintf("codebase-map: %d files, %d lines, %d headings, %d dependency rows%s\n",
                n_files, total_lines, length(ledger), nrow(deps),
                if (should_write) sprintf(" -> %s/.codemap", root) else " (below threshold, no artifacts written)"))
  }
  # Machine-readable markers for the calling hook script (grep these from stdout).
  cat(sprintf("CODEMAP_QUALIFIES=%s\n", if (qualifies) "1" else "0"))
  cat(sprintf("CODEMAP_FIRST_BUILD=%s\n", if (first_build) "1" else "0"))

  invisible(list(root = root, n_files = n_files, total_lines = total_lines,
                 qualifies = qualifies, first_build = first_build,
                 inventory = inv, depends = deps))
}

if (!interactive() && sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  build_codemap(if (length(args)) args[1] else ".")
}
