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

## Fair comparison across architectures (benchmarking guide, read 2026-10-29)

Source: https://deeplabcut.github.io/DeepLabCut/docs/pytorch/Benchmarking_shuffle_guide.html. To compare models on an identical split, create each new shuffle with `deeplabcut.create_training_dataset_from_existing_split(config, from_shuffle=3, from_trainsetindex=0, shuffles=[4], net_type="resnet_50")`, then train and evaluate it. Shuffles with the same `split` value share a data split. The guide suggests numbering PyTorch shuffles in a 1000 range when mirroring TensorFlow shuffles (0, 1, 2 become 1000, 1001, 1002) so the source is obvious; a custom orchestrator may use its own scheme, but not 0. The guide does not list the metrics `evaluate_network` reports or give cluster advice.
