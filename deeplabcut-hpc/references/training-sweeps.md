# Designing a multi-candidate training sweep

Contents: which axis to vary first, current `net_type` options, how to list them, orchestrator checks.

When asked to broaden an orchestrator or sweep (several `train_network` jobs with varying settings) beyond its first candidates, **exhaust the model architecture (`net_type`) axis before reusing secondary tuning knobs** (dataloader settings, augmentation on/off, etc.) just to inflate the candidate count. If the project's own prior benchmark data or the official architecture docs list untested `net_type` options, those are higher-value candidates than a second variant of a knob already covered. Reported once (2026-10-26): the assistant twice defaulted to an already-exhausted tuning knob before checking for untested architectures, and the user had to correct the prioritization twice.

Check both sources before proposing a sweep: the project's benchmark results (if one exists) and the current architectures page, then order candidates architecture-first and defer secondary-knob variants to a later round.

## Current `net_type` options (docs read 2026-10-29, DLC 3.0.2)

Source: https://deeplabcut.github.io/DeepLabCut/docs/pytorch/architectures.html. The authoritative list for the installed version is `from deeplabcut.pose_estimation_pytorch import available_models, available_detectors` (ask the user to run it on the cluster; not run here).

| Family | `net_type` values | Notes from the docs |
|---|---|---|
| ResNet | `resnet_50`, `resnet_101` | Standard bottom-up backbones (heatmap plus PAF head for multi-animal); usable single-animal |
| HRNet | `hrnet_w18`, `hrnet_w32`, `hrnet_w48` | Slower than ResNet, typically more powerful; usable single-animal |
| DEKR | `dekr_w18`, `dekr_w32`, `dekr_w48` | Multi-animal, powerful but very heavy and slow |
| DLCRNet | `dlcrnet_stride16_ms5`, `dlcrnet_stride32_ms5` | Multi-scale ResNet variant with PAFs |
| BUCTD (conditioned top-down) | `ctd_coam_w32`, `ctd_coam_w48`, `ctd_prenet_hrnet_w32`, `ctd_prenet_hrnet_w48`, `ctd_prenet_rtmpose_s`, `_m`, `_x` | Multi-animal; uses bottom-up predictions as conditions; also `_human` variants |
| Top-down | prefix any single-animal model with `top_down_` (for example `top_down_resnet_50`, `top_down_hrnet_w32`) | Needs a detector; accurate in less crowded scenes, weaker with heavy overlap |
| CSPNeXt / RTMPose | `cspnext_s`, `cspnext_m`, `cspnext_x`; `rtmpose_s`, `rtmpose_m`, `rtmpose_x` | Efficient backbone; real-time top-down model |
| AnimalTokenPose | `animal_tokenpose_base` | Video inference only, cannot be trained in DLC |
| Detectors (top-down) | `ssdlite`, `fasterrcnn_mobilenet_v3_large_fpn`, `fasterrcnn_resnet50_fpn_v2` | Set with `detector_type` in `create_training_dataset` |

A candidate must match the project type (single- versus multi-animal); do not propose a multi-animal-only model for a single-animal project without checking the docs.

## Orchestrator checks

- One shuffle per candidate, numbered from 1; create each with `create_training_dataset(config, Shuffles=[n], net_type=...)`, then train with `train_network(config, shuffle=n, ...)`.
- Evaluate with `evaluate_network(config, shuffles=[n], plotting=False)` (`Shuffles=` still works as an alias since 3.0.0).
- Give every task its own output path and config copy (see pitfalls 1 and 8 in `SKILL.md`).
- Compare candidates by the same metric on the same split; the default `runner.key_metric` is `test.mAP`.
- Check walltime feasibility before listing candidates (reported once): estimate seconds per epoch for each `net_type` from a short or partial run (`sacct` Elapsed divided by the last epoch) and compare epochs x pace with the partition limit. In one benchmark several hrnet bottom-up runs ended "partial, cause unknown" after 90 to 170 of 600 epochs because they hit a 48 h limit; treat a partial run with epochs far below target as a walltime hit until the user's `sacct` output says otherwise. If epochs are cut, check that `LRListScheduler` milestones (in epochs) still fall inside the shortened run; or use resume chaining. Without `sacct`, the first-to-last timestamp span of a GPU-monitoring CSV gives hours per run; a span equal to the limit for every partial run confirms walltime kills (reported once). If the user's first message contains a benchmark export with partial runs, load this skill before proposing reruns.
- Evaluate a shuffle in the same DLC build that trained it. `evaluate_network` in the release env rejected a dev-branch config with `extra_forbidden` errors (`runner.load_scheduler_state_dict`, `train_settings.dataloader_kwargs`) because `PoseConfig` forbids unknown keys (reported once; fix applied in a script, not run on a cluster).
- CTD (conditional top-down) shuffles take their conditions from the prediction file written when the bottom-up snapshot was evaluated, so evaluate the chosen bottom-up snapshot first, then pass `CTD_CONDITIONS=<shuffle>,<snapshot file name or index>`; `-1` resolves to the best snapshot when one exists (read in 3.0.2 source, once; not run).
- Pre-flight checks before submitting a CTD or top-down sweep (reported once, from failed jobs): the CTD reference shuffle equals the bottom-up condition shuffle; that shuffle's evaluation-results folder (with the prediction file) is included in any node-local staged copy; the train/test split file exists in the staged copy; top-down models have a crop or head `input_size` set explicitly rather than the word `default` (RTMPose heads carry `model.heads.bodypart.input_size`; whether heatmap top-down nets such as `top_down_hrnet_*` do is unverified, one report says they use the generated `top_down_crop`, so branch on head type and test). For `rtmpose_x`, one report found the generated `data.train.top_down_crop` 256x256 while the head `input_size` was 384x384, and a config validation run before the crop was overridden raised "must match RTMPose input_size"; a second report found the same mismatch for `ctd_prenet_rtmpose_x` (head 384, crop 256, matrix-shape error on the first step; the `s` and `m` variants use 256 and were fine) because a driver script corrected the crop only for methods it classed as top-down and treated CTD methods as "other", so make the driver's top-down branch include CTD methods; set the crop from `input_size` first, then validate (local generated configs only, not run on a cluster; the DLC docs page does not mention either key).
- Before adding default-versus-tuned runs or ablations, diff each tuned config against DLC's defaults (reported once: a "tuned" model differed from the default only in epochs, so a planned default run and an epoch ablation were the same run). Do not call runs seed replicates unless only the seed differs (different detector or batch size is not a replicate); add replicates explicitly.
- Size new batch sizes from measured GPU memory, not guesses: peak is roughly fixed + per-sample x batch size, so read peaks from earlier jobs' GPU-usage logs at two batch sizes (ask the user to paste them; see `hpc-resource-allocation`). Rough rule from one project, not checked upstream.
- Shell defaults: `${VAR:-x}` replaces an empty value too, so a script documented as "empty means DLC default" still applies `x`. Use `${VAR-x}` (default only when unset; checked in bash), or pass an explicit sentinel such as `default` for every variable in a baseline run and map it to None in Python.

## Fair comparison across architectures (benchmarking guide, read 2026-10-29)

Source: https://deeplabcut.github.io/DeepLabCut/docs/pytorch/Benchmarking_shuffle_guide.html. To compare models on an identical split, create each new shuffle with `deeplabcut.create_training_dataset_from_existing_split(config, from_shuffle=3, from_trainsetindex=0, shuffles=[4], net_type="resnet_50")`, then train and evaluate it. Shuffles with the same `split` value share a data split. The guide suggests numbering PyTorch shuffles in a 1000 range when mirroring TensorFlow shuffles (0, 1, 2 become 1000, 1001, 1002) so the source is obvious; a custom orchestrator may use its own scheme, but not 0. The guide does not list the metrics `evaluate_network` reports or give cluster advice.
