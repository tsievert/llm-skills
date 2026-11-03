# The animovement suite: pointers beyond the DLC recipe

**Refers to:** animovement 0.8.0.9002 (anicore 0.8.0.9009, aniread 0.7.0.9006, aniprocess 0.5.0.9003, anicheck 0.3.0.9004,
anispace 0.3.0.9006, animetric 0.5.0.9006, anivis 0.2.1.9003), checked 2026-11-03 on R 4.6.0 against https://animovement.dev/.
These are development builds from R-universe (not CRAN). Compare `packageVersion()` with the list above; if they differ, check
the package news and `?function` before trusting anything here. The DLC recipe and gotchas are in
[dlc-basic-metrics.md](dlc-basic-metrics.md); this file only says what else exists and what was tested. Research ledger:
`research/animovement-ledger.md` in the llm-skills repo.

## Package map

| Package | Use it for | Tested here |
|---|---|---|
| `aniread` | `read_dataset(path)` auto-detects the source and reads it; direct readers for SLEAP, LightningPose, idtracker.ai, TRex, FastTrack, AnimalTA, Anipose, FreeMoCap, C3D, Bonsai, TrackMate, OCTRON, FicTrac, trackballs, movement netCDF; `read_boris()` for event data; `write_aniframe()` (Parquet) | Yes, see below |
| `anicore` | data structures (`anipoint`, `anievent`, skeleton `anistructure`), metadata and unit conversion, angle and circular-statistics helpers | Metadata/units only (DLC recipe) |
| `anicheck` | `check_confidence`, `check_na_gapsize`, `check_na_timing`, `check_segment_length` (experimental) | First two (DLC recipe) |
| `aniprocess` | masks (confidence, speed, hampel, range, ROI, excursion), gap filling, filters (sgolay, Butterworth, Kalman, One Euro, ...) | Confidence, speed, linear, sgolay |
| `anispace` | egocentric transform, translate/rotate, polar/spherical coordinates, quaternions | Not tested |
| `animetric` | `add_kinematics`, `add_tortuosity`, `add_nnd` (social distance), `summarise_path`, `summarise_aniframe` (median/MAD only) | Kinematics, path, `add_nnd` |
| `anivis` | trajectory, time-series, circular and event plots, Okabe-Ito scales | `plot_trajectory` only |

None of them offers immobility/freezing bouts, polygon ROIs, zone entries, latency or time bins: use `scripts/dlc_metrics.R`/`.py`.
Many functions are marked experimental by the authors and may change without a deprecation period.

## Tested 2026-11-03

- **`read_dataset()`** read the package's sample files for DeepLabCut (`.h5`, single animal, no `individual` column), SLEAP,
  LightningPose, idtracker.ai (`.h5`), movement (`.nc`, 2 individuals) and TRex (5 individuals) into `anipoint` frames with
  `confidence` and `keypoint` columns. `.h5` detection needs Bioconductor `rhdf5`; without it detection fails with a message
  naming `rhdf5` (it had to be reinstalled on this machine, so check `requireNamespace("rhdf5")` first). LightningPose is
  reported as "deeplabcut/lightningpose" (ambiguous but read correctly). The sample set has no BORIS file, so `read_boris()` was not run.
- **`mask_na_speed()`** (call it as `mask_na_across(x, "speed", threshold = )`, one track at a time or grouped): on a real
  multi-animal track with four injected single-frame jumps it flagged all four. It flags a row only when **both** the step in and
  the step out are fast, so a jump that lasts several frames (an identity swap, or a sustained teleport) was **not** flagged:
  a 5-frame block of the same size passed through. Use it for isolated spikes, not for identity swaps. `threshold = "auto"` is
  mean + 3 SD per group, which also flagged rows that may be genuine fast movement (4 other rows in 3000 frames), so inspect them.
- **`add_nnd(data, across = "individual", within = "keypoint")`** gives `nnd_1_individual` and `nnd_1_distance`; nose-to-nose
  distance matched a manual calculation exactly over all frames (max difference 0). Without `within`, it measures any keypoint to
  any keypoint of the other animal. Frames where one animal is untracked give `NA` (not zero). Units are those of the frame (pixels
  unless converted first with `convert_unit_space()`).

## Not tested

`anispace` transforms (egocentric frame, quaternions), `anicore` skeleton/joint angles (`as_anijoint`), `add_orientation`,
`add_tortuosity`, `summarise_aniframe`, Kalman/One Euro filters, `read_boris()`, any plotting beyond `plot_trajectory`. Treat these
as pointers: read `?function` and test on a small sample before using them for results.
