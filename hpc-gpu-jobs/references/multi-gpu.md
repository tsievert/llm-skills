# Multi-GPU and multi-node notes (PyTorch on Slurm)

## Contents
- Choosing the pattern
- Pattern A: one task per node, torchrun
- Pattern B: one task per GPU, srun
- Common failures

These patterns are assembled from public cluster guides and were not run on a real
cluster by this skill's author. Treat them as starting points and verify against the
site's documentation.

## Choosing the pattern

- Single node: `torchrun --standalone` is the simplest.
- Multi-node: either one task per node with torchrun spawning one process per GPU
  (Pattern A), or one task per GPU with `srun` and the program initialising the
  process group from Slurm variables (Pattern B).
- Keep `--ntasks-per-node` consistent with the pattern. Do not add `--gpus-per-task`
  to Pattern A.

## Pattern A: one task per node, torchrun

```bash
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-node=4          # or --gres=gpu:4 (site syntax)
#SBATCH --cpus-per-task=32

MASTER_ADDR=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
MASTER_PORT=$((10000 + SLURM_JOB_ID % 50000))
export MASTER_ADDR MASTER_PORT

srun --kill-on-bad-exit=1 torchrun \
  --nnodes="$SLURM_NNODES" \
  --nproc_per_node="${SLURM_GPUS_ON_NODE:-4}" \
  --rdzv_backend=c10d \
  --rdzv_endpoint="$MASTER_ADDR:$MASTER_PORT" \
  train.py
```

`--node_rank` is handled by the c10d rendezvous; do not hand-compute ranks.

## Pattern B: one task per GPU, srun

```bash
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=8

export MASTER_ADDR=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
export MASTER_PORT=$((10000 + SLURM_JOB_ID % 50000))
export WORLD_SIZE=$SLURM_NTASKS

srun --kill-on-bad-exit=1 bash -c 'RANK=$SLURM_PROCID LOCAL_RANK=$SLURM_LOCALID python train.py'
```

The program reads `RANK`, `LOCAL_RANK`, `WORLD_SIZE`, `MASTER_ADDR`, `MASTER_PORT`.
`$SLURM_LOCALID` indexes the GPU inside a node only if each task sees all GPUs; with
`--gpus-per-task=1` each task usually sees one device (`cuda:0`), so use device 0.

## Common failures

| Symptom | Likely cause |
|---|---|
| Hang at init | Wrong `MASTER_ADDR`/port, firewall, wrong NCCL interface; set `NCCL_DEBUG=WARN` |
| `Address already in use` | Port collision with another job; derive port from job ID |
| One rank dies, others hang | Missing `--kill-on-bad-exit=1` |
| Each worker sees one GPU under torchrun | `--gpus-per-task=1` used with torchrun |
| Ranks all use GPU 0 | Tasks see all GPUs and no per-rank device selection |
| Slow scaling beyond one node | Network/interconnect or data pipeline bound; run a scaling test |
| Checkpoint written by every rank | Only rank 0 should write; barrier before exit |
