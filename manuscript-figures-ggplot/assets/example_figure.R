# Worked example: a three-panel behavioural-ecology figure on SIMULATED data.
# Shows the pattern: raw data first, uncertainty at the right unit (individual),
# colour-blind-safe palette plus a second encoding, panels built at final size.
# Run from the skill folder or adjust the source() path.

library(ggplot2)
library(patchwork)
library(ggbeeswarm)   # raw points without overplotting

source("scripts/figure_helpers.R")

set.seed(6153)
n_id <- 24
d <- expand.grid(id = seq_len(n_id), session = c("1", "2"))
d$treatment <- factor(ifelse(d$id <= n_id / 2, "control", "predator odour"),
                      levels = c("control", "predator odour"))
ind <- rnorm(n_id, 0, 0.5)[d$id]
d$latency <- exp(3 + ind + ifelse(d$treatment == "predator odour", 0.5, 0) +
                   ifelse(d$session == "2", -0.2, 0) + rnorm(nrow(d), 0, 0.4))

# One value per individual (mean of sessions on the log scale) = the unit of replication
ind_means <- aggregate(log(latency) ~ id + treatment, d, mean)
names(ind_means)[3] <- "log_latency"

# Group mean and 95% CI over individuals (t-based). For repeated-measures
# designs prefer model-based estimates (see the mixed-models-glmm skill).
ci <- do.call(rbind, lapply(split(ind_means, ind_means$treatment), function(g) {
  tt <- t.test(g$log_latency)
  data.frame(treatment = g$treatment[1], m = tt$estimate, lo = tt$conf.int[1], hi = tt$conf.int[2])
}))

# Two groups: two ends of viridis (stay distinct in grayscale and under colour-vision deficiency)
cols <- setNames(scales::viridis_pal(begin = 0.15, end = 0.8)(2), c("control", "predator odour"))
shps <- c(control = 16, `predator odour` = 17)

pa <- ggplot(ind_means, aes(treatment, exp(log_latency))) +
  geom_beeswarm(aes(colour = treatment, shape = treatment), size = 1.2, cex = 2.5) +
  geom_pointrange(data = ci, aes(y = exp(m), ymin = exp(lo), ymax = exp(hi)),
                  position = position_nudge(x = 0.28), size = 0.3, linewidth = 0.4) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_shape_manual(values = shps, guide = "none") +
  scale_y_log10() +
  labs(x = NULL, y = "Latency (s, log scale)") +
  theme_ms(base_family = "Arial")

pb <- ggplot(d, aes(session, latency, group = id, colour = treatment)) +
  geom_line(linewidth = pt_to_lw(0.4), alpha = 0.5) +
  geom_point(aes(shape = treatment), size = 0.9) +
  scale_colour_manual(values = cols, name = NULL) +
  scale_shape_manual(values = shps, name = NULL) +
  scale_y_log10() +
  labs(x = "Session", y = NULL) +
  theme_ms(base_family = "Arial") +
  theme(legend.position = "bottom")

diff_df <- {
  g <- split(ind_means$log_latency, ind_means$treatment)
  tt <- t.test(g[["predator odour"]], g[["control"]])
  data.frame(est = unname(diff(rev(tt$estimate))), lo = tt$conf.int[1], hi = tt$conf.int[2])
}
pc <- ggplot(diff_df, aes(est, "predator odour - control")) +
  geom_vline(xintercept = 0, linewidth = pt_to_lw(0.4), linetype = "dashed") +
  geom_pointrange(aes(xmin = lo, xmax = hi), size = 0.3, linewidth = 0.4) +
  labs(x = "Difference in log latency (95% CI)", y = NULL) +
  theme_ms(base_family = "Arial")

fig <- (pa | pb | pc) + plot_layout(widths = c(1, 1.2, 1.2)) + panel_tags()

fig_files <- save_figure(fig, "example_fig1",
                         width_mm = journal_width("nature", "two"), height_mm = 70,
                         dir = file.path(tempdir(), "figures"), formats = c("pdf", "png", "tiff"), dpi = 300)
fig_files
check_pdf(sub("tiff$", "pdf", fig_files$file[3]), font_range = c(5, 7), stroke_range = c(0.25, 1))
