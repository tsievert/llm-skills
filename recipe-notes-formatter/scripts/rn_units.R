# rn_units.R -- unit conversion for recipe text (ingredient lines and directions).
# Source with: source("<skill-dir>/scripts/rn_units.R", encoding = "UTF-8")
#
# Policy (see references/units.md): only NON-metric units are converted. Local metric units
# (g, kg, ml, l, dl, cl, msk, tsk, krm, kkp, EL, TL, rkl, tl, ...) are never touched. English
# tbsp/tsp stay as written unless spoons = "ml". Ambiguous units (German Tasse) are flagged,
# not converted. Nothing is invented: a conversion without a known factor is left alone.

.rn_ufrac <- c("\u00bd" = 1/2, "\u2153" = 1/3, "\u2154" = 2/3, "\u00bc" = 1/4, "\u00be" = 3/4,
               "\u215b" = 1/8, "\u215c" = 3/8, "\u215d" = 5/8, "\u215e" = 7/8)
.rn_ufrac_cls <- "[\u00bd\u2153\u2154\u00bc\u00be\u215b\u215c\u215d\u215e]"

# One quantity: mixed number, digit+unicode fraction, text fraction, lone unicode fraction,
# decimal with dot or comma, integer. Order matters (longest first).
.rn_num_re <- paste0("(?:\\d+\\s+\\d+/\\d+|\\d+\\s?", .rn_ufrac_cls, "|\\d+/\\d+|", .rn_ufrac_cls,
                     "|\\d+[.,]\\d+|\\d+)")

# Units we recognise as convertible or ambiguous (matched case-insensitively).
.rn_unit_re <- paste0("fl\\.?\\s?oz\\.?|fluid\\s+ounces?|cups?|ounces?|oz\\.?|pounds?|lbs?\\.?|",
                      "pints?|pt\\.?|quarts?|qt\\.?|gallons?|gal\\.?|sticks?|",
                      "tablespoons?|tbsp\\.?|tbs\\.?|teaspoons?|tsp\\.?|tassen?")

#' Parse a quantity string ("1 1/2", "1\u00bd", "\u00bd", "1,5", "2") to a number.
rn_parse_num <- function(s) {
  s <- trimws(s)
  total <- 0
  uf <- regmatches(s, regexpr(.rn_ufrac_cls, s))
  if (length(uf) == 1) {
    total <- total + .rn_ufrac[[uf]]
    s <- trimws(sub(paste0("\\s?", .rn_ufrac_cls), "", s))
  }
  if (nzchar(s)) {
    for (p in strsplit(s, "\\s+")[[1]]) {
      if (grepl("/", p, fixed = TRUE)) {
        ab <- as.numeric(strsplit(p, "/", fixed = TRUE)[[1]])
        total <- total + ab[1] / ab[2]
      } else {
        total <- total + as.numeric(sub(",", ".", p, fixed = TRUE))
      }
    }
  }
  total
}

#' Round to a cooking-sensible value. Below 20: halves; below 250: steps of 5; otherwise steps of 10.
rn_nice_round <- function(x) {
  if (x < 20) return(round(x * 2) / 2)
  if (x < 250) return(5 * round(x / 5))
  10 * round(x / 10)
}

# Format a number with the requested decimal mark; integers without decimals.
.rn_fmt <- function(x, dec = ".") {
  if (abs(x - round(x)) < 1e-9) return(as.character(round(x)))
  out <- format(round(x, 2), nsmall = 1, trim = TRUE)
  if (dec != ".") out <- sub(".", dec, out, fixed = TRUE)
  out
}

# Convert a base value (ml or g) to the display pair (number, unit), switching to l / kg from 1000.
.rn_display <- function(x, base, dec) {
  if (x >= 1000) {
    v <- round(x / 1000, 2)
    return(paste(.rn_fmt(v, dec), if (base == "ml") "l" else "kg"))
  }
  paste(.rn_fmt(x, dec), base)
}

# Look up what to do with a unit word. Returns list(kind, factor, base, flag).
.rn_unit_info <- function(u, spoons = "keep") {
  k <- tolower(gsub("[.\\s]", "", u, perl = TRUE))
  none <- list(kind = "keep", factor = NA_real_, base = NA_character_, flag = NA_character_)
  hit <- function(kind, factor = NA_real_, base = NA_character_, flag = NA_character_) {
    list(kind = kind, factor = factor, base = base, flag = flag)
  }
  if (grepl("^(floz|fluidounces?)$", k)) return(hit("convert", 29.5735, "ml"))
  if (grepl("^cups?$", k)) return(hit("convert", 236.588, "ml"))
  if (grepl("^(oz|ounces?)$", k)) return(hit("convert", 28.3495, "g",
                                             "oz read as weight; check if the item is a liquid"))
  if (grepl("^(lbs?|pounds?)$", k)) return(hit("convert", 453.592, "g"))
  if (grepl("^(pints?|pt)$", k)) return(hit("convert", 473.176, "ml"))
  if (grepl("^(quarts?|qt)$", k)) return(hit("convert", 946.353, "ml"))
  if (grepl("^(gallons?|gal)$", k)) return(hit("convert", 3785.41, "ml"))
  if (grepl("^sticks?$", k)) return(hit("stick", 113, "g"))
  if (grepl("^(tablespoons?|tbsp|tbs)$", k)) {
    return(if (spoons == "ml") hit("convert", 15, "ml") else none)
  }
  if (grepl("^(teaspoons?|tsp)$", k)) {
    return(if (spoons == "ml") hit("convert", 5, "ml") else none)
  }
  if (grepl("^tassen?$", k)) {
    return(hit("flag", flag = "Tasse is about 250 ml in German recipes but a US cup is 240 ml; left as written"))
  }
  none
}

#' Convert non-metric quantities anywhere in a text (ingredient line or direction step).
#'
#' @param text one string.
#' @param spoons "keep" (default, English tbsp/tsp stay) or "ml" (15 / 5 ml).
#' @param decimal decimal mark for results: "." or "," (use "," for de, sv, fi notes).
#' @return list(text, changes = data.frame(from, to), flags = character()).
rn_convert_units <- function(text, spoons = c("keep", "ml"), decimal = ".") {
  spoons <- match.arg(spoons)
  pat <- paste0("(?<![\\p{L}\\d])(", .rn_num_re, ")(?:\\s*([-\u2013])\\s*(", .rn_num_re, "))?\\s*(",
                .rn_unit_re, ")(?![\\p{L}])")
  m <- gregexpr(pat, text, perl = TRUE, ignore.case = TRUE)[[1]]
  changes <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)
  flags <- character()
  if (m[1] == -1) return(list(text = text, changes = changes, flags = flags))

  starts <- as.integer(m)
  lens <- attr(m, "match.length")
  cs <- attr(m, "capture.start")
  cl <- attr(m, "capture.length")
  cap <- function(i, j) substr(text, cs[i, j], cs[i, j] + cl[i, j] - 1)

  out <- character()
  cursor <- 1L
  for (i in seq_along(starts)) {
    s <- starts[i]
    e <- s + lens[i] - 1L
    if (s < cursor) next            # swallowed by a previous bracket replacement
    q1 <- cap(i, 1); sep <- cap(i, 2); q2 <- cap(i, 3); unit <- cap(i, 4)
    info <- .rn_unit_info(unit, spoons)
    orig <- substr(text, s, e)
    if (info$kind == "keep") next
    if (info$kind == "flag") {
      flags <- c(flags, paste0("'", orig, "': ", info$flag))
      next
    }
    if (info$kind == "stick") {
      if (!grepl("butter|margarine|sm\u00f6r|voi\\b", text, ignore.case = TRUE, perl = TRUE)) {
        flags <- c(flags, paste0("'", orig, "': stick only converted for butter; left as written"))
        next
      }
    }
    # A bracketed metric figure right after the unit, e.g. "1 cup (240 ml)", replaces the imperial value.
    rest <- substr(text, e + 1L, nchar(text))
    br <- regmatches(rest, regexec("^\\s*\\(\\s*(\\d+(?:[.,]\\d+)?)\\s*(kg|g|ml|dl|cl|l)\\s*\\)", rest,
                                   perl = TRUE))[[1]]
    if (length(br) == 3) {
      new <- paste(br[2], br[3])
      consumed_to <- e + nchar(br[1])
      flags <- c(flags, paste0("'", orig, "': used the bracketed metric value from the source"))
    } else {
      f <- function(q) rn_nice_round(rn_parse_num(q) * info$factor)
      v1 <- f(q1)
      if (nzchar(q2)) {
        v2 <- f(q2)
        if (max(v1, v2) >= 1000) {
          div <- 1000; ub <- if (info$base == "ml") "l" else "kg"
          new <- paste0(.rn_fmt(round(v1 / div, 2), decimal), sep, .rn_fmt(round(v2 / div, 2), decimal), " ", ub)
        } else {
          new <- paste0(.rn_fmt(v1, decimal), sep, .rn_fmt(v2, decimal), " ", info$base)
        }
      } else {
        new <- .rn_display(v1, info$base, decimal)
      }
      consumed_to <- e
      if (!is.na(info$flag)) flags <- c(flags, paste0("'", orig, "': ", info$flag))
    }
    out <- c(out, substr(text, cursor, s - 1L), new)
    changes[nrow(changes) + 1, ] <- list(orig, new)
    cursor <- consumed_to + 1L
  }
  out <- c(out, substr(text, cursor, nchar(text)))
  list(text = paste0(out, collapse = ""), changes = changes, flags = unique(flags))
}

#' Convert Fahrenheit oven temperatures ("350\u00b0F", "350 degrees F", "350-375 \u00b0F") to Celsius,
#' rounded to the nearest 5 degrees. Plain "350 degrees" without F is left alone.
rn_convert_temps <- function(text) {
  pat <- "(?<![\\p{L}\\d])(\\d{2,3})(?:\\s*[-\u2013]\\s*(\\d{2,3}))?\\s*(?:[\u00b0\u00ba\u02da]\\s*F|degrees?\\s+F(?:ahrenheit)?|deg\\.?\\s*F)(?![\\p{L}])"
  m <- gregexpr(pat, text, perl = TRUE, ignore.case = FALSE)[[1]]
  changes <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)
  if (m[1] == -1) return(list(text = text, changes = changes, flags = character()))
  starts <- as.integer(m); lens <- attr(m, "match.length")
  cs <- attr(m, "capture.start"); cl <- attr(m, "capture.length")
  to_c <- function(f) 5 * round(((as.numeric(f) - 32) * 5 / 9) / 5)
  out <- character(); cursor <- 1L
  for (i in seq_along(starts)) {
    a <- substr(text, cs[i, 1], cs[i, 1] + cl[i, 1] - 1)
    b <- if (cl[i, 2] > 0) substr(text, cs[i, 2], cs[i, 2] + cl[i, 2] - 1) else ""
    new <- if (nzchar(b)) paste0(to_c(a), "\u2013", to_c(b), " \u00b0C") else paste0(to_c(a), " \u00b0C")
    orig <- substr(text, starts[i], starts[i] + lens[i] - 1L)
    out <- c(out, substr(text, cursor, starts[i] - 1L), new)
    changes[nrow(changes) + 1, ] <- list(orig, new)
    cursor <- starts[i] + lens[i]
  }
  out <- c(out, substr(text, cursor, nchar(text)))
  list(text = paste0(out, collapse = ""), changes = changes, flags = character())
}

#' Convert inch measurements ("9-inch pan", "9x13 inches") to centimetres (nearest 1 cm,
#' nearest 0.5 cm below 5 cm).
rn_convert_lengths <- function(text, decimal = ".") {
  n <- "\\d+(?:[.,]\\d+)?"
  pat <- paste0("(?<![\\p{L}\\d])(", n, ")(?:\\s*[x\u00d7]\\s*(", n, "))?\\s*-?\\s*(?:inch(?:es)?)(?![\\p{L}])")
  m <- gregexpr(pat, text, perl = TRUE, ignore.case = TRUE)[[1]]
  changes <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)
  if (m[1] == -1) return(list(text = text, changes = changes, flags = character()))
  starts <- as.integer(m); lens <- attr(m, "match.length")
  cs <- attr(m, "capture.start"); cl <- attr(m, "capture.length")
  to_cm <- function(x) { v <- as.numeric(sub(",", ".", x, fixed = TRUE)) * 2.54
    if (v < 5) round(v * 2) / 2 else round(v) }
  out <- character(); cursor <- 1L
  for (i in seq_along(starts)) {
    a <- substr(text, cs[i, 1], cs[i, 1] + cl[i, 1] - 1)
    b <- if (cl[i, 2] > 0) substr(text, cs[i, 2], cs[i, 2] + cl[i, 2] - 1) else ""
    new <- if (nzchar(b)) paste0(.rn_fmt(to_cm(a), decimal), "x", .rn_fmt(to_cm(b), decimal), " cm")
           else paste0(.rn_fmt(to_cm(a), decimal), " cm")
    orig <- substr(text, starts[i], starts[i] + lens[i] - 1L)
    out <- c(out, substr(text, cursor, starts[i] - 1L), new)
    changes[nrow(changes) + 1, ] <- list(orig, new)
    cursor <- starts[i] + lens[i]
  }
  out <- c(out, substr(text, cursor, nchar(text)))
  list(text = paste0(out, collapse = ""), changes = changes, flags = character())
}

#' Apply every conversion to one string. Use for ingredient lines and for each direction step.
#' @return list(text, changes = data.frame(from, to, rule), flags)
rn_convert_all <- function(text, spoons = c("keep", "ml"), decimal = ".") {
  spoons <- match.arg(spoons)
  steps <- list(units = rn_convert_units(text, spoons, decimal))
  steps$temps <- rn_convert_temps(steps$units$text)
  steps$lengths <- rn_convert_lengths(steps$temps$text, decimal)
  ch <- do.call(rbind, lapply(names(steps), function(nm) {
    d <- steps[[nm]]$changes
    if (nrow(d)) cbind(d, rule = nm, stringsAsFactors = FALSE) else NULL
  }))
  if (is.null(ch)) ch <- data.frame(from = character(), to = character(), rule = character())
  list(text = steps$lengths$text, changes = ch, flags = unique(unlist(lapply(steps, `[[`, "flags"))))
}

#' Convert a vector of lines; returns the new lines and a tidy table of every change and flag.
rn_convert_lines <- function(lines, spoons = c("keep", "ml"), decimal = ".") {
  spoons <- match.arg(spoons)
  res <- lapply(lines, rn_convert_all, spoons = spoons, decimal = decimal)
  report <- do.call(rbind, lapply(seq_along(res), function(i) {
    r <- res[[i]]
    parts <- list()
    if (nrow(r$changes)) parts$c <- data.frame(line = i, type = "changed", from = r$changes$from,
                                                to = r$changes$to, stringsAsFactors = FALSE)
    if (length(r$flags)) parts$f <- data.frame(line = i, type = "flag", from = r$flags, to = NA_character_,
                                                stringsAsFactors = FALSE)
    if (length(parts)) do.call(rbind, parts) else NULL
  }))
  if (is.null(report)) report <- data.frame(line = integer(), type = character(), from = character(),
                                            to = character())
  list(lines = vapply(res, `[[`, character(1), "text"), report = report)
}
