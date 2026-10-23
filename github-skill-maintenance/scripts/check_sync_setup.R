# Audit the auto-sync setup: global settings.json (skills.paths + SessionStart hook),
# the hook script, the throttle state file and the clone's git state.
# Read-only: it never changes settings or the repository.
#
# Usage:
#   source("github-skill-maintenance/scripts/check_sync_setup.R")
#   check_sync_setup()          # data frame of checks: ok / warn / error
#   check_sync_setup(fetch = TRUE)   # also `git fetch` to compare with origin/main
#
# Requires: jsonlite, gert (CRAN). Facts it relies on are listed in
# references/sync-and-config-facts.md (from the Posit Assistant docs).

# Posit Assistant expands "~" to the user profile. R on Windows expands it to
# Documents instead, so build the home directory explicitly.
user_home <- function() {
  h <- if (.Platform$OS.type == "windows") Sys.getenv("USERPROFILE") else Sys.getenv("HOME")
  normalizePath(h, winslash = "/", mustWork = FALSE)
}

check_sync_setup <- function(repo = NULL, fetch = FALSE,
                             settings = file.path(home, ".posit/assistant/settings.json"),
                             stamp = file.path(home, ".posit/state/llm-skills-last-check"),
                             branch = "main",
                             home = user_home(),
                             cfg = NULL) {
  stopifnot(requireNamespace("jsonlite", quietly = TRUE), requireNamespace("gert", quietly = TRUE))
  res <- data.frame(check = character(), status = character(), detail = character(), stringsAsFactors = FALSE)
  add <- function(check, status, detail) res[nrow(res) + 1, ] <<- list(check, status, detail)
  norm <- function(p) normalizePath(sub("^~", home, p), winslash = "/", mustWork = FALSE)

  if (is.null(repo)) {
    d <- norm(getwd())
    while (!dir.exists(file.path(d, ".git")) && dirname(d) != d) d <- dirname(d)
    repo <- d
  }
  repo <- norm(repo)

  # --- settings file ---
  # `cfg` (a parsed list) can be passed instead of reading the file, for tests
  # and for sessions where R may not read outside the project.
  if (is.null(cfg)) {
    if (!file.exists(settings)) {
      add("settings.json", "error", paste("Not found:", settings))
      return(res)
    }
    cfg <- tryCatch(jsonlite::fromJSON(settings, simplifyVector = FALSE), error = function(e) e)
    if (inherits(cfg, "error")) {
      add("settings.json", "error", paste("Cannot read or parse as JSON:", conditionMessage(cfg)))
      return(res)
    }
    add("settings.json", "ok", "Parses as JSON.")
  } else {
    add("settings.json", "info", "Using the cfg list supplied by the caller.")
  }

  # --- skills.paths ---
  paths <- unlist(cfg$skills$paths)
  defaults <- c("~/.agents/skills", "~/.posit/assistant/skills", ".agents/skills", ".posit/assistant/skills")
  if (is.null(paths)) {
    add("skills.paths", "warn", "Not set: the clone is not discovered unless it lives in a default skills folder.")
  } else {
    miss <- setdiff(defaults, paths)
    add("skills.paths defaults", if (length(miss)) "warn" else "ok",
        if (length(miss)) paste("Setting skills.paths replaces the defaults; missing:", paste(miss, collapse = ", "))
        else "All four default locations are repeated.")
    idx <- which(norm(paths) == repo)
    add("skills.paths clone", if (length(idx)) "ok" else "error",
        if (length(idx)) "Clone is listed." else paste("Clone not listed:", repo))
    if (length(idx) && idx != length(paths))
      add("skills.paths order", "info", "Clone is not last; later paths win on name conflicts, so a skill of the same name in a later folder shadows the repo copy.")
    # Duplicate skill names across folders
    dirs <- Filter(dir.exists, vapply(paths[!grepl("^\\.", paths)], norm, ""))
    nm <- unlist(lapply(dirs, function(p) basename(list.dirs(p, recursive = FALSE))[file.exists(file.path(list.dirs(p, recursive = FALSE), "SKILL.md"))]))
    dup <- unique(nm[duplicated(nm)])
    add("duplicate skill names", if (length(dup)) "warn" else "ok",
        if (length(dup)) paste("Same name in several folders:", paste(dup, collapse = ", ")) else "None across the configured user-level folders.")
  }

  # --- hook entry ---
  hooks <- cfg$hooks$SessionStart
  cmds <- unlist(lapply(hooks, function(g) lapply(g$hooks, function(h) h$command)))
  sync <- cmds[grepl("sync-skills", cmds)]
  if (!length(sync)) {
    add("SessionStart hook", "error", "No command containing 'sync-skills' under hooks.SessionStart.")
  } else {
    add("SessionStart hook", "ok", sync[1])
    script <- sub("^\\s*bash\\s+", "", sync[1])
    if (.Platform$OS.type == "windows")
      add("hook uses bash explicitly", if (grepl("^\\s*bash\\s", sync[1])) "ok" else "warn",
          "Shell-form hooks run under cmd.exe on Windows, so a .sh script needs an explicit `bash` prefix.")
    add("hook script exists", if (file.exists(script)) "ok" else "error", script)
    to <- unlist(lapply(hooks, function(g) lapply(g$hooks, function(h) h$timeout)))
    add("hook timeout", if (length(to) && to[[1]] <= 30) "ok" else "warn",
        if (length(to)) paste0(to[[1]], " s (docs default is 600 s for non-prompt events; a short value stops a slow fetch from delaying the session).")
        else "Not set: defaults to 600 s.")
    if (file.exists(script)) {
      b <- readBin(script, "raw", file.size(script))
      add("hook script line endings", if (as.raw(13) %in% b) "error" else "ok",
          if (as.raw(13) %in% b) "CRLF present; bash will fail." else "LF only.")
      txt <- readLines(script, warn = FALSE)
      add("hook script exits 0", if (any(grepl("exit [1-9]", txt))) "warn" else "ok",
          "Non-zero exits only log a warning, but the script is meant to fail open.")
    }
  }
  if (!is.null(cfg$useHooks) && !identical(cfg$useHooks, TRUE) && !identical(cfg$useHooks, "all"))
    add("useHooks", "warn", paste("useHooks =", jsonlite::toJSON(cfg$useHooks, auto_unbox = TRUE), "may block the hook."))
  if (nzchar(Sys.getenv("PA_DISABLE_HOOKS")))
    add("PA_DISABLE_HOOKS", "warn", "Environment kill switch is set in this R session.")

  # --- throttle stamp ---
  if (file.exists(stamp)) {
    age <- as.numeric(difftime(Sys.time(), file.mtime(stamp), units = "hours"))
    add("throttle stamp", "ok", sprintf("Last successful check %.1f h ago (hook re-checks after 24 h).", age))
    if (age > 24 * 7) add("throttle stamp age", "warn", "Over a week old: the hook may not be running (offline, or hook skipped).")
  } else {
    add("throttle stamp", "warn", paste("Missing:", stamp, "(hook never completed a check)."))
  }

  # --- git state of the clone ---
  tryCatch({
    if (fetch) gert::git_fetch(remote = "origin", repo = repo, verbose = FALSE)
    cur <- gert::git_branch(repo = repo)
    add("branch", if (identical(cur, branch)) "ok" else "warn", paste("On", cur, "(hook only syncs", branch, ")."))
    st <- gert::git_status(repo = repo)
    tracked <- st[st$status != "new", ]
    add("working tree", if (nrow(tracked)) "warn" else "ok",
        if (nrow(tracked)) paste(nrow(tracked), "tracked file(s) with uncommitted changes; the hook skips the pull.") else "No uncommitted tracked changes.")
    untracked <- st[st$status == "new", ]
    if (nrow(untracked)) add("untracked files", "info", paste(utils::head(untracked$file, 5), collapse = ", "))
    ab <- gert::git_ahead_behind(upstream = paste0("origin/", branch), repo = repo)
    add("ahead/behind origin", if (ab$ahead > 0 || ab$behind > 0) "warn" else "ok",
        sprintf("ahead %d, behind %d%s", ab$ahead, ab$behind,
                if (!fetch) " (relative to the last fetch; use fetch = TRUE for the live remote)" else ""))
  }, error = function(e) add("git", "warn", conditionMessage(e)))
  res
}
