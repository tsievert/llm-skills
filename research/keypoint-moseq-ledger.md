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

## Round 3 (2026-10-29): publication and citing literature (OpenAlex, R/httr2; MCP `search_works` not available this session)

Requirement 2 (2026-10-29): expand kpms research with the publication and citing papers to find use cases and downstream workflows, as groundwork for a possible split into a `keypoint-moseq` skill. Downloads of full texts not done (opt-in rule).

| Source | Status | Notes |
|---|---|---|
| OpenAlex W4400580347 (Weinreb et al. 2024, Nature Methods, doi 10.1038/s41592-024-02318-2) | partial | abstract only (truncated by API after the benchmark sentence); 228 citations at query time |
| OpenAlex W4327861594 (bioRxiv preprint 2023) | partial | 65 citations |
| `cites:` both works, union | read (metadata) | 264 works (227 article + 65 preprint, 28 overlap); 2022: 2, 2023: 14, 2024: 49, 2025: 103, 2026: 96 |
| `cites:` + `fulltext.search:moseq` | read (metadata) | 130 works mention "moseq" anywhere in full text (107 via article, 42 via preprint); a mention is NOT proof of use. Only 15 of 264 name MoSeq/syllables in title or abstract |
| Abstracts of ~24 selected works | read | see use cases below; 34 of 264 citing works have no abstract in OpenAlex |
| Nature Protocols W4400033882 (Motion Sequencing protocol, 2024) | not read | no abstract in OpenAlex; it is the depth-camera MoSeq protocol, to check before citing as kpms |
| Wiltschko 2015 original MoSeq, full texts of any paper, GitHub issues/discussions | not researched | |

Facts (abstract-level, no full text read):
- Workflow shape seen repeatedly: DLC or SLEAP (also Lightning Pose, SuperAnimal papers cite kpms) -> kpms syllables -> compare syllable usage/sequence between groups -> tie to neural recordings or interventions.
- Group comparison use cases: drug/treatment response (L-DOPA in Parkinsonian mice, W4412727576; THC, W4414581453; trihexyphenidyl in a dystonia model, W4413380326), disease models (Shank3B, W7164179139; Cntnap2, W4396812056; Parkinsonian mice and vestibular stimulation, W7172424495), injury and recovery (spinal cord injury syllables, W4388211385 and W7134134185), stress/depression/early life stress (W4413908225, W7117580436), social context (W4415982955: 25% of syllables modulated, mostly stationary/undirected), aging (W4413789606 second-order conditioning with DLC + kpms + DeepOF; killifish lifelong tracking W4416570278), learning paradigms.
- Species beyond mouse: marmoset (W4399734846, W4402095293), larval zebrafish (W4399116371), Drosophila (W4386910036, SLEAP), infants (W4404501344, state-space), elephants (review).
- Brain-behaviour: striatal lesion/recording (W4387669747), noradrenergic arousal and movement transitions (W4416591260), mesoscopic imaging with behaviour alignment (W4387896146), photometry/olfactory bulb and ephys papers cite kpms for alignment.
- Methods benchmarks that include kpms: W4409654348 (Patterns 2025: B-SOiD, BFA, VAME, kpms), W4401413035 (action segmentation algorithms), DeepOF (W4380368899), W4405011049 (combining supervised and unsupervised), OpenLabCluster, TASC, GESTURE, TiDHy, masked-autoencoder hierarchy papers. Implication: users will ask "kpms vs B-SOiD/VAME"; the skill currently says out of scope and could carry a short comparison with a pointer.
- Software: Dynamax (JAX state-space package, W4409141507) cites kpms as an application; kpms builds on jax-moseq.
- Reviews usable as orientation: W4400033882 (protocol), W7169163913 (HMMs in neuroscience, 2026), W7119477633 and W7207880142 (computational neuroethology).

Gaps this round could not answer (need full text): kappa chosen in real studies, number of keypoints, how groups were tested (mixed models, permutation, MANOVA, Jensen-Shannon/KL), which min_frequency, whether results were pooled across batches, how syllables were named/validated.

Open research items (add):
- Pick 6-8 methods-heavy open-access papers (candidates: W4415982955, W4413789606, W4412727576, W4388211385, W4413908225, W7164179139, W4409654348) and read methods for stats and kappa choices; needs user approval for downloads (`fetch_epmc_xml`/`fetch_fulltext`, free route first).
- Check Nature Protocols W4400033882 and the Weinreb 2024 methods for the intended downstream analysis.
- Check kpms GitHub issues/discussions for recurring user problems (not searched).

Log:
- 2026-10-29 (round 3): OpenAlex lookups listed above; query code reuses httr2 against api.openalex.org with `cites:`, `fulltext.search:` filters (both work with the free key). Pitfall: do not name an R variable `key` if a helper reads it as the API key.

## Round 4 (2026-10-29): methods of citing papers (full text, free routes only)

Requirement 3 (2026-10-29): user approved fetching 7 papers via free routes only (no metered OpenAlex content API); extract kpms methods, stats tests, kappa choices. Tools: `fetch_fulltext(allow_paid = FALSE)`, `fetch_epmc_xml`, `oa_ft_grep`. Files were in git-ignored `tmp-examples/ft/` and deleted afterwards.

| Paper | Status | Notes |
|---|---|---|
| W4412727576 eNeuro 2025 (Parkinsonian mice) | read (PMC12333470 XML) | uses **depth-camera MoSeq** terminology/Kinect? see below: recorded with Kinect 2.0 and FLIR cameras, 30 fps; kappa scan, Gibbs sampling; cites Weinreb 2024 for model parameters |
| W4415982955 Frontiers Behav Neurosci 2025 (social context) | read (PMC12634660 XML) | SLEAP + kpms **0.4.1**, 10 of 12 keypoints (tail excluded) |
| W4413789606 Cell Reports Methods 2025 (second-order conditioning) | read (PMC12539235 XML) | DLC + kpms + DeepOF |
| W4409654348 Patterns 2025 (benchmark of 4 tools) | read (PMC12142628 XML) | B-SOiD, BFA, VAME, kpms compared on 10-min recordings with manual labels by 3 experts |
| W4388211385 SCI bioRxiv 2023 | partial | **not kpms**: depth-camera MoSeq (moseq2-pca v1.1.3, 10 PCs, max 100 states, Kinect-type depth, usage = emissions per module / total per session, Pearson correlation of modules with BMS, LDA of usage). Lesson: "MoSeq" in a citing paper may mean the depth-based original |
| W7164179139 Shank3B 2026 | partial | PDF read, only 2 "moseq/syllable" hits; mostly other ML features (FDR, Fisher exact for transitions, linear SVM); not a kpms workflow example |
| W4413908225 early life stress bioRxiv | blocked | `oa_but_no_direct_pdf`, not in PMC; not read |

Facts (from the methods text, wording paraphrased):
- Kappa selection is by target syllable duration, not by a metric: eNeuro paper scanned kappa and chose the model whose syllable duration matched ~400 ms (~12 frames at 30 fps) and whose grid movies were behaviourally recognisable to an experienced observer; the Frontiers paper chose kappa iteratively so the median syllable length was 10 frames (~400 ms); the Patterns benchmark used kappa 1e-6 giving a median motif of 520 ms (and states that kappa changes both number of clusters and median duration); the CRM paper used kappa 1e10 and 1e4 (two models), nine latent dimensions (90% variance explained), tail keypoints excluded for low tracking reliability. These match the skill's kappa guidance (scan, target median duration); the wide range (1e-6 to 1e10) is why the skill should not suggest a "default" kappa.
- Keypoint choice: tail excluded in two papers (10 of 12 keypoints; low reliability).
- Stats on syllables: eNeuro paper used the kpms package's Kruskal-Wallis with Dunn post hoc (Benjamini-Hochberg, FDR 0.05) for usage and velocity across conditions, plus entropy rate of the transition matrix; Patterns paper Kruskal-Wallis + Dunn with Holm/FDR on median motif durations; Frontiers paper chi-square proportion tests and Mann-Whitney U with Bonferroni on syllable onset proportions and per-syllable transition probabilities, PCA on syllable usage and "syntax" proportions; CRM paper pooled syllable counts in 1-min bins before/after cue, tested multivariate shift with Hotelling's T2 (after a Henze-Zirkler normality check), per-syllable one-way ANOVA or Kruskal-Wallis with post hoc Tukey/Wilcoxon, transition matrices per mouse (self-transitions removed, averaged per condition), compared via Manhattan distance with permutation tests, Shannon entropy of transitions, IoU of behavioural profiles with permutation tests, DeepOF traits for interpretability.
- Pattern across papers: none of the four used mixed models with animal as random effect on syllable usage; tests mostly treat syllables or animals as independent units. The skill's `statistical-analysis.md` (mixed models, compositional cautions) goes beyond common practice; say so and explain why (pseudoreplication, compositional usage).
- Reporting gaps in the papers: kpms versions often not stated (one states 0.4.1), no latent_dim in most, seeds/number of fits not stated; the skill's provenance step (step 7) addresses this.
- Practical: time-binned syllable counts around stimuli (peri-stimulus) is a common design; `compute_stats_df` does not cover it (needs custom code from `moseq_df`/results.h5).

Pitfalls found: eNeuro paper's text says "MoSeq" yet uses kappa/alpha/gamma defaults like kpms and cites Weinreb 2024 while recording with Kinect; the document does not say whether depth data or keypoints were modelled (unclear, not resolved). Two PDFs from the OpenAlex step were HTML pages saved as `.pdf` (W4412727576, W4413789606, W4409654348 files were not valid PDFs: errors from `pdftools`); the XML route from Europe PMC was the reliable one for biomedical OA papers.

Open items now: read W4413908225 (needs manual download); Nature Protocols and the Weinreb 2024 methods; GitHub issues/discussions for common problems; decide whether to add a "comparison to B-SOiD/VAME" and "peri-stimulus design" section to a `keypoint-moseq` skill.

Log: 2026-10-29 round 4 as above; `tmp-examples/ft` removed.

## Round 5 (2026-10-29): GitHub issues (user problems)

Requirement 4 (2026-10-29): search kpms GitHub issues and discussions for recurring user problems.

| Source | Status | Notes |
|---|---|---|
| github.com/dattalab/keypoint-moseq issues via REST API (unauthenticated) | read | 228 issues (PRs excluded): 201 closed, 27 open; created 2023: 85, 2024: 54, 2025: 46, 2026: 43. No `gh` CLI on this machine, used httr2 |
| GitHub Discussions | blocked | `has_discussions = false`; help also goes through Slack (mentioned by maintainers; not searchable) and email |
| ~16 threads read (maintainer replies) | read | #153, #237, #143, #186, #260, #226, #218, #176, #188, #169, #262, #236, #227, #170, #108, #149 (last two only partly) |

Counts by title keyword (overlapping, rough): GPU/JAX/CUDA/install/Jupyter 54, loading data 39, stats/plotting/analysis 38, grid/trajectory movies 33, syllables/duration/kappa 30, NaN/fitting 26, calibration 16, apply_model/new data 13. Most-discussed: calibration with downsampling (#153, open, 45 comments), group-comparison plot errors (#140), calibration stalls (#122), grid-movie slicing (#149), maDeepLabCut load error (#128).

Recurring problems and maintainer answers (paraphrased):
- **NaNs during fitting**: no general fix; clean keypoints, remove sessions with many errors (#153); long sleeping periods are hard for the AR model, so mask sleep/still periods with a centroid-speed threshold and model the rest separately (#237, WSL2 GPU).
- **Odd syllable duration distribution** (many very short syllables, #186): drop tail keypoints, pre-filter (median or short Gaussian) before modelling; the median alone can match while the shape is off.
- **apply_model differs from extract_results** (#143): the full model estimates syllables and pose together, so results vary; the ar_only model is more stable and consistent between fit and apply. Not reproduced by maintainers. New data raising the syllable count (#176): run apply in batches; csv/h5 contain all syllables but grid movies and trajectory plots only show those above `min_frequency`.
- **apply_model overwrote results.h5** (#218): results are keyed by recording name; identical names in old and new `coordinates` overwrite. Check `coordinates.keys()` differ.
- **Trimming** (#169, #188): trim coordinates/confidences after loading and pass `video_frame_indexes` to calibration, grid movies, `overlay_keypoints_on_video` (and `check_videos` from 0.8.0); misalignment between indexes, coordinates and videos is the usual cause of wrong overlays. Added in 0.4.10.
- **White dot far from animal in grid movies** (#262): centroid speed prior; since 0.6.3 the notebook has an `estimate_sigmasq_loc` cell, older versions hard-coded it; upgrade and refit.
- **Calibration** widgets/stalls/downsampling (#108, #122, #153, #229, 16 issues): long-running theme; downsampling to 200 -> 40 fps via the built-in factor failed in calibration (open).
- **Group-comparison statistics** (#226, #260): the plot flags syllables with Kruskal-Wallis per syllable and FDR across syllables and groups; stats not returned in 0.6-era releases, added to FAQ; matches the skill's note that kpms tests go beyond default use but are simple.
- **Large data / multi-GPU** (#236): turn off parallel message passing, raise `mixed_map_iters` (maximum about n_recordings / n_gpus, 32 used before); for very large data fit on a subset then apply to the rest.
- **JAX version breaks** (#227): jax 0.6 broke `init_model`; fixed by new jax-moseq; the skill's pin note (jax-moseq >= 0.3.8) fits this pattern: install problems recur with each JAX release.
- **Loaders**: SLEAP csv with only 3 bodyparts is "really pushing it" for single-animal syllables (#170); a user's loader bug was `os.path.basename` without the argument.

Coverage check of the skill (grep, not a review): `min_frequency`, `estimate_sigmasq_loc`, `ar_only`, trimming and `video_frame_indexes`, `mixed_map_iters`, Kruskal-Wallis, batching are already mentioned. **Not mentioned**: sleep/still-period masking before fitting (#237), the apply_model recording-name overwrite risk (#218, partly covered by `extract_results` overwrite note, check), pre-filtering for odd duration shape (#186), minimum keypoint count guidance (#170).

Open items: read #140, #122, #229 (calibration and plotting problems) if the skill is to gain a calibration troubleshooting table; check whether #153 (downsampling) is still open on 0.8.3; Slack is not searchable.

Log: 2026-10-29 round 5 as above.

## Round 6 (2026-10-29): calibration threads (#122, #153, #229)

Sources: GitHub REST API, issues #122 (closed, 15 comments, 2024), #229 (closed, 5 comments, 2025), #153 (open, 45 comments; first ~22 comments read in full, the last ones only skimmed, the final state of the downsampling problem is not confirmed). Status: read (#122, #229), partial (#153).

### Calibration troubleshooting table (noise calibration widget, `noise_calibration`)

| Symptom | Cause found in thread | Fix | Source |
|---|---|---|---|
| Widget shows frame but clicks place no "X", yellow circle fixed, Prev/Next do nothing | Missing `%matplotlib widget` (ipympl) before calling `noise_calibration` in a self-written notebook | Run `%matplotlib widget` first (the provided notebook has it) | #229 (2025) |
| Keypoints and "x" only in the first frame, or no widget at all, no error | Widget run outside JupyterLab or from a different environment; old kpms (0.4.2); package state after updating | kpms >= 0.4.3, run from JupyterLab launched inside the kpms environment; update JupyterLab; reload JupyterLab; reinstall via conda helped two users, pip did not; low memory suspected by a maintainer; unrelated holoviews plots failing was a symptom of the same extension problem | #122 (2024; versions: jupyterlab 4.0.10, panel 1.3.6, bokeh 3.3.3, holoviews 1.18.1) |
| Calibration loads 30-50% of frames then errors with a frame index far larger than any recording (e.g. 270590) after downsampling | Stale `error_annotations.csv` in the project directory from an earlier non-downsampled calibration run; calibration reads old annotation frame indices | Delete `error_annotations.csv` (and re-annotate) after changing downsampling or the data | #153 |
| Frames load glitchy, images lag after first few, need to wait | Known backend problem of the widget; maintainers planned a new backend (not confirmed which release) | Wait, advance one frame at a time; unresolved in thread | #153, #122 |
| Occluded keypoint: skip the frame or guess? | Maintainer answer | Place the marker where you estimate the keypoint to be | #229 |
| After downsampling (200 to 40 fps, factor 5), IndexError in `overlay_keypoints_on_video`/grid movies and trajectory plots with weird scale; only very few syllables found; fine without downsampling | Not resolved in the thread (maintainer unsure; suggested checking exported inferred coordinates and trying 2x); possibly videos not downsampled to the same frame count as coordinates | Use `video_frame_indexes` consistently (see trimming in Round 5), check `len(coordinates[key])` against video frame counts, try smaller factors; treat as unresolved | #153 (open) |

Checks the maintainer used that are worth giving users: compare `len(coordinates[key])` with the video frame count for every recording (via `kpms.find_matching_videos` and `vidio.read.OpenCVReader`) before and after downsampling; start from freshly loaded coordinates (double-downsampling is a possibility); export inferred coordinates (`advanced.html#exporting-pose-estimates`) and look for negative or huge values.

Skill coverage (grep): `error_annotations`, `%matplotlib widget`, ipympl not mentioned anywhere in `animal-behaviour-tracking-analysis`. Calibration troubleshooting table above would be new content. Downsampling advice should note the unresolved open issue and not promise it works. Not checked: whether 0.8.3 changed the widget backend (0.8.0 release notes in the ledger mention `check_videos` but nothing on calibration), and the state of #153 after the first 22 comments.

Log: 2026-10-29 round 6 as above.

## Round 7 (2026-10-29): open questions and non-rodent / non-neuroscience evidence

Requirement 5 (2026-10-29): check which questions remain open; look at publications outside rodent neuroscience or with non-rodent examples. Free routes only (Europe PMC XML, OA locations); files in git-ignored `tmp-examples/` deleted afterwards.

### Correction to Round 6 (#153, rest of the thread read, 45 comments)
The downsampling error was the stale `error_annotations.csv` (row stands). The later "weird, small trajectory plots / only 2 syllables / IndexError in overlay" problem was **not** shown to be a downsampling bug: the maintainer fit the user's data in several configurations (latent_dim 2 or 4, with/without the bad recordings, location-aware or not, 5x downsampling or none) and always got reasonable plots; the user then found the odd plots appeared with `jitter = 1e-1` (suggested earlier to cope with NaNs) and not with `jitter = 1e-2`, and that a stale JupyterLab kernel state could also hold wrong coordinates (restart fixed the non-downsampled plots). The maintainer also noted two recordings with failed tracking, that the kappa maximum 1e7 in docs is "typically high enough" but higher values can be needed for high-speed video (200 fps), and that error calibration only changes results via `error_estimator` slope/intercept in the config. Final state: user's issue never confirmed solved; issue still open. Update to the calibration table: replace the last row's cause with "jitter at the maximum (1e-1) with NaN-heavy data produced odd coordinates and trajectory plots; restart the kernel; check tracking failures; kappa may need to exceed 1e7 for 200 fps" (unresolved).

### Source of the method: Weinreb et al. 2024 (PMC11245396, read)
- The paper itself demonstrates **mice, rats and fruit flies**: rats via published 3D motion capture (Rat7M, operant arena with a lever press syllable); fruit flies via a published LEAP 2D keypoint dataset (1 h recordings at 100 fps, four 1 h sessions analysed), where lower/higher target timescale (kappa) gave motifs from tens to hundreds of ms and recognisable locomotion/grooming comparable to MotionMapper; mice also at the sniff timescale and from 2D vs 3D keypoints (7 keypoints for CalMS21 vs 21 for TopViewMouse), with benchmarks against accelerometry, neural recordings and human-annotated social behaviour. So the "non-rodent" capability is documented in the primary paper (flies), not only in later work.
- Explicit method point: depth-camera MoSeq (inputs depth video, "stickiness" hyperparameter) is the predecessor; kpms was built because jitter in keypoint estimates makes MoSeq-like models flicker. Confirms the depth-vs-keypoint wording the skill should use. Nature Protocols paper (10.1038/s41596-024-01072-0) not in Europe PMC; still unread, expected to describe depth MoSeq.

### Non-rodent and non-neuroscience citing works actually checked
| Work | Species / field | Status | Finding |
|---|---|---|---|
| W4404501344 Sci Rep 2024, infant movements | human infants | read (PMC11576873) | **Does not use kpms.** Own state-space model (k = 1, 10, 15 states compared); mentions movement "syllables" as motivation |
| W4399116371 PNAS 2024, larval zebrafish navigation | zebrafish | read (PMC11588111) | **Does not use kpms**; own multiscale models; kpms only in reference list |
| W4386910036 PLoS CB 2025, Drosophila long timescale | fly (SLEAP, 100 fps, 7 days) | read (PMC11813078) | **Does not use kpms**; lists it as an alternative that fails at long timescales/volumes |
| W4411763866 Sci Adv 2025, multi-monkey 3D | macaques | read (PMC12204171) | Reference list only |
| W4411046496 zebrafish seizure (Commun Biol 2025) and W4399140906 behavioural pharmacology (eLife) | zebrafish | read (PMC12141442, PMC11832171) | Reference/thought experiment only; no kpms use |
| W4405526681 eLife 2024 marmoset natural behaviour (also W4402095293 preprint) | marmoset | read (text from OA PDF) | Mentions kpms and syllables only in the Discussion and review responses; own approach; no kpms use found |
| W4410388206 julius seizure flies | fly | read | LSTM classifier; kpms reference-only |
| W4388205568 human activity recognition | human | read | cites kpms in a literature survey; no use |
| W4399734846 marmoset (Curr Biol), W4416570278 killifish, W7214791008 dairy cattle video analytics (SSRN), W4401406797 zebrafish social states | marmoset, killifish, cattle, zebrafish | **not read** | no open text reachable (paywall, HTML-only, SSRN needs metered API); abstracts do not name kpms |

Result: of 14 non-rodent/other-field citing works examined or screened, none was confirmed to run kpms on its own data. A full-text "moseq" hit in non-rodent papers mostly means a citation. A title/abstract search of the whole 2024-26 corpus found 15 works naming keypoint-moseq, all mouse neuroscience except benchmarks and datasets (also: open-field entropy/spectral metrics with AVATAR-3D keypoints W7130817800; supervised plus kpms frailty/ageing clock in mice W7140377619; Huntington model W7211903820; compound discrimination across contexts W7170964837). Consequences for a skill: (1) the only documented non-rodent applications are in Weinreb 2024 (fly, 100 fps; rat 3D); (2) no evidence in this search of use on livestock, birds, fish, primates or humans, so the skill should not claim it works for them and should say it is untested for them and what to check (keypoint count, jitter, egocentric alignment needs anterior/posterior keypoints, timescale/kappa scan against species-specific bout durations, keypoint tracking quality); (3) kappa must be re-scanned per frame rate and species (200 fps and 100 fps cases above).

### Which earlier open items are now closed
- Nature Protocols and Weinreb methods: Weinreb read (above); Protocols still unread (not essential: depth MoSeq).
- #153 end state: read (above); remains open upstream.
- Closed as answered: kappa choices (Round 4), common stats (Round 4), issue themes (Round 5).

### Still open
- Whether 0.8.3 changed the calibration widget or fixed #153's jitter/NaN behaviour (not tested; widget cannot be tested headlessly).
- `apply_model` consistency on 0.8.3 and the recording-name overwrite (#218) with 0.8.3's `extract_results(overwrite=...)` (partly addressed by 0.8.2 notes; not run).
- Whether kpms is used outside neuroscience (ethology, agriculture, wildlife): not found; searching with species-specific tracking tools (DLC for wildlife, SLEAP for flies) and non-"moseq" wording (for example "autoregressive hidden Markov", "switching linear dynamical") would be the next attempt; unpublished GitHub usage and Slack are not searchable.
- Closed-access papers (Curr Biol marmoset, killifish, ELS bioRxiv) need manual download by the user if their methods matter.
- Unclear whether "MoSeq" in the eNeuro Parkinson paper means depth or keypoint (Round 4); a re-read of its methods would settle this.

Log: 2026-10-29 round 7 as above. Another sighting of the earlier lesson: `fetch_fulltext()` saved an HTML page as `.pdf` for a bioRxiv record while still reporting `downloaded`/manifest ok for other files; the first-bytes check (`%PDF-`) found HTML in `W4416570278.pdf`.

## Round 8 (2026-10-29): skill split done

Requirement 6 (2026-10-29): create the `keypoint-moseq` skill with the corrected jitter caution, the calibration table and a "species and frame-rate checks" section; trim `animal-behaviour-tracking-analysis` to metrics. Done: findings from rounds 3-7 are in `keypoint-moseq/references/common-problems.md`, `use-cases-and-literature.md`, `syllable-statistics.md`, `SKILL.md` (rule 10, species section). The existing "jitter 1e-1" advice in `hpc-and-troubleshooting.md` was corrected. No new searches this round.

## Round 9 (2026-10-30): release 0.8.4 notes

Source: `gh api repos/dattalab/keypoint-moseq/releases` (0.8.4, published 2026-10-29; read, not run locally; `gh release view` failed, use the api route).
- Result-changing: `compute_stats_df` rows for every recording x syllable (frequency 0, NaN otherwise, #306); `run_kruskal` ignores NaN, skips constant/empty-group syllables, tied permutations counted (p-values were too small in 0.8.3); circular `heading_mean/std` (#314); density-sampled grid movie windows in seconds (#315); `overlay_keypoints_on_video` honours `video_frame_indexes` (#300); `init_model(location_aware)` keeps `allo_hypparams` (#304).
- Fixes: `update_hypparams` raises for structural params (#310); `plot_syllable_frequencies` sorting; `update_config` numpy values and unknown keys (#313); pandas 3 `syll_info.csv` (#324).
- Skill updated: workflow version table, syllable-statistics, downstream-analysis, SKILL.md. Open: run 0.8.4 locally (headless script, `compute_stats_df` row counts, `run_kruskal`), check `kpms_summarise_results.py` comment about `frequency`.

Local test 0.8.4 (2026-10-30, Windows, uv venv Python 3.12, CPU, synthetic DLC csv 6 x 1500 frames x 5 bodyparts, in git-ignored `tmp-examples/k084`, to delete):
- `kpms_headless_fit.py` fresh and resumed fine (resume reported only the remaining 2 of 6 iterations). `check_nan_proportions` still prints a Styler repr in scripts.
- `compute_stats_df(min_frequency=0)`: 498 rows = 6 recordings x 83 syllables; 294 rows frequency 0; 298 NaN duration (4 more: only first/last instance). Heading columns `heading_mean/std/min/max`. Velocity columns are `velocity_px_s_*`. Default `min_frequency` 0.005.
- `run_kruskal` returns a tuple (DataFrame, DataFrame, dict); prints a warning when most syllables have a group with < 3 values; 3 vs 3 non-overlapping gave p_adj 0.10.
- Not run: grid movies, overlay, update_hypparams/update_config, location_aware.
