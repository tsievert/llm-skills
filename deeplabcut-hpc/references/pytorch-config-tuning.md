# Tuning `pytorch_config.yaml`: optimizer, scheduler, augmentation

Contents: what the file exposes, documented defaults, optimizer, scheduler, augmentation, what is not exposed, upstream status.

`pytorch_config.yaml` is DLC's own abstraction over PyTorch, not raw PyTorch code. It exposes a curated subset of `torch.optim`, `torch.optim.lr_scheduler` and the `albumentations` library. Re-verify keys against https://deeplabcut.github.io/DeepLabCut/docs/pytorch/pytorch_config.html for the installed version before editing. Defaults below were read from that page on 2026-10-29 (DLC 3.0.2 is the latest release); they have drifted from the code before (see config/code drift below). Research record: `research/deeplabcut-hpc-ledger.md` in the llm-skills repo.

## Documented defaults (2026-10-29)

| Block | Key and default |
|---|---|
| top level | `device: auto`, `resume_training_from` (full path to a `snapshot-NNN.pt`) |
| `train_settings` | `batch_size: 1`, `dataloader_workers: 0`, `dataloader_pin_memory: true`, `display_iters: 500`, `epochs: 200`, `seed: 42` |
| `runner` | `key_metric: test.mAP` (`key_metric_asc: true`; or `test.rmse` with `false`), `eval_interval: 1` |
| `runner.snapshots` | `max_snapshots: 5`, `save_epochs: 25`, `save_optimizer_state: false` |
| `runner.gpus` | a list such as `[0, 1]`; no default stated |
| `data.train.affine` | `p: 0.5`, `rotation: 30`, `scaling: [0.5, 1.25]`, `translation: 0` |
| `data.train` other | `covering: true`, `crop_sampling` (448 x 448, `max_shift: 0.1`, `method: hybrid`), `gaussian_noise: 12.75`, `motion_blur: true` |
| `inference` | `multithreading` (enabled), `compile` (disabled, backend `inductor`), `autocast` (disabled) |

`train_network(...)` also accepts overrides directly (3.0.2 signature): `epochs`, `save_epochs`, `batch_size`, `detector_epochs`, `detector_batch_size`, `snapshot_path`, `detector_path`, `device`, `max_snapshots_to_keep`, `pytorch_cfg_updates` (dict applied to the config). Prefer these over editing YAML in a script, and confirm with `help(deeplabcut.train_network)` on the cluster version.

## Optimizer, scheduler

**Optimizer** (`runner.optimizer`): `type` accepts any class from `torch.optim` (the docs show `SGD` with `lr: 1e-3, momentum: 0.9`, and `AdamW` with `lr: 1e-4`); `params` passes through as kwargs. No default is documented, and the docs advise against changing the type unless experienced.

**Scheduler** (`runner.scheduler`, optional): `type` accepts any `torch.optim.lr_scheduler` class. The documented default is `LRListScheduler` (DLC-specific: `lr_list`, `milestones`). `StepLR` (`step_size`, `gamma`), `SequentialLR` (nested `schedulers` plus `milestones`) and `ChainedScheduler` are named as usable. Set `runner.load_scheduler_state_dict: false` when editing the scheduler and resuming from a snapshot, or the old schedule state silently overrides the new config.

## Augmentation

Backed by `albumentations`, not `torchvision.transforms` or `imgaug` (the DLC user guide says so). Documented keys under `data.train` / `data.inference`: `affine` (`p`, `rotation`, `scaling`, `translation`), `covering` (coarse dropout), `crop_sampling` (`height`, `width`, `max_shift`, `method`: `uniform`/`keypoints`/`density`/`hybrid`), `gaussian_noise` (float, or `true` for 12.75), `motion_blur`, `hflip` (`true` for detectors or without symmetric keypoints; otherwise `p` plus `symmetries`), `hist_eq`, `resize` (`height`, `width`, `keep_ratio`), and `auto_padding` (`min_height`, `min_width`, `pad_height_divisor`, `pad_width_divisor`, `position`, `border_mode`, ...). The `collate` block (`ResizeFromDataSizeCollate`: `max_shift`, `max_size`, `min_scale`, `max_scale`, `min_short_side`, `max_short_side`, `multiple_of`, `to_square`) controls batch-level rescaling.

## Where DLC's abstraction stops short

Check these before writing a feature request; the gap may have closed.

- **Augmentation coverage.** DLC exposes a fixed list of named augmentations, not arbitrary `albumentations` transforms (no `ColorJitter`, `ElasticTransform`, weather or other blur families; full set at https://albumentations.ai/docs/). https://github.com/DeepLabCut/DeepLabCut/pull/3148 adds a `transform` list passing any `albumentations` class by name. It was **open and unmerged** on 2026-10-29 (base `main`, last updated 2026-03-30), and the config page documents no `transform` key. If the user needs an augmentation outside the list, point to the PR rather than inventing a workaround, and re-check its status.
- **Config/code drift.** https://github.com/DeepLabCut/DeepLabCut/issues/2753 (closed 2024-10-18) documented a docs key `fliplr` that the code called `hflip`, and `rotation` applied symmetrically while `translation` was not. The docs now show `hflip` and `translation: 0`, but treat keys in older tutorials with suspicion and confirm against `deeplabcut.pose_estimation_pytorch.data.transforms.build_transforms` in the installed version if an augmentation behaves unexpectedly.
- **No raw PyTorch access in training.** Gradient clipping, mixed precision (`torch.cuda.amp`), gradient accumulation, EMA, `torch.compile` for training and custom losses or backbones are not documented as training keys. `inference.autocast` and `inference.compile` exist (both off by default) but apply to inference only. Using any of the others means patching DLC's training code, which forks the user off the maintained loop; confirm that is wanted first. Raw API for reference: https://docs.pytorch.org/docs/stable/optim.html and https://docs.pytorch.org/docs/stable/notes/amp_examples.html.

When a documented option and the live behavior disagree, or a desired option is not exposed, follow "When something fails: search upstream before improvising" in `SKILL.md` before concluding it is missing, and report with links so the user can decide whether to file or upvote a feature request.
