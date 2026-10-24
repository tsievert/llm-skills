# rn_profile.R -- learn the user's tag structure and note conventions from existing notes.
# Source after rn_core.R: source("<skill-dir>/scripts/rn_profile.R", encoding = "UTF-8")
# Needs: yaml; optional cld2 (CRAN) for language detection. The profile is a YAML file the user
# can read and edit; it is updated on every run and only written with confirmed = TRUE.

#' Read a Bases (.base) file and list the tags and folder its filters mention.
rn_read_base <- function(path) {
  txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  tg <- regmatches(txt, gregexpr("file\\.tags\\.contains\\(\"([^\"]+)\"\\)", txt))[[1]]
  tg <- unique(sub("^file\\.tags\\.contains\\(\"(.*)\"\\)$", "\\1", tg))
  fo <- regmatches(txt, gregexpr("file\\.folder == \"([^\"]+)\"", txt))[[1]]
  views <- regmatches(txt, gregexpr("name: ([^\n]+)", txt))[[1]]
  list(path = path, tags = tg, folders = unique(sub("^file\\.folder == \"(.*)\"$", "\\1", fo)),
       views = sub("^name: ", "", views))
}

.rn_detect_lang <- function(text) {
  if (!requireNamespace("cld2", quietly = TRUE) || !nzchar(trimws(text))) return(NA_character_)
  cld2::detect_language(text)
}

#' Scan notes in a folder (recursive) and collect conventions. One row per note.
#' @return list(notes = data.frame, tags = list per note).
rn_scan_notes <- function(dir, recursive = TRUE) {
  files <- list.files(dir, pattern = "\\.md$", recursive = recursive, full.names = TRUE)
  rows <- list(); tag_list <- list()
  for (f in files) {
    n <- rn_read_note(f)
    b <- n$body
    h2 <- sub("^##\\s+", "", b[grepl("^##\\s+", b) & !grepl("^###", b)])
    i_dir <- which(grepl("^##\\s+(Directions?|Instructions?|Zubereitung|Valmistus|G\u00f6r s\u00e5|Tillagning|Method)", b, ignore.case = TRUE))[1]
    dir_txt <- if (!is.na(i_dir)) paste(b[(i_dir + 1):length(b)], collapse = " ") else paste(b, collapse = " ")
    cb <- b[grepl("^\\s*- \\[[ xX]\\]", b)]
    idx <- regmatches(head(b, 14), regexpr("\\[\\[[^]]*[Cc]ookbook[^]]*\\]\\]", head(b, 14)))
    rows[[length(rows) + 1]] <- data.frame(
      file = basename(f), lang = .rn_detect_lang(dir_txt),
      n_tags = length(n$tags), placeholders = length(n$tag_placeholders) + length(n$alias_placeholders),
      ticked = sum(grepl("^\\s*- \\[[xX]\\]", cb)), unticked = sum(grepl("^\\s*- \\[ \\]", cb)),
      has_ingredients_tag = any(grepl("^#ingredients\\s*$", b)),
      is_recipe = ("recipe" %in% n$tags) || any(grepl("^#ingredients\\s*$", b)) || length(cb) > 2,
      index_link = if (length(idx)) idx[1] else NA_character_,
      author = if (!is.null(n$front$author)) as.character(n$front$author)[1] else NA_character_,
      props = paste(names(n$front), collapse = ","),
      h2 = paste(h2, collapse = "|"), stringsAsFactors = FALSE)
    tag_list[[basename(f)]] <- n$tags
  }
  list(notes = if (length(rows)) do.call(rbind, rows) else data.frame(), tags = tag_list)
}

# Tag counts: own (note carries exactly this tag) and rolled up (also counts child tags).
.rn_tag_counts <- function(tag_list) {
  all_tags <- unlist(tag_list, use.names = FALSE)
  own <- if (length(all_tags)) sort(table(all_tags), decreasing = TRUE) else table(character())
  own <- setNames(as.integer(own), names(own))
  parents <- unique(unlist(lapply(names(own), function(t) {
    p <- strsplit(t, "/", fixed = TRUE)[[1]]
    vapply(seq_along(p), function(k) paste(p[1:k], collapse = "/"), "")
  })))
  rollup <- vapply(parents, function(p) sum(vapply(tag_list, function(tt) any(tt == p | startsWith(tt, paste0(p, "/"))), TRUE)), 1L)
  list(own = own, rollup = sort(rollup, decreasing = TRUE))
}

# Nearest used tag for a tag nobody uses: by last path segment, normalised edit distance.
.rn_nearest <- function(tag, used) {
  if (!length(used)) return(list(tag = NA_character_, dist = NA_real_))
  leaf <- function(x) sub(".*/", "", x)
  d <- vapply(used, function(u) {
    a <- leaf(tag); b <- leaf(u)
    as.numeric(utils::adist(a, b)) / max(nchar(a), nchar(b))
  }, 1)
  i <- which.min(d)
  # Only suggest a neighbour that is plausibly a spelling variant; otherwise there is none.
  if (d[i] > 0.5) return(list(tag = NA_character_, dist = NA_real_))
  list(tag = unname(used[i]), dist = unname(round(d[i], 2)))
}

#' Learn the profile from a folder of existing notes (and optionally a .base file).
#'
#' @param dir folder with the user's notes (usually input/).
#' @param base optional path to a .base file whose filters mention tags.
#' @param previous profile from rn_profile_read(); decisions and pending tags are kept.
#' @param author,index_link override what is learned (e.g. confirmed by the user).
rn_learn_profile <- function(dir, base = NULL, previous = NULL, author = NULL, index_link = NULL) {
  sc <- rn_scan_notes(dir)
  nt <- sc$notes
  if (!nrow(nt)) stop("No .md notes found in ", dir, call. = FALSE)
  # Learn only from recipe notes: tagged `recipe` or with an ingredient list. Index pages,
  # shopping lists and templates would distort the counts.
  is_recipe <- nt$is_recipe
  if (!any(is_recipe)) stop("No recipe notes found in ", dir, " (no `recipe` tag, no ingredient list).", call. = FALSE)
  skipped <- nt$file[!is_recipe]
  nt <- nt[is_recipe, , drop = FALSE]
  sc$tags <- sc$tags[nt$file]
  cnt <- .rn_tag_counts(sc$tags)
  mode1 <- function(x) { x <- x[!is.na(x)]; if (length(x)) names(sort(table(x), decreasing = TRUE))[1] else NA_character_ }
  base_info <- if (!is.null(base)) rn_read_base(base) else NULL
  review <- list()
  if (!is.null(base_info)) {
    unused <- base_info$tags[!(base_info$tags %in% names(cnt$rollup))]
    review$base_tags_unused_in_notes <- lapply(unused, function(t) {
      nr <- .rn_nearest(t, names(cnt$own))
      list(base_tag = t, nearest_used_tag = nr$tag, distance = nr$dist)
    })
    review$tags_not_in_base <- setdiff(names(cnt$own), base_info$tags)
  }
  prev_dec <- if (!is.null(previous$decisions)) previous$decisions else list(tag_map = list(), approved_new_tags = character())
  profile <- list(
    profile_version = 1L,
    learned_at = format(Sys.time(), "%Y-%m-%d %H:%M"),
    learned_from = list(folder = basename(normalizePath(dir)), n_notes = nrow(nt),
                        skipped_non_recipe_files = as.list(skipped),
                        base_file = if (!is.null(base)) basename(base) else NULL),
    author = if (!is.null(author)) author else if (!is.null(previous$author)) previous$author else mode1(nt$author),
    index_link = if (!is.null(index_link)) index_link else if (!is.null(previous$index_link)) previous$index_link else mode1(nt$index_link),
    checkbox_default = if (!is.null(previous$checkbox_default)) previous$checkbox_default else
      if (sum(nt$ticked) >= sum(nt$unticked)) "ticked" else "unticked",
    heading_ingredients = "Ingredients", heading_directions = "Directions", image_width = 300L,
    spoons = if (!is.null(previous$spoons)) previous$spoons else "keep",
    note_facts = list(
      languages = lapply(as.list(table(nt$lang[!is.na(nt$lang)])), as.integer),
      notes_with_ingredients_tag = sum(nt$has_ingredients_tag),
      ingredient_items_ticked = sum(nt$ticked), ingredient_items_unticked = sum(nt$unticked),
      notes_with_template_placeholders = sum(nt$placeholders > 0),
      property_keys = lapply(as.list(sort(table(unlist(strsplit(nt$props, ","))), decreasing = TRUE)), as.integer),
      h2_headings = lapply(as.list(sort(table(unlist(strsplit(nt$h2, "\\|"))), decreasing = TRUE)), as.integer)),
    tag_vocabulary = sort(names(cnt$own)),
    tag_counts = as.list(cnt$own),
    tag_counts_rollup = as.list(cnt$rollup),
    review = review,
    decisions = prev_dec,
    pending_new_tags = if (!is.null(previous$pending_new_tags)) previous$pending_new_tags else character()
  )
  # Placeholder tags like "{ tag2 }" are template debris, never vocabulary.
  profile$tag_vocabulary <- profile$tag_vocabulary[rn_tag_ok(profile$tag_vocabulary)]
  profile
}

#' Classify proposed tags against the profile: known, mapped (user decision), new (valid, needs
#' approval), invalid. Never add a tag to a note unless it is known, mapped or approved.
rn_check_tags <- function(tags, profile) {
  tags <- unique(sub("^#", "", tags))
  approved <- profile$decisions$approved_new_tags
  map <- profile$decisions$tag_map
  data.frame(
    tag = tags,
    status = vapply(tags, function(t) {
      if (!rn_tag_ok(t)) "invalid"
      else if (t %in% names(map)) "mapped"
      else if (t %in% profile$tag_vocabulary || t %in% approved) "known"
      else "new"
    }, ""),
    use = vapply(tags, function(t) if (t %in% names(map)) map[[t]] else t, ""),
    stringsAsFactors = FALSE, row.names = NULL)
}

rn_profile_read <- function(path) {
  if (!file.exists(path)) return(NULL)
  yaml::yaml.load(paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n"))
}

#' Write the profile. Refuses without confirmed = TRUE; an existing file is backed up first.
rn_profile_write <- function(profile, path = "recipe-profile.yml", backup_dir = "backup", confirmed = FALSE) {
  if (!isTRUE(confirmed)) stop("Show the user what changes and ask first; then call with confirmed = TRUE.", call. = FALSE)
  header <- paste0("# Recipe notes profile. Learned from existing notes; edit by hand if you like.\n",
                   "# decisions$tag_map: tag you do not want -> tag to use instead.\n",
                   "# decisions$approved_new_tags: tags you approved beyond the learned vocabulary.\n")
  txt <- paste0(header, yaml::as.yaml(profile))
  rn_write_text(txt, dirname(path), basename(path), backup_dir = backup_dir, overwrite = TRUE)
}

#' Short human-readable summary for the report.
rn_profile_summary <- function(profile) {
  v <- profile$tag_counts
  top <- head(unlist(v), 8)
  c(sprintf("Learned from %d notes (%s).", profile$learned_from$n_notes, profile$learned_from$folder),
    sprintf("Vocabulary: %d tags; most used: %s.", length(profile$tag_vocabulary),
            paste0(names(top), " (", top, ")", collapse = ", ")),
    sprintf("Author: %s. Index link: %s. Checkbox default: %s.", profile$author, profile$index_link, profile$checkbox_default),
    if (length(profile$review$base_tags_unused_in_notes)) {
      paste0("Base filters with no matching notes: ",
             paste(vapply(profile$review$base_tags_unused_in_notes, function(x)
               paste0(x$base_tag, " (nearest used: ", x$nearest_used_tag, ")"), ""), collapse = "; "))
    })
}
