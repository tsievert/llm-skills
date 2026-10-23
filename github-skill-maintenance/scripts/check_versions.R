# Find package-version claims in skill text and compare them with the installed
# and the current CRAN (or PyPI) versions, so stale claims can be reviewed.
#
# Usage:
#   source("github-skill-maintenance/scripts/check_versions.R")
#   check_versions()                  # data frame, one row per claim
#   check_versions(offline = TRUE)    # skip CRAN / PyPI lookups
#
# A claim is "<name> <version>" or "<name> (v<version>)" where <name> is a CRAN
# package that is installed locally or written in backticks (looked up in
# available.packages()), or one of `py_packages`. Plain-text names of packages
# that are not installed are skipped on purpose (CRAN has English-word packages
# such as "default" and "and"). It is a heuristic: it reports candidates to
# REVIEW, it never edits a skill. An older
# claim is not wrong by itself ("tested with X") but should be a conscious choice.
# Requires: no extra packages; internet for the lookups (jsonlite for PyPI).

# Names as written in the skills -> PyPI project names.
py_packages <- c("keypoint-moseq" = "keypoint-moseq", "kpms" = "keypoint-moseq",
                 "movement" = "movement", "deeplabcut" = "deeplabcut",
                 "skills-ref" = "skills-ref")

check_versions <- function(repo = find_repo_root_cv(), offline = FALSE) {
  files <- list.files(repo, pattern = "\\.(md|R|py|sh|sbatch)$", recursive = TRUE, full.names = TRUE)
  files <- files[!grepl("/(\\.git|\\.Rproj\\.user|\\.venv)/|AGENTS\\.md$", files)]

  cran <- if (!offline) {
    ap <- tryCatch(available.packages(), error = function(e) NULL)
    if (is.null(ap)) NULL else setNames(ap[, "Version"], ap[, "Package"])
  }
  local_pkgs <- rownames(installed.packages())

  # name, optional "(" or "v", then a dotted version such as 1.9-4, 0.11.2.10, 0.17.0
  pat <- "(?<![A-Za-z0-9._-])([A-Za-z][A-Za-z0-9._-]*)(`?)\\s+\\(?v?(\\d+\\.\\d+(?:[.-]\\d+)*)(?![\\d.]*\\d*[A-Za-z%])"
  rows <- list()
  for (f in files) {
    txt <- readLines(f, warn = FALSE, encoding = "UTF-8")
    for (i in seq_along(txt)) {
      m <- gregexpr(pat, txt[i], perl = TRUE)[[1]]
      if (m[1] == -1) next
      st <- attr(m, "capture.start"); ln <- attr(m, "capture.length")
      for (k in seq_along(m)) {
        nm <- substr(txt[i], st[k, 1], st[k, 1] + ln[k, 1] - 1)
        ticked <- ln[k, 2] > 0
        ver <- substr(txt[i], st[k, 3], st[k, 3] + ln[k, 3] - 1)
        # CRAN holds many English-word packages ("default", "and", "likelihood").
        # Plain-text names count only if installed here; otherwise they need backticks.
        is_r <- nm %in% local_pkgs || (ticked && !is.null(cran) && nm %in% names(cran))
        is_py <- tolower(nm) %in% names(py_packages)
        if (!is_r && !is_py) next
        rows[[length(rows) + 1]] <- data.frame(
          file = sub(paste0("^", repo, "/"), "", f), line = i, package = nm,
          claimed = ver, stringsAsFactors = FALSE)
      }
    }
  }
  if (!length(rows)) return(data.frame())
  res <- unique(do.call(rbind, rows))

  res$installed <- vapply(res$package, function(p)
    if (p %in% local_pkgs) as.character(utils::packageVersion(p)) else NA_character_, "")
  res$latest <- vapply(res$package, function(p) {
    if (offline) return(NA_character_)
    if (tolower(p) %in% names(py_packages)) return(pypi_latest(py_packages[[tolower(p)]]))
    if (!is.null(cran) && p %in% names(cran)) return(unname(cran[[p]]))
    NA_character_
  }, "")
  res$status <- mapply(function(cl, lt, ins) {
    if (is.na(lt)) return(if (is.na(ins)) "no reference version" else compare_status(cl, ins, "installed"))
    compare_status(cl, lt, "latest")
  }, res$claimed, res$latest, res$installed)
  res[order(res$status == "same", res$file, res$line), ]
}

compare_status <- function(claimed, ref, what) {
  cmp <- tryCatch(utils::compareVersion(norm_ver(claimed), norm_ver(ref)), error = function(e) NA)
  if (is.na(cmp)) return("unparsed")
  if (cmp == 0) "same"
  else if (cmp < 0) paste("claim older than", what)
  else paste("claim newer than", what)
}

norm_ver <- function(v) gsub("-", ".", v)

pypi_latest <- function(project) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) return(NA_character_)
  tryCatch(jsonlite::fromJSON(sprintf("https://pypi.org/pypi/%s/json", project))$info$version,
           error = function(e) NA_character_)
}

find_repo_root_cv <- function(start = getwd()) {
  d <- normalizePath(start, winslash = "/")
  repeat {
    if (dir.exists(file.path(d, ".git"))) return(d)
    parent <- dirname(d)
    if (parent == d) stop("No git repository found above ", start)
    d <- parent
  }
}
