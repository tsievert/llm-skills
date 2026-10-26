# Basic metrics from DLC output: distance, speed, immobility, ROI occupancy

## Contents

- [Pipeline (order matters)](#pipeline-order-matters)
- [Scripts (same definitions in R and Python; tested to give identical results)](#scripts-same-definitions-in-r-and-python-tested-to-give-identical-results)
- [Worked numbers: why smoothing and thresholds matter (synthetic data)](#worked-numbers-why-smoothing-and-thresholds-matter-synthetic-data)
- [Metric notes](#metric-notes)
- [Statistics (short)](#statistics-short)
- [Existing tools (documentation read 2026-10-23; trajr, animovement and movement were installed and run)](#existing-tools-documentation-read-2026-10-23-trajr-animovement-and-movement-were-installed-and-run)
- [animovement in R (installed and tested 2026-10-23)](#animovement-in-r-installed-and-tested-2026-10-23)
- [movement in Python (installed and tested 2026-10-23)](#movement-in-python-installed-and-tested-2026-10-23)
- [Synthetic validation versus real recordings](#synthetic-validation-versus-real-recordings)
- [Caveats](#caveats)


Use this for hypothesis-driven measures (how far, how fast, how long in a zone, how often immobile). It complements keypoint-MoSeq (unsupervised syllables); the two can be run on the same DLC files.

## Pipeline (order matters)

1. **Inspect the raw file**: header rows (3 for single animal: scorer, bodyparts, coords; 4 with an `individuals` row for multi-animal), likelihood distribution per keypoint, fraction of low-likelihood frames, jumps. DLC's own plots (`plot_trajectories`) show likelihood and the histogram of frame-to-frame differences; both should look clean before trusting any metric.
2. **Mask** points below a likelihood threshold (to NaN). Choose the threshold from the distribution, not from convention; DLC has `pcutoff` in `config.yaml`, other tools use e.g. 0.95 (DLCAnalyzer example). Report it.
3. **Interpolate short gaps only** (`--max-gap-frames`, in frames). Long gaps stay missing; never bridge seconds of lost tracking, because that fabricates movement or immobility.
4. **Calibrate** pixels to cm with a known length in the arena (`px_per_cm = pixel distance / real distance` between two landmarks, ideally across several landmarks). Redo per camera setup. A tilted camera or lens distortion makes px_per_cm vary across the image; say so if the arena fills a small part of the frame or the view is oblique.
5. **Smooth** positions (Savitzky-Golay, order 2, window in frames, odd). Window choice is a trade-off (see numbers below); give it in seconds in the methods and keep it fixed across groups.
6. **Derive** speed, distance, immobility bouts, ROI membership, entries, latency.
7. **Aggregate** per animal/session/time bin and merge with metadata, then analyse (statistics section).

## Scripts (same definitions in R and Python; tested to give identical results)

| Script | Input | Notes |
|---|---|---|
| `scripts/dlc_metrics.py` | DLC `.csv` or `.h5`, single or multi-animal | CLI; writes `summary.csv` (one row per animal), `frames/<recording>.csv`, optional `bins.csv`. Needs numpy, pandas, scipy (and pytables for `.h5`) |
| `scripts/dlc_metrics.R` | DLC `.csv`; `.h5` via `aniread::read_deeplabcut()` (needs rhdf5) and `dlc_from_anipoint()` | Functions `dlc_read`, `dlc_metrics`, `dlc_bins`; base R plus `signal` (CRAN) for smoothing |

Definitions (stated in both file headers):

- `speed[t] = distance(pos[t], pos[t-1]) * fps` (cm/s with `--px-per-cm`, else px/s); `distance_total` sums valid steps; steps touching a NaN are skipped.
- Immobile frame: speed below `--move-threshold`; a bout needs at least `--min-immobile-s`. Call it "freezing" only after validation (below).
- ROI occupancy uses the cleaned, smoothed position; missing frames count as outside, and `*_frac_valid` divides by frames with a valid position. Entry = start of a run of in-ROI frames lasting at least `--min-roi-s`.
- ROIs are JSON in **video pixel coordinates (origin top-left, y downward)**: `circle`, `rect`, `polygon` (even-odd rule, vertices in order). Overlapping ROIs are allowed.

Checks done while writing them: R and Python summaries, frame tables and bins agree to 1e-8 on synthetic single- and multi-animal DLC-format CSVs; `.h5` and `.csv` readers agree; the speed and path length equal `trajr::TrajDerivatives` / `TrajLength` on a gap-free segment (trajr 1.5.1). Not tested on real recordings.

### Always plot the ROIs over the tracks

Wrong ROI coordinates (flipped y, different crop or resolution, drawn on another camera setup) are the most likely silent error. Overlay ROIs on the track or on a frame grabbed from the same video before computing anything:

```r
ggplot(fr, aes(x_px, y_px)) + geom_path(colour = "grey40", linewidth = 0.3) +
  geom_point(data = subset(fr, immobile), colour = "red", size = 0.4) +
  annotate("rect", xmin = 0, xmax = 300, ymin = 0, ymax = 480, fill = NA, colour = "darkgreen") +
  scale_y_reverse() + coord_equal()      # reverse y: image coordinates grow downwards
```

If tracking was run on cropped or resized videos, check that the ROI coordinates are in the same frame of reference as the DLC output.

## Worked numbers: why smoothing and thresholds matter (synthetic data)

Synthetic animal, 120 s at 30 fps, alternating 10 s blocks of movement and true stillness with 0.25 px tracking jitter, 12.4 px/cm, immobility threshold 2 cm/s, minimum bout 2 s:

| Setting | Total distance (cm) | Fraction immobile | Immobile bouts found |
|---|---|---|---|
| No smoothing | 305 | 0.04 | 2 |
| Savitzky-Golay window 5 | 264 | 0.50 | 6 |

True stillness was 50% of the time. Jitter alone made frame-to-frame speeds exceed the threshold often enough to break every immobility run, and it inflated path length. This is a toy example, not a recommendation: on real data choose smoothing window, threshold and minimum duration by checking against manually scored video, and report them.

## Metric notes

- **Body part**: use a stable central point (back/spine/centre) for locomotion, ROI occupancy and distance; the nose is noisier and fits nose-poke or sniffing-zone questions. Say which point defines "in the zone".
- **Distance and speed**: report distance per time bin, mean speed and, if needed, speed while moving (speed above the threshold). Maximum speed is dominated by tracking glitches; prefer percentiles.
- **Immobility/freezing**: threshold plus minimum duration on a body-centre keypoint. Validate against manual scoring on a subset (agreement, e.g. Cohen's kappa or per-frame confusion) before reporting. Tracking jitter, breathing and head movements make the thresholds setup-specific. DLCAnalyzer exposes movement cut-offs and a floating cut-off (default 0.03 in its FST example) but no hard-coded freezing definition; its units are the tool's own, so do not copy them.
- **ROI**: time, entries, latency to first entry, share of valid time. Positions near a border flicker in and out; use smoothing and `--min-roi-s`, or a hysteresis rule, and state it. Time in zone is a share of a time budget, so also report total valid time.
- **Path shape**: straightness and sinuosity (`trajr::TrajStraightness`, `TrajSinuosity2` after `TrajRediscretize`; Benhamou 2004 correction per the trajr docs), turning angles (`movement.kinematics.compute_turning_angle`). Results depend on sampling and smoothing; compare only within one pipeline.
- **Thigmotaxis/centre use**: define wall and centre ROIs from the arena geometry, or use distance to the wall; the centre share depends on the zone you draw.
- **Multi-animal**: check identity swaps first (they create impossible jumps in speed). Pairwise distance between animals is available as `movement.kinematics.compute_pairwise_distances`. In DLC multi-animal files the `individuals` row names each animal; the scripts output one row per individual.
- **Time bins**: use fixed bins from a common start (stimulus or session start) and equal durations across animals; trim or flag sessions with different lengths.

## Statistics (short)

Full guidance (tidy metadata layout, one model per metric type, repeated sessions, covariates, censored latencies, GAMs for time courses, multiplicity, reporting) is in [statistical-analysis.md](statistical-analysis.md); runnable simulated templates are in `scripts/stats_demo.R`.

- Unit: animal. Several sessions or bins per animal need a random intercept for animal (and session where relevant) or aggregation per animal; frames are not independent.
- Time courses (distance per minute, ROI time per bin): mixed models or GAMs (see `gam-mgcv`, `mixed-models-glmm` once it exists) with bin as the covariate. Do not run a t-test per bin.
- Proportions of time (in ROI, immobile) are bounded: use binomial/beta-binomial with frame counts and an animal random effect, not a Gaussian model on percentages.
- Decide beforehand which metrics are primary, how tracks with too much missing data (`frac_missing_final`) are excluded, and report exclusions. Missingness can differ by group or zone (animals near the walls are tracked worse), which biases ROI results.

## Existing tools (documentation read 2026-10-23; trajr, animovement and movement were installed and run)

| Tool | Language | What it offers | Notes |
|---|---|---|---|
| `movement` (neuroinformatics-unit) | Python (docs v0.17.0; `pip install movement`) | `load_poses.from_dlc_file(path, fps=)`, `filtering` (`filter_by_confidence`, `interpolate_over_time`, `rolling_filter`, `savgol_filter`), `kinematics` (`compute_velocity`, `compute_speed`, `compute_acceleration`, `compute_path_length`, `compute_path_straightness`, `compute_turning_angle`, `compute_pairwise_distances`), `roi` (`PolygonOfInterest`, `LineOfInterest`, `compute_region_occupancy`, `load_rois`) | Installed and tested 2026-10-23, see the next section. Its docs recommend `animovement` for R |
| `animovement` | R (R-universe, not CRAN) | Reads DLC and many other sources, QC checks, masking/interpolation/filters, kinematics, ROI masking, plots | Installed and tested 2026-10-23 with the user's permission, see the next section |
| `trajr` | R (CRAN 1.5.1) | `TrajFromCoords(track, xCol, yCol, timeCol, fps, spatialUnits)`, `TrajSmoothSG(trj, p, n)`, `TrajDerivatives`, `TrajSpeedIntervals(trj, fasterThan, slowerThan)`, `TrajStraightness`, `TrajSinuosity2` | Tested for speed and length. The vignette's argument naming for smoothing is inconsistent; check `?TrajSmoothSG` |
| `DLC2Kinematics` | Python (`pip install dlc2kinematics`) | `load_data`, `compute_velocity`, `compute_acceleration` (joint angles and more per its README) | README says API may change |
| `DLCAnalyzer` (ETHZ-INS) | R scripts, GPL-3.0, not a package | `ReadDLCDataFromCSV`, `CleanTrackingData`, `CalibrateTrackingData`, `AddZones`, `CalculateMovement`, `ZoneReport`, presets for open field, elevated plus maze, forced swim | Good worked examples for those paradigms; maintenance status unclear; needs `sp`, `imputeTS` |
| `dlcpr` | R, GitHub only | `read.dlc`, `read.all`, `get_velocity` (3rd-order approximation) | GitHub source, would need permission; small |
| `DeepOF` | Python | Time-in-zone, climbing, basic social interaction motifs for rodents, plus unsupervised embeddings | Heavier framework; relies on DLC/SLEAP output |
| `DLCutils/time_in_each_roi.py` | Python | Time per rectangular ROI | **Not recommended as is**: no likelihood filtering and, in the version read, the default `check_inroi=True` assigns every frame to its nearest ROI centre without a bounds check (the docstring says the opposite). Use proper point-in-region tests, as in this skill's scripts |

For a first look in Python, `movement` plus a short script is usually enough; for R, animovement (front end and kinematics) plus the scripts here (polygon ROIs, entries, immobility, bins) cover most needs.

## animovement in R (installed and tested 2026-10-23)

animovement is a family of R packages by Mikkel Roald-Arbøl (`aniread`, `anicheck`, `aniprocess`, `anispace`, `animetric`, `anivis`, `anicore`). It is on R-universe, **not CRAN**, so installing or updating needs the user's explicit permission (given for this install on 2026-10-23; ask again for updates or other non-CRAN packages):

```r
install.packages("animovement", repos = c("https://animovement.r-universe.dev", "https://cloud.r-project.org"))
```

Tested with animovement 0.8.0.9002 (anicore 0.8.0.9009, aniread 0.7.0.9006, aniprocess 0.5.0.9003, animetric 0.5.0.9006) on R 4.6.0. These are development-numbered builds, so record versions and expect API changes.

Recipe that ran on synthetic single- and multi-animal DLC CSVs (filter to one keypoint first; the `*_across` functions work on whole data frames):

```r
library(animovement)
x <- aniread::read_deeplabcut("trial1_DLC.csv", video_height = 480) |>       # set the real video height (see gotchas)
  anicore::set_metadata(sampling_rate = 30) |>                                # fps is not in DLC files
  anicore::convert_unit_time("s") |>
  anicore::convert_unit_space("cm", calibration_factor = 1 / 12.4)            # 1 / px_per_cm
x <- dplyr::filter(x, keypoint == "spine2")

anicheck::check_confidence(x); anicheck::check_na_gapsize(x)                  # QC reports
k <- x |>
  aniprocess::mask_na_across("confidence", threshold = 0.9) |>
  aniprocess::replace_na_across("linear", max_gap = 10) |>
  aniprocess::filter_across("sgolay", window_width = 5, order = 2) |>
  animetric::add_kinematics()                     # speed, acceleration, cumulative_distance, turning ...
animetric::summarise_path(k)                      # total_distance, straightness, sinuosity, e_max
roi <- aniprocess::mask_na_across(k, "roi", x_center = 320 / 12.4, y_center = (480 - 240) / 12.4, radius = 80 / 12.4)
sum(!is.na(roi$x)) / 30                           # seconds inside the circle
anivis::plot_trajectory(k)
```

Multi-animal files are returned with an `individual` column; group by `individual` (and `keypoint`) for per-animal results.

**Agreement with this skill's scripts** (same synthetic tracks, likelihood 0.9, gaps up to 10 frames, Savitzky-Golay window 5): total distance 264.19 vs 264.20 cm (single) and 301 vs 300.6 and 246 vs 246.2 cm (multi-animal); time in a circular ROI 2.4 s in both. Mean speed differed (2.16 vs 2.24 cm/s) because animovement derives speed differently from the plain frame-to-frame step used in the scripts; do not mix definitions inside one analysis.

**Gotchas found**

- `read_deeplabcut()` flips y to a y-up system. Without `video_height` it guessed an extent (511 for a 480-pixel-high test video), so y values were wrong for ROIs drawn in image pixels. Pass the true height; then `y_new = height - y_image`, and ROIs must use the flipped y (as in the example above). A warning appears if any y exceeds the given height.
- fps is not stored in DLC files: set it with `set_metadata(sampling_rate = )`; `convert_unit_time("s")` then makes `time` seconds.
- `mask_na_confidence()` works on a numeric vector and fails on a whole data frame; use `mask_na_across(data, "confidence", threshold = )`.
- `.h5` input needs `rhdf5` (Bioconductor; installing from Bioconductor is allowed in this repo). Without it the reader asks interactively whether to install it, which hangs a non-interactive session. With rhdf5 2.56.1 installed, both pandas "fixed" and DLC-style "table" h5 files read fine and equal the CSV values (single and multi-animal). `dlc_from_anipoint()` in `scripts/dlc_metrics.R` turns the result into the input of `dlc_metrics()` (tested: identical summary to the CSV route).
- `mask_na_across(..., "roi", ...)` only supports rectangular bounds (`x_min` etc.) and circles; no polygons. There is no function for entries, latency or immobility bouts, and no fraction-of-valid-time output.
- Interpolation limits: `replace_na_across("linear", max_gap = 10)` left a 60-frame gap missing (as intended), but the gap-size check should always be read before choosing `max_gap`.

**Verdict**: useful for R users as the front end (reading, QC reports, masking, interpolation, filtering, kinematics, path summaries, publication-style trajectory plots). Use this skill's `dlc_metrics.R` or `.py` for polygon ROIs, entries and latency, immobility bouts, time bins and per-file summary CSVs, or feed the animovement-cleaned track into your own summaries.

## movement in Python (installed and tested 2026-10-23)

`movement` (neuroinformatics-unit; docs v0.17.0) installed with `uv pip install movement tables` into a Python 3.12 venv on Windows (no GPU needed; `tables` is for `.h5`, check whether your environment already has it). Dimension names are singular (`keypoint`, `individual`).

```python
from movement.io import load_poses
from movement import filtering, kinematics
from movement.roi import PolygonOfInterest

ds = load_poses.from_dlc_file("trial1_DLC.csv", fps=30)        # .csv or .h5; time is in seconds when fps is given
pos, conf = ds.position.sel(keypoint="spine2"), ds.confidence.sel(keypoint="spine2")
p = filtering.filter_by_confidence(pos, conf, threshold=0.9)
p = filtering.interpolate_over_time(p, method="linear", max_gap=10)
p = filtering.savgol_filter(p, window=5, polyorder=2)
cm = p / 12.4                                                   # pixels to cm by hand
speed = kinematics.compute_speed(cm); length = kinematics.compute_path_length(cm)
roi = PolygonOfInterest([(0, 0), (300, 0), (300, 480), (0, 480)], name="left")
seconds_in_roi = roi.contains_point(p).sum("time") / 30
```

Tested on the same synthetic single- and multi-animal files (csv and DLC-style table h5 give identical results). Keep image coordinates (y down) for ROIs; movement does not flip y.

| Quantity | movement | `dlc_metrics` scripts |
|---|---|---|
| Path length, single animal (cm) | 264.15 | 264.20 |
| Path length, multi-animal (cm) | 300.62, 246.12 | 300.64, 246.17 |
| Mean speed, single (cm/s) | 2.164 | 2.240 |
| Time in rectangular ROI, single (s) | 7.233 | 7.233 |
| Time in rectangular ROI, multi (s) | 64.73, 0 | 64.87, 0 |

Differences are explained by definitions: movement computes speed with central differences (like animovement, 2.162), the scripts use the backward step; movement's `savgol_filter` leaves NaN around gaps (64 vs 60 missing frames), which shortens ROI time slightly; `compute_path_length` has its own NaN policy (`nan_policy='ffill'|'scale'`, warning above 20% NaN).

What it offers beyond the scripts: xarray data model, many loaders (SLEAP, anipose, NWB), more kinematics (acceleration, turning angle, straightness, pairwise distances), ROI collections with distance and angle to regions, `compute_region_occupancy`, a napari GUI. What it lacks for these tasks: circular ROIs (polygons only, approximate a circle with many vertices), immobility bouts, entries/latency summaries, time-binned summary tables. Its APIs change between releases, so pin the version. `compute_region_occupancy` was not run.

**Choosing**: use `movement` for Python projects that need broader analysis or several tracking formats; use the `dlc_metrics` scripts when you need entries, latency, immobility bouts and bin tables with fixed, documented definitions. Both can be combined (movement for cleaning, scripts for summaries), but keep one speed definition per analysis.

## Synthetic validation versus real recordings

Everything above is **internal-consistency** evidence, not accuracy evidence: the scripts agree with each other to 1e-8 and with `trajr`/`animovement`/`movement` on the same synthetic tracks, but synthetic tracks have no real camera geometry, no real tracking jitter pattern, and no ground-truth behaviour. This skill has never run the scripts (or compared them) on a real recording, so the choices that matter most on real data — likelihood threshold, smoothing window, immobility threshold and minimum bout length — are untested defaults, not validated ones. This mirrors the kpms gap in `hpc-and-troubleshooting.md`: synthetic/toy testing gives confidence the arithmetic is right, not that the real-world numbers are.

The biggest named risk is calling an immobility bout "freezing" without checking it against manual scoring (flagged already in "Metric notes" above). Both scripts can now do that check directly instead of leaving it as an exercise:

- Python: `--manual-immobile manual.csv` (columns `recording,frame,immobile`, `frame` 0-indexed to match the `frames/<recording>.csv` output) writes `<out>/validation_immobile.csv` with per-recording `n_compared`, `accuracy`, `cohens_kappa`, `tp`, `fp`, `fn`, `tn`.
- R: `validate_immobile(frames, manual)` in `scripts/dlc_metrics.R`, where `manual` is a two-column `data.frame(frame, immobile)` for that one recording, returns `n_compared`, `accuracy`, `cohens_kappa` and the confusion `table()`.

### Ask the user to help close this gap

The next time these scripts run on a real recording, ask the user to:

1. Hand-score immobility (or whatever behaviour the threshold is meant to approximate) on a subset of frames or a short clip, in the `recording,frame,immobile` format above, and run `--manual-immobile`/`validate_immobile()` against it. Kappa below about 0.6 (conventional "moderate" cutoff) means the threshold, minimum bout length or body part needs revisiting before reporting "freezing".
2. Re-measure a known real-world distance in the video (arena wall, object-to-object) by hand and compare it to the script's `px_per_cm`-scaled output, to catch calibration or lens-distortion errors the synthetic tests cannot see.
3. Report the camera setup (angle, crop, resolution, whether the animal can climb or rear out of plane) so the "flat floor, perpendicular camera" assumption in the caveats below can be checked rather than assumed.

Record the resulting kappa/accuracy numbers, the chosen thresholds, and anything that looked wrong (ROI overlay mismatch, calibration drift, identity swaps) as a `skill-lessons` entry (see "Capture lessons" in `SKILL.md`) — **this specific gap (no real-recording validation yet) is a standing, named trigger for that section**, not just the generic "something failed" case. Anonymise species/paradigm details per the usual lessons rules; the numbers themselves (kappa, thresholds, which assumption broke) are what's useful here, not the dataset.

## Caveats

- Pixel-to-cm scaling assumes a flat floor and a camera perpendicular to it. Climbing, rearing or tilted views break this; report 2D projected distance.
- fps from the video file, not from the protocol: variable frame rate or dropped frames shift every time-based metric. Verify frame count against duration.
- A DLC file's name usually contains the network suffix; strip it when matching to metadata (see `downstream-analysis.md`).
