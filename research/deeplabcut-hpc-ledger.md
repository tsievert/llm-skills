# deeplabcut-hpc research ledger

Skill: `deeplabcut-hpc`. Status: round 1 done 2026-10-29. No cluster access; all facts are from docs, the GitHub API and release notes.

## Requirements

| # | Requirement | Date |
|---|---|---|
| 1 | Research the skill against current DeepLabCut 3.x docs | 2026-10-29 |
| 2 | Split the tuning and sweep sections out of SKILL.md into `references/` | 2026-10-29 |

## Sources

| Source | Status | Finding |
|---|---|---|
| https://deeplabcut.github.io/DeepLabCut/llms.txt | read | Entry point unchanged (manifest, docs.jsonl, api.jsonl, API reference) |
| .../knowledge/manifest.json | read | `latest-release` alias = 3.0.2; versions `3.0.2`, `main`; docs.jsonl unversioned |
| .../knowledge/3.0.2/api.jsonl | read (signatures only) | Real path works; no `available_models` entries |
| .../docs/pytorch/pytorch_config.html | read | Keys and defaults, see Facts |
| .../docs/pytorch/architectures.html | read | `net_type` list, see Facts |
| .../docs/installation.html | read | Python 3.10-3.12 unchanged; extras unchanged; TF deprecation by 3.2 (TBD) |
| .../docs/pytorch/user_guide.html | partial (first 90 kB of 726 kB) | Epochs not iterations; `engine: pytorch` in config.yaml; `available_models()` |
| .../docs/recipes/BatchProcessing.html | read | TF-era API, does not address DLC 3 |
| GitHub releases API (v3.0.0 to v3.0.2) | read | Dates and notes below |
| GitHub PR 3148 (custom augmentation) | read | Still open, unmerged, base `main`, last updated 2026-03-30 |
| GitHub issue 2753 (augmentation inconsistencies) | read | Closed 2024-10-18 (completed) |
| `gh` CLI | blocked locally | Not on PATH on this machine; keyless GitHub REST API via fetch works instead |
| forum.image.sc, DLC source code | not researched | |

## Facts

- Releases: v3.0.0 2026-05-22, v3.0.1 2026-07-28 (Pydantic `ProjectConfig`, docs overhaul, torch 2.13 lock), v3.0.2 2026-09-23 (`analyze_videos` honours `overwrite`; empty/`null` YAML fields treated as unset; numpy/matplotlib upper bounds removed). rc14 had `conditions:` moved under `inference:` and pandas restricted to <3.0.
- `train_network` (3.0.2) args include `epochs`, `save_epochs`, `batch_size`, `detector_epochs`, `detector_batch_size`, `snapshot_path`, `detector_path`, `device`, `engine`, `pytorch_cfg_updates`, `gputouse`, `max_snapshots_to_keep`.
- `evaluate_network` takes `shuffles` (lowercase), `plotting=False` by default, `engine`, `snapshots_to_evaluate`, `per_keypoint_evaluation`, and `**torch_kwargs`. **CORRECTION 2026-10-29 (round 2):** round 1 inferred that `Shuffles=` is silently swallowed. Wrong: `compat.py` at v3.0.2 has `@renamed_parameter(old="Shuffles", new="shuffles", since="3.0.0")`, so the old spelling works as an alias, and the benchmarking guide still uses `Shuffles=`. `snapshotindex` and `detector_snapshot_index` pass via `**torch_kwargs` to the PyTorch evaluator.
- `analyze_videos`: `batch_size`, `destfolder`, `overwrite`, `auto_track`, `engine`; no `plotting`.
- `create_training_dataset` uses `num_shuffles`/`Shuffles`, `net_type`, `detector_type`, `engine`, `ctd_conditions`.
- `pytorch_config.yaml` defaults: `train_settings` batch_size 1, dataloader_workers 0, dataloader_pin_memory true, display_iters 500, epochs 200, seed 42; `runner` key_metric `test.mAP`, eval_interval 1, snapshots max_snapshots 5 / save_epochs 25 / save_optimizer_state false; `data.train` affine p 0.5 rotation 30 scaling [0.5, 1.25] translation 0, covering true, crop_sampling 448x448 max_shift 0.1 hybrid, gaussian_noise 12.75, motion_blur true; `inference` multithreading, `compile` (off), `autocast` (off). Mixed precision exists only under `inference`; no training AMP, gradient clipping, EMA or albumentations `transform` list documented.
- Architectures (`net_type`): resnet_50/101, hrnet_w18/32/48, dekr_w18/32/48, dlcrnet_stride16_ms5/stride32_ms5, ctd_* (BUCTD), `top_down_` prefix for any single-animal model, cspnext_s/m/x, rtmpose_s/m/x, animal_tokenpose_base (inference only); detectors ssdlite, fasterrcnn_mobilenet_v3_large_fpn, fasterrcnn_resnet50_fpn_v2. Full list: `available_models()`, `available_detectors()`.

## Open research items

- (Resolved round 2) `Shuffles=` is a valid alias; no bug.
- (Resolved round 2) The user-guide page is only 11.6 kB (the 726 kB was api.jsonl); it has no multi-GPU or benchmarking content.
- Whether PR 3148 or a successor ships in 3.1; re-check before pointing users at it.
- Forum threads on Slurm/HPC.

## Log

- 2026-10-29: round 1 (above). Skill edits: split tuning and sweep sections into references, corrected the `Shuffles=` sketch, refreshed defaults and PR status.

## Round 2 (2026-10-29): user guide, multi-GPU, benchmarking, forum

| Source | Status | Finding |
|---|---|---|
| .../docs/pytorch/user_guide.html | read in full (11.6 kB) | Round 1 mislabelled the 726 kB as this page; it was api.jsonl. Content: epochs not iterations, shuffles via the TF methods, `available_models()`, `engine:` in config.yaml |
| .../docs/pytorch/Benchmarking_shuffle_guide.html | read | `create_training_dataset_from_existing_split(config, from_shuffle, from_trainsetindex, shuffles, net_type)`; train `batch_size=8` example; `evaluate_network(config, Shuffles=[4], snapshotindex="all")`; 1000-range shuffle numbering convention; no metrics list, no cluster notes |
| .../knowledge/main/docs.jsonl (chars 0-270000 of 469255) | partial | No entries on multi-GPU, Slurm/HPC, mixed precision. Restart-at-checkpoint sections (`resume_training_from`, detector variant) and variable-image-size note (batch > 1 needs equal sizes) exist. Chars 270000+ not read |
| raw `deeplabcut/compat.py` at v3.0.2 | read (via fetch summary) | `evaluate_network` alias for `Shuffles` (see correction above); engine detection from `metadata.yaml`; TF branch drops `pcutoff`/`**torch_kwargs` |
| raw `pose_estimation_pytorch/runners/train.py` at v3.0.2 | read (via fetch summary) | Multi-GPU = `torch.nn.DataParallel` when `gpus` list given (device must be `cuda`); no DDP, AMP/GradScaler or gradient clipping; resume uses `snapshot_path`, `load_scheduler_state_dict` default true; resumed `fit()` sets epochs = starting_epoch + epochs |
| forum.image.sc (topics, search.json) | blocked | HTTP 403 from the fetch tool |
| web search for DLC Slurm/cluster threads | search | Only TF-era (2020-2022) cluster threads: create the training dataset on the cluster (paths), `DLClight` for no display, GPU use shown in `nvidia-smi`, TF-era single-GPU-only answer (2022). One PyTorch-forum thread about a conda DLC install on an HPC node (2024). The 3.0 release announcement (forum, 2026-06-04) lists highlights only. No DLC 3 Slurm thread found |

Facts added: see Open items. The multi-GPU and resume statements come from a fetch tool summarising source files, not from running code; treat as "read, not run".

Open research items (round 2): install DLC 3.0.2 in a uv venv and verify `Shuffles=` alias warning, `runner.gpus` DataParallel on a multi-GPU node (needs the user's cluster), resume epoch semantics; docs.jsonl chars 270000+; forum access via a browser or API key.

## Triage round 2026-11-11 (lessons inbox)

| Source | Status | Finding |
|---|---|---|
| https://github.com/DeepLabCut/DeepLabCut/issues/3547 | read (search snippet) | Worker count 28 slower than 6; main process 98.5% CPU with 2 workers; larger batch did not raise utilisation. Backs the pitfall 5 caveat. |
| local bash test | run | `${X:-d}` gives d for empty X; `${X-d}` gives empty. |

Outcomes: dataloader caveat, CTD/top-down pre-flight and shell-default notes added; dev-branch env note already present; top-down head `input_size` for heatmap nets parked (patch untested).

## Triage round 2026-11-16 (lessons inbox)

| Source | Status | Finding |
|---|---|---|
| https://github.com/DeepLabCut/DeepLabCut/issues/3592 | read (search listing via gh) | Open issue: default top-down rtmpose_x config has 256 crop vs 384 head input_size and crashes at the first step; matches one lessons report. |
| https://docs.astral.sh/uv/concepts/indexes/ | read | Default `first-index` limits candidates to the first index containing a package; `unsafe-best-match` is pip-like but exposes dependency confusion. |

Outcomes: trigger wording broadened, defaults section and uv note added to references.

## Maintenance trim 2026-11-17

Moved out of `SKILL.md` (no content dropped): pitfalls 4, 5, 7, 8, 11a detail to `references/pitfall-details.md`; the upstream-search procedure to `references/upstream-search.md`. Real-use evidence moved here from the former "Not verified" section:

- 2026-10-24, two independent sessions on a user project: diagnosing a multi-animal-to-single-animal project split that gave fewer annotated frames than expected (Slurm console log, JSON manifest/validation report, checksum manifest), and building a small orchestrator to submit several training jobs with varying hyperparameters, reviewed against HPC and DLC practice (headless plotting backend, dataloader-worker sizing, a shared-resource race in one script). All fixed and checked locally with `bash -n`, the bundled sbatch linter and dry runs. Still never run on a real cluster.

## 2026-11-23 (later): rework proposal for references/training-sweeps.md

Trigger: `deeplabcut-hpc` SKILL.md was already reworked today (commit d4c5bd3, 109 -> smaller, 8.8 KB), so the churn
(28 SKILL.md edits, 31 commits in 60 d) is mostly history. The live pressure is on `references/training-sweeps.md`:
14.1 KB, 12 edits in 60 d, grew by 3 lines in today's rework, full of provenance ("reported once", dates) and mixes
four topics. Problem in one sentence: one file holds net_type choice, benchmark reading, orchestrator hygiene and
CTD/top-down pre-flight, so every new report is appended as another bullet.

Proposed shape (net size not larger, SKILL.md untouched except pointers):
- `training-sweeps.md` (~5 KB): axis order, net_type table, orchestrator checks, fair-comparison guide.
- `benchmark-interpretation.md` (new): reading an export, what "default" means, walltime feasibility, batch-size sizing, ranking caveat.
- `ctd-topdown-preflight.md` (new): CTD conditions, pre-flight list, rtmpose_x crop/input_size, same-build evaluation, DLCRNet, unique bodyparts.
Status: inventory shown to user, awaiting approval; no edits made.

### Parked-entry greps vs training-sweeps.md (2026-11-23)
- 98 (older exports lack split/config hash): already-present, line "Exports from older iterations may lack the split hash...".
- 103 (PoseConfig.build noisy): already-present, "Local dry runs" bullet (redirect stdout or tail).
- 110 (dry-run needs sibling submit script stub): already-present, same bullet.
- 104 (R session cannot read the scratch dir): NOT present (grep for read tool/blocked/JSON found nothing). Proposed one line in the local-defaults recipe.

### Rule inventory, training-sweeps.md (28 rules; target ~5 KB + 2 new references)
A=training-sweeps.md, B=benchmark-interpretation.md (new), C=ctd-topdown-preflight.md (new).
1 net_type axis before secondary knobs: keep A. 2 check benchmark + architectures page, architecture first: merge with 1, A.
3 net_type table: keep A. 4 candidate must match single/multi-animal: keep A. 5 DLCRNet PAF error on single-animal: move C.
6 CPU-install 3.0.2 model names (top_down prefix): merge into table notes, A. 7 export tabulation before ranking: move B.
8 missing shuffles -> compare iteration, config not copied: move B. 9 older export NULL-safe: move B (parked 98 absorbed).
10 default = DLC-generated default, hist_eq off, PoseConfig.build recipe: move B. 11 driver settings differing from default listed; dataloader uniform: move B.
12 bare-baseline feature switches stated: move B. 13 rtmpose_x crop 256 vs 384 (#3592): move C. 14 test-split optimism: move B.
15 one shuffle per candidate, numbering from 1: keep A. 16 evaluate_network call and Shuffles alias: keep A. 17 own output path/config per task: keep A (pointer).
18 uniquebodyparts -> bottom-up only: move C. 19 compare traceback line numbers vs local script; failed shuffles register in metadata.yaml: keep A.
20 orchestrator holds next submission only; refuse-reuse list: keep A. 21 local dry runs stub + noisy output: move C (parked 103, 110 absorbed).
22 same metric same split, key_metric test.mAP: keep A. 23 walltime feasibility: move B. 24 evaluate in the same DLC build (extra_forbidden): move C.
25 CTD conditions from prediction file, CTD_CONDITIONS: move C. 26 CTD/top-down pre-flight incl. crop/input_size by head type: move C, condense.
27 diff tuned vs default; replicates only if seed differs: move B. 28 batch size from measured GPU memory: move B.
29 shell ${VAR:-x} vs ${VAR-x}: keep A. 30 fair comparison via create_training_dataset_from_existing_split: keep A.
New: 104 line (print results in the Python step or read with the read tool, not from the R session): add C or B.
Drop: none; all provenance ("reported once", dates) removed from text and kept here.

### Rework applied 2026-11-23 (uncommitted)
training-sweeps.md 14.1 -> 4.8 KB; new benchmark-interpretation.md (5.1 KB) and ctd-topdown-preflight.md (3.1 KB); SKILL.md pointer line only (9019 -> ~9230 B, +~0.2 KB for two extra pointers). Provenance removed from text. Parked 98/103/110 covered (already-present), 104 added to benchmark-interpretation.md. lint clean apart from description-length info; skills-ref validate passed; 17 distinctive terms from the inventory each found in the new files. Not tested: no DLC code run; dispositions/watermark untouched (triage not archived).
