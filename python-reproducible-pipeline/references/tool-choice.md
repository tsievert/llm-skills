# Choosing a workflow tool

- [How the verdicts were reached](#how-the-verdicts-were-reached) | [Comparison](#comparison) | [When to leave the default](#when-to-leave-the-default) | [What was not checked](#what-was-not-checked)

## How the verdicts were reached

Official documentation pages and PyPI metadata were read on 2026-10-23; Snakemake (with
the Slurm plugin) was also run locally. Third-party comparison blogs were used only for
orientation and carry less weight (vendor-style posts, version claims in them were not
reliable). Nothing except Snakemake was executed. Source list: [sources.md](sources.md).

## Comparison

| Tool | Model | Slurm / HPC route | Python + R + shell steps | Verified here | Verdict for a researcher with Python/R analyses on Slurm |
|---|---|---|---|---|---|
| Snakemake 9.x | File-based rules, DAG inferred from outputs; Python DSL | Executor plugin `snakemake-executor-plugin-slurm`; profiles | `script:` for Python, R, R Markdown, Julia, Bash; `shell:`; `notebook:` | Run locally, dry run of the Slurm profile | Default. Mature, big academic user base (Köster & Rahmann 2012; Mölder et al. 2021) |
| pytask 0.6 | Python functions as tasks, lazy execution, hashes | Not verified (plugins: pytask-parallel, pytask-r, ...) | Python first; R via plugin | Docs read only | Reasonable on a laptop; unproven on Slurm |
| Nextflow | Dataflow of processes in a Groovy DSL on the JVM | Native SLURM, LSF, cloud executors | Any scripting language per process | Docs read only | Strong alternative, especially for nf-core pipelines; second language, Java 17-26, Windows only via WSL |
| DVC 3.x | Stages in `dvc.yaml`, hashes in `dvc.lock`, run cache | Not covered by the pipelines page | Any command | Docs read only | Better as data versioning than as the orchestrator |
| Prefect 3 | Python flows and tasks, state tracking, UI, events | Dask task runner can take a cluster class; Slurm not mentioned | Python | Docs read only | Not recommended here: platform/service oriented |
| Dagster 1.13 | Asset graph, webserver, schedules | No Slurm or HPC executor in the executor list | Python (and integrations) | Docs read only | Not recommended here |
| Kedro, Hamilton, Luigi, doit | Various | Not assessed | Python | Metadata only | Not assessed; Luigi's development was described as slow (pytask docs) |

## When to leave the default

- **R-only analysis:** `targets` + `crew.cluster` (`crew_controller_slurm()` exists, maturing) is the R-native route; dependencies are R objects, not files. There is no skill for it yet.
- **Mixed and already in `targets`:** `targets` can run external scripts as file targets, but its manual does not cover non-R targets; Snakemake handles mixed steps more directly.
- **Python functions with in-memory hand-over:** pytask or plain functions; Snakemake passes data through files, which suits reproducibility but costs I/O.
- **Cloud-first or existing nf-core pipeline:** Nextflow.
- **Service-style scheduling and monitoring (cron-like, dashboards):** Prefect or Dagster, but that is operations, not analysis reproducibility.
- **Fewer than about three steps and no cluster:** a script that calls the steps plus `uv run --locked` may be enough; say so rather than adding a tool.

## What was not checked

Prefect local-server requirement, Dagster webserver/daemon requirement, pytask on Slurm,
Nextflow resume on a shared filesystem (the docs describe an NFS timestamp caveat and a
`lenient` mode), Kedro and Hamilton. If the user's choice depends on one of these, read
the live docs first.
