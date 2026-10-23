# Lint a data-deposit README against the common requirements.
# Base R only. Prints findings; it cannot judge whether the content is TRUE.
# The section list encodes the minimum elements and recommended sections as of
# 2026-10-23 (see references/sources.md); re-check the repository's current
# guidance before relying on it.
#
# Usage:
#   source("data-repository-readme/scripts/check_readme.R")
#   check_readme("deposit/README.md", dir = "deposit", double_blind = FALSE)
#   check_readme("deposit/README.md", profile = "dryad")   # Dryad's four-section README

check_readme <- function(readme, dir = dirname(readme), double_blind = FALSE,
                         profile = c("full", "dryad")) {
  profile <- match.arg(profile)
  stopifnot(file.exists(readme))
  txt <- readLines(readme, warn = FALSE, encoding = "UTF-8")
  all <- paste(txt, collapse = "\n")
  res <- list()
  add <- function(level, check, msg) res[[length(res) + 1]] <<- data.frame(level, check, msg)

  # Elements (Borealis minimum nine + Dryad four + Cornell core); pattern = any match
  req <- c(
    "title"            = "^#\\s+\\S|title",
    "authors/creators" = "author|creator|investigator|principal",
    "description"      = "description|summary|abstract|overview",
    "contact"          = "contact|@",
    "license"          = "licen[cs]e|CC0|CC BY|CC-BY",
    "identifier (DOI)" = "doi|10\\.\\d{4,9}/|persistent identifier",
    "methods"          = "method|collected|collection",
    "related pubs"     = "publication|related|citation|cite",
    "software/versions"= "software|R version|R \\d\\.\\d|Python \\d|package",
    "file list"        = "file|folder|director",
    "variable defs"    = "variable|column|codebook|data dictionary",
    "units"            = "\\bunits?\\b|measured in",
    "missing values"   = "missing|\\bNA\\b|empty cell|not recorded"
  )
  # Dryad's README template has four sections (description, files and variables,
  # code/software, access). Authors, contact, license, DOI and related papers go
  # into its submission form, so they are not required in the README itself.
  if (profile == "dryad")
    req <- req[!names(req) %in% c("title", "authors/creators", "contact", "license",
                                  "identifier (DOI)", "related pubs", "methods")]
  for (k in names(req)) if (!grepl(req[[k]], all, ignore.case = TRUE, perl = TRUE))
    add("warning", "missing-element", sprintf("No sign of: %s", k))

  # Borealis "enhanced" tier: recommended, so info only (not for the Dryad profile)
  if (profile == "full") {
    enh <- c("funding"            = "fund|grant|award",
             "date of collection" = "collect\\w*[^\\n]{0,40}\\d{4}|\\d{4}-\\d{2}-\\d{2}",
             "geographic location"= "location|coordinates|latitude|region|site",
             "recommended citation" = "suggested citation|recommended citation|please cite|cite as",
             "version information" = "version|changelog")
    for (k in names(enh)) if (!grepl(enh[[k]], all, ignore.case = TRUE, perl = TRUE))
      add("info", "enhanced-element", sprintf("Recommended element not found: %s", k))
  }

  # Leftover placeholders
  ph <- grep("\\[TODO|\\[insert|<[^>]*(delete|help|example)[^>]*>|TBD|XXX|lorem", txt, ignore.case = TRUE)
  if (length(ph)) add("error", "placeholders", sprintf("%d placeholder line(s), first at line %d", length(ph), ph[1]))

  # File coverage
  if (dir.exists(dir)) {
    f <- list.files(dir, recursive = TRUE)
    f <- f[!grepl("^README", basename(f), ignore.case = TRUE)]
    unmentioned <- f[!vapply(f, function(x) grepl(basename(x), all, fixed = TRUE), logical(1))]
    if (length(unmentioned)) add("error", "undocumented-files",
      sprintf("%d file(s) not named in README: %s", length(unmentioned),
              paste(utils::head(unmentioned, 6), collapse = ", ")))
    cand <- unique(unlist(regmatches(all, gregexpr("`[^`/\\s]+\\.[A-Za-z0-9]{1,5}`", all, perl = TRUE))))
    cand <- gsub("`", "", cand)
    ghost <- cand[!cand %in% basename(f) & grepl("\\.(csv|tsv|txt|xlsx?|R|r|py|rds|rda|h5|json|md|pdf|png|zip)$", cand)]
    if (length(ghost)) add("warning", "ghost-files",
      sprintf("Named in README but not found in %s: %s", dir, paste(utils::head(ghost, 6), collapse = ", ")))
  }

  # Dates
  bad <- regmatches(all, gregexpr("\\b\\d{1,2}[./]\\d{1,2}[./]\\d{2,4}\\b", all))[[1]]
  if (length(bad)) add("warning", "dates", sprintf("Non-ISO date(s), use YYYY-MM-DD: %s", paste(utils::head(bad, 4), collapse = ", ")))

  # Wording that Dryad advises against / that breaks independence
  if (grepl("see (the )?(manuscript|paper|article)", all, ignore.case = TRUE))
    add("warning", "independence", "'see manuscript/paper' found: the README should stand alone")
  if (grepl("\\b(must|required to|obliged)\\b", all, ignore.case = TRUE))
    add("info", "legal-wording", "Words like 'must/required' can read as legal conditions; Dryad advises encouraging citation instead (check the target repository)")

  # Abbreviations: crude check for ALL-CAPS tokens that never appear with a definition
  body <- txt[!(grepl("[A-Z]", txt) & txt == toupper(txt))]   # skip ALL-CAPS heading lines
  body <- paste(body, collapse = "\n")
  ab <- unique(unlist(regmatches(body, gregexpr("\\b[A-Z]{2,6}\\b", body))))
  ab <- setdiff(ab, c("README", "CSV", "TSV", "DOI", "ISO", "NA", "CC", "BY", "TXT", "JSON", "PDF", "ORCID", "UTF", "TODO", "OF", "URL", "ZIP", "HTML", "XML", "MD", "R", "OS", "GPS", "USA", "EU", "UK"))
  ab <- ab[!vapply(ab, function(a) grepl(paste0("\\(", a, "\\)|", a, "\\s*[:=(-]|[:=-]\\s*", a), all), logical(1))]
  if (length(ab)) add("info", "abbreviations", sprintf("Possibly undefined abbreviation(s): %s", paste(utils::head(ab, 8), collapse = ", ")))

  # Double-blind
  if (double_blind && grepl("@|orcid\\.org|\\b\\d{4}-\\d{4}-\\d{4}-\\d{3}[\\dX]\\b", all, perl = TRUE))
    add("error", "double-blind", "Email/ORCID found but the journal uses double-blind review: remove identifying info until acceptance")

  # Format
  if (!grepl("\\.(md|txt)$", readme, ignore.case = TRUE))
    add("warning", "format", "Use Markdown (.md) or plain text (.txt)")
  if (grepl("\r", readChar(readme, file.size(readme)), fixed = TRUE))
    add("info", "line-endings", "CRLF line endings found")

  if (!length(res)) return(data.frame(level = "ok", check = "none", msg = "No findings (content truth not checked)"))
  do.call(rbind, res)
}
