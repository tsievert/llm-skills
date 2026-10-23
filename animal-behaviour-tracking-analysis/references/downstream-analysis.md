# Downstream analysis of keypoint-MoSeq results (R and Python)

Contents: tidy tables, metadata, R recipe, Python recipe, statistics, transitions, validation and reporting, kpms built-in analysis.

## 1. Tidy tables from results.h5

Three tidy tables carry nearly every analysis. Both languages produce identical columns (verified equal on a real 4-recording results.h5):

| Table | Columns | Use |
|---|---|---|
| bouts | recording, syllable, start_frame, end_frame, n_frames, duration_s, bout_index | dwell time, sequences |
| usage | recording, syllable, n_frames, n_bouts, mean_bout_s, frame_fraction, bout_fraction (zeros included) | group comparisons of usage |
| transitions | recording, from, to, n (bout-level, no self-transitions) | transition matrices and graphs |

These definitions are this skill's own. kpms' `compute_stats_df` reports a `frequency` column; check its docs before assuming it equals `frame_fraction` or `bout_fraction`.

R (needs `hdf5r`; installing from CRAN is fine):

```r
source("scripts/kpms_results.R")
frames <- kpms_read_frames("proj/run1/results.h5")        # latent = TRUE adds latent_state columns
bouts  <- kpms_bouts(frames, fps = 30)
usage  <- kpms_usage(bouts)
trans  <- kpms_transitions(bouts)
```

Python (h5py, numpy, pandas only; no JAX):

```bash
python scripts/kpms_summarise_results.py proj/run1/results.h5 --out summary --fps 30
```

`--min-bout-frames` / `min_bout_frames` drops very short bouts. That makes the sequence discontinuous, so report it. Default keeps everything.

## 2. Metadata join (do this deliberately)

`recording` is the file name without extension (or `<file>_<individual>` for multi-animal DLC). Build a metadata table with one row per recording: animal ID, group or treatment, session/day, arena, camera, duration, and anything that could confound (time of day, batch). Then:

```r
meta  <- read.csv("metadata.csv")
usage <- merge(usage, meta, by = "recording", all.x = TRUE)
stopifnot(!anyNA(usage$group))     # unmatched recording names are the usual failure
```

DLC file names usually carry a long network suffix (`..._DLC_<network>_...`). Strip it in a documented step (for example `sub("DLC_.*$", "", recording)`) and check the result is unique and matches the metadata keys.

## 3. Statistics: what is the unit and what is the question

Short version here; the full path from metric tables to models (tidy layout, model per metric type, design issues, reporting) is in [statistical-analysis.md](statistical-analysis.md), with runnable templates in `scripts/stats_demo.R`.

- **Unit**: recording, nested in animal. Frames and bouts are not independent samples. Aggregate to the animal or use a random intercept for animal (and session if repeated).
- **Normalise**: usage counts depend on how long each recording is. Use counts with `offset(log(total))` or fractions, not raw counts, when recording lengths differ.
- **Per-syllable counts** (tested on simulated data; glmmTMB 1.1.15.2, emmeans 2.0.4):

```r
library(glmmTMB); library(emmeans)
fit_one <- function(d) {
  m <- glmmTMB(n_bouts ~ group + offset(log(total)) + (1 | animal), family = nbinom2, data = d)
  as.data.frame(pairs(emmeans(m, ~ group), reverse = TRUE, type = "response"))   # rate ratios
}
# usage must contain `total` = total bouts (or frames) per recording
res <- do.call(rbind, lapply(split(usage, usage$syllable),
                             \(d) cbind(syllable = d$syllable[1], fit_one(d))))
res$p_adj <- p.adjust(res$p.value, "BH")
```

  Check each model with DHARMa residuals for the syllables you report; sparse syllables with many zeros may need zero-inflation or exclusion. With few animals per group the random-effect variance is poorly estimated; say so.
- **Which syllables**: fix a usage threshold before looking at groups (kpms plots use `min_frequency` 0.005 by default) and report how many syllables were tested and adjusted over. Do not pick syllables because they differ.
- **Compositional view**: usage shares sum to 1. For whole-repertoire questions consider a compositional method (`DirichletReg`, `compositions`) or a multivariate test on usage (vegan PERMANOVA with permutations restricted by animal). None of these were run in this skill; check assumptions and zero handling before use.
- **Dwell times**: `duration_s` is positive and right-skewed; models such as Gamma or log-normal mixed models with animal and recording random effects are options. Not tested here.
- **Time-resolved questions** (change over a session or after a stimulus): use `frame`/`start_frame` with the stimulus times from your protocol, bin to seconds, and fit a GAM (see `gam-mgcv`). Syllable usage is not stationary within a trial.
- If groups differ in tracking quality or NaN fraction, syllable usage can differ because of the tracking, not the behaviour. Compare NaN proportions between groups first.

## 4. Transitions

```r
library(igraph)
tm <- aggregate(n ~ from + to, data = trans[trans$recording %in% group_a, ], FUN = sum)
tm$p <- tm$n / ave(tm$n, tm$from, FUN = sum)      # row-normalised: P(next = to | from)
g  <- graph_from_data_frame(tm[tm$n >= 10, c("from", "to", "p")])
```

(`igraph` code not run in this skill; the transitions table itself was tested.) Notes:

- Transition counts are sparse for rare syllables; threshold and say so. Row-normalised matrices ignore how often the source syllable occurs; also show usage.
- kpms docs offer `generate_transition_matrices(..., normalize="bigram"|"rows"|"columns")` and graph plots; they require the `index.csv` group file. Check the output of `interactive_group_setting` once on a workstation to see the file format, or write it by hand with a `group` column per recording.
- Group differences in transitions need replication across animals; a difference between two pooled matrices is not a test.

## 5. Validation and reporting

1. Show or describe syllables from grid movies/trajectories; name them only after viewing. Keep a table: syllable number, label, evidence (movies reviewed, by whom).
2. Report kpms and jax versions, seed(s), kappa for AR and full model, iterations, `latent_dim`, bodyparts used, fps, recordings included, any merge or min-bout rule, number of syllables above the threshold.
3. State how stable the syllable set was across seeds.
4. Deposit `results.h5`, `config.yml`, the checkpoint (or its summary), the metadata table and the scripts with the data (see the planned `reproducible-research-data` skill).
5. Remember the model is fit to pose, not to behaviour labels: a syllable is a statistical pattern of movement and is not guaranteed to be a behaviour in the ethological sense.

## 6. kpms built-in analysis (Python)

Signatures checked on 0.8.0 (run on synthetic data; they changed from 0.7.x, so check `help()` on older installs): `compute_moseq_df(project_dir, model_name, fps=None, smooth_heading=True)` (columns name, centroid_x/y, heading, angular_velocity, velocity_px_s, syllable, frame_index, group, fps, onset; `fps` comes from the config if not given) and `compute_stats_df(moseq_df, min_frequency=0.005, groupby=["group","name"])`. The old call `compute_stats_df(project_dir, model_name, moseq_df, ..., fps=30)` raises `TypeError` on 0.8.0. Per the 0.8.0 notes, other renames (grid movies: `pre`/`post`/`min_duration`/`filter_size` became `before_onset_sec`/`after_onset_sec`/`min_instance_duration_sec`/`smoothing_filter_frames`) are silently ignored when the old names are passed; not run. Other functions:  `plot_syll_stats_with_sem(...)` for group tests, `generate_transition_matrices`, `visualize_transition_bigram`, `plot_transition_graph_group`, `label_syllables` (writes `syll_info.csv`). Use these for quick looks; for mixed-model inference export the tables and analyse in R or statsmodels, because the built-in group tests treat each recording as independent and offer no covariates or interactions (verified in the 0.6.6 source: permutation Kruskal-Wallis with BH correction plus Dunn post hoc, one `group` column; details in [statistical-analysis.md](statistical-analysis.md)).
