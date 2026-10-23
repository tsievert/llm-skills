---
name: hpc-cluster-docs
description: Identifies which HPC cluster and scheduler (Slurm, PBS/Torque, LSF, SGE) the user runs on and looks up that site's official documentation before any job script, resource request, or HPC Python code is written or reviewed. Use first whenever a task mentions Slurm, sbatch, srun, qsub, bsub, partitions, queues, modules, job arrays, "the cluster", or "HPC", unless a cluster profile is already known from memory or the conversation.
---

# HPC cluster identification and documentation lookup

Clusters differ in ways that silently break scripts: required `--account`/`--partition`
flags, GPU syntax, default memory, array limits, preemption, scratch purge rules.
Never write cluster-specific directives from memory. Establish the site first, then
read its docs.

Examples of real site variance found while building this skill: one site says not to
set `--partition` at all; another requires `--account` and `--partition`; one forbids
`--mem` and overriding `OMP_NUM_THREADS`; one effectively bans job arrays.

## Where this skill runs

The assistant runs on the user's local machine, not on the cluster. It cannot log in,
run `sbatch`/`sinfo`/`module avail` or read the cluster's filesystem. Cluster-side
commands here are instructions for the user to run and paste back. Only public
documentation (web fetch) can be read directly.

**Requirement:** whenever information is needed that only the cluster can provide,
stop and ask the user to run the specific shell command(s), given in a code block, and
paste back the output. Do not guess or proceed on assumptions.

## Workflow

1. **Check what is already known.** Look in project memory (AGENTS.md section
   "HPC cluster profile") and the conversation. If a profile exists, confirm it in
   one line and reuse it; do not re-ask.
2. **Otherwise ask the user** in a single batch (use the AskUser tool if available,
   with free text):
   - Cluster / institution name (e.g. "Uni X Y-cluster")
   - Scheduler, if they know it (assume Slurm only as a hypothesis; confirm)
   - Account/project and intended partition or queue, if known
   - Whether GPUs are needed
   - How Python environments are managed there (modules, conda/mamba, venv/uv, containers)
3. **If the user does not know the answers**, give them these read-only commands to run
   on the login node and paste back:
   ```bash
   sinfo -s                                   # partitions
   scontrol show config | grep -iE 'SelectType|JobRequeue|MaxArraySize|PreemptType|KillWait|DefMemPer'
   sacctmgr show assoc user=$USER format=account,partition,qos
   module avail python 2>&1 | head -20
   ```
4. **Look up the official docs online.** Search for the site's user guide
   (e.g. "<site> HPC user guide slurm job submission"), prefer the institution's own
   documentation domain, and fetch the relevant pages. Re-fetch rather than trusting
   memory, because site docs change. Give the user the URLs you relied on.
5. **Extract the site facts** in the checklist below. Say explicitly which items you
   could not find; do not guess partition names, account flags, or module names.
6. **Offer to save a cluster profile** to project memory (AGENTS.md) so future sessions
   skip steps 2-5. Only write it if the user agrees.

## Site facts checklist

| Fact | Why it matters |
|---|---|
| Scheduler and version | Directive syntax; srun/`--cpus-per-task` behaviour changed in Slurm 22.05 |
| Partitions: max time, max memory/CPUs, default memory per CPU | Request sizing; jobs above the partition limit can stay pending forever |
| Account / QOS required? | Submission rejected without it |
| GPU request syntax (`--gres=gpu:N`, `--gpus`, constraint for model) | Differs per site |
| Array limits (`MaxArraySize`, per-user job cap) | Some sites discourage or cap arrays |
| Preemption / requeue policy, grace period | Decides whether checkpointing is mandatory |
| Storage: home quota, project, scratch path, purge policy, node-local `$TMPDIR` | Where logs and checkpoints may go |
| Module system and Python policy | `module purge` + `module load` vs conda/venv; whether pip is allowed |
| Internet access on compute nodes | Affects package installs and data downloads inside jobs |
| Node-local scratch: variable (`$TMPDIR`, `$SLURM_SCRATCH`, ...), local vs shared, size, `--tmp` request, purge/cleanup at job end | Staging data and periodic syncs; work left there is lost on cancel |
| `KillWait` and signal behaviour at time limit/preemption | How long a final sync or checkpoint can take |
| Shared-filesystem type and whether `flock` works | Whether file locks are usable to avoid races |
| GPU partitions, types, VRAM, CUDA modules, fractional/shared GPU options | Driver/CUDA compatibility and request syntax (`hpc-gpu-jobs`) |
| R modules, library policy, package install location, extra modules for compiled packages | `hpc-r-code` |
| Login-node rules | Heavy work there is usually prohibited |
| Email notification policy | Some sites restrict `--mail-type` |

## Format of the profile (when saving)

```markdown
## HPC cluster profile
- Site: ...  Scheduler: Slurm <version>  Docs: <urls>
- Account: ...  Default partition: ...  GPU syntax: ...
- Limits: max time ..., arrays ..., preemption ...
- Storage: scratch=..., logs=..., purge=...
- Python: <modules / conda / venv>, internet on compute nodes: yes/no
- Verified on: <date>
```

## Next skills

- Writing or reviewing submission scripts: `hpc-job-scripts`
- Python code that runs inside jobs: `hpc-python-code`
- Choosing or diagnosing CPU/memory/GPU/time requests: `hpc-resource-allocation`
- GPU / deep-learning jobs: `hpc-gpu-jobs`
- R scripts and R pipelines on the cluster: `hpc-r-code`
- DeepLabCut training and video analysis: `deeplabcut-hpc`
- DeepLabCut training and video analysis: `deeplabcut-hpc`

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
