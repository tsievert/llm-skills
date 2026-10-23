---
name: hpc-resource-allocation
description: Chooses and corrects HPC job resource requests (CPUs, memory, GPUs, wall time, nodes, array size) using a measure-then-size workflow with sacct/seff, and diagnoses jobs that were killed for memory or time, stayed pending, or wasted resources. Use when the user asks how much memory, time, cores, or GPUs to request, how to tune an sbatch script, why a job hit OUT_OF_MEMORY or TIMEOUT, why it is slow or stuck pending, or how to batch many short jobs.
---

# HPC resource allocation

Over-requesting lengthens queue time, burns allocation/priority, and wastes shared
hardware; under-requesting gets jobs killed. The goal is accurate, measured requests
with modest headroom. Get site limits from `hpc-cluster-docs` first (partition
maximums and default memory vary).

## Workflow: measure, then size

1. **Classify the workload.** Serial, multithreaded (one process, many threads),
   multiprocess/embarrassingly parallel, MPI, GPU. Only parallel code benefits from
   more CPUs; only GPU code benefits from GPUs.
2. **Make a first guess small**, not generous: a short `--time`, a modest `--mem`,
   a representative but reduced input. Run it (interactive session or short batch).
3. **Measure** after it ends:
   ```bash
   sacct -j <id> --format=JobID,JobName,State,Elapsed,Timelimit,AllocCPUS,TotalCPU,ReqMem,MaxRSS
   seff <id>        # if installed: CPU and memory efficiency summary
   ```
   Compare `MaxRSS` to `ReqMem`, `Elapsed` to `Timelimit`, and `TotalCPU` to
   `Elapsed x AllocCPUS`. `MaxRSS` for jobs with steps is reported per step; check the right row.
4. **Scale to the real input** and re-measure; memory and time often scale with input size,
   so extrapolate from two sizes, not one.
5. **Set the final request** with headroom: memory about 10-20% above measured peak,
   time about 20-50% above measured (time headroom is cheap but very long limits hurt
   backfill scheduling). Document the measured numbers in a comment.
6. **Re-check periodically**; data or code changes shift needs.

## Directive mapping

| Workload | Directives |
|---|---|
| Serial | `--ntasks=1 --cpus-per-task=1` |
| Threads / multiprocessing on one node | `--nodes=1 --ntasks=1 --cpus-per-task=N`, program uses `$SLURM_CPUS_PER_TASK` |
| Many independent tasks | job array, 1 CPU each, throttle `%N` |
| MPI | `--ntasks=N` (and `--nodes`/`--ntasks-per-node` if layout matters), launch with `srun` |
| Hybrid MPI + threads | `--ntasks`, `--cpus-per-task`, `OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK` |
| GPU | the site's GPU syntax (`--gres=gpu:N` or `--gpus=N`); request multiple GPUs only if the code uses them; see `hpc-gpu-jobs` |
| R | `Rscript`, workers from `availableCores()`; see `hpc-r-code` |

Rules of thumb:

- `--cpus-per-task` > 1 only for multithreaded/multiprocess code. If unsure, benchmark
  with 2 and 4 CPUs and compare wall time.
- Prefer `--mem` (per node) for single-node jobs, `--mem-per-cpu` when memory scales
  with core count. They are mutually exclusive. `--mem=0` takes all memory on the node;
  use only when you really need the node.
- Request in terms of cores/tasks when flexible; avoid `--exclusive` unless needed.
- Do not request more than the largest node of the partition offers; the job will
  pend indefinitely, as will a `--time` above the partition limit.
- Parallel efficiency usually drops as CPUs grow; find the sweet spot with a short scaling test.
- More CPUs also means longer queue wait. Four 24-core jobs can beat one 96-core job.
- Combine many jobs under ~5 minutes into fewer longer ones (or loop inside one job);
  per-job overhead dominates. Do not make jobs so long that failures waste hours: use
  checkpointing (`hpc-python-code`) and skip-if-done logic.
- Do not set `--partition` blindly; use what the cluster profile says (some sites
  recommend leaving it unset).

## Diagnosing failures

| `sacct` State / symptom | Meaning | Action |
|---|---|---|
| `OUT_OF_MEMORY` or log says "oom-kill" / "Cgroup mem limit exceeded" | Used more than requested | Raise memory from measured `MaxRSS`; check for leaks or avoidable copies |
| `TIMEOUT` | Hit wall-time | Raise `--time`, add checkpoint/requeue, or split work |
| `FAILED`, `ExitCode` non-zero | Program error | Read the job log; check output dir existed; run the linter |
| `CANCELLED` | User, admin, or preemption | Check `scontrol show job`, partition preemption policy |
| `NODE_FAIL` | Hardware | Resubmit; use `--requeue` if allowed |
| Pending, reason `Resources` / `Priority` | Waiting for capacity or priority | Reduce request, shorten `--time`, check fairshare |
| Pending, `QOSMaxJobsPerUserLimit` | Per-user cap | Wait or use arrays with throttle |
| Pending, `DependencyNeverSatisfied` | Upstream job failed | Cancel; use `--kill-on-invalid-dep=yes` next time |

`squeue --me --start` and `sbatch --test-only` estimate start times. Estimated queue
time falls when requests are smaller and time limits are tighter and accurate, because
backfill scheduling can fit them into gaps.

## Efficiency review checklist

- [ ] `MaxRSS` is within roughly 60-90% of `ReqMem` (not 5%, not 100%)
- [ ] CPU efficiency (`TotalCPU / (Elapsed x AllocCPUS)`) is reasonable for the workload
- [ ] `Elapsed` is a healthy fraction of `Timelimit` (not 2%, not 99%)
- [ ] GPU utilisation checked (`nvidia-smi` in job or site tooling) before asking for more GPUs
- [ ] Thread/process counts match the allocation (no oversubscription)
- [ ] Tiny jobs batched or arrayed; arrays throttled
