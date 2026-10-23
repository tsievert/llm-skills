library(targets)
library(tarchetypes)

# Loads every script in R/ (functions only; no work happens at load time)
tar_source()

tar_option_set(
  # Per-target seeds are derived from this value and the target name
  seed = 2604,
  # NULL runs targets one after another; see make_controller() in R/controllers.R
  controller = make_controller()
)

list(
  # Config and the external script are file targets: a change in either invalidates what depends on it
  tar_target(config_file, "config/config.yml", format = "file"),
  tar_target(config, read_config(config_file)),
  tar_target(sim_script, "py/simulate.py", format = "file"),

  # One small target per setting: changing one value only invalidates its own dependants
  # (depending on the whole config list would rerun everything whenever any value changes)
  tar_target(sample_id, config$samples),
  tar_target(n_obs, config$n_obs),
  tar_target(slope, config$slope),

  # One Python run per sample (dynamic branching); each branch returns a file path
  tar_target(
    sim_csv,
    run_python_sim(sim_script, sample_id, n_obs, slope, tar_seed_get()),
    pattern = map(sample_id),
    format = "file"
  ),
  tar_target(sim_data, read_sim(sim_csv), pattern = map(sim_csv)),

  tar_target(fit, fit_model(sim_data)),
  tar_target(coef_table, tidy_coefs(fit)),

  # Report: reads upstream results with literal tar_read() calls
  tar_quarto(report, "report.qmd")
)
