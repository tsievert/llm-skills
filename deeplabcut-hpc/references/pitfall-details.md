# DLC pitfalls: full detail

Long form of the one-line pitfalls in `SKILL.md`. Verify keys and signatures against the docs for the installed version; they drift.

## 4. Training length and config keys (PyTorch)

Control length via `train_network(..., epochs=...)` or `train_settings.epochs` in `pytorch_config.yaml`. Other documented keys: `train_settings.batch_size` (default 1), `train_settings.dataloader_workers` (default 0), `runner.snapshots.save_epochs` (25), `runner.snapshots.max_snapshots` (5), `runner.gpus` (list), top-level `device` (`auto`), top-level `resume_training_from` (path to a `snapshot-NNN.pt`). One report found the 3.0.2 code defaults differ from the docs (batch 8, covering off); see [pytorch-config-tuning.md](pytorch-config-tuning.md).

## 5. Dataloader workers

The default is 0, which starves the GPU. Raise `dataloader_workers` to at most `--cpus-per-task` (leave one core free). More workers are not always faster: if the main training process sits near 100% CPU while workers idle, extra workers will not help and very high counts can be slower (reported once; upstream issue DeepLabCut #3547 shows 28 workers slower than 6 with the main process at 98.5% CPU). Then profile the main process (`py-spy`) and test `dataloader_pin_memory` on/off, crop size, evaluation interval and torch thread counts before adding workers. Read the Slurm allocation with `parallelly`-style logic from `hpc-python-code`, not `os.cpu_count()`.

## 7. Checkpoint and resume

Snapshots are saved every `save_epochs`. Set it low enough that a time-limit kill loses little, and resume with `resume_training_from` (config) or `train_network(..., snapshot_path=...)` pointing to the last snapshot. In the 3.0.2 runner source a resumed `fit()` treats the epoch count as additional epochs (`starting_epoch + epochs`), so set `epochs` to the remaining number in a requeue script and check the log after the first resume (read from source, not run). Write the resume logic so a requeued job continues instead of restarting (see `hpc-job-scripts` for requeue and `--signal`).

## 8. Multiple shuffles, projects and GPUs

One GPU per training run by default. `runner.gpus: [0, 1]` enables multi-GPU training, which in 3.0.2 is `torch.nn.DataParallel` on one node with `device: cuda` (no DistributedDataParallel; read from source, not run; the config docs give no scaling advice), so request `--gres=gpu:N` on one node and treat scaling as untested. Use job arrays with one shuffle or project per task, each with isolated output (the BatchProcessing recipe uses a `sys.argv[1]` index per GPU). Start shuffle numbering at 1, not 0: DLC's API defaults (`train_network`, `evaluate_network`, `analyze_videos`) and GUI treat 1 as the practical floor, and a custom orchestrator that picked 0 for its baseline run was reported to cause downstream confusion (2026-10-26).

## 13. Snapshot choice, skeletons and names for video analysis (one install, verify on yours)

- `analyze_videos` has no snapshot argument in its signature on the checked 3.x install, only `**torch_kwargs`, and the config `snapshotindex` of -1 left the choice unclear. Pass `snapshot_index` (and `detector_snapshot_index` for top-down) through `torch_kwargs`, accept `"best"`, check with `get_model_snapshots`, and log the resolved file names. A "found multiple best snapshots" warning from stale folders resolved to the highest epoch there.
- Check each model is single-animal or multi-animal (`project_type` in the benchmark or config) before designing any step that consumes the H5: layout and tracking differ.
- Before `create_labeled_video(draw_skeleton=True)`, check that the config skeleton uses real bodypart names (a template skeleton or `[]` draws nothing or fails). Present a proposed skeleton to the user for review; never treat an anatomical order inferred from abbreviations as final.
- Keep bodypart names short in H5 and config (long names can error); put readable names in a side mapping used for documentation and skeleton authoring.

## 12. Re-split and evaluation (2 sessions, not confirmed on a cluster)

After `create_training_dataset` or any re-split, `metadata.yaml` can record another engine, and `evaluate_network` then falls back to TensorFlow (`ModuleNotFoundError: tensorflow` on a PyTorch project). Check the engine entries in `metadata.yaml` and pass the engine explicitly in headless evaluation (`engine=Engine.PYTORCH`, from `deeplabcut.core.engine`). The argument is `shuffles=[n]` in 3.0.2; the old `Shuffles=` still works as a renamed-parameter alias since 3.0.0 (read from `compat.py`), so prefer `shuffles=`. Extra PyTorch options such as `snapshotindex` pass through `**torch_kwargs`. Treat evaluation results older than the shuffle's `Documentation_data` pickle as stale (compare mtimes). Evaluation also writes some files (the combined results CSV) outside the per-shuffle folder, so a name-glob sync-back from node-local scratch loses them. Sync each job's outputs into a job-specific path (one writer per path) and let downstream checks fall back to the per-snapshot CSVs.
