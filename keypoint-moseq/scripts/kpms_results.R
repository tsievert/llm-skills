# Helpers for reading keypoint-MoSeq results.h5 in R (base R + hdf5r).
# source("scripts/kpms_results.R")
#
#   frames <- kpms_read_frames("proj/run1/results.h5")      # frame-level table
#   bouts  <- kpms_bouts(frames, fps = 30)                  # one row per syllable run
#   usage  <- kpms_usage(bouts)                             # recording x syllable, zeros included
#   trans  <- kpms_transitions(bouts)                       # recording x from x to
#
# Column definitions match scripts/kpms_summarise_results.py. Merge your own metadata
# (animal, group, session) by `recording` before modelling.

kpms_read_frames <- function(path, latent = FALSE) {
  stopifnot(requireNamespace("hdf5r", quietly = TRUE), file.exists(path))
  f <- hdf5r::H5File$new(path, mode = "r")
  on.exit(f$close_all(), add = TRUE)

  # Recordings are groups holding a `syllable` dataset. Names with "/" (kpms
  # path_in_name = TRUE) are nested groups, so search recursively.
  recs <- character()
  walk <- function(grp, prefix) {
    for (nm in hdf5r::list.groups(grp, recursive = FALSE)) {
      p <- if (nzchar(prefix)) paste(prefix, nm, sep = "/") else nm
      g <- grp[[nm]]
      if ("syllable" %in% hdf5r::list.datasets(g, recursive = FALSE)) recs <<- c(recs, p)
      walk(g, p)
    }
  }
  walk(f, "")
  if (!length(recs)) stop("No recording groups with a 'syllable' dataset in ", path)

  # hdf5r reverses dimension order relative to h5py: a (frames x k) dataset arrives as k x frames.
  as_cols <- function(x, n) {
    if (is.null(dim(x))) return(matrix(x, ncol = 1))
    if (nrow(x) == n && ncol(x) != n) x else t(x)
  }

  out <- lapply(sort(recs), function(r) {
    z <- as.integer(f[[paste0(r, "/syllable")]]$read())
    n <- length(z)
    cen <- as_cols(f[[paste0(r, "/centroid")]]$read(), n)
    df <- data.frame(
      recording = r,
      frame = seq_len(n) - 1L,
      syllable = z,
      heading = as.numeric(f[[paste0(r, "/heading")]]$read()),
      centroid_x = cen[, 1],
      centroid_y = cen[, 2],
      stringsAsFactors = FALSE
    )
    if (latent) {
      lat <- as_cols(f[[paste0(r, "/latent_state")]]$read(), n)
      colnames(lat) <- paste0("latent_", seq_len(ncol(lat)) - 1L)
      df <- cbind(df, lat)
    }
    df
  })
  do.call(rbind, out)
}

kpms_bouts <- function(frames, fps, min_bout_frames = 1L) {
  out <- lapply(split(frames, frames$recording), function(d) {
    d <- d[order(d$frame), ]
    z <- d$syllable
    chg <- which(diff(z) != 0) + 1L
    starts <- c(1L, chg)
    ends <- c(chg, length(z) + 1L)
    b <- data.frame(
      recording = d$recording[1],
      syllable = z[starts],
      start_frame = starts - 1L,
      end_frame = ends - 1L
    )
    b$n_frames <- b$end_frame - b$start_frame
    b$duration_s <- b$n_frames / fps
    b$bout_index <- seq_len(nrow(b)) - 1L
    b[b$n_frames >= min_bout_frames, ]
  })
  b <- do.call(rbind, out)
  rownames(b) <- NULL
  b[order(b$recording, b$bout_index), ]
}

kpms_usage <- function(bouts) {
  recs <- sort(unique(bouts$recording))
  sylls <- sort(unique(bouts$syllable))
  grid <- expand.grid(syllable = sylls, recording = recs, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  grid <- grid[, c("recording", "syllable")]
  agg <- aggregate(
    cbind(n_frames, n_bouts = 1L) ~ recording + syllable, data = bouts,
    FUN = sum
  )
  agg$mean_bout_s <- aggregate(duration_s ~ recording + syllable, data = bouts, FUN = mean)$duration_s
  u <- merge(grid, agg, by = c("recording", "syllable"), all.x = TRUE)
  u$n_frames[is.na(u$n_frames)] <- 0L
  u$n_bouts[is.na(u$n_bouts)] <- 0L
  u$frame_fraction <- u$n_frames / ave(u$n_frames, u$recording, FUN = sum)
  u$bout_fraction <- u$n_bouts / ave(u$n_bouts, u$recording, FUN = sum)
  u[order(u$recording, u$syllable), ]
}

kpms_transitions <- function(bouts) {
  out <- lapply(split(bouts, bouts$recording), function(b) {
    b <- b[order(b$bout_index), ]
    s <- b$syllable
    if (length(s) < 2) return(NULL)
    d <- data.frame(recording = b$recording[1], from = s[-length(s)], to = s[-1])
    aggregate(n ~ recording + from + to, data = cbind(d, n = 1L), FUN = sum)
  })
  t <- do.call(rbind, out)
  rownames(t) <- NULL
  t
}
