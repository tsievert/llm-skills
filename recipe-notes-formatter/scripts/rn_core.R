# rn_core.R -- project folders, safe writing, note reading, rendering and checking.
# Source with: source("<skill-dir>/scripts/rn_core.R", encoding = "UTF-8")
# Needs: yaml. Never writes to input/. Never overwrites: existing files are backed up first.

#' Check that the conversion project has its folders. Nothing is created here.
#' @param root project folder (default: the working directory).
#' @return data.frame(item, path, exists, needed_for)
rn_project_check <- function(root = ".") {
  items <- data.frame(
    item = c("input", "output", "output/images", "backup", "recipe-profile.yml"),
    needed_for = c("source notes, text files and link lists (never modified)",
                   "finished notes",
                   "downloaded pictures",
                   "timestamped copies of anything that would be replaced",
                   "learned tag and property profile"),
    stringsAsFactors = FALSE)
  items$path <- file.path(root, items$item)
  items$exists <- file.exists(items$path)
  items[, c("item", "path", "exists", "needed_for")]
}

#' Create missing project folders. Refuses without confirmed = TRUE (the user must say yes first).
rn_project_create <- function(root = ".", confirmed = FALSE) {
  chk <- rn_project_check(root)
  missing <- chk[!chk$exists & chk$item != "recipe-profile.yml", ]
  if (!nrow(missing)) return(invisible(character()))
  if (!isTRUE(confirmed)) {
    stop("Missing folders: ", paste(missing$item, collapse = ", "),
         ". Ask the user for permission, then call again with confirmed = TRUE.", call. = FALSE)
  }
  for (p in missing$path) dir.create(p, recursive = TRUE)
  invisible(missing$path)
}

#' Copy a file into backup/<timestamp>/ before it is replaced. Verifies the copy by MD5.
#' @return path of the backup copy.
rn_backup <- function(path, backup_dir = "backup", stamp = format(Sys.time(), "%Y%m%d-%H%M%S")) {
  if (!file.exists(path)) stop("Nothing to back up: ", path, call. = FALSE)
  dest_dir <- file.path(backup_dir, stamp)
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  dest <- file.path(dest_dir, basename(path))
  if (normalizePath(dest, mustWork = FALSE) == normalizePath(path, mustWork = FALSE)) {
    stop("Backup destination equals the source: ", path, call. = FALSE)
  }
  ok <- file.copy(path, dest, overwrite = FALSE)
  if (!ok || unname(tools::md5sum(path)) != unname(tools::md5sum(dest))) {
    stop("Backup failed or differs from the original: ", dest, call. = FALSE)
  }
  dest
}

#' File-system safe note name from a recipe title. "/" becomes " or ", illegal characters
#' become "-", umlauts and spaces are kept, length is capped.
rn_safe_filename <- function(title, max_chars = 120) {
  x <- gsub("\\s*/\\s*", " or ", title)
  x <- gsub("[?\"*<>]", "", x)                       # dropped: they carry no meaning in a name
  x <- gsub("\\s*:\\s*", " - ", x)                   # "Eintopf: Rind" -> "Eintopf - Rind"
  x <- gsub("[\\\\|#^\\[\\]]", "-", x, perl = TRUE)  # Obsidian link characters and path separators
  x <- gsub("[[:cntrl:]]", " ", x)
  x <- trimws(gsub("\\s+", " ", x))
  x <- sub("[. ]+$", "", x)
  if (!nzchar(x)) x <- "recipe"
  if (nchar(x) > max_chars) x <- trimws(substr(x, 1, max_chars))
  x
}

#' Write text as UTF-8 with LF line endings. Never replaces silently:
#' an existing file is backed up first (overwrite = TRUE) or a numbered name is used (default).
#' @return path written.
rn_write_text <- function(text, dir, filename, backup_dir = "backup", overwrite = FALSE) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(dir, filename)
  if (file.exists(path)) {
    if (overwrite) {
      rn_backup(path, backup_dir)
    } else {
      stem <- tools::file_path_sans_ext(filename); ext <- tools::file_ext(filename)
      k <- 2L
      repeat {
        cand <- file.path(dir, paste0(stem, " (", k, ")", if (nzchar(ext)) paste0(".", ext) else ""))
        if (!file.exists(cand)) { path <- cand; break }
        k <- k + 1L
      }
    }
  }
  con <- file(path, "wb")
  on.exit(close(con))
  writeBin(charToRaw(enc2utf8(gsub("\r\n", "\n", text, fixed = TRUE))), con)
  path
}

# ---- reading notes ------------------------------------------------------------------------

#' Obsidian tag rules: letters, digits, _, -, / ; at least one non-digit; no spaces.
rn_tag_ok <- function(tag) {
  grepl("^[\\p{L}\\p{N}_/-]+$", tag, perl = TRUE) & grepl("[^\\d/]", tag, perl = TRUE)
}

# Normalise a frontmatter list field (tags or aliases) that may hold strings, comma lists, or the
# broken template placeholders `- "{ tag2 }":` (YAML reads those as one-key mappings).
.rn_field_values <- function(x) {
  vals <- character(); placeholders <- character()
  if (is.null(x)) return(list(values = vals, placeholders = placeholders))
  items <- if (is.list(x)) x else as.list(x)
  for (el in items) {
    if (is.list(el)) {
      placeholders <- c(placeholders, names(el))
    } else if (!is.null(el) && !is.na(el)) {
      s <- as.character(el)
      parts <- if (grepl("[, ]", s)) trimws(strsplit(s, "[, ]+")[[1]]) else s
      vals <- c(vals, parts[nzchar(parts)])
    }
  }
  list(values = sub("^#", "", vals), placeholders = placeholders)
}

#' Read a Markdown note: frontmatter (parsed), body lines, tags, problems.
rn_read_note <- function(path) {
  bytes <- readBin(path, "raw", n = min(file.size(path), 20000))
  crlf <- any(bytes == as.raw(13))
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  problems <- character()
  front <- list(); front_lines <- character(); body <- lines
  if (length(lines) && grepl("^---\\s*$", lines[1])) {
    close_at <- which(grepl("^---\\s*$", lines[-1]))[1] + 1L
    if (!is.na(close_at)) {
      front_lines <- lines[2:(close_at - 1L)]
      body <- if (close_at < length(lines)) lines[(close_at + 1L):length(lines)] else character()
      front <- tryCatch(yaml::yaml.load(paste(front_lines, collapse = "\n")),
                        error = function(e) { problems <<- c(problems, paste("YAML error:", conditionMessage(e))); list() })
      if (is.null(front) || !is.list(front)) front <- list()
    } else problems <- c(problems, "frontmatter is not closed")
  } else problems <- c(problems, "no frontmatter on line 1")
  tg <- .rn_field_values(front$tags)
  al <- .rn_field_values(front$aliases)
  list(path = path, front = front, front_lines = front_lines, body = body, crlf = crlf,
       tags = tg$values, tag_placeholders = tg$placeholders,
       aliases = al$values, alias_placeholders = al$placeholders, problems = problems)
}

# ---- rendering ----------------------------------------------------------------------------

.rn_q <- function(x) paste0("\"", gsub("([\"\\\\])", "\\\\\\1", x), "\"")

#' Render one recipe as an Obsidian note. See references/note-format.md for the layout.
#'
#' @param rec list: title, source, lang, tags, aliases, servings, time, image_file, image_credit,
#'   notes (character, optional callout lines), ingredients = list(list(name, items)),
#'   directions = list(list(name, steps)). Texts must already be unit-converted.
#' @param profile list from rn_profile_read()/rn_learn_profile(); controls author, index link,
#'   checkbox default, image width and headings. Missing entries fall back to defaults.
rn_render_note <- function(rec, profile = list()) {
  pf <- function(name, default) if (!is.null(profile[[name]])) profile[[name]] else default
  box <- if (identical(pf("checkbox_default", "ticked"), "ticked")) "- [x] " else "- [ ] "
  h_ing <- pf("heading_ingredients", "Ingredients"); h_dir <- pf("heading_directions", "Directions")
  out <- "---"
  out <- c(out, if (length(rec$aliases)) c("aliases:", paste0("  - ", .rn_q(rec$aliases))) else "aliases: []")
  out <- c(out, paste0("source: ", if (length(rec$source) && nzchar(rec$source)) .rn_q(rec$source) else ""))
  tags <- unique(c("recipe", rec$tags))
  out <- c(out, "tags:", paste0("  - ", tags))
  if (nzchar(pf("author", ""))) out <- c(out, paste0("author: ", pf("author", "")))
  if (length(rec$lang) && nzchar(rec$lang)) out <- c(out, paste0("lang: ", rec$lang))
  if (length(rec$servings) && !is.na(rec$servings)) out <- c(out, paste0("servings: ", rec$servings))
  if (length(rec$time) && !is.na(rec$time)) out <- c(out, paste0("time: ", rec$time))
  has_img <- length(rec$image_file) && nzchar(rec$image_file)
  if (has_img) out <- c(out, paste0("cover: ", .rn_q(paste0("[[", rec$image_file, "]]"))))
  out <- c(out, "---")
  if (has_img) {
    out <- c(out, paste0("![[", rec$image_file, "|", pf("image_width", 300), "]]"))
    if (length(rec$image_credit) && nzchar(rec$image_credit)) out <- c(out, paste0("%%Photo: ", rec$image_credit, "%%"))
    out <- c(out, "")
  }
  out <- c(out, paste0("# ", rec$title))
  if (nzchar(pf("index_link", ""))) out <- c(out, pf("index_link", ""))
  out <- c(out, "")
  if (length(rec$notes)) out <- c(out, "> [!note]", paste0("> ", rec$notes), "")
  out <- c(out, paste0("## ", h_ing))
  for (g in rec$ingredients) {
    if (length(g$name) && nzchar(g$name)) out <- c(out, "", paste0("### ", g$name))
    out <- c(out, "#ingredients", paste0(box, g$items))
  }
  out <- c(out, "", "---", "", paste0("## ", h_dir))
  for (g in rec$directions) {
    if (length(g$name) && nzchar(g$name)) out <- c(out, "", paste0("### ", g$name), "")
    steps <- sub("^\\s*(?:step\\s*)?\\d+[.)]\\s*", "", g$steps, ignore.case = TRUE, perl = TRUE)
    out <- c(out, paste0(seq_along(steps), ". ", steps))
  }
  paste0(paste(out, collapse = "\n"), "\n")
}

# ---- checking -----------------------------------------------------------------------------

#' Validate a finished note against the format rules and the profile. Run after writing and fix
#' every `error` (loop: check, fix, check). Findings: level (error/warn/info), check, message.
rn_check_note <- function(path, profile = list(), spoons = "keep") {
  f <- data.frame(level = character(), check = character(), message = character(), stringsAsFactors = FALSE)
  add <- function(level, check, msg) f[nrow(f) + 1, ] <<- list(level, check, msg)
  if (!file.exists(path)) { add("error", "file", "file does not exist"); return(f) }
  n <- rn_read_note(path)
  for (p in n$problems) add("error", "frontmatter", p)
  if (n$crlf) add("info", "line-endings", "file has CRLF line endings; LF is used by the skill")
  if (!("recipe" %in% n$tags)) add("error", "tags", "tag `recipe` is missing")
  bad <- n$tags[!rn_tag_ok(n$tags)]
  if (length(bad)) add("error", "tags", paste("invalid Obsidian tag(s):", paste(bad, collapse = ", ")))
  if (length(n$tag_placeholders) || length(n$alias_placeholders)) {
    add("error", "placeholders", "template placeholders left in tags or aliases")
  }
  vocab <- profile$tag_vocabulary
  if (length(vocab)) {
    unk <- setdiff(n$tags, vocab)
    if (length(unk)) add("warn", "tags", paste("not in the profile vocabulary (suggest, do not invent):", paste(unk, collapse = ", ")))
  }
  for (k in c("servings", "time")) {
    if (!is.null(n$front[[k]]) && !is.numeric(n$front[[k]])) add("error", k, paste(k, "must be a number"))
  }
  if (!is.null(n$front$Created_at) || !is.null(n$front$Modified_at)) {
    add("warn", "timestamps", "Created_at/Modified_at are left to Templater; remove them")
  }
  b <- n$body
  h_ing <- if (!is.null(profile$heading_ingredients)) profile$heading_ingredients else "Ingredients"
  h_dir <- if (!is.null(profile$heading_directions)) profile$heading_directions else "Directions"
  i_ing <- which(grepl(paste0("^## ", h_ing, "\\s*$"), b))
  i_dir <- which(grepl(paste0("^## ", h_dir, "\\s*$"), b))
  if (!length(i_ing)) add("error", "ingredients", paste0("heading '## ", h_ing, "' missing"))
  if (!length(i_dir)) add("error", "directions", paste0("heading '## ", h_dir, "' missing"))
  if (length(i_ing) && length(i_dir)) {
    seg <- b[(i_ing[1] + 1):(i_dir[1] - 1)]
    items <- seg[grepl("^\\s*- ", seg)]
    if (!length(items)) add("error", "ingredients", "no ingredient list found")
    if (any(!grepl("^- \\[[ x]\\] \\S", items))) add("error", "ingredients", "list items must look like '- [x] text'")
    want <- if (identical(profile$checkbox_default, "unticked")) "\\[ \\]" else "\\[x\\]"
    if (any(!grepl(paste0("^- ", want), items))) add("warn", "ingredients", "checkbox state differs from the profile default")
    for (j in which(grepl("^- \\[", seg))) {
      prev <- if (j > 1) seg[j - 1] else ""
      if (!grepl("^- \\[", prev) && !grepl("^#ingredients\\s*$", prev)) {
        add("warn", "ingredients", paste0("list starting at '", substr(seg[j], 1, 30), "' has no #ingredients line directly above"))
      }
    }
    txt <- sub("^- \\[[ x]\\] ", "", items)
    steps_seg <- b[(i_dir[1] + 1):length(b)]
    steps <- steps_seg[grepl("^\\d+\\. ", steps_seg)]
    if (!length(steps)) add("error", "directions", "no numbered steps found")
    for (t in c(txt, steps)) {
      r <- rn_convert_all(t, spoons = spoons)
      if (nrow(r$changes)) add("warn", "units", paste0("non-metric left: '", r$changes$from[1], "' in '", substr(t, 1, 40), "'"))
    }
  }
  if (any(grepl("^## (Intro|FINISH)\\s*:?\\s*$", b))) {
    add("info", "sections", "empty Intro/FINISH sections should be dropped (profile default)")
  }
  emb <- regmatches(b, regexpr("!\\[\\[[^\\]|]+", b, perl = TRUE))
  if (length(emb)) {
    img <- sub("^!\\[\\[", "", emb[1])
    p <- file.path(dirname(path), "images", img)
    if (!file.exists(p)) add("error", "image", paste("embedded image not found next to the note:", file.path("images", img)))
  }
  if (!nrow(f)) add("info", "ok", "no findings")
  f
}
