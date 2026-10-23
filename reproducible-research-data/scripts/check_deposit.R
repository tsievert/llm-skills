# Pre-upload checks and a checksummed staging copy for a research data deposit.
# Source this file, then: check_deposit("path/to/deposit"); stage_deposit(from, to).
# Nothing is uploaded, published or changed in the source folder. Every check is a heuristic:
# it looks at names, sizes, encodings and text patterns, not at meaning. Needs base R (R >= 4.5 for
# tools::sha256sum, otherwise the digest package).
# Repository limits below were read on 2026-10-23 and change; re-read the live page before relying on them.

.rrd_sha256 <- function(files) {
  if (!length(files)) return(character())
  if (exists("sha256sum", asNamespace("tools"))) return(unname(tools::sha256sum(files)))
  vapply(files, function(x) digest::digest(x, algo = "sha256", file = TRUE), "", USE.NAMES = FALSE)
}

.rrd_finding <- function(check, level, item, message) {
  data.frame(check = check, level = level, item = item, message = message, stringsAsFactors = FALSE)
}

# Regexes (matched against the path relative to the deposit root)
.rrd_junk_dirs <- "(^|/)(\\.git|\\.Rproj\\.user|\\.venv|venv|__pycache__|_targets|\\.snakemake|renv/library|node_modules)(/|$)"
.rrd_junk_files <- "(^|/)(\\.RData|\\.Rhistory|\\.Ruserdata|\\.DS_Store|Thumbs\\.db|desktop\\.ini)$"
.rrd_secret_names <- "(^|/)(\\.env|\\.Renviron|\\.netrc|\\.pgpass|id_rsa|id_ed25519|credentials(\\.json)?|secrets?\\.(ya?ml|json|toml))$|\\.(pem|key|p12|pfx|kdbx)$"
.rrd_secret_patterns <- c(
  `GitHub token`         = "gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}",
  `AWS access key id`    = "AKIA[0-9A-Z]{16}",
  `private key block`    = "-----BEGIN [A-Z ]*PRIVATE KEY-----",
  `token/key assignment` = "(?i)(api[_-]?key|token|secret|passw(or)?d)[\"']?\\s*(<-|=|:)\\s*[\"'][A-Za-z0-9_\\-\\.]{16,}[\"']"
)
.rrd_text_ext <- "\\.(r|py|qmd|rmd|md|txt|csv|tsv|yml|yaml|json|toml|sh|cfg|ini|smk|cff)$"
.rrd_code_ext <- "\\.(r|py|qmd|rmd|sh|smk|jl|m)$|(^|/)Snakefile$"
.rrd_lockfiles <- "(^|/)(renv\\.lock|uv\\.lock|poetry\\.lock|requirements[^/]*\\.txt|environment\\.ya?ml|conda-lock\\.ya?ml|pyproject\\.toml|session[-_]?info[^/]*\\.(txt|md))$"
# Characters ERDA rejects plus those that break paths elsewhere
.rrd_bad_chars <- "[<>{}|*?\\[\\]:\"\\\\#%&]"

# Limits per repository profile, read 2026-10-23 (Dryad: recommended file size, web interface total;
# Zenodo: per upload through the form). NULL means "not established here: read the live page".
.rrd_profiles <- list(
  generic = list(max_file_gb = NULL, max_files = NULL, max_total_gb = NULL, rar = "warning"),
  dryad   = list(max_file_gb = 10,   max_files = NULL, max_total_gb = 2000, rar = "error"),
  zenodo  = list(max_file_gb = NULL, max_files = 100,  max_total_gb = 50,   rar = "warning"),
  figshare = list(max_file_gb = NULL, max_files = NULL, max_total_gb = NULL, rar = "warning")
)

#' Check a deposit folder before upload.
#' @param dir folder that will be uploaded (the staged copy, not the working project).
#' @param repo "generic", "dryad", "zenodo" or "figshare" (sets size and count limits; see .rrd_profiles).
#' @param max_file_gb,max_files,max_total_gb override the profile (NULL keeps it).
#' @return data frame: check, level (error/warning/info), item, message. Zero rows if nothing was found.
check_deposit <- function(dir, repo = c("generic", "dryad", "zenodo", "figshare"),
                          max_file_gb = NULL, max_files = NULL, max_total_gb = NULL) {
  repo <- match.arg(repo)
  prof <- .rrd_profiles[[repo]]
  if (is.null(max_file_gb)) max_file_gb <- prof$max_file_gb
  if (is.null(max_files)) max_files <- prof$max_files
  if (is.null(max_total_gb)) max_total_gb <- prof$max_total_gb
  if (!dir.exists(dir)) stop("Not a directory: ", dir)

  f <- list()
  add <- function(...) f[[length(f) + 1]] <<- .rrd_finding(...)

  all_files <- list.files(dir, recursive = TRUE, all.files = TRUE, include.dirs = FALSE, no.. = TRUE)
  if (!length(all_files)) {
    return(.rrd_finding("empty", "error", dir, "The folder has no files."))
  }

  # Junk directories: one finding per directory, then drop their files from the other checks
  jd <- grepl(.rrd_junk_dirs, all_files)
  if (any(jd)) {
    hit <- unique(sub(paste0("(", .rrd_junk_dirs, ").*$"), "\\1", all_files[jd]))
    for (h in hit) add("junk", "warning", sub("/$", "", h),
                       "Version-control, cache or session directory inside the deposit. Build the deposit from a clean export (git archive), not from the working folder.")
  }
  files <- all_files[!jd]
  for (x in files[grepl(.rrd_junk_files, files)]) {
    add("junk", "warning", x, "Session or operating-system file. Remove it from the deposit.")
  }
  full <- file.path(dir, files)
  sz <- file.size(full)

  # Names
  for (x in files[grepl(" ", files, fixed = TRUE)]) add("file-name", "warning", x, "Space in the path. Use letters, digits, hyphen and underscore only.")
  for (x in files[grepl("[^\\x01-\\x7F]", files, perl = TRUE)]) add("file-name", "warning", x, "Non-ASCII character in the path. Some systems and zip tools mangle it; ASCII is advised.")
  for (x in files[grepl(.rrd_bad_chars, files, perl = TRUE)]) add("file-name", "error", x, "Character in the path that some archives reject (ERDA rejects < > { | } * ? [ ]) or that breaks scripts.")
  for (x in files[nchar(files) > 150]) add("file-name", "warning", x, "Path longer than 150 characters; Windows tools and zip files can fail.")
  low <- tolower(files)
  for (d in unique(low[duplicated(low)])) add("file-name", "error", paste(files[low == d], collapse = " | "), "Paths differ only in letter case; they collide on Windows and macOS.")

  # Sizes and counts
  for (i in which(sz == 0)) add("empty-file", "warning", files[i], "Zero-byte file. Remove it or explain it in the README.")
  if (!is.null(max_file_gb)) {
    for (i in which(!is.na(sz) & sz > max_file_gb * 1024^3)) {
      add("size", "warning", files[i], sprintf("%.1f GB, above the %s profile value of %g GB per file (read 2026-10-23, check the live page).", sz[i] / 1024^3, repo, max_file_gb))
    }
  }
  if (!is.null(max_total_gb) && sum(sz, na.rm = TRUE) > max_total_gb * 1024^3) {
    add("size", "warning", "(total)", sprintf("%.1f GB in total, above the %s profile value of %g GB.", sum(sz, na.rm = TRUE) / 1024^3, repo, max_total_gb))
  }
  if (!is.null(max_files) && length(files) > max_files) {
    add("size", "warning", "(count)", sprintf("%d files, above the %s profile value of %d per upload. Bundle small files into a documented zip.", length(files), repo, max_files))
  }

  # Formats
  rar <- files[grepl("\\.rar$", files, ignore.case = TRUE)]
  for (x in rar) add("format", prof$rar, x, "RAR archive; Dryad does not accept it and it is not an open format. Use zip or tar.gz.")
  for (x in files[grepl("\\.(exe|dll|so|dylib|app|msi|bat|cmd)$", files, ignore.case = TRUE)]) {
    add("format", "warning", x, "Executable or binary library. Deposit source code and build instructions instead.")
  }
  for (x in files[grepl("\\.(xlsx?|docx?|pptx?|sav|dta|sas7bdat|mat)$", files, ignore.case = TRUE)]) {
    add("format", "info", x, "Proprietary format. Repositories and journals prefer open formats (CSV, TSV, plain text); keep this file only with a reason, and say so in the README.")
  }
  for (x in files[grepl("\\.(rds|rda|rdata|pkl|pickle|qs2?)$", files, ignore.case = TRUE)]) {
    add("format", "info", x, "Language-specific binary object. Readable only with R or Python of a given version; add an open-format copy (CSV, parquet) of the data that matter.")
  }

  # README, licence, environment
  top <- files[!grepl("/", files)]
  has_readme <- any(grepl("^README(\\.md|\\.txt)?$", top, ignore.case = TRUE))
  if (!has_readme) add("readme", "error", "README", "No README at the top level. Draft it with the data-repository-readme skill.")
  code <- files[grepl(.rrd_code_ext, files, ignore.case = TRUE)]
  if (length(code)) {
    if (!any(grepl(.rrd_lockfiles, files, ignore.case = TRUE))) {
      add("environment", "warning", "(code)", sprintf("%d code files but no lockfile or session-info file (renv.lock, uv.lock, requirements.txt, environment.yml, sessionInfo output). Software versions are part of reproducibility.", length(code)))
    }
    if (!any(grepl("^(LICEN[CS]E|COPYING)", top, ignore.case = TRUE))) {
      add("licence", "info", "(code)", "Code present but no LICENSE file at the top level. State the code licence (for example MIT) in a file and in the README.")
    }
  }

  # Text-file checks: encoding, secrets, absolute paths. Binary files are skipped.
  is_text <- grepl(.rrd_text_ext, files, ignore.case = TRUE) & !is.na(sz) & sz > 0
  for (i in which(is_text)) {
    n <- min(sz[i], 1e6)
    raw <- tryCatch(readBin(full[i], "raw", n = n), error = function(e) NULL)
    if (is.null(raw) || any(raw == 0)) next
    if (sz[i] > n) raw <- raw[seq_len(length(raw) - 3)]
    txt <- rawToChar(raw)
    if (!validUTF8(txt)) {
      add("encoding", "warning", files[i], "Not valid UTF-8 (probably Latin-1 or Windows-1252). Re-save as UTF-8 so accented names and units survive.")
      next
    }
    if (length(raw) >= 3 && all(raw[1:3] == as.raw(c(0xEF, 0xBB, 0xBF)))) {
      add("encoding", "info", files[i], "UTF-8 byte-order mark; some readers show it as a stray character in the first column name.")
    }
    for (nm in names(.rrd_secret_patterns)) {
      if (grepl(.rrd_secret_patterns[[nm]], txt, perl = TRUE, useBytes = TRUE)) {
        add("secret", "error", files[i], sprintf("Looks like a %s (value not shown). Remove it, rotate the credential, and rebuild the deposit from a clean export.", nm))
      }
    }
    if (grepl(.rrd_code_ext, files[i], ignore.case = TRUE) &&
        grepl("[A-Za-z]:[/\\\\]Users[/\\\\]|/home/[A-Za-z0-9_.-]+/|/Users/[A-Za-z0-9_.-]+/", txt, perl = TRUE)) {
      add("absolute-path", "warning", files[i], "Hard-coded personal path (also reveals a user name). Use paths relative to the project root, or a documented config value.")
    }
  }
  for (x in files[grepl(.rrd_secret_names, files, ignore.case = TRUE)]) {
    add("secret", "error", x, "File name suggests credentials or keys. Never deposit it.")
  }

  # Duplicates and manifest
  keep <- !is.na(sz) & sz > 0 & !grepl("^MANIFEST\\.tsv$", files)
  if (sum(keep) > 1) {
    h <- .rrd_sha256(full[keep])
    for (d in unique(h[duplicated(h)])) {
      add("duplicate", "info", paste(files[keep][h == d], collapse = " | "), "Byte-identical files. Keep one, or say in the README why both are there.")
    }
  }
  if ("MANIFEST.tsv" %in% files) {
    m <- tryCatch(utils::read.delim(file.path(dir, "MANIFEST.tsv"), stringsAsFactors = FALSE), error = function(e) NULL)
    if (is.null(m) || !all(c("path", "bytes", "sha256") %in% names(m))) {
      add("manifest", "warning", "MANIFEST.tsv", "Exists but does not have the columns path, bytes, sha256.")
    } else {
      miss <- setdiff(m$path, files)
      extra <- setdiff(setdiff(files, "MANIFEST.tsv"), m$path)
      common <- intersect(m$path, files)
      changed <- common[.rrd_sha256(file.path(dir, common)) != m$sha256[match(common, m$path)]]
      for (x in miss) add("manifest", "error", x, "Listed in MANIFEST.tsv but missing from the folder.")
      for (x in changed) add("manifest", "error", x, "Checksum differs from MANIFEST.tsv (file changed after staging).")
      for (x in extra) add("manifest", "warning", x, "Present but not listed in MANIFEST.tsv.")
    }
  } else {
    add("manifest", "info", "MANIFEST.tsv", "No manifest. stage_deposit() writes one (path, bytes, sha256) so the uploaded copy can be verified against the server copy.")
  }

  out <- if (length(f)) do.call(rbind, f) else .rrd_finding("none", "info", "", "")[0, ]
  lv <- c(error = 1, warning = 2, info = 3)
  out <- out[order(lv[out$level], out$check, out$item), ]
  rownames(out) <- NULL
  out
}

#' Copy a source tree into a new staging folder, verify every copy by checksum, write MANIFEST.tsv.
#' The source is never changed. The destination must not exist or must be empty, and the two
#' folders must not contain each other (a copy onto itself can truncate files).
#' @param from source folder (for example a mapped server drive or a `git archive` export).
#' @param to new staging folder.
#' @param exclude regex on relative paths to leave out (default: junk directories and files).
#' @param read_only set the read-only flag on the staged files (a guard against edits, not security).
#' @return the manifest (path, bytes, sha256), invisibly.
stage_deposit <- function(from, to, exclude = paste(.rrd_junk_dirs, .rrd_junk_files, sep = "|"),
                          read_only = FALSE) {
  if (!dir.exists(from)) stop("Source is not a directory: ", from)
  nf <- normalizePath(from, winslash = "/", mustWork = TRUE)
  nt <- normalizePath(to, winslash = "/", mustWork = FALSE)
  cmp <- function(x) if (.Platform$OS.type == "windows") tolower(x) else x
  nf <- sub("/$", "", cmp(nf)); nt <- sub("/$", "", cmp(nt))
  if (identical(nf, nt) || startsWith(paste0(nt, "/"), paste0(nf, "/")) || startsWith(paste0(nf, "/"), paste0(nt, "/"))) {
    stop("Source and destination are the same folder or contain each other: ", from, " | ", to)
  }
  if (dir.exists(to) && length(list.files(to, all.files = TRUE, no.. = TRUE))) {
    stop("Destination exists and is not empty: ", to)
  }
  rel <- list.files(from, recursive = TRUE, all.files = TRUE, include.dirs = FALSE, no.. = TRUE)
  rel <- rel[!grepl(exclude, rel)]
  if (!length(rel)) stop("Nothing to copy from ", from)
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  for (d in unique(dirname(rel))) if (d != ".") dir.create(file.path(to, d), recursive = TRUE, showWarnings = FALSE)
  ok <- file.copy(file.path(from, rel), file.path(to, rel), overwrite = FALSE, copy.date = TRUE)
  if (!all(ok)) stop("Copy failed for: ", paste(rel[!ok], collapse = ", "))
  src_h <- .rrd_sha256(file.path(from, rel))
  dst_h <- .rrd_sha256(file.path(to, rel))
  bad <- rel[src_h != dst_h]
  if (length(bad)) stop("Checksum mismatch after copying: ", paste(bad, collapse = ", "))
  m <- data.frame(path = rel, bytes = file.size(file.path(to, rel)), sha256 = dst_h, stringsAsFactors = FALSE)
  m <- m[order(m$path), ]
  utils::write.table(m, file.path(to, "MANIFEST.tsv"), sep = "\t", quote = FALSE, row.names = FALSE, eol = "\n")
  if (read_only) Sys.chmod(file.path(to, c(rel, "MANIFEST.tsv")), mode = "0444")
  message(sprintf("Staged %d files (%.1f MB) in %s; every copy verified by sha256; MANIFEST.tsv written.",
                  nrow(m), sum(m$bytes) / 1024^2, to))
  invisible(m)
}
