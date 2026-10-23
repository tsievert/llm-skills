---
name: hpc-gpu-jobs
description: Writes and reviews GPU batch jobs on HPC clusters (Slurm gres/gpus syntax, CPU-to-GPU ratios, DataLoader workers, CUDA modules, single- and multi-GPU PyTorch launch with torchrun or srun, ports and rendezvous, GPU monitoring, node-local data staging, checkpointing). Use when the user asks for a GPU or deep-learning job script, how many GPUs/CPUs/memory to request, why a GPU job is slow, idle, or hangs, or how to monitor GPU utilisation on a cluster.
---

# GPU jobs on HPC

Run `hpc-cluster-docs` first: GPU syntax, types, partitions, QOS limits and CUDA
modules are site-specific. Use `hpc-job-scripts` for the general script rules and
`hpc-python-code` for checkpoint/signal code.

## Where this skill runs

The assistant runs on the user's local machine, not on the cluster, and usually has no
matching GPU. It writes and lints job scripts and code; it cannot run `nvidia-smi`,
`torch.cuda.is_available()`, `torchrun` or `sbatch`. GPU, multi-GPU and rendezvous
behaviour is untested until the user runs it; ask for the commands' output and logs.

**Requirement:** whenever information is needed that only the cluster can provide (GPU
types, driver/CUDA versions, `nvidia-smi` output, logs), stop and ask the user to run
the specific shell command(s), given in a code block, and paste back the output. Do
not guess or proceed on assumptions.

## Request only what the code uses

- Only GPU-enabled code benefits. A GPU request on CPU-only code wastes resources,
  lengthens queue time and lowers fair-share priority.
- Many programs use a single GPU. Request more only if the code is written for it,
  and run a scaling test (1, 2, 4 GPUs) before asking for many.
- Develop and debug on a short or debug GPU partition or an interactive session with
  a small job, not full-length runs.
- Do CPU-only preprocessing (tokenising, decoding, feature extraction) in separate CPU
  jobs and feed the GPU job from prepared shards. A GPU idle during preprocessing is
  expensive. (General practice; confirm against the site's policies.)

## Directives

Syntax varies per site. Common forms (confirm which your site expects):

| Intent | Typical directive |
|---|---|
| N GPUs on the node | `--gres=gpu:N` or `--gpus=N` |
| Specific model | `--gres=gpu:<type>:N` or `--constraint=<feature>` |
| GPUs per node (multi-node) | `--gpus-per-node=N` |
| One GPU per task | `--ntasks=K --gpus-per-task=1` |
| CPUs/memory tied to GPUs | `--cpus-per-gpu=C`, `--mem-per-gpu=M` |

- `--gres=gpu:N` counts GPUs **per node**.
- Slurm sets `CUDA_VISIBLE_DEVICES` for the allocation. Do not override it unless the
  site says so; do log it.
- Memory (`--mem`) is host RAM, not GPU memory. Check VRAM against partition
  hardware (`sinfo -o "%N %G %m" -p <partition>` lists nodes and GRES).
- Match CPUs to the data pipeline: `--cpus-per-task` should cover DataLoader workers
  (`num_workers` about equal to CPUs per GPU, then measure; in one published example
  GPU utilisation rose from 18% to 55% going from 1 to 8 workers). More workers also
  use more RAM.

## Environment

- `module purge` then load the CUDA/driver-compatible modules the docs specify, or use
  a conda/venv/container build whose CUDA runtime matches the node driver. Build the
  environment on the login node or per the site's instructions, never inside the job.
- At job start log: `nvidia-smi`, `echo $CUDA_VISIBLE_DEVICES`,
  `python -c "import torch; print(torch.cuda.is_available(), torch.version.cuda)"`.
  Fail fast if no GPU is visible rather than silently running on CPU.
- Set `OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK` (or a smaller value) for CPU-side threads.

## Launch patterns (PyTorch)

Choose one pattern; do not mix them.

| Pattern | Directives | Launch |
|---|---|---|
| Single GPU | `--gres=gpu:1 --cpus-per-task=C` | `python train.py` |
| Multi-GPU, one node, torchrun | `--nodes=1 --ntasks=1 --gres=gpu:G --cpus-per-task=C` | `torchrun --standalone --nproc_per_node=$G train.py` |
| One task per GPU via srun | `--ntasks-per-node=G --gpus-per-task=1` | `srun python train.py` (reads `SLURM_PROCID`, `SLURM_LOCALID`) |
| Multi-node | one of the above plus `--nodes=N` | see [references/multi-gpu.md](references/multi-gpu.md) |

- Do not combine `--gpus-per-task=1` with `torchrun`: each worker then sees one GPU.
- Do not combine `--gpus-per-node` with `srun`-launched per-GPU tasks unless every
  task should see all GPUs.
- Rendezvous address from the first node:
  `scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1`. Derive `MASTER_PORT`
  from the job ID (`10000 + SLURM_JOB_ID % 50000`) instead of a fixed or
  `$RANDOM` port, which can collide with another job on the node.
- Use `srun --kill-on-bad-exit=1` for multi-process jobs so one dead rank ends the job
  instead of hanging the others.

Templates: [assets/gpu-single.sh](assets/gpu-single.sh),
[assets/gpu-multigpu-torchrun.sh](assets/gpu-multigpu-torchrun.sh)

## Monitoring and efficiency

- Log GPU utilisation during the run (background sampler, stopped at exit):
  ```bash
  nvidia-smi --query-gpu=timestamp,index,utilization.gpu,memory.used,memory.total \
    --format=csv -l 30 -f "logs/gpu_${SLURM_JOB_ID}.csv" &
  GPU_MON=$!; trap 'kill $GPU_MON 2>/dev/null || true' EXIT
  ```
  Or attach to a running job: `srun --jobid=<id> --overlap nvidia-smi` (needs
  site permission; `--overlap` may be required on newer Slurm).
- Low utilisation usually means a starved input pipeline (too few workers, slow
  shared filesystem, small batches) or CPU-bound preprocessing. Stage the dataset to
  node-local scratch (`hpc-job-scripts` references/arrays-and-scratch.md) and use
  `pin_memory=True`, `prefetch_factor`, persistent workers.
- GPU OOM: reduce batch size, use mixed precision or gradient accumulation; request a
  larger-VRAM type rather than more GPUs if the model does not fit.
- Fractional/shared GPUs (MIG, MPS, shard) and exclusive modes are site-specific; check
  the docs before assuming a whole GPU. Sharing a GPU between busy kernels can slow both.
- NCCL: network interface and InfiniBand settings (`NCCL_SOCKET_IFNAME` etc.) are
  site-specific; copy them from the site's docs. `NCCL_DEBUG=WARN` helps diagnose hangs.

## Robustness

- GPU jobs are long and expensive: checkpoint (model, optimizer, scheduler, RNG, step),
  write atomically, resume automatically, and handle `SIGUSR1` as in
  `hpc-job-scripts` references/checkpoint-requeue.md and `hpc-python-code`.
- Seed every rank deliberately (base seed + rank) and log it.
- DataLoader workers must ignore `SIGUSR1` so only the main process checkpoints.
- Test the restart path on a short job before the long run.
- Request the shortest `--time` that fits; short GPU jobs backfill sooner.

## Checklist

- [ ] GPU syntax, type and QOS copied from the cluster docs
- [ ] `--cpus-per-task` and `num_workers` agree; measured GPU utilisation
- [ ] Launch pattern consistent (torchrun or srun, not both)
- [ ] Port/rendezvous derived from the job ID; `--kill-on-bad-exit` set
- [ ] GPU visibility and CUDA version logged at start
- [ ] Checkpoint, resume, and signal path tested
- [ ] Data staged near the node; results synced to persistent storage

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.
