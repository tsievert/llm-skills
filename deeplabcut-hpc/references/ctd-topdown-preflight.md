# CTD, top-down and local dry-run checks

Contents: net types that fail by project type, `rtmpose_x` crop mismatch, CTD conditions, pre-flight list, same-build evaluation, local dry runs. Verified by reading 3.0.2 or `main` source and local generated configs; none run on a cluster.

## Net types that fail by project type

- DLCRNet (`dlcrnet_*`): `make_pose_config.py` on `main` raises "PAF parameters are required for DLCRNet models" with no single-animal check, and a single-animal project hit it. Leave DLCRNet out of single-animal sweeps.
- Unique bodyparts: if the project config has a non-empty `uniquebodyparts`, only bottom-up net types are valid. `main` raises a `ValueError` ("unique bodyparts, which is not yet implemented for top-down models") for `top_down_*`, `rtmpose_*` and `ctd_*`. Build one config per candidate net type locally before queuing.

## Crop and head `input_size`

- Known upstream failure (3.0.2): the generated default top-down `rtmpose_x` config has a 256 crop but a 384 head `input_size` and crashes at the first step (DeepLabCut issue #3592, open when checked 2026-11-16). `ctd_prenet_rtmpose_x` shows the same mismatch (the `s` and `m` variants use 256 and are fine). Config validation raises "must match RTMPose input_size". Set the crop from `input_size` first, then validate.
- A driver that corrects the crop only for methods classed as top-down misses CTD methods; include CTD in the top-down branch.
- RTMPose heads carry `model.heads.bodypart.input_size`; heatmap top-down nets (`top_down_cspnext_*`, `top_down_hrnet_*`, `top_down_resnet_*`) have no head `input_size` and use the generated 256x256 `top_down_crop`. A driver that requires `input_size` fails with "Top-down models require model.heads.bodypart.input_size". Branch on head type and test. Specify crop or `input_size` explicitly rather than the word `default`.

## CTD conditions

CTD shuffles take their conditions from the prediction file written when the bottom-up snapshot was evaluated. Evaluate the chosen bottom-up snapshot first, then pass `CTD_CONDITIONS=<shuffle>,<snapshot file name or index>`; `-1` resolves to the best snapshot when one exists.

## Pre-flight list before submitting a CTD or top-down sweep

- The CTD reference shuffle equals the bottom-up condition shuffle.
- That shuffle's evaluation-results folder (with the prediction file) is in any node-local staged copy.
- The train/test split file exists in the staged copy.
- Top-down models have crop or head `input_size` set explicitly (see above).

## Evaluate in the build that trained

Evaluate a shuffle in the same DLC build that trained it. `evaluate_network` in the release env rejected a dev-branch config with `extra_forbidden` errors (`runner.load_scheduler_state_dict`, `train_settings.dataloader_kwargs`) because `PoseConfig` forbids unknown keys.

## Local dry runs

A copied orchestrator needs a stub of its sibling submit script (and the split file it checks for). `PoseConfig.build` for models with PAF heads prints many "Valid subgraph found" lines, so redirect stdout or tail the output.
