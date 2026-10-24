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

  # --- lessons hooks (PostToolUse matcher "skill" + Stop; see the skill-lessons skill) ---
  lessons_hook_entries <- function(event) {
    out <- list()
    for (g in cfg$hooks[[event]]) for (h in g$hooks) {
      if (grepl("lessons-hook", if (is.null(h$command)) "" else h$command))
        out[[length(out) + 1]] <- list(cmd = h$command, matcher = if (is.null(g$matcher)) "" else g$matcher,
                                       timeout = h$timeout,
                                       extra = setdiff(names(h), c("type", "command", "timeout", "args")))
    }
    out
  }
  matcher_hits <- function(m, tool) {
    if (!nzchar(m) || m == "*") return(TRUE)
    if (grepl("^[A-Za-z0-9_ ,|-]*$", m)) return(tool %in% trimws(strsplit(m, "[,|]")[[1]]))
    grepl(m, tool)
  }
  post <- lessons_hook_entries("PostToolUse")
  stop_ <- lessons_hook_entries("Stop")
  add("lessons PostToolUse hook", if (length(post)) "ok" else "warn",
      if (length(post)) post[[1]]$cmd else "No lessons-hook command under hooks.PostToolUse: skill loads are not logged.")
  add("lessons Stop hook", if (length(stop_)) "ok" else "warn",
      if (length(stop_)) stop_[[1]]$cmd else "No lessons-hook command under hooks.Stop: no end-of-session reminder.")
  if (length(post)) {
    add("lessons matcher covers 'skill'", if (matcher_hits(post[[1]]$matcher, "skill")) "ok" else "error",
        paste0("matcher = '", post[[1]]$matcher, "' (the usage log needs the skill tool)."))
    if (matcher_hits(post[[1]]$matcher, "bash") || post[[1]]$matcher %in% c("", "*"))
      add("lessons matcher cost", "info", "Matcher also fires on code/shell tools: each call costs about 0.5 s on Windows (Git Bash start-up). Intended only when error counting is wanted.")
  }
  les <- c(post, stop_)
  if (length(les)) {
    cmds_l <- vapply(les, function(e) e$cmd, "")
    scripts_l <- unique(sub("^\\s*bash\\s+", "", cmds_l))
    if (length(scripts_l) > 1) add("lessons hooks share one script", "warn", paste(scripts_l, collapse = " | "))
    if (.Platform$OS.type == "windows")
      add("lessons hooks use bash explicitly", if (all(grepl("^\\s*bash\\s", cmds_l))) "ok" else "warn",
          "Shell-form hooks run under cmd.exe on Windows.")
    bad_fields <- unique(unlist(lapply(les, function(e) e$extra)))
    add("lessons hook handler fields", if (length(bad_fields)) "error" else "ok",
        if (length(bad_fields)) paste("Unsupported fields (handler is skipped):", paste(bad_fields, collapse = ", ")) else "Only type, command, timeout.")
    tos <- unlist(lapply(les, function(e) e$timeout))
    add("lessons hook timeout", if (length(tos) == length(les) && all(tos <= 30)) "ok" else "warn",
        if (length(tos)) paste(tos, collapse = ", ") else "Not set: defaults to 600 s for these events.")
    for (script in scripts_l) {
      if (!file.exists(script)) { add("lessons hook script exists", "error", script); next }
      add("lessons hook script exists", "ok", script)
      b <- readBin(script, "raw", file.size(script))
      add("lessons hook line endings", if (as.raw(13) %in% b) "error" else "ok",
          if (as.raw(13) %in% b) "CRLF present; bash will fail." else "LF only.")
      txt <- readLines(script, warn = FALSE)
      add("lessons hook exits 0", if (any(grepl("exit [1-9]", txt))) "warn" else "ok",
          "Fail open: a non-zero exit only logs a warning, but the script should never need one.")
      add("lessons hook stop-loop guard", if (any(grepl("stop_hook_active", txt))) "ok" else "error",
          "A Stop hook that blocks must check stop_hook_active or it can loop.")
      if (.Platform$OS.type == "windows" || nzchar(Sys.which("bash"))) {
        st <- suppressWarnings(system2("bash", c("-n", shQuote(script)), stdout = FALSE, stderr = FALSE))
        add("lessons hook syntax (bash -n)", if (identical(st, 0L)) "ok" else "error", script)
      }
    }
  }
  # Data folder: the assistant's R session may not read outside the project; report that
  # as info and give the shell commands instead of working around the guard.
  # --- skill-trigger hook (UserPromptSubmit + PostToolUse matcher "skill" + Stop; see
  # github-skill-maintenance/references/skill-trigger-hook.md) ---
  trigger_hook_entries <- function(event) {
    out <- list()
    for (g in cfg$hooks[[event]]) for (h in g$hooks) {
      if (grepl("skill-trigger-hook", if (is.null(h$command)) "" else h$command))
        out[[length(out) + 1]] <- list(cmd = h$command, matcher = if (is.null(g$matcher)) "" else g$matcher,
                                       timeout = h$timeout,
                                       extra = setdiff(names(h), c("type", "command", "timeout", "args")))
    }
    out
  }
  ups <- trigger_hook_entries("UserPromptSubmit")
  post_t <- trigger_hook_entries("PostToolUse")
  stop_t <- trigger_hook_entries("Stop")
  add("skill-trigger UserPromptSubmit hook", if (length(ups)) "ok" else "warn",
      if (length(ups)) ups[[1]]$cmd else "No skill-trigger-hook command under hooks.UserPromptSubmit: pending skill-trigger instructions are never recorded.")
  add("skill-trigger PostToolUse hook", if (length(post_t)) "ok" else "warn",
      if (length(post_t)) post_t[[1]]$cmd else "No skill-trigger-hook command under hooks.PostToolUse: a skill() call never clears the pending marker, so every match would be reminded.")
  add("skill-trigger Stop hook", if (length(stop_t)) "ok" else "warn",
      if (length(stop_t)) stop_t[[1]]$cmd else "No skill-trigger-hook command under hooks.Stop: a pending instruction is recorded but never enforced.")
  if (length(post_t))
    add("skill-trigger matcher covers 'skill'", if (matcher_hits(post_t[[1]]$matcher, "skill")) "ok" else "error",
        paste0("matcher = '", post_t[[1]]$matcher, "' (clearing the marker needs the skill tool)."))
  trig <- c(ups, post_t, stop_t)
  if (length(trig)) {
    cmds_t <- vapply(trig, function(e) e$cmd, "")
    scripts_t <- unique(sub("^\\s*bash\\s+", "", cmds_t))
    if (length(scripts_t) > 1) add("skill-trigger hooks share one script", "warn", paste(scripts_t, collapse = " | "))
    if (.Platform$OS.type == "windows")
      add("skill-trigger hooks use bash explicitly", if (all(grepl("^\\s*bash\\s", cmds_t))) "ok" else "warn",
          "Shell-form hooks run under cmd.exe on Windows.")
    bad_fields_t <- unique(unlist(lapply(trig, function(e) e$extra)))
    add("skill-trigger hook handler fields", if (length(bad_fields_t)) "error" else "ok",
        if (length(bad_fields_t)) paste("Unsupported fields (handler is skipped):", paste(bad_fields_t, collapse = ", ")) else "Only type, command, timeout.")
    for (script in scripts_t) {
      if (!file.exists(script)) { add("skill-trigger hook script exists", "error", script); next }
      add("skill-trigger hook script exists", "ok", script)
      b <- readBin(script, "raw", file.size(script))
      add("skill-trigger hook line endings", if (as.raw(13) %in% b) "error" else "ok",
          if (as.raw(13) %in% b) "CRLF present; bash will fail." else "LF only.")
      txt <- readLines(script, warn = FALSE)
      add("skill-trigger hook exits 0", if (any(grepl("exit [1-9]", txt))) "warn" else "ok",
          "Fail open: a non-zero exit only logs a warning, but the script should never need one.")
      add("skill-trigger hook stop-loop guard", if (any(grepl("stop_hook_active", txt))) "ok" else "error",
          "A Stop hook that blocks must check stop_hook_active or it can loop.")
      add("skill-trigger hook uses grep -P", if (any(grepl("grep .*-[a-zA-Z]*P", txt))) "info" else "ok",
          "Uses PCRE lookahead for the question-vs-instruction check; confirm `grep -P` works in the hook's actual shell if trigger detection seems to misfire.")
      if (.Platform$OS.type == "windows" || nzchar(Sys.which("bash"))) {
        st <- suppressWarnings(system2("bash", c("-n", shQuote(script)), stdout = FALSE, stderr = FALSE))
        add("skill-trigger hook syntax (bash -n)", if (identical(st, 0L)) "ok" else "error", script)
      }
    }
  }
  tdir <- file.path(home, ".posit/skill-triggers")
  seen_t <- tryCatch({
    list(reminders = if (file.exists(file.path(tdir, "reminders.tsv"))) readLines(file.path(tdir, "reminders.tsv"), warn = FALSE) else NULL,
         pending = list.files(file.path(tdir, "state"), pattern = "\\.pending$"))
  }, error = function(e) e)
  if (inherits(seen_t, "error")) {
    add("skill-trigger data", "info", paste("Not readable from this R session (path guard). Run in a shell:",
        "wc -l ~/.posit/skill-triggers/reminders.tsv; ls ~/.posit/skill-triggers/state/*.pending 2>/dev/null | wc -l"))
  } else {
    add("skill-trigger reminders log", "info", sprintf("%d block(s) issued so far; %d session(s) currently pending.",
        length(seen_t$reminders), length(seen_t$pending)))
  }

  ldir <- file.path(home, ".posit/lessons")
  seen <- tryCatch({
    list(usage = if (file.exists(file.path(ldir, "usage.tsv"))) readLines(file.path(ldir, "usage.tsv"), warn = FALSE) else NULL,
         inbox = list.files(file.path(ldir, "inbox"), pattern = "\\.md$"),
         processed = list.files(file.path(ldir, "inbox", "processed"), pattern = "\\.md$"),
         reminded = list.files(file.path(ldir, "state"), pattern = "\\.reminded$"))
  }, error = function(e) e)
  if (inherits(seen, "error")) {
    add("lessons data", "info", paste("Not readable from this R session (path guard). Run in a shell:",
        "wc -l ~/.posit/lessons/usage.tsv; ls ~/.posit/lessons/inbox | wc -l; ls ~/.posit/lessons/state/*.reminded | wc -l"))
  } else {
    n_u <- length(seen$usage)
    last <- if (n_u) strsplit(utils::tail(seen$usage, 1), "\t")[[1]][1] else NA
    add("lessons usage log", if (n_u) "ok" else "info",
        sprintf("%d skill load(s) logged; last: %s", n_u, if (is.na(last)) "none" else last))
    add("lessons inbox", "info", sprintf("%d unprocessed file(s), %d processed.", length(seen$inbox), length(seen$processed)))
    add("lessons reminders vs entries", if (length(seen$reminded) > 0 && length(seen$inbox) == 0) "warn" else "info",
        sprintf("%d session(s) reminded, %d inbox file(s). Many reminders and no entries means the reminder is not followed, or nothing went wrong; read the reminded sessions to tell which.",
                length(seen$reminded), length(seen$inbox)))
  }

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
