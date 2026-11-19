# Capacity benchmark (finding the largest input that fits)

Use when the goal is the largest input per job (for example frames per GPU fit), not a safe request for a known job. A capacity ceiling is maximised; headroom margins apply only to the memory later requested.

- **Independent attempts.** One array task per input size, so one failure does not stop the others.
- **Largest first, skip-if-larger-passed.** A descending ladder gives a decisive first result (an all-data attempt that fails at initialisation in minutes) and later rungs are skipped once a larger one passed. Bisect between the last pass and first failure in rounds.
- **Only a program-reported GPU out-of-memory is a ceiling.** Timeout, host RAM kill, NaN or a crash say nothing about GPU capacity: classify them inconclusive and do not bisect on them. Read the program's own status file, not only the exit code.
- **Init failures give a lower bound.** An allocation error reports one failed allocation and the pool size, not the total need, so arithmetic cannot narrow the ladder; use a dense descending ladder because failures are cheap.
- **Record context per attempt.** GPU model and partition (see `hpc-gpu-jobs`); the ceiling does not transfer to another partition.
- **Feed the result back** as a generated limits file that the orchestrator reads.
- Ask for the cluster facts (QOS limits, `sinfo` GRES, input sizes) in one batch of questions plus read-only commands before designing the ladder.
