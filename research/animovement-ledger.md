# Research: animovement suite vs `animal-behaviour-tracking-analysis` (round 2026-11-03)

**Refers to (version stamp, re-check when any differs):** animovement 0.8.0.9002, anicore 0.8.0.9009, aniread 0.7.0.9006,
aniprocess 0.5.0.9003, anicheck 0.3.0.9004, anispace 0.3.0.9006, animetric 0.5.0.9006, anivis 0.2.1.9003 (R-universe dev builds,
identical on animovement.dev and installed here on 2026-11-03), R 4.6.0, rhdf5 2.56.1. To pick up changes: run
`check_versions()` from `github-skill-maintenance` (the same stamp is in `animal-behaviour-tracking-analysis/references/animovement-suite.md`
line 3) and read each package's `news/index.html`.

Question: does the skill cover animovement well enough, and what does the rest of the suite offer? Source-quality rules from
`AGENTS.md` applied (all sources are the package authors' own pkgdown sites; nothing skipped). Statuses: read / partial / not researched.

## 1. Requirements

| # | Requirement |
|---|---|
| R1 | (2026-11-03, user) Check https://animovement.dev/ and judge whether the skill covers animovement well enough. |
| R2 | (2026-11-03, user) Explore all other packages in the suite. |
| R3 | (2026-11-03, user) Log as research. Skill files were not changed in this round. |

## 2. Sources

| # | Source | Status | Used for |
|---|---|---|---|
| S1 | https://animovement.dev/ | read | suite pitch: DLC, SLEAP, idtracker.ai, trackballs; modular, testthat + codecov |
| S2 | https://animovement.dev/packages/index.html | read | package list; install from R-universe or conda (prefix.dev `animovement` channel, Pixi); `animovement_install_suggested()` |
| S3 | https://animovement.dev/learn/index.html | read | no tutorials published yet |
| S4 | pkgdown home + reference index of anicore, aniread, anicheck, aniprocess, anispace, animetric, anivis (`https://animovement.dev/<pkg>/`) | read | function lists in section 4 |
| S5 | Function help pages, news pages, Get Started / Help / Find / Contribute / About | not researched | open items |

## 3. Facts

- Suite by Mikkel Roald-Arbøl, MIT licence, R-universe (not CRAN), conda channel too. Cite the toolbox as a whole (Zenodo
  doi:10.5281/zenodo.13235277) or the single package.
- Versions on the site on 2026-11-03 equal what is installed here (animovement 0.8.0.9002, anicore 0.8.0.9009, aniread 0.7.0.9006,
  aniprocess 0.5.0.9003, anicheck 0.3.0.9004, anispace 0.3.0.9006, animetric 0.5.0.9006, anivis 0.2.1.9003). The skill's earlier test
  (2026-10-23) therefore still describes the current builds, except it lists neither anicheck, anispace nor anivis versions.
- Local check (2026-11-03): `read_deeplabcut(path, video_height)` still has only those two arguments; `add_kinematics()` gives speed,
  acceleration, cumulative_distance, v_x/v_y, a_x/a_y, course, turning speed/rate/acceleration, cumulative_turning;
  `summarise_aniframe()` returns median and MAD only; `mask_na_roi()` takes rectangular bounds and circle (`radius`) only.
- The reference indexes contain **no** function for immobility/freezing bouts, polygon ROIs, zone entries, latency or time bins, so the
  skill's statement of that gap is still correct.
- Many pieces are marked experimental (may change without deprecation): `add_orientation`, `compute_min_step`, `summarise_aniframe`,
  `mask_na_hampel`, `mask_na_segment_length`, `filter_ccma`, `filter_deadband`, `check_segment_length`, structure/joint functions,
  quaternion conversions, `plot_circular`, `plot.anipoint`.

## 4. The suite

| Package | Role | Notable functions | In the skill? |
|---|---|---|---|
| animovement | metapackage, loads the core packages | `animovement_install_suggested()` | yes (install, recipe) |
| anicore | data structures: `anipoint`/aniframe, `anievent`, `anistructure` (skeleton, segments, joints); metadata, units, axis directions, angles, circular statistics | `set_metadata`, `convert_unit_space/time`, `reflect_axis`, `as_anisegment`, `as_anijoint`, `circ_mean/sd/median`, `unwrap_angle`, `angle_between` | partly (metadata and unit conversion in the recipe) |
| aniread | readers/writers | `read_dataset()` (auto-detects source), `detect_source`, `read_deeplabcut`, `read_sleap`, `read_lightningpose`, `read_idtracker`, `read_trex`, `read_fasttrack`, `read_animalta`, `read_anipose`, `read_freemocap`, `read_c3d`, `read_bonsai`, `read_trackmate`, `read_octron`, `read_movement`, `read_trackball`, `read_custom`; events: `read_boris`; skeletons: `read_structure_deeplabcut/sleap`; `write_dataset`, `write_aniframe` (Parquet), `write_intracktive` | `read_deeplabcut` only |
| anicheck | data-quality diagnostics | `check_confidence`, `check_na_gapsize`, `check_na_timing`, `check_segment_length` | first two in the recipe |
| aniprocess | masking, gap filling, filters | masks: confidence, excursion, hampel, range, roi, segment_length, speed; fill: linear, locf, spline, stine, value; filters: sgolay, gaussian, rollmean/median, butterworth low/high-pass, FFT, kalman (regular and irregular), one_euro, triangular, ccma, deadband; `find_peaks/troughs`; `*_across` and `*_with` wrappers | confidence mask, linear fill, sgolay only |
| anispace | coordinate transforms | `transform_to_egocentric`, `translate_coords`, `rotate_coords`, polar/cylindrical/spherical mapping, quaternion algebra (`quat_*`) | no |
| animetric | metrics | `add_kinematics`, `add_tortuosity` (sliding window), `add_nnd` (nearest-neighbour distance, social), `add_orientation`, `add_point`, `summarise_path` (straightness, sinuosity, E_max), `summarise_aniframe` | `add_kinematics`, `summarise_path` only |
| anivis | plots | `plot_trajectory`, `plot_timeseries`, `plot_circular`, `plot_events`, check plots, Okabe-Ito scales, `theme_animovement` | `plot_trajectory` only |

## 5. Verdict on coverage (assistant judgement, 2026-11-03)

For the skill's actual scope (DLC output to basic hypothesis-driven metrics), coverage is adequate and accurate: the recipe, y-flip
and fps gotchas, rhdf5 note, agreement numbers and the "what animovement lacks" list all still hold on the current builds.

It is thin as a guide to the **suite**: the skill names the seven packages but describes only the DLC path. Candidate additions, in
order of likely value (none made yet, each is a user decision):

1. Mention `read_dataset()` plus the other readers (SLEAP, LightningPose, idtracker.ai, TRex, FastTrack) and `read_boris()` events,
   since users of other trackers may land in this skill; check the skill's scope line, which currently says DLC only.
2. Mention `mask_na_speed()` / `mask_na_hampel()` as an outlier and identity-swap screen before metrics (not yet tested here).
3. Mention `anispace::transform_to_egocentric()` and `anicore::as_anijoint()` for posture or body-centred analyses, and `add_nnd()` for
   social distance, as pointers marked untested.
4. Note that `summarise_aniframe()` gives median/MAD, not the means used in the skill's tables.
5. Add the conda/Pixi install route and the "experimental" list so users expect API changes.

Not recommended: re-implementing anything the suite lacks (polygons, entries, immobility) differently from `scripts/dlc_metrics.R`.

## 6. Open research items

| # | Item |
|---|---|
| O1 | Test `read_dataset()` on SLEAP/LightningPose sample files via `get_sample_data()` before the skill points to them. |
| O2 | Test `mask_na_speed()` and `mask_na_hampel()` on a track with a synthetic identity swap; compare with likelihood masking. |
| O3 | Test `transform_to_egocentric()` and `add_nnd()` on multi-animal data. |
| O4 | Read news pages for deprecations since 2026-10-23 (not done). |
| O5 | Decide whether to widen the skill's DLC-only scope line, or keep other trackers as one-line pointers. |

## 6b. Tests run 2026-11-03 (versions as stamped above)

| # | Test | Result |
|---|---|---|
| T1 | `get_sample_data()` + `detect_source()` + `read_dataset()` for deeplabcut (h5, single mouse), sleap, lightningpose, idtrackerai (h5), movement (nc, 2 mice), trex (5 locusts) | All read into `anipoint` with `confidence`; `individual` column absent for the single-animal DLC and LightningPose files. LightningPose detected as "deeplabcut/lightningpose" but read fine. `boris` has no sample file (not tested). |
| T2 | `read_dataset()` on `.h5` without `rhdf5` | Detection fails, message names `rhdf5`. `rhdf5` was missing in this library (earlier install lost); reinstalled via BiocManager (allowed), 2.56.1. |
| T3 | `mask_na_across(x, "speed")` on a real 2-mouse nose track (3000 frames) with 4 injected single-frame jumps of 300 px and one 5-frame jump | All 4 single-frame jumps flagged; the 5-frame block was not (matches the help: a row needs both steps fast). `"auto"` (mean + 3 SD) flagged 2 further rows, a fixed 2000 px/s threshold 3 further rows: possibly real fast movement, not checked against video. |
| T4 | `add_nnd(across = "individual", within = "keypoint")` on nose coordinates of the 2-mouse sample | Matches a manual Euclidean distance exactly (max difference 0 over all frames); `NA` where an animal is untracked (364 frames); without `within` it is any keypoint to any keypoint (distance min 0.22, median 394 px). |

## 6c. Should there be a separate `animovement` skill? (assistant judgement, 2026-11-03)

Recommendation: **not now.** Reasons: (1) the package sites are good pkgdown references the assistant can read on demand, and there
are no tutorials yet (S3), so a skill would mostly restate function lists that go stale; (2) the packages are dev builds
(0.x.y.9000) with many experimental functions, so a skill's API claims would age quickly; (3) the territory overlaps the existing
skill (basic metrics from DLC) and would need a clash decision against it and against `keypoint-moseq`; (4) what is durable and
useful is already in the existing skill: gotchas, agreement numbers and a hand-off to the scripts for what animovement lacks.
Chosen alternative: a version-stamped reference file `references/animovement-suite.md` plus a short section in `SKILL.md`.
Revisit when any of: the user works with non-DLC trackers or non-rodent/biomechanics data (SLEAP, TRex, FreeMoCap, C3D, trackballs)
often enough to need an end-to-end recipe per source; the suite reaches a stable release or CRAN; tutorials are published; or
lessons show repeated failures with the suite. At that point it would be a skill for "R workflows for movement data from any
tracker" and should take over the animovement parts of `animal-behaviour-tracking-analysis`.

## 7. Log

- 2026-11-03: Fetched the home page, packages page, Learn page, pkgdown home and reference index for all eight packages; compared
  installed versions (identical to the site) and checked signatures and outputs locally. Read `animal-behaviour-tracking-analysis`
  `SKILL.md` and the animovement section of `references/dlc-basic-metrics.md` for the comparison. No skill file was edited.
- 2026-11-03 (later): Tested `read_dataset()` (6 sample sources), `mask_na_speed()` and `add_nnd()` (section 6b); reinstalled `rhdf5`
  after finding it missing; added `animal-behaviour-tracking-analysis/references/animovement-suite.md` and a pointer section in its
  `SKILL.md`; recorded the separate-skill judgement (6c). Not tested: anispace, as_anijoint, add_orientation, read_boris, Kalman/One
  Euro filters.
