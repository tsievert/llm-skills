# Read-only audit of a Git repository that holds a research project.
# Source this file, then run audit_repo("."). Nothing is changed, committed or sent anywhere.
# Needs: git on PATH. Optional: cffr + jsonvalidate (release_check, write_citation_cff).
# Every check is a heuristic: it looks at names, sizes and text patterns, not at meaning.

.git <- function(path, args) {
  out <- suppressWarnings(system2(
    "git", c("-C", shQuote(path), "-c", "core.quotepath=false", args),
    stdout = TRUE, stderr = TRUE
  ))
  status <- attr(out, "status")
  list(out = as.character(out), status = if (is.null(status)) 0L else status)
}

.finding <- function(check, level, item, message) {
  data.frame(check = check, level = level, item = item, message = message,
             stringsAsFactors = FALSE)
}

# Files that the pipeline and deposit skills require to be tracked.
.must_track <- c("renv.lock", "uv.lock", "_targets.R", "Snakefile", "CITATION.cff",
                 "README.md", "LICENSE", "LICENSE.md", "pyproject.toml", ".gitattributes")

.secret_names <- "(^|/)(\\.env|\\.Renviron|\\.netrc|\\.pgpass|id_rsa|id_ed25519|credentials(\\.json)?|secrets?\\.(ya?ml|json|toml))$|\\.(pem|key|p12|pfx|kdbx)$"

# Patterns for secret-looking text. Zenodo and Figshare tokens have no fixed prefix,
# so they are only caught by the assignment pattern. The value is never printed.
.secret_patterns <- c(
  `GitHub token`         = "gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}",
  `AWS access key id`    = "AKIA[0-9A-Z]{16}",
  `private key block`    = "-----BEGIN [A-Z ]*PRIVATE KEY-----",
  `token/key assignment` = "(?i)(api[_-]?key|token|secret|passw(or)?d)[\"']?\\s*(<-|=|:)\\s*[\"'][A-Za-z0-9_\\-\\.]{16,}[\"']"
)

.binary_ext <- "\\.(png|jpe?g|gif|tiff?|pdf|zip|gz|tgz|bz2|xz|7z|rds|rda|rdata|qs2?|h5|hdf5|parquet|feather|xlsx?|docx?|pptx?|mp4|avi|mov|npy|npz|pkl|sqlite|db|so|dll|exe)$"

# --- Checks ---------------------------------------------------------------------------

.check_files <- function(path, large_mb) {
  f <- list()
  tracked <- .git(path, c("ls-files"))$out
  untracked <- .git(path, c("ls-files", "--others", "--exclude-standard"))$out
  size_of <- function(x) file.size(file.path(path, x))

  for (set in list(list(tracked, "tracked"), list(untracked, "untracked, not ignored"))) {
    files <- set[[1]]
    if (!length(files)) next
    sz <- size_of(files) / 1024^2
    for (i in which(!is.na(sz) & sz >= large_mb)) {
      lvl <- if (sz[i] >= 100) "error" else "warning"
      f[[length(f) + 1]] <- .finding(
        "large-file", lvl, files[i],
        sprintf("%.0f MiB, %s. GitHub warns at 50 MiB and blocks at 100 MiB; per the repo rule, large data stay on the server and are deposited, not committed.",
                sz[i], set[[2]]))
    }
  }

  bad <- "(^|/)(\\.RData|\\.Rhistory|\\.Ruserdata|\\.Rproj\\.user/|\\.venv/|__pycache__/|_targets/objects/|\\.DS_Store|Thumbs\\.db)"
  for (x in tracked[grepl(bad, tracked)]) {
    f[[length(f) + 1]] <- .finding("tracked-junk", "warning", x,
      "Session, cache or regenerable file is tracked. Add it to .gitignore and run `git rm --cached` (ignoring is not retroactive).")
  }
  office <- tracked[grepl("\\.(xlsx?|docx?|pptx?)$", tracked, ignore.case = TRUE)]
  for (x in office) {
    f[[length(f) + 1]] <- .finding("binary-office", "info", x,
      "Office file is tracked: diffs are unreadable. Prefer CSV for data; keep manuscripts as text (Quarto).")
  }
  rdata <- tracked[grepl("\\.(rds|rda|rdata)$", tracked, ignore.case = TRUE)]
  for (x in rdata) {
    f[[length(f) + 1]] <- .finding("binary-r-data", "info", x,
      "Binary R data tracked. Fine if small and a deliberate input; regenerable objects belong in the pipeline store, not Git.")
  }
  if (length(f)) do.call(rbind, f) else NULL
}

.check_ignore_rules <- function(path) {
  f <- list()
  gi <- file.path(path, ".gitignore")
  if (!file.exists(gi)) {
    return(.finding("gitignore", "warning", ".gitignore", "No .gitignore at the repository root."))
  }
  lines <- trimws(readLines(gi, warn = FALSE))
  rules <- lines[nzchar(lines) & !startsWith(lines, "#")]

  # Required files that an ignore rule hides (the `*.lock` incident class).
  ig <- .git(path, c("ls-files", "--others", "--ignored", "--exclude-standard", "--directory"))$out
  hit <- ig[basename(sub("/$", "", ig)) %in% .must_track & !grepl("/$", ig)]
  for (x in hit) {
    rule <- .git(path, c("check-ignore", "-v", "--no-index", shQuote(x)))$out
    f[[length(f) + 1]] <- .finding("required-file-ignored", "error", x,
      paste0("File that the project needs tracked is ignored by: ", paste(rule, collapse = " "),
             ". Add a negation after the rule, e.g. `!", basename(x), "`."))
  }

  # Negation under an excluded parent has no effect (git docs, tested).
  for (i in seq_along(rules)) {
    if (!startsWith(rules[i], "!")) next
    target <- sub("^/", "", sub("^!", "", rules[i]))
    parts <- strsplit(target, "/", fixed = TRUE)[[1]]
    if (length(parts) < 2) next
    parents <- vapply(seq_len(length(parts) - 1), function(k) paste(parts[1:k], collapse = "/"), "")
    earlier <- sub("^/", "", sub("/$", "", rules[seq_len(i - 1)]))
    earlier <- earlier[!startsWith(rules[seq_len(i - 1)], "!")]
    if (any(parents %in% earlier)) {
      f[[length(f) + 1]] <- .finding("negation-under-excluded-parent", "warning", rules[i],
        "A parent directory is excluded by an earlier rule, so this `!` has no effect. Write `dir/*` instead of `dir/`.")
    }
  }

  # Generic lock rule without negations for the pipeline lockfiles.
  if (any(rules %in% c("*.lock", "*lock")) &&
      !all(c("!renv.lock", "!uv.lock") %in% rules)) {
    f[[length(f) + 1]] <- .finding("lock-rule", "info", "*.lock",
      "`*.lock` also matches renv.lock and uv.lock. Add `!renv.lock` and `!uv.lock` if the project uses them.")
  }
  if (length(f)) do.call(rbind, f) else NULL
}

.check_eol <- function(path) {
  f <- list()
  out <- .git(path, "ls-files --eol")$out
  m <- regmatches(out, regexec("^i/(\\S+)\\s+w/(\\S+)\\s+attr/(.*?)\\s*\\t(.*)$", out))
  m <- m[lengths(m) == 5]
  if (!length(m)) return(NULL)
  d <- data.frame(i = vapply(m, `[`, "", 2), w = vapply(m, `[`, "", 3),
                  attr = vapply(m, `[`, "", 4), path = vapply(m, `[`, "", 5))
  for (x in d$path[d$i %in% c("crlf", "mixed")]) {
    f[[length(f) + 1]] <- .finding("eol-index", "warning", x,
      "Committed with CRLF or mixed line endings. Scripts that run on Linux break. Add a .gitattributes rule and `git add --renormalize .`.")
  }
  has_attr <- file.exists(file.path(path, ".gitattributes"))
  crlf_wt <- sum(d$w %in% c("crlf", "mixed") & d$attr == "")
  if (crlf_wt > 0 && has_attr) {
    f[[length(f) + 1]] <- .finding("eol-working-tree", "info", "(working tree)",
      sprintf("%d tracked file(s) have CRLF in the working tree and no attribute. Harmless for the index; matters if a script is copied from the working tree to Linux.", crlf_wt))
  }
  if (length(f)) do.call(rbind, f) else NULL
}

.check_secrets <- function(path, history) {
  f <- list()
  files <- unique(c(.git(path, "ls-files")$out,
                    .git(path, c("ls-files", "--others", "--exclude-standard"))$out))
  tracked <- .git(path, "ls-files")$out
  for (x in files[grepl(.secret_names, files, ignore.case = TRUE)]) {
    where <- if (x %in% tracked) "tracked" else "untracked and not ignored (would be committed by `git add .`)"
    f[[length(f) + 1]] <- .finding("secret-filename", "error", x,
      paste0("Name looks like a credential file; ", where,
             ". Rotate the credential if it was ever pushed, then ignore the file."))
  }
  scan <- files[!grepl(.binary_ext, files, ignore.case = TRUE)]
  scan <- scan[!is.na(file.size(file.path(path, scan))) & file.size(file.path(path, scan)) < 1024^2]
  for (x in scan) {
    txt <- tryCatch(readLines(file.path(path, x), warn = FALSE, encoding = "bytes"),
                    error = function(e) character(), warning = function(w) character())
    for (nm in names(.secret_patterns)) {
      ln <- which(grepl(.secret_patterns[[nm]], txt, perl = TRUE, useBytes = TRUE))
      for (l in utils::head(ln, 3)) {
        f[[length(f) + 1]] <- .finding("secret-content", "error", sprintf("%s:%d", x, l),
          paste0("Matches the pattern '", nm, "' (value not shown). Check by eye; if real, rotate it first, then remove it. A literal token typed into R code also lands in the console history."))
      }
    }
  }
  if (history) {
    h <- .git(path, c("log", "--all", "--diff-filter=A", "--name-only", "--pretty=format:"))$out
    h <- unique(h[nzchar(h)])
    for (x in h[grepl(.secret_names, h, ignore.case = TRUE)]) {
      f[[length(f) + 1]] <- .finding("secret-in-history", "error", x,
        "A file with a credential-like name was added in some commit. Deleting it now does not remove it from history; see references/secrets-and-history.md.")
    }
  }
  if (length(f)) do.call(rbind, f) else NULL
}

.check_sync <- function(path) {
  p <- normalizePath(path, winslash = "/", mustWork = TRUE)
  dirs <- character()
  cur <- p
  repeat {
    dirs <- c(dirs, cur)
    up <- dirname(cur)
    if (identical(up, cur)) break
    cur <- up
  }
  markers <- c(".stfolder", ".dropbox", ".dropbox.cache")
  f <- list()
  for (d in dirs) {
    for (mk in markers) {
      if (file.exists(file.path(d, mk))) {
        tool <- if (mk == ".stfolder") "Syncthing" else "Dropbox"
        extra <- ""
        if (tool == "Syncthing") {
          st <- file.path(d, ".stignore")
          ign <- if (file.exists(st)) paste(readLines(st, warn = FALSE), collapse = "\n") else ""
          extra <- if (!nzchar(ign)) " There is no .stignore at the folder root."
                   else if (!grepl("\\.git", ign)) " .stignore does not mention .git."
                   else ""
        }
        f[[length(f) + 1]] <- .finding("sync-folder", "warning", d,
          paste0("The repository sits inside a ", tool, " folder (marker ", mk, ").", extra,
                 " File-by-file sync of .git from two devices can corrupt a repository; edit on one device, or ignore .git and use push/pull. See references/windows-and-sync.md."))
        break
      }
    }
  }
  if (grepl("(OneDrive|Dropbox|Google ?Drive|iCloud|Mobile Documents|Nextcloud|Seafile)", p, ignore.case = TRUE) && !length(f)) {
    f[[length(f) + 1]] <- .finding("sync-folder", "warning", p,
      "The path looks like a cloud-sync folder. See references/windows-and-sync.md.")
  }
  if (length(f)) do.call(rbind, f) else NULL
}

# --- Entry point ----------------------------------------------------------------------

#' Audit a repository. Returns a data frame (check, level, item, message); empty = no findings.
#' @param path repository root (or any folder inside it)
#' @param large_mb size threshold for the large-file check
#' @param history also scan the file names ever added in any commit (can be slow on big repos)
audit_repo <- function(path = ".", large_mb = 50, history = TRUE) {
  top <- .git(path, "rev-parse --show-toplevel")
  if (top$status != 0) stop("Not inside a Git repository: ", path, call. = FALSE)
  path <- top$out[1]
  res <- list(
    if (!file.exists(file.path(path, ".gitattributes")))
      .finding("gitattributes", "info", ".gitattributes",
               "No .gitattributes: line endings depend on each machine's core.autocrlf (Git for Windows sets it to true system-wide). Pin them for scripts, e.g. `*.sh text eol=lf`."),
    if (!length(.git(path, "remote")$out))
      .finding("remote", "info", "origin", "No remote configured: the repository exists only on this machine (Git is not a backup)."),
    .check_ignore_rules(path),
    .check_files(path, large_mb),
    .check_eol(path),
    .check_secrets(path, history),
    .check_sync(path)
  )
  res <- do.call(rbind, Filter(Negate(is.null), res))
  if (is.null(res)) {
    return(data.frame(check = character(), level = character(), item = character(),
                      message = character(), stringsAsFactors = FALSE))
  }
  res$level <- factor(res$level, c("error", "warning", "info"))
  res <- res[order(res$level, res$check), ]
  res$level <- as.character(res$level)
  rownames(res) <- NULL
  res
}

# --- Data manifest --------------------------------------------------------------------

.sha256 <- function(files) {
  if (exists("sha256sum", asNamespace("tools"))) {
    unname(tools::sha256sum(files))
  } else {
    vapply(files, function(x) digest::digest(x, algo = "sha256", file = TRUE), "", USE.NAMES = FALSE)
  }
}

#' Write a manifest (path, bytes, sha256) of a data folder. Modification times are left out on
#' purpose: they change on every copy and would make the file differ without the data differing.
#' @param dir folder holding the data (for example a mapped server folder)
#' @param out manifest path, tab-separated; keep it in Git, keep the data out
data_manifest <- function(dir, out = "data-manifest.tsv") {
  files <- sort(list.files(dir, recursive = TRUE, all.files = TRUE, no.. = TRUE), method = "radix")
  files <- files[!dir.exists(file.path(dir, files))]
  outn <- normalizePath(out, winslash = "/", mustWork = FALSE)
  files <- files[normalizePath(file.path(dir, files), winslash = "/", mustWork = FALSE) != outn]
  if (any(grepl("[\t\n]", files))) stop("A file name contains a tab or newline; rename it first.", call. = FALSE)
  full <- file.path(dir, files)
  m <- data.frame(path = files, bytes = file.size(full), sha256 = .sha256(full),
                  stringsAsFactors = FALSE)
  utils::write.table(m, out, sep = "\t", quote = FALSE, row.names = FALSE)
  invisible(m)
}

#' Compare a folder with a manifest. Status: ok, changed, missing (in manifest only), extra (in folder only).
verify_manifest <- function(dir, manifest = "data-manifest.tsv") {
  m <- utils::read.delim(manifest, quote = "", colClasses = "character", check.names = FALSE)
  now <- sort(list.files(dir, recursive = TRUE, all.files = TRUE, no.. = TRUE), method = "radix")
  now <- now[!dir.exists(file.path(dir, now))]
  now <- setdiff(now, basename(manifest))
  res <- data.frame(path = union(m$path, now), stringsAsFactors = FALSE)
  res$status <- vapply(res$path, function(p) {
    inm <- p %in% m$path
    inf <- p %in% now
    if (inm && !inf) return("missing")
    if (!inm && inf) return("extra")
    same <- identical(.sha256(file.path(dir, p)), m$sha256[match(p, m$path)])
    if (same) "ok" else "changed"
  }, "")
  res[order(res$status != "ok", res$path), ]
}

# --- Release helpers ------------------------------------------------------------------

#' Pre-release checks for a tagged release (read-only). Returns a data frame like audit_repo().
#' @param tag expected tag name; if NULL the tag exactly at HEAD is used, if any
release_check <- function(path = ".", tag = NULL) {
  top <- .git(path, "rev-parse --show-toplevel")
  if (top$status != 0) stop("Not inside a Git repository: ", path, call. = FALSE)
  path <- top$out[1]
  f <- list()
  add <- function(level, item, msg) f[[length(f) + 1]] <<- .finding("release", level, item, msg)

  if (length(.git(path, "status --porcelain")$out))
    add("error", "working tree", "Uncommitted or untracked changes: the release would not contain them.")
  up <- .git(path, "rev-list --count @{u}..HEAD")
  if (up$status != 0) add("warning", "upstream", "No upstream branch: nothing has been pushed.")
  else if (as.integer(up$out[1]) > 0) add("error", "upstream", sprintf("%s commit(s) not pushed.", up$out[1]))
  at <- .git(path, "tag --points-at HEAD")$out
  at <- at[nzchar(at)]
  if (is.null(tag)) tag <- if (length(at)) at[1] else NA_character_
  if (is.na(tag)) add("error", "tag", "No tag at HEAD. Tag the release commit (annotated: `git tag -a v1.0.0 -m ...`).")
  else if (!tag %in% at) add("error", "tag", sprintf("Tag '%s' does not point at HEAD.", tag))

  for (fl in c("LICENSE", "LICENSE.md", "README.md")) {
    # LICENSE and LICENSE.md are alternatives
    if (fl == "LICENSE.md") next
    ok <- if (fl == "LICENSE") any(file.exists(file.path(path, c("LICENSE", "LICENSE.md", "LICENSE.txt")))) else file.exists(file.path(path, fl))
    if (!ok) add("warning", fl, "Missing; Zenodo and GitHub show it, repositories ask for a licence.")
  }
  cff <- file.path(path, "CITATION.cff")
  zj <- file.path(path, ".zenodo.json")
  if (file.exists(zj) && file.exists(cff))
    add("warning", ".zenodo.json", "Both exist: Zenodo uses only .zenodo.json and ignores CITATION.cff.")
  if (file.exists(cff)) {
    if (requireNamespace("cffr", quietly = TRUE) && requireNamespace("jsonvalidate", quietly = TRUE)) {
      v <- suppressMessages(cffr::cff_validate(cff, verbose = FALSE))
      if (!isTRUE(v)) add("error", "CITATION.cff", "Fails validation against the CFF schema (see write_citation_cff() for how to print the errors).")
      y <- tryCatch(yaml::read_yaml(cff), error = function(e) NULL)
      if (!is.null(y)) {
        ver <- y[["version"]]
        if (!is.na(tag) && !is.null(ver) && !identical(sub("^v", "", tag), as.character(ver)))
          add("warning", "CITATION.cff", sprintf("version '%s' differs from tag '%s'.", ver, tag))
        dr <- y[["date-released"]]
        if (!is.null(dr) && !grepl("^\\d{4}-\\d{2}-\\d{2}$", as.character(dr)))
          add("error", "CITATION.cff", "date-released is not YYYY-MM-DD.")
      }
    } else add("info", "CITATION.cff", "cffr/jsonvalidate not installed: file not validated.")
  } else if (!file.exists(zj)) add("info", "CITATION.cff", "No CITATION.cff or .zenodo.json: GitHub and Zenodo get no citation metadata.")
  if (!length(f)) return(data.frame(check = character(), level = character(), item = character(), message = character()))
  do.call(rbind, f)
}

#' Write and validate a CITATION.cff with cffr (works for non-package projects).
#' @param authors one string per person: "Given Family <mail> (ORCID: <https://orcid.org/xxxx-xxxx-xxxx-xxxx>)"; a bare "(https://orcid.org/...)" drops the ORCID silently
#' @param license an SPDX identifier, e.g. "MIT", "CC-BY-4.0", "CC0-1.0"
write_citation_cff <- function(path = "CITATION.cff", title, authors, version, date_released,
                               license, type = "software", doi = NULL, repository_code = NULL,
                               abstract = NULL, keywords = NULL) {
  if (!requireNamespace("cffr", quietly = TRUE) || !requireNamespace("jsonvalidate", quietly = TRUE))
    stop("Install cffr and jsonvalidate from CRAN first.", call. = FALSE)
  if (!grepl("^\\d{4}-\\d{2}-\\d{2}$", date_released)) stop("date_released must be YYYY-MM-DD.", call. = FALSE)
  args <- list(cff_version = "1.2.0", message = "If you use this, please cite it using these metadata.",
               title = title, authors = cffr::as_cff_person(authors), version = version,
               `date-released` = date_released, license = license, type = type)
  args$doi <- doi
  args$`repository-code` <- repository_code
  args$abstract <- abstract
  args$keywords <- keywords
  x <- do.call(cffr::cff, args)
  cffr::cff_write(x, outfile = path, validate = FALSE, verbose = FALSE)
  # cff_write(validate = TRUE) can write an invalid file silently, so validate the file itself.
  v <- suppressMessages(cffr::cff_validate(path, verbose = FALSE))
  if (!isTRUE(v)) {
    er <- attr(v, "errors")
    print(er[, intersect(c("instancePath", "message"), names(er)), drop = FALSE])
    stop("CITATION.cff written but INVALID; fix the fields above.", call. = FALSE)
  }
  invisible(path)
}
