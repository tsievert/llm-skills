# keypoint-MoSeq (kpms) research ledger

Skill: `animal-behaviour-tracking-analysis`. Append new rounds; do not repeat a search that has a row.

## Requirements

| # | Requirement | Date |
|---|---|---|
| 1 | Check the skill against the kpms repo and docs after several breaking releases; update stale references and guidelines | 2026-10-29 |

## Sources

| Source | Status | Notes |
|---|---|---|
| https://api.github.com/repos/dattalab/keypoint-moseq/releases | read | 0.6.13 to 0.8.3 notes (below) |
| https://api.github.com/repos/dattalab/keypoint-moseq/commits | partial | first ~90 KB; 0.8.2/0.8.3 commit titles |
| https://keypoint-moseq.readthedocs.io/en/stable/modeling.html | read | tutorial written for notebook 0.8 |
| .../install.html | read | Python 3.10-3.14, conda example now Python 3.12, `check_installation()` |
| .../advanced.html | read | kappa scan, model selection, merging unchanged in shape |
| .../analysis.html | read | `compute_stats_df(moseq_df, min_frequency, groupby)`; no definitions of frequency/duration on the page |
| .../FAQs.html | read | still lists an email for NaN problems although the repo now points support to GitHub issues (commit 2026-10-29) |
| GitHub `CHANGELOG.md`, release tag URLs | blocked | 404; the releases list was enough |
| Installed 0.8.3 source (uv venv, Python 3.12) | read, run | signatures via `inspect`, docstrings |

## Facts (releases)

- 0.8.3 (2026-10-28): loader fixes for DLC/SLEAP/Lightning Pose. Multi-animal DLC `bodyparts` is a list in file order; DLC `-1` placeholder keypoints load as missing; recordings with no keypoints skipped; with `_filtered` copies present only the unfiltered files load (a pattern such as `*_filtered.h5` loads the filtered ones); `.hdf5` extension loads; DLC 3D loads as 3D; a `.slp` with several videos loads all.
- 0.8.2 (2026-10-27): needs jax-moseq >= 0.3.8. `moseq_df` angular velocity no longer spikes at +-pi; `stats_df` durations exclude each recording's first and last instance; transition matrices count the transition out of each recording's first syllable; `extract_results` keeps inferred labels where segments overlap; `apply_model(ar_only=True)` defaults to one iteration; `run_kruskal` labels fixed; `format_data` raises ValueError for recordings no longer than `nlags`; `calibration.save_params` takes three values instead of a dict.
- 0.8.0 (2026-10-23): `[cuda]` extra; `compute_stats_df` lost `project_dir/model_name/fps`; renamed grid-movie/trajectory/dendrogram args (old names silently ignored); `check_video_paths` replaced by `check_videos`; non-30 fps results change (project fps now used).
- 0.7.0 (2026-10-22): Python 3.10-3.14, dependency pins removed, pandas 3 fix for the group comparison plot. 0.6.13: recordings loaded from a directory are sorted.

## Local tests (0.8.3, Windows, uv venv Python 3.12, jax 0.12.0.1, numpy 2.5.4, pandas 3.1.0, CPU, synthetic DLC csv, 4 x 1500 frames)

- `kpms_headless_fit.py` ran fresh and resumed unchanged. Bug found: on resume `done_iter` from `load_checkpoint` is numpy int64 and broke `json.dumps` for `run_summary.json` (fixed with `int()`).
- `check_nan_proportions` works with pandas 3.1.0 now (earlier finding on 0.6.6/0.8.0 is stale). In a script it prints a Styler repr, not the table.
- `extract_results` has `overwrite` now (raises for recordings already present). `fit_model(fps=)` only switches progress plots to seconds; `init_model(metadata=)` only improves the OOM message.
- results.h5 layout unchanged (`centroid`, `heading`, `latent_state`, `syllable`). Python summariser and R reader agree (469 bouts on the same file); both read 0.8.3 output.
- `compute_moseq_df` adds an `fps` column; `compute_stats_df` columns as in docs; `generate_transition_matrices` runs.

## Open research items

- (done 2026-10-29) Multi-animal DLC csv and `_filtered` handling: see Local tests round 2. Still open: SLEAP, Lightning Pose, DLC `.h5`/`.hdf5`/3D loaders.
- `check_videos`, grid movies, `apply_model` on 0.8.3 not run.
- Not checked whether the `-1` DLC padding or SLEAP changes affect the skill's `dlc_metrics` scripts (they do not use kpms).

## Log

- 2026-10-29: first round; releases, docs pages, install + signature inspection, script fresh/resume test, summary readers.
- 2026-10-29 (round 2): synthetic multi-animal DLC csv test on 0.8.3 (uv venv, Python 3.12).

## Local tests, round 2 (0.8.3, synthetic multi-animal DLC csv: 2 individuals, 5 bodyparts, 3 files + 2 `_filtered` copies)

| Case | Result |
|---|---|
| `_filtered` copies next to raw files | skipped by default; glob `*_filtered.csv` loads them (keys `<stem>_filtered_<individual>`) |
| `-1` placeholder (50 frames of one keypoint) | loaded as NaN (nan fraction 0.0125 as expected) |
| Individual with all-NaN keypoints | dropped; other individual of the same file still loads |
| Keys | `<file>_<individual>` |
| File with reversed bodypart column order | loaded silently, keypoints in wrong slots (positional assignment from first file's bodyparts); upstream behaviour, not reported by this skill |
| `kpms_headless_fit.py` on the 5 recordings | fit (3+3 iters), results.h5 has 5 recordings |
