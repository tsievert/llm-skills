# Snakemake on Slurm, reruns and reports

- [Profile](#profile) | [Resources](#resources) | [Cluster-side facts to ask the user for](#cluster-side-facts-to-ask-the-user-for) | [Rerun triggers](#rerun-triggers) | [Rerun and NFS test for the user](#rerun-and-nfs-test-for-the-user) | [Reports](#reports) | [Not tested](#not-tested)

Everything here was read from the Snakemake docs and the Slurm plugin catalogue page
(2026-10-23) or tested locally on Windows with Snakemake 9.27.1 and the plugin 2.8.0.
Re-read the plugin page before changing profile keys: the plugin has its own release cycle.

## Profile

- A profile is a YAML file whose top-level keys are CLI flags (`executor: slurm` is `--executor slurm`; `default-resources:` is `--default-resources`).
- `--workflow-profile slurm` reads `workflow/profiles/slurm/profile.yaml` (or `profiles/slurm/`); `--profile` searches global locations; command-line flags beat the workflow profile, which beats global profiles; merging is per top-level key, so a later `default-resources:` replaces the whole earlier block.
- The default file name is `profile.yaml` (or `config.yaml` for older setups); a `v9+.` infix such as `profile.v9+.yaml` sets a minimum Snakemake version.
- Tested locally: the template profile is picked up (an invalid `executor` in it produced an argument error) and `snakemake --workflow-profile slurm -n` dry-runs. Submission was not possible.

## Resources

| Key | Meaning | Note |
|---|---|---|
| `slurm_partition`, `slurm_account` | `--partition`, `--account` | values from the site, not guesses |
| `mem_mb` | `--mem` | mutually exclusive with `mem_mb_per_cpu` |
| `mem_mb_per_cpu` | `--mem-per-cpu` | use one of the two consistently in defaults and rules |
| `runtime` | wall time in minutes | `--time` |
| `cpus_per_task` | `--cpus-per-task` | also set `threads:` in the rule so tools use it |
| `gres`, `gpu`, `constraint`, `slurm_extra` | GPU and site-specific flags | keep cluster-specific values in the profile, not in rules; `slurm_extra` cannot override flags the plugin sets |

Caveats listed on the plugin page: `--jobs` is required; jobs run in a non-interactive `sh`
(`.bashrc` is not sourced; use `precommand` to source an environment); running Snakemake
inside a Slurm job warns and pauses; status polling starts about 40 s after submission and
backs off to 180 s; array jobs add synchronisation overhead; whether the controller may run
on a login node is site policy.

Per-rule overrides after measuring go in `set-resources:` (see `hpc-resource-allocation`;
the `benchmark:` files in the template give runtime and memory per job).

## Cluster-side facts to ask the user for

The assistant cannot run these. Give them in a code block and wait for the output:

```bash
sinfo -s                                             # partitions and limits
sacctmgr show assoc user=$USER format=account,partition,qos   # accounts the user may charge
which uv && uv --version                             # is uv on the PATH of compute nodes?
module avail python 2>&1 | head -20                  # site Python modules (if uv is absent)
df -hT . | tail -1                                   # filesystem type of the project directory
```

Also ask for the site's policy on running the Snakemake controller on a login node.

## Rerun triggers

`--rerun-triggers` accepts `code`, `input`, `mtime`, `params` and `software-env`; all five are on by default.
Observed locally (Snakemake 9.27.1, Windows, dry runs):

| Change | Reran? |
|---|---|
| Edited a script, comment only | yes (code) |
| Changed a config value that the rule receives via `params:` | yes (params) |
| Changed a config value that the script reads from `snakemake.config` | no |
| Changed input file content | yes |
| `touch` on an unchanged file (newer mtime, same content) | no, also with `--rerun-triggers mtime` |

The last row is unexplained by the docs read. `--max-checksum-file-size` (default 1 MB:
checksums are computed only for smaller files) fits the observation but was not tested
directly; larger files may behave differently. Related options: `--touch` (marks outputs
up to date, loses provenance, last resort), `--consider-ancient`, `--rerun-incomplete`,
`--cleanup-metadata`, `--list-input-changes`, `--latency-wait` (default 5 s, raise on
shared filesystems; the template uses 60).

## Rerun and NFS test for the user

Nextflow's docs describe NFS timestamp problems; Snakemake's behaviour on a shared
filesystem is untested. To check on the cluster, in a copy of the template project there
(outputs on the shared filesystem):

```bash
uv sync --locked && uv run --locked snakemake --cores 2          # first run
uv run --locked snakemake --cores 2 -n                           # expect: Nothing to be done
touch config/config.yaml workflow/scripts/summarise.py           # mtime only
uv run --locked snakemake --cores 2 -n                           # expect: Nothing to be done
echo "# c" >> workflow/scripts/summarise.py
uv run --locked snakemake --cores 2 -n                           # expect: summarise reruns (code changed)
```

Paste back the three dry-run outputs and the filesystem line from `df -hT`. Unexpected
reruns after the first dry run would indicate timestamp problems.

## Reports

`snakemake --report report.html` builds a self-contained HTML (about 3 MB for the
template, with script code embedded); `.zip` is recommended for large outputs. Mark
outputs with `report(path, caption="report/x.rst", category="...")` (captions are
reStructuredText). Requires the `pygments` package, which Snakemake does not install:
the first attempt failed with "Python package pygments must be installed to create reports".
Not tested: opening the HTML in a browser, Quarto or notebook outputs in a report.

## Not tested

Real Slurm submission, requeue and signals, `precommand`, `shared-fs-usage` and storage
plugin settings, conda or container deployment (`--sdm`), WSL, Linux and macOS, Snakemake
inside a job, paths with spaces, `--cache`.
