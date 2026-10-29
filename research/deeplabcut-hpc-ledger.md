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
