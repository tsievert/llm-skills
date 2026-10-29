# Common keypoint-MoSeq problems from the upstream issue tracker

## Contents

- [How this was gathered](#how-this-was-gathered)
- [Calibration troubleshooting](#calibration-troubleshooting)
- [Other recurring problems](#other-recurring-problems)
- [Checks the maintainers asked users to run](#checks-the-maintainers-asked-users-to-run)

## How this was gathered

Read on 2026-10-29 from github.com/dattalab/keypoint-moseq (228 issues, 201 closed; Discussions are disabled; help also goes through Slack and email, which could not be searched). About 20 threads were read for maintainer answers; none of the problems below was reproduced by this skill. Issue numbers are leads: check whether the installed version is newer than the thread. Details and sources: `research/keypoint-moseq-ledger.md` in the llm-skills repo (rounds 5-7).

Counts of issues by title keyword (rough, overlapping): GPU/JAX/CUDA/install 54, loading data 39, stats and plotting 38, grid and trajectory movies 33, syllables/duration/kappa 30, NaNs and fitting 26, calibration 16, apply_model 13.

## Calibration troubleshooting

Noise calibration (`noise_calibration`) is an interactive widget (clicks on video frames). It does not run headless; the fit script skips it.

| Symptom | Cause found in the thread | Fix | Issue |
|---|---|---|---|
| No "X" after clicking, yellow circle fixed, Prev/Next do nothing | `%matplotlib widget` (ipympl) not run before `noise_calibration` in a self-written notebook | Run `%matplotlib widget` first (the tutorial notebook has it) | #229 |
| Keypoints and "x" only in the first frame, or no widget and no error | Old kpms (0.4.2), widget run from a different environment than the one JupyterLab was started in, stale packages after an update | kpms >= 0.4.3; launch JupyterLab inside the kpms environment; update and reload JupyterLab; reinstalling with conda helped two users, pip did not; low memory suspected by a maintainer; unrelated holoviews plots not showing was the same extension problem | #122 |
| Loads 30-50% of frames, then errors with a frame index larger than any recording (example 270590) after downsampling | Stale `error_annotations.csv` in the project folder from an earlier non-downsampled calibration | Delete `error_annotations.csv` (annotations must be redone) after changing downsampling or the data | #153 |
| Frames load slowly, only the skeleton and not the image appears when stepping | Known widget backend problem; a new backend was planned (release not confirmed) | Wait, step one frame at a time; unresolved in the thread | #153, #122 |
| Occluded keypoint: skip or guess? | Maintainer answer | Place the marker where you estimate the keypoint to be | #229 |
| After 5x downsampling (200 to 40 fps): `IndexError` in overlays or grid movies, tiny trajectory plots, almost no syllables | Not shown to be downsampling. The maintainer fitted the data in several configurations (latent_dim 2 and 4, with and without the failed recordings, location-aware or not, with and without downsampling) and always got reasonable plots. The user found the odd plots only with `jitter = 1e-1` on NaN-heavy data (`1e-2` was fine), and a stale JupyterLab kernel state also held wrong coordinates | Restart the kernel; lower jitter; remove failed recordings; compare `len(coordinates[key])` with video frame counts; exported inferred coordinates should have no huge or negative values. Thread never confirmed solved and is still open | #153 |

Error calibration only affects results through `error_estimator` `slope` and `intercept` in the config; a differing pair between runs can change outcomes. Headless alternative: calibrate once on a workstation and copy `slope` and `intercept` into `config.yml`.

## Other recurring problems

| Problem | Maintainer answer or finding | Issue |
|---|---|---|
| NaNs during fitting (also WSL2 with GPU) | No general fix. Clean the keypoints and remove recordings with many tracking errors. Long sleeping or stationary periods are hard for the autoregressive model: build a still/moving mask from smoothed centroid speed and a minimum duration, and model the active periods. Raising `jitter` is a last resort (see rule 10 in `SKILL.md`) | #153, #237 |
| Odd syllable duration distribution (very many very short syllables although the median matches) | Drop unreliable keypoints (tail), pre-filter the keypoints (median filter or a short Gaussian) before modelling; the median alone does not show the shape | #186 |
| `apply_model` syllables differ from `extract_results` for the same data | The full model estimates syllables and pose jointly, so results vary run to run. The `ar_only` model is more stable and gives near-identical syllables from fit and apply. Not reproduced by maintainers | #143 |
| New data gives more syllables | Apply new data in batches in a loop. csv and h5 contain all syllables, but grid movies and trajectory plots show only syllables above `min_frequency` | #176 |
| `apply_model` erased earlier results | Results are keyed by recording name; a new recording with the same name overwrites the old one. Check that `coordinates.keys()` differ between old and new data | #218 |
| Leave out parts of a video (shelter, start and end) | Trim `coordinates` and `confidences` after loading and pass `video_frame_indexes` to calibration, grid movies, `overlay_keypoints_on_video` (and `check_videos` from 0.8.0); added in 0.4.10. Misaligned indexes, coordinates and video are the usual cause of wrong overlays | #169, #188 |
| White dot far from the animal in grid movies | Centroid speed prior. From 0.6.3 the notebook has an `estimate_sigmasq_loc` cell that sets it from the data; older versions hard-coded it. Upgrade and refit | #262 |
| Large datasets, multi-GPU out of memory | Turn off parallel message passing, raise `mixed_map_iters` (maximum about n_recordings / n_gpus, 32 used before), or fit a subset and apply the model to the rest | #236 |
| `init_model` fails after a JAX release | jax 0.6 broke it in 2025; fixed by a new jax-moseq. Install problems recur with new JAX releases, so check the jax-moseq version first | #227 |
| SLEAP csv import with 3 bodyparts | A maintainer fixed a user's loader bug (`os.path.basename` without its argument) and said 3 bodyparts is "really pushing it" for single-animal syllables | #170 |
| Group-comparison statistics unclear | The plot flags syllables with a Kruskal-Wallis test per syllable and FDR across syllables and groups (added to the upstream FAQ); stats were not returned by older releases | #226, #260 |
| Different kappa for high frame rate | The documented scan upper bound 1e7 is usually enough; higher values can be needed at high frame rates | #153 |

## Checks the maintainers asked users to run

1. Compare frame counts for every recording:

```python
from vidio.read import OpenCVReader
keys = sorted(coordinates.keys())
videos = kpms.find_matching_videos(keys, video_dir)
for key, video in zip(keys, videos):
    print(len(coordinates[key]), len(OpenCVReader(video)), key)
```

2. After downsampling, reload the coordinates from scratch (double downsampling is a possibility) and print the shapes before and after.
3. `kpms.overlay_keypoints_on_video(..., video_frame_indexes=video_frame_indexes)` to see whether keypoints and video line up.
4. Export the inferred coordinates (docs: advanced topics, exporting pose estimates) and look for negative or huge values.
5. Delete `error_annotations.csv` after changing the data or its frame rate, and restart the kernel when plots look wrong.

Not checked: whether 0.8.3 changed the calibration widget, and whether #153 still occurs on 0.8.3. Ask the user for their kpms, jax-moseq, JupyterLab, panel and bokeh versions before diagnosing widget problems.
