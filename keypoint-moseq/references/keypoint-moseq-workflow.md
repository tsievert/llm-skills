# keypoint-MoSeq workflow reference

## Contents

- [Version changes that matter (0.6.6 to 0.8.4)](#version-changes-that-matter-066-to-084)
- [Pipeline (interactive Python API, as in the tutorial)](#pipeline-interactive-python-api-as-in-the-tutorial)
- [Output structure](#output-structure)
- [Config keys that matter](#config-keys-that-matter)
- [Kappa (stickiness) and syllable duration](#kappa-stickiness-and-syllable-duration)
- [Preparing the data: still periods, filtering, trimming](#preparing-the-data-still-periods-filtering-trimming)
- [Checking the fit](#checking-the-fit)
- [Applying a fitted model to new recordings](#applying-a-fitted-model-to-new-recordings)
- [Advanced options (from the docs, none run here)](#advanced-options-from-the-docs-none-run-here)
- [Data requirements (FAQ)](#data-requirements-faq)

Source: kpms stable docs (modeling tutorial for notebook version "0.8", FAQs, advanced topics, analysis) re-read 2026-10-29 against 0.8.3, plus runs on 0.6.6, 0.8.0 and (2026-10-29, scripts, CPU) 0.8.3. Re-check against the installed version. Since 0.8.0 the tutorial passes `metadata=metadata` to `init_model` and `**config()` (so `fps`) to `fit_model`, validates videos with `check_videos`, and starts with `kpms.check_installation(notebook_version="0.8")`. `scripts/kpms_headless_fit.py` passes `metadata=` and `fps=` (needs >= 0.8.0). Research record: `research/keypoint-moseq-ledger.md` in the llm-skills repo.

## Version changes that matter (0.6.6 to 0.8.4)

0.8.4 rows come from the release notes (read 2026-10-30). Locally run on 0.8.4 (2026-10-30, Windows, uv venv Python 3.12, CPU, synthetic DLC csv, 6 recordings): headless fit and resume, `compute_stats_df` full recording x syllable grid (498 rows = 6 x 83 at `min_frequency=0`), circular heading columns present, `run_kruskal` warning for groups with fewer than 3 values, and a 3 vs 3 non-overlapping test giving an adjusted p of about 0.10 (not 0.0001). Not run: grid movies, `overlay_keypoints_on_video`, `update_hypparams`, `update_config`, `location_aware`.

| Change | Release | Consequence |
|---|---|---|
| `check_video_paths` replaced by `check_videos(coordinates, print_table=True, **config())`; raises for missing videos or keypoints past the video end | 0.8.0 | Update older code; skip when there are no videos |
| Renamed grid-movie, trajectory and dendrogram args (`pre`, `post`, `min_duration`, `filter_size` became `before_onset_sec`, `after_onset_sec`, `min_instance_duration_sec`, `smoothing_filter_frames`); old names are silently ignored | 0.8.0 | Old code runs with defaults instead of failing; grep for the old names |
| Velocities and durations use the project `fps` | 0.8.0 | Results at non-30 fps differ from older runs; always set `fps` |
| `compute_stats_df` no longer takes `project_dir`, `model_name`, `fps` | 0.8.0 | See `downstream-analysis.md` section 6 |
| Needs jax-moseq >= 0.3.8; Python 3.10-3.14; dependency pins removed | 0.7.0, 0.8.2 | A fresh install pulls NumPy 2 and pandas 3; pin for old environments |
| `format_data` raises `ValueError` for recordings no longer than `nlags` | 0.8.2 | Drop or merge very short recordings before fitting |
| `stats_df` durations drop each recording's first and last syllable instance; transition matrices count the transition out of a recording's first syllable; angular velocity no longer spikes at +-pi; `extract_results` keeps inferred labels where segments overlap | 0.8.2 | Numbers differ from earlier runs and from this skill's own summaries (see `downstream-analysis.md`) |
| `apply_model(ar_only=True)` defaults to one iteration | 0.8.2 | Pass `num_iters` explicitly |
| `extract_results(overwrite=False)` raises for recordings already in `results.h5` | 0.8.x | The script deletes the file first |
| `calibration.save_params` takes three values, not a dict | 0.8.2 | Only matters for custom calibration code |
| Loader fixes: DLC `-1` placeholders become missing, multi-animal `bodyparts` in file order, DLC `_filtered` copies skipped when raw files exist, recordings without keypoints skipped, `.hdf5` loads, DLC 3D loads as 3D, `.slp` loads all its videos | 0.8.3 | Recording keys and keypoint counts can change versus 0.8.2; re-check the `load_keypoints` output after upgrading. Per the loader docstring a glob such as `*_filtered.h5` loads the filtered files if you want those (not run here) |
| `compute_stats_df` gives every recording a row for each syllable passing `min_frequency` (frequency 0, duration and kinematics NaN where unused); frequency plots average over all recordings; `order="diff"` can change | 0.8.4 | Row counts and kinematic means of `stats_df` differ from 0.8.3; use `skipna` means or filter NaN rows; do not pool 0.8.3 and 0.8.4 tables |
| `run_kruskal` skips NaN (0.8.3 counted them as 0), skips syllables constant across recordings or with a group lacking values, warns when a group has < 3 values; permutation p-values now count ties (0.8.3 gave 0.0001 for non-overlapping groups whatever the sizes) | 0.8.4 | Fewer significant syllables with groups up to about 8 recordings; re-run earlier built-in tests and do not compare with 0.8.3 stars |
| `heading_mean`/`heading_std` in `stats_df` are circular statistics | 0.8.4 | 0.8.3 heading means near +-pi were wrong |
| `overlay_keypoints_on_video` honours `video_frame_indexes` (pass one recording's array, `video_frame_indexes[name]`, not the dict); errors before writing if keypoints need frames past the video end | 0.8.4 | Fixes wrong overlays for trimmed or downsampled data (#300); the trimming checks in `common-problems.md` now work |
| Density-sampled grid movies use 0.167 s before and 0.5 s after onset at the project fps (0.8.3: 5 and 15 frames) | 0.8.4 | Only differs from before at non-30 fps |
| `init_model(location_aware=True)` uses the given `allo_hypparams` (0.8.3 replaced them with defaults) | 0.8.4 | Refit if you set custom ones |
| `update_hypparams` raises for `num_states`, `latent_dim`, `nlags`, `S_0_scale`, `K_0_scale` | 0.8.4 | Set these in the config and initialise a new model; 0.8.3 silently changed only the stored value |
| `update_config` writes numpy values as plain numbers/lists and keeps settings without a default | 0.8.4 | A `config.yml` broken by `fps=np.float64(30)` under 0.8.3 needs a manual fix |
| Recordings loaded from a directory are sorted | 0.6.13 | Noise calibration reproducible across machines |


## Pipeline (interactive Python API, as in the tutorial)

```python
import keypoint_moseq as kpms
project_dir = "proj"
config = lambda: kpms.load_config(project_dir)

# 1. Load DLC output (csv or h5; folder is searched recursively)
coordinates, confidences, bodyparts = kpms.load_keypoints("dlc_out/", "deeplabcut")
kpms.check_nan_proportions(coordinates, bodyparts, breakdown=True)
kpms.check_installation()   # prints versions and JAX devices (0.8.0+)

# 2. Project + config (setup_project fails if project_dir exists)
kpms.setup_project(project_dir, deeplabcut_config="dlc/config.yaml")   # or bodyparts=..., skeleton=...
kpms.update_config(project_dir, use_bodyparts=[...], anterior_bodyparts=["nose"],
                   posterior_bodyparts=["spine4"], fps=30, video_dir="videos/")
kpms.check_videos(coordinates, print_table=True, **config())   # optional, needs the videos (0.8.0+)

# 3. Preprocess
coordinates, confidences = kpms.outlier_removal(coordinates, confidences, project_dir,
                                                overwrite=False, **config())
data, metadata = kpms.format_data(coordinates, confidences, **config())
# kpms.noise_calibration(...) is interactive (widget); optional

# 4. PCA, latent_dim, sigmasq_loc
pca = kpms.fit_pca(**data, **config()); kpms.save_pca(pca, project_dir)
kpms.update_config(project_dir, latent_dim=4)
kpms.update_config(project_dir, sigmasq_loc=kpms.estimate_sigmasq_loc(data["Y"], data["mask"], filter_size=config()["fps"]))

# 5. AR-HMM then full model
model = kpms.init_model(data, metadata=metadata, pca=pca, **config())
model = kpms.update_hypparams(model, kappa=1e6)
model, model_name = kpms.fit_model(model, data, metadata, project_dir, ar_only=True, num_iters=50, **config())
model, data, metadata, it = kpms.load_checkpoint(project_dir, model_name, iteration=50)
model = kpms.update_hypparams(model, kappa=1e4)
model = kpms.fit_model(model, data, metadata, project_dir, model_name, ar_only=False,
                       start_iter=it, num_iters=it + 500, **config())[0]

# 6. Reindex (checkpoint only), then extract
kpms.reindex_syllables_in_checkpoint(project_dir, model_name)
model, data, metadata, it = kpms.load_checkpoint(project_dir, model_name)
results = kpms.extract_results(model, metadata, project_dir, model_name)
kpms.save_results_as_csv(results, project_dir, model_name)
```

`scripts/kpms_headless_fit.py` implements this headless and resumable. Findings from running it on 0.6.6 (the 0.8.3 re-run is noted per bullet and below):

- `fit_model(..., model_name)` accepts a name on the first call, so a chosen name works as the resume key; without it kpms auto-names the folder with a timestamp.
- `extract_results` adds to an existing `results.h5`. In 0.6.6 the `overwrite` argument did not exist; in 0.8.3 it does and recordings already in the file raise without it. The script deletes the derived file first, which works on both and also drops recordings no longer in the data.
- 0.8.3 re-run (CPU, synthetic data): fresh fit, resume and extraction work unchanged. On resume `load_checkpoint` returns a numpy int that broke the script's JSON summary; fixed with `int()`. In a script `check_nan_proportions` prints a Styler repr, not the table, so read NaN fractions another way (for example from `coordinates`) when it matters; it no longer fails under pandas 3.
- 0.8.3 loader test (2026-10-29, synthetic multi-animal DLC csv, 2 individuals, 3 files): `_filtered` copies are skipped by default and a glob such as `ma/*_filtered.csv` loads them; `-1` placeholders become NaN; an individual with no keypoints in any frame is dropped (the other individual of that file still loads); keys are `<file>_<individual>`; the fit script ran on the result (5 recordings).
- **Gotcha found in that test: bodyparts are taken from the first file and assigned by position.** A file whose columns were in a different order loaded without any warning, with its keypoints in the wrong slots (nose labelled as spine3 and so on). Files from one DLC network share an order, so this is a risk mainly when merging outputs of different networks or configs. `scripts/kpms_headless_fit.py` now checks every csv/h5 header (DLC format, `_filtered` copies ignored when raw files exist) and exits on a mismatch; tested 2026-10-29 on synthetic csv and h5, single and multi-animal. For other loaders check the headers yourself. Not reported upstream by this skill; the 0.8.3 note "returns bodyparts in file order" does not promise reordering across files.
- Not run on 0.8.3: SLEAP/Lightning Pose loaders, DLC `.h5`/`.hdf5` and 3D files, `check_videos`, grid movies, `apply_model`, GPU.
- A custom `setup_project(bodyparts=...)` writes a placeholder skeleton (`BODYPART1`...) that triggers warnings; pass a real `skeleton` (the script builds a chain) or use the DLC config.
- Resuming works from `checkpoint.h5` (latest iteration); the full-model kappa persists in the checkpoint (checked: 1e4 after a resume).

## Output structure

`{project_dir}/{model_name}/results.h5`: one group per recording with datasets `syllable` (frames,), `latent_state` (frames, latent_dim), `centroid` (frames, 2 for 2D), `heading` (frames,). Names containing `/` (from `path_in_name=True`) become nested groups. The per-recording CSV export (`save_results_as_csv`) has columns `syllable, centroid x, centroid y, heading, latent_state 0..k`. Verified on 0.6.6 and again on 0.8.3 (layout unchanged): R and h5py readers equal these. `compute_moseq_df` output also carries an `fps` column.

## Config keys that matter

| Key | Meaning / advice |
|---|---|
| `use_bodyparts` | Subset and order of keypoints in the model. 5-10, informative, whole body; omit rodent tails |
| `anterior_bodyparts`, `posterior_bodyparts` | Define heading; choose robust, rarely occluded points |
| `fps` | Must be the real frame rate. Syllable durations and kappa targets depend on it |
| `latent_dim` | Default heuristic in the tutorial: dims explaining 90% of PCA variance, or 10, whichever is lower. The script applies this unless `--latent-dim` is given. Memory grows with it |
| `outlier_scale_factor` | Tutorial uses 6.0 for outlier removal |
| `sigmasq_loc` | Set from `estimate_sigmasq_loc` (tutorial heuristic) |
| `video_dir` | Only needed for movies and overlays |

The kappa value is not a config key you edit by hand: it is read at `init_model` and changed with `update_hypparams(model, kappa=...)`.

## Kappa (stickiness) and syllable duration

- Kappa controls how long syllables last. Higher gives longer, fewer transitions. Tune it by the **median syllable duration**: docs give about 400 ms (12 frames at 30 fps) as a target for rodents. Adjust by factors of 10 or more and refit.
- AR-HMM stage needs a higher kappa than the full model for similar durations. Docs example: 1e6 for the AR stage and 1e4 for the full model (starting values, not recommendations for your data).
- The target is a duration in frames, so it depends on fps and species: `duration_s x fps` (about 400 ms is the rodent rule of thumb: 12 frames at 30 fps, 10 at 25, 8 at 20). Published studies chose kappa by matching 400 ms or a median of 10 frames and by checking grid movies; their values span 1e-6 to 1e10 (see `use-cases-and-literature.md`), and the docs scan stops at 1e7, which a maintainer called typically high enough but not always at 100-200 fps. Never reuse a kappa from another setup.
- Fit until duration stabilises: under 10 iterations for AR-only, 10-50 for the full model, then run 200-500 iterations (defaults in the script: 50 AR + 500 full).
- Automatic scan from the docs: `kappas = np.logspace(3, 7, 5)`; per kappa fit AR (50 iters) at kappa and the full model (200 iters) at kappa/10, then `kpms.plot_kappa_scan(kappas, project_dir, prefix)`. Run as an array, one kappa per task (adapt the fit script: it already takes `--kappa-ar` and `--kappa-full`, set the latter to a tenth of the former and name models by kappa).

## Preparing the data: still periods, filtering, trimming

Collected from upstream issues (#237, #186, #169, #188; not reproduced here, see `common-problems.md`):

- **Long still periods** (sleep, inactivity) are hard for the autoregressive model and can end in NaNs. Build a mask from smoothed centroid speed and a minimum duration, and model the active periods (slice coordinates and confidences, keep the frame index offsets).
- **Odd duration distribution** (many very short syllables although the median is right): drop unreliable keypoints and pre-filter the keypoints (median filter or a short Gaussian) before modelling.
- **Trimming** (animal absent, shelter, start and end of a video): trim `coordinates` and `confidences` after loading and pass `video_frame_indexes` to calibration, grid movies, `overlay_keypoints_on_video` and (0.8.0+) `check_videos`.
- **Jitter**: leave at the default unless NaNs appear; then raise one step at a time and inspect trajectory plots (rule 10 in `SKILL.md`).

## Checking the fit

1. Median duration and the count of syllables above `min_frequency` (0.005 default in plots).
2. Fitting progress PDF (`fitting_progress.pdf` in the model folder).
3. Grid movies / trajectory plots per syllable (`generate_grid_movies`, `generate_trajectory_plots`); needs the videos. This is the only way to judge whether a syllable is meaningful.
4. Multiple seeds: fit about 20 restarts for a final model per docs (`init_model(..., seed=jax.random.PRNGKey(i))`), then `kpms.expected_marginal_likelihoods(project_dir, model_names)` (returns scores and standard errors; verified to run on 0.6.6), choose the best, and compare syllable assignments between runs with `plot_confusion_matrix(results_1, results_2)`. If different seeds give very different syllables, report that instead of presenting one run as the truth.

## Applying a fitted model to new recordings

Load the checkpoint, load and outlier-filter new keypoints, `format_data`, then `kpms.apply_model(model, data, metadata, project_dir, model_name, **config())`. Use `overwrite=True` when re-applying to recordings from the original training set (docs recommend applying to both new and original data to control for assignment differences). Pass `num_iters` explicitly with `ar_only=True`; since 0.8.2 the default is one iteration. Refit instead of applying when the new data differ in setup (camera, body size, keypoint set). Syllables absent in some recordings are expected and give zero counts.

## Advanced options (from the docs, none run here)

- Temporal downsampling: `downsample_timepoints(coordinates, rate)`, then pass `video_frame_indexes` to calibration and movie functions.
- Trimming: slice coordinates and confidences per recording and keep the frame index offsets.
- Merging similar syllables: `generate_syllable_mapping(results, [[1,3],[4,5]])` then `apply_syllable_mapping` and `save_hdf5` to a new file. Keep the original and report the merge rule.
- Location-aware modelling (`location_aware=True`): experimental, not tested in the paper.
- Memory knobs: `parallel_message_passing=False` (about 4-6 times less memory, slower), `set_mixed_map_iters(n)`, `set_mixed_map_gpus(n)`; or fit on a subset and `apply_model` to the rest.

## Data requirements (FAQ)

- A few hours of video (several hundred thousand frames) is the rule of thumb; more data gives more syllables (HDP prior), so rare behaviours need more data.
- Multiple animals of similar size: one model, one key per individual (`<file>_<individual>` for multi-animal DLC, `<file>_track0` for SLEAP; `exclude_individuals` defaults to `['single']`; set `shared_videos=True` in `check_videos`). Different sizes (adults and pups): separate models.
- NaNs: `check_nan_proportions`; consider re-running tracking with a lower detection threshold. Test for tracking quality: can you tell what the animal does from the keypoints alone.
- 3D (anipose) is loadable; grid movies need `keypoints_only=True` or a single camera.
- License: academic use free (Harvard licence); commercial use needs permission. Citation: Weinreb et al. 2024, Nature Methods (https://www.nature.com/articles/s41592-024-02318-2).
