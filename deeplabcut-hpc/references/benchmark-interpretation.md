# Reading a benchmark export and planning comparisons

Contents: interpreting an export, what "default" means, walltime feasibility, replicates and ablations, batch-size sizing, ranking caveat. If the user's first message contains a benchmark export with partial runs, load this skill before proposing reruns.

## Interpreting an export

Before ranking shuffles by mAP or RMSE, tabulate for each: training method (bottom-up, top-down, conditioned top-down), detector, conditioning shuffle (CTD), scheduler type and milestones against the epochs actually run, and the spread within same-config replicate groups (that spread is the noise level for any difference). Skipping this led to a method difference being explained by crop sampling, and to a completed cosine schedule being called misaligned. Training-curve (in-training) mAP is not comparable across methods; for CTD it was far above the later benchmark evaluation (cause unverified), so report CTD gain relative to its conditioner shuffle using evaluated numbers.

- Field map (schema 5.1.0, verify on the file): test metrics under `comparisons.models[].metrics`; resolved configs in `configuration_registry[<hash>].resolved_configuration`, joined by each shuffle's `configuration_hash`; training state, termination cause, runtime and GPU peak under `shuffles[]`. Check `names()` before assuming this for another schema.
- Stale export: logs copied later can show a shuffle evaluated after the JSON was written. Compare the consolidate-job time with the JSON copy and ask for a re-export before calling a shuffle unevaluated.
- Missing shuffles: compare the iteration named in the training logs with the iteration in the benchmark job log, and ask the user to grep the cluster copy of the config for `iteration:`. A config edited locally but not copied to the cluster makes the export cover the old iteration.
- Older iterations may lack the split hash (empty split registry) or a config hash for a not-started shuffle; code written for the newer schema then fails with "attempt to select less than one element in get1index". Access these fields NULL-safely and do not assume comparability across iterations.

## What "default" means

- "Default" is DLC's own generated default, never a reference shuffle or a heuristic. It has `hist_eq` off, so a default run is already the histeq-off arm. Generated 3.0.2 values are in `pytorch-config-tuning.md`; diff a benchmark export's resolved configs against them first.
- To record defaults locally (no GPU, training or weight download): in a scratch uv env with the cluster's DLC version, create a throwaway project per project type (single and multi-animal), call `PoseConfig.build(project_config, pose_config_path, top_down=..., net_type=...)` for each net type, write a version-tagged CSV and diff each shuffle's resolved config against it key by key. Conditional top-down nets need `ctd_conditions` (a dummy shuffle number is enough). When a net is missing from an existing defaults recorder, extend that script and regenerate its single table (check old rows are unchanged) instead of adding a sibling file.
- Print results from the Python step, or read the output file with the `read` tool; the assistant's R session can neither read nor write the scratch directory (write helper files with the `write` tool or bash).
- List driver settings that differ from DLC defaults (for example dataloader workers, `pin_memory`, the `rtmpose_x` crop). Dataloader settings (workers, `pin_memory`, `persistent_workers`, `prefetch_factor`) change throughput only: apply them uniformly across compared runs or say the baseline differs, and set them from measured GPU utilisation. They are not deviations from default. Batch size is a model parameter, not a throughput setting.
- When deriving a "bare baseline" from a script that exists to exercise a dev-branch feature, state which feature switches stay on or off and why; do not reset them silently.
- Before adding default-versus-tuned runs or ablations, diff each tuned config against DLC defaults: a "tuned" model that differs only in epochs makes a planned default run and an epoch ablation the same run. A benchmark export's resolved per-shuffle configs make this a quick diff. Call runs seed replicates only if just the seed differs; add replicates explicitly.
- Caveat for any ranking: the best snapshot is chosen on the test split, so reported test metrics are optimistic.

## Walltime feasibility

Check before listing candidates: estimate seconds per epoch for each `net_type` from a short or partial run (`sacct` Elapsed divided by the last epoch) and compare epochs x pace with the partition limit. Several hrnet bottom-up runs ended "partial, cause unknown" after 90 to 170 of 600 epochs because they hit a 48 h limit; treat a partial run with epochs far below target as a walltime hit until the user's `sacct` output says otherwise. If epochs are cut, check that `LRListScheduler` milestones (in epochs) still fall inside the shortened run, or use resume chaining. Without `sacct`, the first-to-last timestamp span of a GPU-monitoring CSV gives hours per run; a span equal to the limit for every partial run confirms walltime kills.

## Batch-size sizing

Size new batch sizes from measured GPU memory: peak is roughly fixed + per-sample x batch size, so read peaks from earlier jobs' GPU-usage logs at two batch sizes (ask the user to paste them; see `hpc-resource-allocation`). Rough rule, not checked upstream. Scale peaks only within one architecture: they include allocator and evaluation spikes and do not follow model size, and for top-down runs the detector dominates the peak, so a pose-phase batch size needs its own measurement.
