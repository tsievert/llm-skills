# Helpers for journal-ready ggplot2 figures. Source this file:
#   source("<skill-dir>/scripts/figure_helpers.R")
# Needs: ggplot2 (>= 3.5; tested 4.0.3), ragg, patchwork, colorspace, png.
# Optional: qpdf on PATH (for check_pdf()), tiff package (for TIFF pixel checks).
# Tested on Windows, R 4.6.0. Not tested on Linux/macOS or on a cluster (fonts differ there).

stopifnot(requireNamespace("ggplot2", quietly = TRUE))

# Journal widths in mm -----------------------------------------------------
# Values come from the sources in references/journal-specs.md (checked 2026-10-23).
# They are a starting point: ALWAYS confirm against the target journal's current
# instructions for authors before submission. NA = not verified.
#   nature: official (research-figure-guide.nature.com); one_half is the upper end of 120-136.
#   elsevier: official (elsevier.com artwork sizing); font_min = 6 pt for sub/superscripts, 7 pt normal text.
#   science: from a third-party summary of Science's instructions (not read from science.org);
#            "one_half" is Science's 2-column width (12.1 cm), the 3-column width is 18.4 cm = two_col.
#   behav_ecol: official OUP "Instructions to authors" (85, 129 or 177 mm wide, up to 238 mm deep).
#   frontiers: official Frontiers author guidelines page (85 / 180 mm; text >= 8 pt; page is old).
#   cell, nature_comms: third-party summaries only. springer_large: one Springer journal's guidelines
#   for large-format journals; Oecologia's own page was not read.
journal_specs <- data.frame(
  journal   = c("nature", "nature_comms", "science", "cell", "elsevier", "springer_large",
                "behav_ecol", "frontiers"),
  one_col   = c(89, 88, 57, 85, 90, 84, 85, 85),
  one_half  = c(136, NA, 121, 114, 140, NA, 129, NA),
  two_col   = c(183, 180, 184, 174, 190, 174, 177, 180),
  max_h     = c(170, NA, NA, NA, NA, 234, 238, NA),
  font_min  = c(5, NA, 5, NA, 6, NA, NA, 8),
  font_max  = c(7, NA, NA, NA, NA, NA, NA, NA),
  stringsAsFactors = FALSE
)

journal_width <- function(journal, cols = c("one", "one_half", "two")) {
  cols <- match.arg(cols)
  col <- c(one = "one_col", one_half = "one_half", two = "two_col")[[cols]]
  row <- journal_specs[journal_specs$journal == journal, ]
  if (nrow(row) == 0) stop("Unknown journal '", journal, "'. Known: ",
                           paste(journal_specs$journal, collapse = ", "), call. = FALSE)
  w <- row[[col]]
  if (is.na(w)) stop("No verified value for ", journal, "/", cols,
                     ". Look it up in the journal's instructions.", call. = FALSE)
  w
}

# Unit conversions ----------------------------------------------------------
# ggplot2 theme text sizes are in pt. geom_text(size=) is in mm unless
# size.unit = "pt". Line widths (linewidth=) are in mm; 1 mm = 2.134 pt of
# stroke in the PDF (checked from the PDF content stream, see SKILL.md).
mm_to_in  <- function(x) x / 25.4
pt_to_lw  <- function(pt) pt / 2.134   # linewidth (mm) giving a stroke of `pt` points
lw_to_pt  <- function(lw) lw * 2.134

# Palettes ------------------------------------------------------------------
# Okabe-Ito (Okabe & Ito 2008; recommended by Wong 2011 and Wilke 2019).
# Base R >= 4.0 ships it, so no extra package is needed. Black is dropped from
# the default set because it is often used for neutral/reference elements.
okabe_ito <- unname(grDevices::palette.colors(9, "Okabe-Ito"))[-1]
names(okabe_ito) <- c("orange", "skyblue", "green", "yellow", "blue", "vermillion", "purple")

scale_colour_ms <- function(..., values = okabe_ito) ggplot2::scale_colour_manual(..., values = values)
scale_fill_ms   <- function(..., values = okabe_ito) ggplot2::scale_fill_manual(..., values = values)

# Theme ---------------------------------------------------------------------
# Small base size so that text is the printed size when the figure is saved at
# its final width (see save_figure()). `family` defaults to "" (device default).
# Prefer an explicit sans-serif the journal accepts (Arial/Helvetica); on a
# machine without Arial use "Liberation Sans" or "Arimo" (metric-compatible).
theme_ms <- function(base_size = 7, base_family = "", base_line_size = base_size / 22,
                     palette = c("viridis", "okabe"), geom_line_pt = 0.5) {
  palette <- match.arg(palette)
  ggplot2::theme_classic(base_size = base_size, base_family = base_family,
                         base_line_size = base_line_size) +
    ggplot2::theme(
      # Default colour palettes: viridis (colour-blind-safe, grayscale-safe) for continuous scales;
      # discrete scales use viridis or Okabe-Ito. Requires ggplot2 >= 4.0 (ignored with a warning before).
      palette.colour.continuous = "viridis", palette.fill.continuous = "viridis",
      palette.colour.discrete = if (palette == "viridis") "viridis" else unname(okabe_ito),
      palette.fill.discrete   = if (palette == "viridis") "viridis" else unname(okabe_ito),
      # Layer defaults in print units: geoms draw lines at `geom_line_pt` points unless set explicitly
      geom = ggplot2::element_geom(linewidth = pt_to_lw(geom_line_pt), borderwidth = pt_to_lw(geom_line_pt)),

      axis.text         = ggplot2::element_text(colour = "black"),
      axis.ticks        = ggplot2::element_line(colour = "black"),
      strip.background  = ggplot2::element_blank(),
      strip.text        = ggplot2::element_text(face = "plain", hjust = 0),
      legend.key.size   = grid::unit(3, "mm"),
      legend.title      = ggplot2::element_text(face = "plain"),
      plot.title.position = "plot",
      plot.tag          = ggplot2::element_text(size = base_size + 1, face = "bold"),
      plot.background   = ggplot2::element_rect(fill = "white", colour = NA)
    )
}

# Multi-panel -----------------------------------------------------------------
# Lowercase tags (Nature style). Use "A" for Science/Cell. Needs patchwork.
panel_tags <- function(tag_levels = "a", base_size = 7) {
  stopifnot(requireNamespace("patchwork", quietly = TRUE))
  patchwork::plot_annotation(
    tag_levels = tag_levels,
    theme = ggplot2::theme(plot.tag = ggplot2::element_text(size = base_size + 1, face = "bold"))
  )
}

# Saving ----------------------------------------------------------------------
# Writes <dir>/<name>.<fmt> at the exact journal size.
#  pdf  : cairo_pdf, vector, fonts embedded
#  svg  : svglite (text stays text; fonts are NOT embedded, only referenced)
#  png  : ragg::agg_png at `dpi`
#  tiff : ragg::agg_tiff at `dpi`, LZW compression
# Returns a data frame of what was written (file, size in mm, pixels, bytes).
save_figure <- function(plot, name, width_mm, height_mm, dir = "figures",
                        formats = c("pdf", "png"), dpi = 600, bg = "white") {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  out <- lapply(formats, function(fmt) {
    path <- file.path(dir, paste0(name, ".", fmt))
    dev <- switch(fmt,
      pdf  = grDevices::cairo_pdf,
      svg  = if (requireNamespace("svglite", quietly = TRUE)) svglite::svglite
             else stop("Install svglite for SVG output.", call. = FALSE),
      png  = ragg::agg_png,
      tiff = function(filename, width, height, units, res, bg, ...)
               ragg::agg_tiff(filename, width = width, height = height, units = units,
                              res = res, background = bg, compression = "lzw"),
      stop("Unsupported format: ", fmt, call. = FALSE))
    args <- list(filename = path, plot = plot, width = width_mm, height = height_mm,
                 units = "mm", device = dev, bg = bg)
    if (fmt %in% c("png", "tiff")) args$dpi <- dpi
    do.call(ggplot2::ggsave, args)
    data.frame(file = path, width_mm = width_mm, height_mm = height_mm,
               px_w = if (fmt %in% c("png", "tiff")) round(mm_to_in(width_mm) * dpi) else NA,
               px_h = if (fmt %in% c("png", "tiff")) round(mm_to_in(height_mm) * dpi) else NA,
               kb = round(file.size(path) / 1024))
  })
  do.call(rbind, out)
}

# PDF check ---------------------------------------------------------------------
# Needs qpdf. Reports embedded fonts and the printed text sizes found in the
# content stream (Tm matrix scale factors; cairo_pdf output) and stroke widths
# in points. Compare with the journal's limits.
check_pdf <- function(path, font_range = NULL, stroke_range = NULL) {
  qpdf <- Sys.which("qpdf")
  if (qpdf == "") stop("qpdf not found on PATH; cannot inspect the PDF.", call. = FALSE)
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  status <- system2(qpdf, c("--qdf", "--object-streams=disable", shQuote(path), shQuote(tmp)),
                    stdout = FALSE, stderr = FALSE)
  if (status > 1) stop("qpdf failed on ", path, call. = FALSE)
  x <- readLines(tmp, warn = FALSE, encoding = "latin1")
  fonts <- trimws(sub("^\\s*/BaseFont\\s*/", "", grep("^\\s*/BaseFont", x, value = TRUE)))
  embedded <- sum(grepl("/FontFile", x))
  tm <- grep(" Tm$", x, value = TRUE)
  sizes <- sort(unique(round(abs(as.numeric(
    vapply(strsplit(tm, " "), \(p) if (abs(as.numeric(p[1])) > 0) p[1] else p[2], "")
  )), 2)))
  wl <- grep(" w$", x, value = TRUE)
  strokes <- sort(unique(round(as.numeric(sub("^.*?([0-9.]+) w$", "\\1", wl, perl = TRUE)), 2)))
  res <- list(fonts = fonts, n_font_files_embedded = embedded,
              text_sizes_pt = sizes, stroke_widths_pt = strokes)
  msgs <- character()
  if (length(fonts) && embedded < length(fonts)) msgs <- c(msgs, "Not all fonts appear embedded.")
  if (!is.null(font_range) && length(sizes)) {
    bad <- sizes[sizes < font_range[1] | sizes > font_range[2]]
    if (length(bad)) msgs <- c(msgs, paste0("Text sizes outside ", font_range[1], "-", font_range[2],
                                            " pt: ", paste(bad, collapse = ", ")))
  }
  if (!is.null(stroke_range) && length(strokes)) {
    bad <- strokes[strokes < stroke_range[1] | strokes > stroke_range[2]]
    if (length(bad)) msgs <- c(msgs, paste0("Strokes outside ", stroke_range[1], "-", stroke_range[2],
                                            " pt: ", paste(bad, collapse = ", ")))
  }
  res$problems <- if (length(msgs)) msgs else "none found"
  res
}

# Colour-vision-deficiency preview ------------------------------------------------
# Renders the plot at final size, simulates deuteranopia, protanopia and
# tritanopia (colorspace::deutan/protan/tritan, severity 1), and writes a PNG
# with the four versions in a 2 x 2 grid (original, deutan; protan, tritan).
# A simulation is an approximation and not
# a substitute for also encoding groups by shape, line type or direct labels.
cvd_preview <- function(plot, path, width_mm = 89, height_mm = 60, dpi = 150) {
  stopifnot(requireNamespace("colorspace", quietly = TRUE), requireNamespace("png", quietly = TRUE))
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f))
  ggplot2::ggsave(f, plot, width = width_mm, height = height_mm, units = "mm",
                  dpi = dpi, device = ragg::agg_png, bg = "white")
  img <- png::readPNG(f)[, , 1:3]
  d <- dim(img)
  hex <- grDevices::rgb(img[, , 1], img[, , 2], img[, , 3])
  sim <- function(fun) {
    s <- colorspace::hex2RGB(fun(hex, severity = 1))@coords
    array(pmin(pmax(s, 0), 1), dim = d)
  }
  panels <- list(img, sim(colorspace::deutan), sim(colorspace::protan), sim(colorspace::tritan))
  gap <- array(1, dim = c(d[1], 10, 3))
  vgap <- array(1, dim = c(10, 2 * d[2] + 10, 3))
  top <- abind_cols(abind_cols(panels[[1]], gap), panels[[2]])
  bot <- abind_cols(abind_cols(panels[[3]], gap), panels[[4]])
  row <- abind_rows(abind_rows(top, vgap), bot)
  png::writePNG(row, path)
  invisible(path)
}
abind_cols <- function(a, b) {
  out <- array(0, dim = c(dim(a)[1], dim(a)[2] + dim(b)[2], 3))
  out[, seq_len(dim(a)[2]), ] <- a
  out[, dim(a)[2] + seq_len(dim(b)[2]), ] <- b
  out
}
abind_rows <- function(a, b) {
  out <- array(0, dim = c(dim(a)[1] + dim(b)[1], dim(a)[2], 3))
  out[seq_len(dim(a)[1]), , ] <- a
  out[dim(a)[1] + seq_len(dim(b)[1]), , ] <- b
  out
}
