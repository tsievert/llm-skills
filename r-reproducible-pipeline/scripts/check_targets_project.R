#!/usr/bin/env Rscript
# Static checker for a targets + renv (+ Quarto, + uv Python steps) project.
#
# Usage in an R session:   source("<skill-dir>/scripts/check_targets_project.R"); check_targets_project(".")
# Usage from a shell:      Rscript <skill-dir>/scripts/check_targets_project.R [project-dir]
#
# It reads files only. It does not run the pipeline, contact a cluster or install anything,
# so it cannot see behaviour at run time (what targets actually reruns, what a cluster accepts).
# Needs base R plus the CRAN packages yaml (optional) and jsonlite. Exit status 1 if any ERROR.

check_targets_project <- function(path = ".", quiet = FALSE) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  findings <- list()
  add <- function(level, check, file, message) {
    findings[[length(findings) + 1L]] <<- data.frame(level = level, check = check, file = file,
                                                     message = message, stringsAsFactors = FALSE)
  }
  rel <- function(f) sub(paste0(path, "/"), "", f, fixed = TRUE)
  in_dir <- function(...) file.path(path, ...)

  skip_dirs <- "(^|/)(renv|_targets|\\.git|\\.quarto|_freeze|\\.venv|tmp-examples|node_modules)(/|$)"
  all_files <- list.files(path, recursive = TRUE, all.files = TRUE, full.names = TRUE)
  all_files <- all_files[!grepl(skip_dirs, rel(all_files))]
  r_files <- all_files[grepl("\\.[Rr]$", all_files)]
  doc_files <- all_files[grepl("\\.(qmd|Rmd|rmd)$", all_files)]
  sh_files <- all_files[grepl("\\.(sh|sbatch|slurm)$", all_files)]
  yaml_files <- all_files[grepl("\\.ya?ml$", all_files) & !grepl("(^|/)_(quarto|targets)\\.ya?ml$", rel(all_files))]
  target_script <- in_dir("_targets.R")
  read_lines <- function(f) suppressWarnings(readLines(f, warn = FALSE))
  strip_comments <- function(x) x[!grepl("^\\s*#", x)]

  # 1. Pipeline script ---------------------------------------------------------------
  if (!file.exists(target_script)) {
    add("ERROR", "target-script", "_targets.R", "No _targets.R in the project root (set tar_config_set(script=) if it lives elsewhere).")
  }

  # Walk calls in the parsed R code (comments are dropped by the parser)
  walk <- function(e, f) {
    f(e)
    if (is.call(e)) {
      parts <- as.list(e)
      for (i in seq_along(parts)) {
        if (identical(parts[[i]], quote(expr = ))) next
        walk(parts[[i]], f)
      }
    }
    invisible(NULL)
  }
  fn_name <- function(e) if (is.call(e) && (is.symbol(e[[1]]) || (is.call(e[[1]]) && identical(e[[1]][[1]], quote(`::`))))) {
    if (is.symbol(e[[1]])) as.character(e[[1]]) else as.character(e[[1]][[3]])
  } else NA_character_
  parsed <- lapply(r_files, function(f) tryCatch(parse(f, keep.source = FALSE), error = function(err) {
    add("ERROR", "parse", rel(f), paste("R file does not parse:", conditionMessage(err)))
    NULL
  }))
  names(parsed) <- r_files
  each_call <- function(f, files = r_files) for (file in files) for (ex in parsed[[file]] %||% list()) walk(ex, function(e) f(e, file))
  `%||%` <- function(a, b) if (is.null(a)) b else a

  # 2. Seeds -------------------------------------------------------------------------
  if (file.exists(target_script)) {
    seen_option_set <- FALSE; seed_arg <- NULL
    each_call(function(e, file) if (identical(fn_name(e), "tar_option_set")) {
      seen_option_set <<- TRUE
      a <- as.list(e)[-1]
      if ("seed" %in% names(a)) seed_arg <<- a[["seed"]]
    }, files = target_script)
    if (is.logical(seed_arg) && length(seed_arg) == 1L && is.na(seed_arg)) {
      add("ERROR", "seed", "_targets.R", "tar_option_set(seed = NA) turns seeding off: results are not reproducible and targets always look outdated.")
    } else if (is.null(seed_arg)) {
      add("INFO", "seed", "_targets.R", "No explicit seed in tar_option_set(); targets uses a default. Set seed = <integer> so the choice is recorded.")
    }
  }
  each_call(function(e, file) if (identical(fn_name(e), "set.seed") && !identical(file, target_script)) {
    add("INFO", "set-seed", rel(file), "set.seed() inside project code: targets already seeds each target from its name; a manual seed can hide that or repeat streams across targets.")
  })

  # 3. Hidden inputs: files read or scripts called without a file target ---------------
  read_fns <- "^(read\\.(csv|csv2|delim|table|fwf)|read_(csv|csv2|tsv|delim|excel|rds|parquet|feather|fwf|table)|readRDS|fread|load|scan|readLines|read_parquet|read_feather|read_xlsx|read_sav)$"
  each_call(function(e, file) {
    nm <- fn_name(e)
    if (!is.na(nm) && grepl(read_fns, nm) && length(e) > 1 && is.character(e[[2]]) && length(e[[2]]) == 1) {
      add("WARN", "untracked-input", rel(file), sprintf("%s(\"%s\") reads a literal path: targets cannot see it change. Make it a tar_target(..., format = \"file\") and pass the path.", nm, e[[2]]))
    }
    if (!is.na(nm) && nm %in% c("system", "system2", "run", "shell")) {
      lits <- character()
      walk(e, function(x) if (is.character(x)) lits <<- c(lits, x))
      scripts <- lits[grepl("\\.(py|R|r|sh|jl|pl)$", lits)]
      if (length(scripts)) {
        add("WARN", "untracked-script", rel(file), sprintf("%s() runs the literal script %s: edits to it are invisible to targets. Declare it as a file target and pass it as an argument.", nm, paste(unique(scripts), collapse = ", ")))
      }
    }
    if (!is.na(nm) && nm == "setwd") add("WARN", "setwd", rel(file), "setwd() in project code breaks relative paths for other targets and workers; use paths relative to the project root.")
    if (!is.na(nm) && nm %in% c("py_install", "virtualenv_create", "install_python")) add("WARN", "runtime-python-install", rel(file), sprintf("%s() installs Python at run time; declare it in a pyproject.toml with uv.lock instead.", nm))
    if (!is.na(nm) && nm %in% c("install.packages", "install_github", "pak", "install")) add("WARN", "runtime-install", rel(file), sprintf("%s() installs packages while the pipeline runs; declare them in renv.lock instead.", nm))
  })

  # 4. Text-level patterns -------------------------------------------------------------
  code_text <- unlist(lapply(c(r_files, doc_files, sh_files), function(f) {
    l <- strip_comments(read_lines(f)); if (length(l)) paste0(rel(f), "\t", l) else character()
  }))
  grep_text <- function(pattern) code_text[grepl(pattern, code_text, perl = TRUE)]
  for (l in grep_text("reporter\\s*=\\s*[\"']summary[\"']")) {
    add("WARN", "reporter", strsplit(l, "\t")[[1]][1], "reporter = \"summary\" is deprecated in targets; use \"balanced\", \"verbose\" or \"timestamp\".")
  }
  for (l in grep_text("[\"'](?:[A-Za-z]:[\\\\/]|/(?:home|Users|scratch|work|mnt|data)/)")) {
    parts <- strsplit(l, "\t")[[1]]
    if (!grepl("\\.sbatch$|\\.sh$|\\.slurm$", parts[1])) add("WARN", "absolute-path", parts[1], "Absolute path in project code; use paths relative to the project root.")
  }
  for (l in grep_text("tar_make\\([^)]*callr_function\\s*=\\s*NULL")) {
    add("INFO", "debug-run", strsplit(l, "\t")[[1]][1], "tar_make(callr_function = NULL) is for debugging only; it can corrupt results. Do not leave it in scripts.")
  }
  # Crew Slurm controllers
  slurm_files <- unique(vapply(grep_text("crew_controller_slurm"), function(l) strsplit(l, "\t")[[1]][1], ""))
  for (f in slurm_files) {
    txt <- paste(strip_comments(read_lines(in_dir(f))), collapse = "\n")
    if (!grepl("log_output", txt)) add("WARN", "crew-logs", f, "crew_options_slurm() without log_output: worker logs go to /dev/null by default.")
    if (!grepl("time_minutes", txt)) add("WARN", "crew-walltime", f, "No time_minutes in crew_options_slurm(): seconds_wall is a soft limit inside mirai, not the Slurm walltime.")
    if (grepl("<[A-Z][A-Z_]*>", txt)) add("ERROR", "placeholders", f, "<PLACEHOLDER> values left in the Slurm controller; fill them from the site documentation.")
  }
  for (f in sh_files) {
    lines <- read_lines(f)
    # #SBATCH lines are directives, not comments
    if (grepl("<[A-Z][A-Z_]*>", paste(lines[!grepl("^\\s*#", lines) | grepl("^\\s*#SBATCH", lines)], collapse = "\n"))) {
      add("ERROR", "placeholders", rel(f), "<PLACEHOLDER> values left in the job script; fill them from the site documentation.")
    }
  }

  # 5. YAML config traps (YAML 1.1 as read by R's yaml package) ------------------------
  bool_words <- "y|n|yes|no|on|off|true|false"
  for (f in yaml_files) {
    lines <- strip_comments(read_lines(f))
    key_hits <- lines[grepl(paste0("^\\s*-?\\s*(", bool_words, ")\\s*:"), lines, ignore.case = TRUE)]
    for (h in key_hits) add("ERROR", "yaml-key", rel(f), sprintf("Key '%s' is read as a logical value by R's yaml package (YAML 1.1). Rename it (e.g. n_obs) or quote it.", trimws(sub(":.*$", "", h))))
    val_hits <- lines[grepl(paste0(":\\s*(", bool_words, ")\\s*$"), lines, ignore.case = TRUE) & !grepl("^\\s*(true|false)\\s*:", lines, ignore.case = TRUE)]
    val_hits <- val_hits[!grepl(":\\s*(true|false)\\s*$", val_hits, ignore.case = TRUE)]
    for (h in val_hits) add("WARN", "yaml-value", rel(f), sprintf("Value in '%s' is read as logical (e.g. country code NO, answers y/n). Quote it if text is meant.", trimws(h)))
  }

  # 6. Version control ------------------------------------------------------------------
  in_git <- dir.exists(in_dir(".git")) || nzchar(tryCatch(system2("git", c("-C", shQuote(path), "rev-parse", "--git-dir"), stdout = TRUE, stderr = FALSE), error = function(e) "", warning = function(w) ""))
  if (in_git && nzchar(Sys.which("git"))) {
    git <- function(...) suppressWarnings(tryCatch(system2("git", c("-C", shQuote(path), ...), stdout = TRUE, stderr = FALSE), error = function(e) character()))
    tracked <- git("ls-files", "_targets")
    tracked_objs <- tracked[!grepl("^_targets/meta/", tracked)]
    if (length(tracked_objs)) add("WARN", "store-committed", "_targets/", sprintf("%d file(s) of the targets store are tracked by git (outside _targets/meta/). The store is large and regenerable; ignore it.", length(tracked_objs)))
    ignored <- system2("git", c("-C", shQuote(path), "check-ignore", "-q", "_targets/objects/x"), stdout = FALSE, stderr = FALSE)
    if (!identical(ignored, 0L) && !length(tracked)) add("WARN", "store-not-ignored", ".gitignore", "_targets/ is not git-ignored; add it (optionally keep _targets/meta/meta).")
    renv_lib_tracked <- git("ls-files", "renv/library")
    if (length(renv_lib_tracked)) add("WARN", "renv-library-committed", "renv/library", "The renv project library is tracked by git; commit renv.lock, not the library.")
  } else {
    add("INFO", "git", ".", "Not a git repository (or git not found): version-control checks skipped.")
  }

  # 7. renv -----------------------------------------------------------------------------
  lock_file <- in_dir("renv.lock")
  lock_pkgs <- NULL
  if (!file.exists(lock_file)) {
    add("WARN", "renv-lock", "renv.lock", "No renv.lock: package versions are not pinned. Run renv::init() and commit renv.lock, .Rprofile, renv/activate.R, renv/settings.json.")
  } else {
    lock <- tryCatch(jsonlite::read_json(lock_file), error = function(e) NULL)
    if (is.null(lock)) add("ERROR", "renv-lock", "renv.lock", "renv.lock is not valid JSON.") else lock_pkgs <- names(lock$Packages)
  }
  rprofile <- in_dir(".Rprofile")
  if (file.exists(lock_file)) {
    rp <- tryCatch(read_lines(rprofile), error = function(e) NULL)
    if (is.null(rp) && file.exists(rprofile)) {
      add("INFO", "renv-activate", ".Rprofile", "Could not read .Rprofile from this session; check by hand that it sources renv/activate.R.")
    } else if (!any(grepl("renv/activate.R", rp, fixed = TRUE))) {
      add("WARN", "renv-activate", ".Rprofile", "renv.lock exists but .Rprofile does not source renv/activate.R: new R sessions will not use the project library.")
    }
    if (!file.exists(in_dir("renv", "activate.R"))) add("WARN", "renv-activate", "renv/activate.R", "renv/activate.R is missing; commit it together with renv.lock.")
  }
  if (!is.null(lock_pkgs)) {
    base_pkgs <- rownames(utils::installed.packages(priority = c("base", "recommended")))
    used <- character()
    each_call(function(e, file) {
      nm <- fn_name(e)
      if (identical(nm, "library") || identical(nm, "require") || identical(nm, "requireNamespace") || identical(nm, "loadNamespace")) {
        if (length(e) > 1) { a <- e[[2]]; used <<- c(used, if (is.symbol(a)) as.character(a) else if (is.character(a)) a) }
      }
      if (is.call(e) && (identical(e[[1]], quote(`::`)) || identical(e[[1]], quote(`:::`))) && is.symbol(e[[2]])) used <<- c(used, as.character(e[[2]]))
      if (identical(nm, "tar_option_set")) {
        a <- as.list(e)[-1]
        if ("packages" %in% names(a)) walk(a[["packages"]], function(x) if (is.character(x)) used <<- c(used, x))
      }
    })
    for (f in doc_files) {
      txt <- paste(read_lines(f), collapse = "\n")
      m <- regmatches(txt, gregexpr("(?:library|require)\\(([A-Za-z][A-Za-z0-9.]*)\\)|([A-Za-z][A-Za-z0-9.]*)::", txt, perl = TRUE))[[1]]
      used <- c(used, sub("^(?:library|require)\\(([^)]*)\\)$", "\\1", sub("::$", "", m)))
    }
    if (file.exists(target_script) && any(grepl("tar_quarto|tar_render", read_lines(target_script)))) used <- c(used, "quarto")
    used <- setdiff(unique(used[nzchar(used)]), c(base_pkgs, "pkg"))
    missing_pkgs <- setdiff(used, lock_pkgs)
    if (length(missing_pkgs)) add("WARN", "renv-missing", "renv.lock", sprintf("Packages used in the project but missing from renv.lock: %s. Re-run renv::snapshot(); packages used only at run time need a library() line in _dependencies.R.", paste(sort(missing_pkgs), collapse = ", ")))
    if (!"targets" %in% lock_pkgs) add("WARN", "renv-missing", "renv.lock", "targets itself is not in renv.lock.")
  }

  # 8. Python steps through uv --------------------------------------------------------
  uses_python <- any(grepl("\\.py[\"']", code_text)) || length(grep_text("[\"']uv[\"']")) > 0 || length(grep_text("\\buv run\\b")) > 0 || dir.exists(in_dir("py"))
  if (uses_python) {
    locks <- all_files[basename(all_files) == "uv.lock"]
    pins <- all_files[basename(all_files) %in% c(".python-version", "pyproject.toml")]
    if (!length(locks)) add("WARN", "python-lock", ".", "Python steps found but no uv.lock: the Python environment is not pinned. Create it with uv lock (see python-reproducible-pipeline).")
    if (!length(pins)) add("WARN", "python-pin", ".", "Python steps found but no pyproject.toml or .python-version.")
    uv_files <- unique(vapply(grep_text("[\"']uv[\"']|\\buv run\\b"), function(l) strsplit(l, "\t")[[1]][1], ""))
    for (f in uv_files) {
      if (!any(grepl("--locked|--frozen", read_lines(in_dir(f))))) add("WARN", "uv-locked", f, "uv run without --locked: a stale lock is re-resolved silently instead of failing.")
    }
  }

  # 9. Reports -------------------------------------------------------------------------
  if (length(doc_files) && file.exists(target_script) && !any(grepl("tar_quarto|tar_render", read_lines(target_script)))) {
    add("INFO", "report", rel(doc_files[1]), "Quarto/R Markdown document found but no tar_quarto()/tar_render() in _targets.R: the report is not rebuilt when its inputs change.")
  }
  for (f in doc_files) {
    txt <- paste(read_lines(f), collapse = "\n")
    if (grepl("tar_(read|load)_raw\\(", txt)) add("INFO", "report-deps", rel(f), "tar_read_raw()/tar_load_raw() are not seen by tar_quarto()'s static dependency scan; use literal tar_read(name).")
    if (grepl("```\\{python", txt)) add("INFO", "report-python", rel(f), "Python chunk in a targets-built report: dependency detection is R-only; declare files it reads via extra_files or an R-side tar_read(). Untested in this skill.")
  }

  out <- if (length(findings)) do.call(rbind, findings) else data.frame(level = character(), check = character(), file = character(), message = character())
  out <- out[order(factor(out$level, c("ERROR", "WARN", "INFO"))), , drop = FALSE]
  rownames(out) <- NULL
  if (!quiet) {
    if (!nrow(out)) cat("No findings.\n") else for (i in seq_len(nrow(out))) cat(sprintf("%-5s [%s] %s: %s\n", out$level[i], out$check[i], out$file[i], out$message[i]))
    cat(sprintf("\n%d error(s), %d warning(s), %d info.\n", sum(out$level == "ERROR"), sum(out$level == "WARN"), sum(out$level == "INFO")))
  }
  invisible(out)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  res <- check_targets_project(if (length(args)) args[[1]] else ".")
  quit(status = if (any(res$level == "ERROR")) 1L else 0L)
}
