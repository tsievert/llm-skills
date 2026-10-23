# keypoint-MoSeq workflow reference

## Contents

- [Pipeline (interactive Python API, as in the tutorial)](#pipeline-interactive-python-api-as-in-the-tutorial)
- [Output structure](#output-structure)
- [Config keys that matter](#config-keys-that-matter)
- [Kappa (stickiness) and syllable duration](#kappa-stickiness-and-syllable-duration)
- [Checking the fit](#checking-the-fit)
- [Applying a fitted model to new recordings](#applying-a-fitted-model-to-new-recordings)
- [Advanced options (from the docs, none run here)](#advanced-options-from-the-docs-none-run-here)
- [Data requirements (FAQ)](#data-requirements-faq)

Source: kpms stable docs (modeling tutorial, FAQs, advanced topics, io API) read on 2026-10-23, plus runs on 0.6.6. Re-check against the installed version.


## Pipeline (interactive Python API, as in the tutorial)

```python
import keypoint_moseq as kpms
project_dir = "proj"
config = lambda: kpms.load_config(project_dir)

# 1. Load DLC output (csv or h5; folder is searched recursively)
coordinates, confidences, bodyparts = kpms.load_keypoints("dlc_out/", "deeplabcut")
kpms.check_nan_proportions(coordinates, bodyparts, breakdown=True)

# 2. Project + config (setup_project fails if project_dir exists)
kpms.setup_project(project_dir, deeplabcut_config="dlc/config.yaml")   # or bodyparts=..., skeleton=...
kpms.update_config(project_dir, use_bodyparts=[...], anterior_bodyparts=["nose"],
                   posterior_bodyparts=["spine4"], fps=30, video_dir="videos/")

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
model = kpms.init_model(data, pca=pca, **config())
model = kpms.update_hypparams(model, kappa=1e6)
model, model_name = kpms.fit_model(model, data, metadata, project_dir, ar_only=True, num_iters=50)
model, data, metadata, it = kpms.load_checkpoint(project_dir, model_name, iteration=50)
model = kpms.update_hypparams(model, kappa=1e4)
model = kpms.fit_model(model, data, metadata, project_dir, model_name, ar_only=False,
                       start_iter=it, num_iters=it + 500)[0]

# 6. Reindex (checkpoint only), then extract
kpms.reindex_syllables_in_checkpoint(project_dir, model_name)
model, data, metadata, it = kpms.load_checkpoint(project_dir, model_name)
results = kpms.extract_results(model, metadata, project_dir, model_name)
kpms.save_results_as_csv(results, project_dir, model_name)
```

`scripts/kpms_headless_fit.py` implements this headless and resumable. Findings from running it on 0.6.6:

- `fit_model(..., model_name)` accepts a name on the first call, so a chosen name works as the resume key; without it kpms auto-names the folder with a timestamp.
- `extract_results` appends to an existing `results.h5`; the `overwrite` argument documented in the stable docs does not exist in 0.6.6. The script deletes the derived file first, which works on both.
- A custom `setup_project(bodyparts=...)` writes a placeholder skeleton (`BODYPART1`...) that triggers warnings; pass a real `skeleton` (the script builds a chain) or use the DLC config.
- Resuming works from `checkpoint.h5` (latest iteration); the full-model kappa persists in the checkpoint (checked: 1e4 after a resume).

## Output structure

`{project_dir}/{model_name}/results.h5`: one group per recording with datasets `syllable` (frames,), `latent_state` (frames, latent_dim), `centroid` (frames, 2 for 2D), `heading` (frames,). Names containing `/` (from `path_in_name=True`) become nested groups. The per-recording CSV export (`save_results_as_csv`) has columns `syllable, centroid x, centroid y, heading, latent_state 0..k`. Verified on 0.6.6: R and h5py readers equal these.

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
- Fit until duration stabilises: under 10 iterations for AR-only, 10-50 for the full model, then run 200-500 iterations (defaults in the script: 50 AR + 500 full).
- Automatic scan from the docs: `kappas = np.logspace(3, 7, 5)`; per kappa fit AR (50 iters) at kappa and the full model (200 iters) at kappa/10, then `kpms.plot_kappa_scan(kappas, project_dir, prefix)`. Run as an array, one kappa per task (adapt the fit script: it already takes `--kappa-ar` and `--kappa-full`, set the latter to a tenth of the former and name models by kappa).

## Checking the fit

1. Median duration and the count of syllables above `min_frequency` (0.005 default in plots).
2. Fitting progress PDF (`fitting_progress.pdf` in the model folder).
3. Grid movies / trajectory plots per syllable (`generate_grid_movies`, `generate_trajectory_plots`); needs the videos. This is the only way to judge whether a syllable is meaningful.
4. Multiple seeds: fit about 20 restarts for a final model per docs (`init_model(..., seed=jax.random.PRNGKey(i))`), then `kpms.expected_marginal_likelihoods(project_dir, model_names)` (returns scores and standard errors; verified to run on 0.6.6), choose the best, and compare syllable assignments between runs with `plot_confusion_matrix(results_1, results_2)`. If different seeds give very different syllables, report that instead of presenting one run as the truth.

## Applying a fitted model to new recordings

Load the checkpoint, load and outlier-filter new keypoints, `format_data`, then `kpms.apply_model(model, data, metadata, project_dir, model_name, **config())`. Use `overwrite=True` when re-applying to recordings from the original training set. Refit instead of applying when the new data differ in setup (camera, body size, keypoint set). Syllables absent in some recordings are expected and give zero counts.

## Advanced options (from the docs, none run here)

- Temporal downsampling: `downsample_timepoints(coordinates, rate)`, then pass `video_frame_indexes` to calibration and movie functions.
- Trimming: slice coordinates and confidences per recording and keep the frame index offsets.
- Merging similar syllables: `generate_syllable_mapping(results, [[1,3],[4,5]])` then `apply_syllable_mapping` and `save_hdf5` to a new file. Keep the original and report the merge rule.
- Location-aware modelling (`location_aware=True`): experimental, not tested in the paper.
- Memory knobs: `parallel_message_passing=False` (about 4-6 times less memory, slower), `set_mixed_map_iters(n)`, `set_mixed_map_gpus(n)`; or fit on a subset and `apply_model` to the rest.

## Data requirements (FAQ)

- A few hours of video (several hundred thousand frames) is the rule of thumb; more data gives more syllables (HDP prior), so rare behaviours need more data.
- Multiple animals of similar size: one model, one key per individual (`<file>_<individual>` for multi-animal DLC; `exclude_individuals` defaults to `['single']`). Different sizes (adults and pups): separate models.
- NaNs: `check_nan_proportions`; consider re-running tracking with a lower detection threshold. Test for tracking quality: can you tell what the animal does from the keypoints alone.
- 3D (anipose) is loadable; grid movies need `keypoints_only=True` or a single camera.
- License: academic use free (Harvard licence); commercial use needs permission. Citation: Weinreb et al. 2024, Nature Methods (https://www.nature.com/articles/s41592-024-02318-2).
