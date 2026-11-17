# HPC threading research ledger

Generic wording only (public repo). Created 2026-11-17 for maintenance review task 9. Append new rounds as dated sections.

## Section index

1. Requirements
2. Round 2026-11-17: multithreaded `bam` slow on fragmented or cross-socket core sets
3. Open research items
4. Log

## 1. Requirements

| # | Requirement | Date |
|---|---|---|
| R1 | Never guess site facts: cluster-specific information (topology, binding defaults, `CPU_IDs`) comes from the user running commands (`hpc-cluster-docs` flow). | 2026-11-17 |
| R2 | Keep the "Where this skill runs" rule in `hpc-r-code` and `hpc-resource-allocation`. | 2026-11-17 |
| R3 | Default outcome: park (one report, confidence low) until a second report or a benchmark confirms; no SKILL.md text from one project. | 2026-11-17 |

## 2. Round 2026-11-17

Report summarised: identical 8-thread `bam(discrete = TRUE, nthreads = 8)` array tasks (about 40k rows, mgcv 1.9.5, 96-core
two-socket shared nodes, `--cpus-per-task=8`); two of many tasks ran 4-7x slower, with scattered `CPU_IDs` across both sockets
(fast tasks had contiguous IDs); node load below allocation. Cause unconfirmed.

### Sources

| Source | Status | Facts |
|---|---|---|
| mgcv `?bam` (1.9.5, local help) | read (nthreads/discrete sections) | With `discrete = TRUE`, `nthreads` threads the discrete cross-products; the help says multi-threaded gains are often disappointing because machines are memory-bandwidth limited rather than flop limited. Multi-threaded BLAS plus `nthreads > 1` usually slows things down; `nthreads = c(2, 1)` threads only the inner products. Supports "benchmark fewer threads"; says nothing about sockets or placement. |
| Slurm `mc_support` https://slurm.schedmd.com/mc_support.html | read | `--cpu-bind` defaults to none; binding needs `TaskPlugin=task/affinity`. `--hint=memory_bound` uses one core per socket (not what a threaded single task wants); `-B`/`--sockets-per-node` are minimums for node selection, not a placement guarantee. Default `--distribution=block:cyclic` keeps a task's CPUs on one socket "where possible" only. |
| Slurm `sbatch` https://slurm.schedmd.com/sbatch.html | partial (first 90k of 130k characters) | No documented option guarantees one socket for a `--cpus-per-task` request. `--sockets-per-node` etc. need `select/cons_tres` with a Core/Socket `CR_*` setting; `--hint` excludes those options; `--exclusive` avoids node sharing but is not socket-specific. `--cpu-bind` text was beyond the part read. |
| libgomp env vars https://gcc.gnu.org/onlinedocs/libgomp/Environment-Variables.html | partial (index page only) | Lists `OMP_PROC_BIND`, `OMP_PLACES`, `OMP_WAIT_POLICY`, `GOMP_CPU_AFFINITY`, `GOMP_SPINCOUNT`, `OMP_DISPLAY_AFFINITY`. Semantics and defaults not read. |
| Site documentation of the user's cluster | not researched | Needed: whether `task/affinity` or cgroup binding is on, whether cores are allocated per socket, and any recommended `--cpu-bind`/`--exclusive` settings. |
| OpenAlex literature | not researched | Software-behaviour question, no scientific-method claim; OpenAlex is unlikely to help. |

### Facts and inference

- Established (docs): threaded `bam` is memory-bandwidth limited (mgcv help); Slurm gives no placement guarantee for `--cpus-per-task` (sbatch page); binding is off by default (mc_support).
- Consistent with the report but not established: the slow tasks lost because threads straddled sockets (barrier and memory traffic across the interconnect, or memory allocated on the other socket). The report found a correlation with `CPU_IDs`, not a controlled test.
- Not tested: no benchmark here (no cluster in this session; a local single-socket machine cannot reproduce it). Never infer topology.

### Proposal (no skill text yet)

Default outcome R3: park. If a second report arrives, a short note for `hpc-r-code` (and a one-line pointer in `hpc-resource-allocation`) would say: for threaded jobs on shared multi-socket nodes, benchmark 1, 4 and 8 threads on moderate data and expect sublinear gains; if some array tasks are much slower than identical siblings, ask the user to run `scontrol show job -d <jobid>` (CPU_IDs) and `scontrol show node` and compare; options to try only after site docs: fewer threads, `--exclusive`, `--cpu-bind`, resubmitting only slow tasks; note `sstat` needs the real job id. Ask the user to run these; do not guess.

## 3. Open research items

| # | Item | Status |
|---|---|---|
| O1 | Read the rest of the `sbatch` page (`--cpu-bind`, `--exclusive`, `--distribution`) and `OMP_PROC_BIND`/`OMP_PLACES`/`OMP_WAIT_POLICY` pages. | open |
| O2 | User-run benchmark on the cluster: same fit with `nthreads` 1, 4, 8, pinned to one socket vs scattered (e.g. `taskset`/`--cpu-bind`), recorded with `CPU_IDs`. | open, needs user |
| O3 | Site docs lookup for the user's cluster (`hpc-cluster-docs`). | open, needs user |
| O4 | Second independent report. | waiting |

## 4. Log

- 2026-11-17: round 1 (docs only). Outcome: entry stays parked; no skill files edited.
