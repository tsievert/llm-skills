# Basic behavioural metrics from DeepLabCut (DLC) CSV output in R (base R; smoothing needs `signal`).
# Same definitions and column names as scripts/dlc_metrics.py (see its header for the exact definitions).
#
#   source("scripts/dlc_metrics.R")
#   tracks <- dlc_read("trial1_DLC.csv", bodypart = "spine2")        # list: one data.frame per individual
#   rois <- list(
#     centre = list(type = "circle", centre = c(320, 240), radius = 80),
#     left   = list(type = "rect", x0 = 0, y0 = 0, x1 = 300, y1 = 480),
#     poly   = list(type = "polygon", points = rbind(c(10, 10), c(200, 10), c(100, 150))))
#   res <- dlc_metrics(tracks[[1]], fps = 30, likelihood = 0.9, max_gap = 10, px_per_cm = 12.4,
#                      smooth_window = 5, move_threshold = 2, min_immobile_s = 2, rois = rois)
#   res$summary    # one row;  res$frames  # per-frame table;  dlc_bins(res$frames, 30, 60, names(rois))
#
# ROI coordinates are VIDEO PIXELS (origin top-left, y grows downwards). dlc_read() reads CSV only; for .h5 use
# aniread::read_deeplabcut() (needs Bioconductor rhdf5) plus dlc_from_anipoint() below, or the Python script.
#
# Validation against manual scoring (see references/dlc-basic-metrics.md, "Synthetic validation versus real
# recordings": this script's logic was checked against synthetic data only, never a real recording):
#   v <- validate_immobile(res$frames, manual)   # manual = data.frame(frame, immobile) for ONE recording
#   v$accuracy; v$cohens_kappa; v$confusion

dlc_read <- function(path, bodypart) {
  hdr <- strsplit(readLines(path, n = 4), ",", fixed = TRUE)
  multi <- identical(trimws(hdr[[2]][1]), "individuals")
  nh <- if (multi) 4L else 3L
  hdr <- hdr[seq_len(nh)]
  dat <- utils::read.csv(path, skip = nh, header = FALSE, check.names = FALSE)
  bp <- hdr[[nh - 1L]]; co <- hdr[[nh]]
  ind <- if (multi) hdr[[2]] else rep("animal", length(bp))
  sel <- which(bp == bodypart)
  if (!length(sel)) stop("bodypart '", bodypart, "' not in: ", paste(unique(bp[-1]), collapse = ", "))
  out <- lapply(unique(ind[sel]), function(i) {
    cols <- sel[ind[sel] == i]
    d <- data.frame(x = dat[[cols[co[cols] == "x"]]], y = dat[[cols[co[cols] == "y"]]],
                    likelihood = dat[[cols[co[cols] == "likelihood"]]])
    d
  })
  names(out) <- unique(ind[sel])
  out
}

runs <- function(mask) {
  m <- c(FALSE, mask, FALSE)
  d <- diff(as.integer(m))
  list(start = which(d == 1), end = which(d == -1))   # 1-based start, exclusive-end index (end - start = length)
}

interpolate_short_gaps <- function(v, max_gap) {
  n <- length(v); isn <- is.na(v)
  r <- runs(isn)
  for (k in seq_along(r$start)) {
    a <- r$start[k]; b <- r$end[k]            # NA run is a..(b-1)
    if (a > 1 && b <= n && (b - a) <= max_gap)
      v[a:(b - 1)] <- stats::approx(c(a - 1, b), c(v[a - 1], v[b]), xout = a:(b - 1))$y
  }
  v
}

smooth_segments <- function(v, window, order = 2) {
  if (window <= 1) return(v)
  if (!requireNamespace("signal", quietly = TRUE)) stop("install.packages('signal') for smoothing")
  r <- runs(!is.na(v))
  for (k in seq_along(r$start)) {
    a <- r$start[k]; b <- r$end[k] - 1
    if ((b - a + 1) >= window) v[a:b] <- signal::sgolayfilt(v[a:b], p = order, n = window)
  }
  v
}

in_roi <- function(x, y, spec) {
  switch(spec$type,
    circle = (x - spec$centre[1])^2 + (y - spec$centre[2])^2 <= spec$radius^2,
    rect = x >= min(spec$x0, spec$x1) & x <= max(spec$x0, spec$x1) &
           y >= min(spec$y0, spec$y1) & y <= max(spec$y0, spec$y1),
    polygon = {
      px <- spec$points[, 1]; py <- spec$points[, 2]
      inside <- rep(FALSE, length(x)); j <- length(px)
      for (i in seq_along(px)) {
        straddle <- (py[i] > y) != (py[j] > y)
        xc <- (px[j] - px[i]) * (y - py[i]) / (py[j] - py[i]) + px[i]
        inside <- xor(inside, straddle & (x < xc))
        j <- i
      }
      inside
    },
    stop("unknown ROI type: ", spec$type))
}

dlc_metrics <- function(tr, fps, likelihood = 0.9, max_gap = 5, px_per_cm = NULL, smooth_window = 0,
                        move_threshold = 2, min_immobile_s = 1, rois = list(), min_roi_s = 0) {
  n <- nrow(tr)
  x <- tr$x; y <- tr$y
  bad <- is.na(x) | is.na(y) | is.na(tr$likelihood) | tr$likelihood < likelihood
  x[bad] <- NA; y[bad] <- NA
  miss_raw <- mean(is.na(x))
  x <- interpolate_short_gaps(x, max_gap); y <- interpolate_short_gaps(y, max_gap)
  miss_final <- mean(is.na(x))
  x <- smooth_segments(x, smooth_window); y <- smooth_segments(y, smooth_window)

  scale <- if (is.null(px_per_cm)) 1 else 1 / px_per_cm
  step <- c(NA_real_, sqrt(diff(x)^2 + diff(y)^2) * scale)
  speed <- step * fps
  valid <- !is.na(speed)
  slow <- valid & speed < move_threshold
  r <- runs(slow)
  keep <- (r$end - r$start) / fps >= min_immobile_s
  immobile <- rep(FALSE, n)
  for (k in which(keep)) immobile[r$start[k]:(r$end[k] - 1)] <- TRUE

  frames <- data.frame(frame = seq_len(n) - 1L, time_s = (seq_len(n) - 1L) / fps,
                       x_px = x, y_px = y, speed = speed, immobile = immobile)
  summ <- data.frame(n_frames = n, duration_s = n / fps, frac_missing_raw = miss_raw,
                     frac_missing_final = miss_final, unit = if (is.null(px_per_cm)) "px" else "cm",
                     distance_total = sum(step, na.rm = TRUE),
                     mean_speed = if (any(valid)) mean(speed, na.rm = TRUE) else NA_real_,
                     frac_immobile = sum(immobile) / max(sum(valid), 1),
                     n_immobile_bouts = sum(keep))
  min_roi_frames <- max(1L, as.integer(round(min_roi_s * fps)))
  ok <- !is.na(x)
  for (nm in names(rois)) {
    inside <- rep(FALSE, n)
    inside[ok] <- in_roi(x[ok], y[ok], rois[[nm]])
    frames[[paste0("roi_", nm)]] <- inside
    rr <- runs(inside)
    starts <- rr$start[(rr$end - rr$start) >= min_roi_frames]
    summ[[paste0(nm, "_time_s")]] <- sum(inside) / fps
    summ[[paste0(nm, "_frac_valid")]] <- sum(inside) / max(sum(ok), 1)
    summ[[paste0(nm, "_entries")]] <- length(starts)
    summ[[paste0(nm, "_latency_s")]] <- if (length(starts)) (starts[1] - 1) / fps else NA_real_
  }
  list(summary = summ, frames = frames)
}

cohen_kappa <- function(manual, pred) {
  manual <- as.logical(manual); pred <- as.logical(pred)
  po <- mean(manual == pred)
  pa1 <- mean(manual); pb1 <- mean(pred)
  pe <- pa1 * pb1 + (1 - pa1) * (1 - pb1)
  if (pe == 1) return(if (po == 1) 1 else NA_real_)
  (po - pe) / (1 - pe)
}

# frames: this script's per-frame table (needs frame, immobile). manual: data.frame(frame, immobile) for the
# SAME recording (pre-filter a multi-recording table to one recording before calling). Errors if there is no
# frame overlap, since that usually means a frame-indexing or recording-matching mistake, not zero agreement.
validate_immobile <- function(frames, manual) {
  m <- merge(frames[c("frame", "immobile")], manual[c("frame", "immobile")],
             by = "frame", suffixes = c("_pred", "_manual"))
  if (!nrow(m)) stop("no overlapping frames between frames and manual scoring; check frame indexing/recording")
  manual_l <- as.logical(m$immobile_manual); pred_l <- as.logical(m$immobile_pred)
  list(n_compared = nrow(m), accuracy = mean(manual_l == pred_l),
       cohens_kappa = cohen_kappa(manual_l, pred_l),
       confusion = table(manual = manual_l, predicted = pred_l))
}

dlc_bins <- function(frames, fps, bin_s, roi_names = character()) {
  frames$bin <- floor(frames$time_s / bin_s)
  frames$step <- frames$speed / fps
  out <- do.call(rbind, lapply(split(frames, frames$bin), function(d) {
    o <- data.frame(bin = d$bin[1], bin_start_s = d$bin[1] * bin_s,
                    distance = if (all(is.na(d$step))) NA_real_ else sum(d$step, na.rm = TRUE),
                    mean_speed = mean(d$speed, na.rm = TRUE), frac_immobile = mean(d$immobile))
    for (nm in roi_names) o[[paste0(nm, "_time_s")]] <- sum(d[[paste0("roi_", nm)]]) / fps
    o
  }))
  rownames(out) <- NULL
  out
}

# Convert an animovement::read_deeplabcut() result (works for .h5 when Bioconductor `rhdf5` is installed) into
# the same list of per-individual data.frames that dlc_read() returns. read_deeplabcut() flips y to y-up using
# `video_height`, so pass the SAME height here to restore image coordinates (y down) for pixel ROIs.
#   a <- aniread::read_deeplabcut("trial1_DLC.h5", video_height = 480)
#   tracks <- dlc_from_anipoint(a, "spine2", video_height = 480)
dlc_from_anipoint <- function(data, keypoint, video_height) {
  d <- as.data.frame(data)
  d <- d[d$keypoint == keypoint, , drop = FALSE]
  if (!"individual" %in% names(d)) d$individual <- "animal"
  out <- lapply(split(d, d$individual, drop = TRUE), function(g) {
    g <- g[order(g$time), ]
    data.frame(x = g$x, y = video_height - g$y, likelihood = g$confidence)
  })
  out
}
