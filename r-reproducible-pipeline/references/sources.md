# Sources and status

Contents: pages read; pages not read; versions; literature.

Looked up 2026-10-23. Re-check before stating a function argument or version.

## Read

- targets manual, https://books.ropensci.org/targets/ : walkthrough, projects, random (seeds),
  literate-programming, performance, debugging, hpc (the "old way" clustermq/future page),
  crew chapter (see below).
- crew and crew.cluster (reference pages `crew_controller_slurm`, `crew_options_slurm`).
- tarchetypes reference for `tar_quarto()`.
- renv: https://rstudio.github.io/renv/articles/renv.html , reference/lockfiles.html , and the
  Python article.
- Quarto: project scripts (https://quarto.org/docs/projects/scripts.html), code execution and
  virtual environments pages.
- Posit Package Manager snapshots: search results and `pak::ppm_snapshots()` (tested). The
  admin documentation URL returned only a redirect and the PyPI setup page is not readable as
  text, so the PyPI snapshot URL form is unconfirmed.

## Not read or not found

- targets "files" page (404 at the guessed URL); `tar_map`, `tar_rep`, `tar_resources_*`,
  `tarchetypes` factories beyond `tar_quarto()`; Target Markdown; `gittargets`.
- How to start `tar_make()` inside a Slurm job (not on the HPC page).

## Versions seen (CRAN, 2026-10-23)

targets 1.12.0, tarchetypes 0.14.1, crew 1.3.3, crew.cluster 0.4.0, renv 1.3.1, quarto (R) 1.5.1,
qs2 0.3.1. `tar_seed()` deprecated since targets 1.3.2.9001 (use `tar_seed_get()`);
`reporter = "summary"` deprecated since 1.10.1.9010.

## Literature (OpenAlex; authors checked, abstracts not read)

- Landau, "The targets R package", JOSS 2021, https://doi.org/10.21105/joss.02959
- Sandve et al., "Ten simple rules for reproducible computational research", PLoS Comput Biol 2013,
  https://doi.org/10.1371/journal.pcbi.1003285
- Wilson et al., "Good enough practices in scientific computing", PLoS Comput Biol 2017,
  https://doi.org/10.1371/journal.pcbi.1005510
- Gupte et al., "A guide to pre-processing high-throughput animal tracking data", J Anim Ecol 2021,
  https://doi.org/10.1111/1365-2656.13610 (field-specific pipeline example)
- No peer-reviewed comparison of targets with Snakemake or Nextflow was found.
