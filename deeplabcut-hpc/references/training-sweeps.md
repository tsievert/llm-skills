# Designing a multi-candidate training sweep

Contents: which axis to vary first, current `net_type` options, orchestrator checks, fair comparison across architectures. Reading results is in [benchmark-interpretation.md](benchmark-interpretation.md); CTD, top-down and dry-run checks are in [ctd-topdown-preflight.md](ctd-topdown-preflight.md).

## Order of candidates

Exhaust the model architecture (`net_type`) axis before reusing secondary knobs (dataloader settings, augmentation on/off) to inflate the candidate count. Check both sources before proposing a sweep: the project's own benchmark results (if any) and the current architectures page. Order candidates architecture-first; defer secondary-knob variants to a later round. Untested `net_type` options are higher value than a second variant of a knob already covered.

## Current `net_type` options (DLC 3.0.2)

Source: https://deeplabcut.github.io/DeepLabCut/docs/pytorch/architectures.html. The authoritative list for the installed version is `from deeplabcut.pose_estimation_pytorch import available_models, available_detectors` (ask the user to run it on the cluster).

| Family | `net_type` values | Notes |
|---|---|---|
| ResNet | `resnet_50`, `resnet_101` | Standard bottom-up backbones (heatmap plus PAF head for multi-animal); usable single-animal |
| HRNet | `hrnet_w18`, `hrnet_w32`, `hrnet_w48` | Slower than ResNet, typically more powerful; usable single-animal |
| DEKR | `dekr_w18`, `dekr_w32`, `dekr_w48` | Multi-animal, powerful but very heavy and slow |
| DLCRNet | `dlcrnet_stride16_ms5`, `dlcrnet_stride32_ms5` | Multi-scale ResNet variant with PAFs; expect it to fail on single-animal projects (see the pre-flight file) |
| BUCTD (conditioned top-down) | `ctd_coam_w32`, `ctd_coam_w48`, `ctd_prenet_hrnet_w32`, `ctd_prenet_hrnet_w48`, `ctd_prenet_rtmpose_s`, `_m`, `_x` | Multi-animal; uses bottom-up predictions as conditions; also `_human` variants |
| Top-down | `rtmpose_s/m/x`, `top_down_cspnext_s/m/x`, `top_down_hrnet_w18/32/48`, `top_down_resnet_50/101` | Needs a detector; accurate in less crowded scenes, weaker with heavy overlap. Bare `cspnext_*` is a backbone name, not a top-down model |
| CSPNeXt / RTMPose | `cspnext_s/m/x`, `rtmpose_s/m/x` | Efficient backbone; real-time top-down model |
| AnimalTokenPose | `animal_tokenpose_base` | Video inference only, cannot be trained in DLC |
| Detectors (top-down) | `ssdlite`, `fasterrcnn_mobilenet_v3_large_fpn`, `fasterrcnn_resnet50_fpn_v2` | Set with `detector_type` in `create_training_dataset` |

A CPU install of 3.0.2 returned 34 model names and 3 detectors; still print `available_models()` for the installed version. A candidate must match the project type (single- versus multi-animal); do not propose a multi-animal-only model for a single-animal project without checking the docs.

## Orchestrator checks

- One shuffle per candidate, numbered from 1; create each with `create_training_dataset(config, Shuffles=[n], net_type=...)`, then train with `train_network(config, shuffle=n, ...)`.
- Evaluate with `evaluate_network(config, shuffles=[n], plotting=False)` (`Shuffles=` still works as an alias since 3.0.0).
- Give every task its own output path and config copy (pitfalls 1 and 8 in `SKILL.md`).
- Before resubmitting after a failure, compare the traceback's line numbers with the local script: a local patch may never have been copied to the cluster. Failed jobs also register their shuffle in `metadata.yaml`, so use new numbers.
- Keep the orchestrator to the next planned submission only: no per-round variables or round history. Move finished and failed shuffle numbers to the refuse-reuse list, never reuse a failed number, and archive old versions outside the script.
- Before planning epoch or schedule ablations, check that the driver exposes scheduler milestones and learning rate, not only epochs and batch size (see `pytorch-config-tuning.md`).
- Rank CTD conditioner candidates among bottom-up shuffles only; a CTD evaluation failure after normal training points to a top-down conditioner.
- Compare candidates by the same metric on the same split; the default `runner.key_metric` is `test.mAP`.
- Shell defaults: `${VAR:-x}` replaces an empty value too, so a script documented as "empty means DLC default" still applies `x`. Use `${VAR-x}` (default only when unset), or pass an explicit sentinel such as `default` for every variable in a baseline run and map it to None in Python.

## Fair comparison across architectures

Source: https://deeplabcut.github.io/DeepLabCut/docs/pytorch/Benchmarking_shuffle_guide.html. To compare models on an identical split, create each new shuffle with `deeplabcut.create_training_dataset_from_existing_split(config, from_shuffle=3, from_trainsetindex=0, shuffles=[4], net_type="resnet_50")`, then train and evaluate it. Shuffles with the same `split` value share a data split. The guide suggests numbering PyTorch shuffles in a 1000 range when mirroring TensorFlow shuffles (0, 1, 2 become 1000, 1001, 1002); a custom orchestrator may use its own scheme, but not 0. The guide does not list the metrics `evaluate_network` reports or give cluster advice.
