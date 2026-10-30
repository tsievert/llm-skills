# Worked statistical templates for behaviour metrics and keypoint-MoSeq usage, on SIMULATED data.
# Run top to bottom (source("scripts/stats_demo.R")); every block is a template to adapt, not a recipe to copy blindly.
# Design simulated: 24 animals (3 groups x 8, both sexes), 2 sessions each = 48 recordings; group effects are built in
# so the models have something to find. Packages: glmmTMB, DHARMa, emmeans, lme4, lmerTest, survival, coxme, mgcv,
# vegan, permute (all CRAN).
#
# This file covers only what is specific to tracking data: time-to-event latency, a GAM time course, keypoint-MoSeq
# syllable usage/transitions/durations. For the generic model-choice logic (Gamma/binomial/beta-binomial/nbinom2,
# offsets, zero inflation, random-slope structure, DHARMa diagnostics, multiplicity, repeatability) see the
# `mixed-models-glmm` skill and its tested `scripts/glmm_templates.R` (same simulation design, same seed family;
# blocks 1-5 there are the distance/ROI/entries/multiplicity templates this file used to duplicate).

suppressPackageStartupMessages({
  library(glmmTMB); library(DHARMa); library(emmeans); library(lmerTest)
  library(survival); library(coxme); library(mgcv); library(vegan); library(permute)
})
set.seed(4817)

# ---- 1. Simulated metadata + metrics (one row per recording) -------------------------------------------------------
animals <- data.frame(animal = sprintf("a%02d", 1:24),
                      group = factor(rep(c("ctrl", "odourA", "odourB"), each = 8), levels = c("ctrl", "odourA", "odourB")),
                      sex = factor(rep(c("F", "M"), 12)))
animals$u_dist <- rnorm(24, 0, 0.2)       # animal-level random effects
animals$u_roi  <- rnorm(24, 0, 0.4)
meta <- do.call(rbind, lapply(1:24, function(i) cbind(animals[rep(i, 2), ], day = factor(c("d1", "d2")))))
meta$recording <- sprintf("%s_%s", meta$animal, meta$day)
meta$duration_s <- 300
meta$frac_missing <- runif(nrow(meta), 0, 0.05)

eff_g <- c(ctrl = 0, odourA = -0.25, odourB = 0)       # odourA lowers distance
meta$distance <- rgamma(nrow(meta), shape = 20,
                        rate = 20 / (600 * exp(eff_g[as.character(meta$group)] + meta$u_dist - 0.1 * (meta$day == "d2"))))
meta$n_valid <- round(meta$duration_s * 30 * (1 - meta$frac_missing))
p_roi <- plogis(-1.5 + c(ctrl = 0, odourA = -0.6, odourB = 0.1)[as.character(meta$group)] + meta$u_roi)
meta$n_roi <- rbinom(nrow(meta), meta$n_valid, rbeta(nrow(meta), p_roi * 30, (1 - p_roi) * 30))  # beta-binomial-ish
meta$entries <- rnbinom(nrow(meta), mu = 0.05 * meta$duration_s * exp(c(0, -0.4, 0)[as.integer(meta$group)] + meta$u_roi / 2), size = 5)
lat <- rexp(nrow(meta), rate = exp(-4.2 + c(0, -0.5, 0)[as.integer(meta$group)] + meta$u_roi / 2))
meta$event <- as.integer(lat < meta$duration_s)       # 0 = never entered: censored at session length
meta$latency_s <- pmin(lat, meta$duration_s)
# meta$distance, meta$n_roi/n_valid, meta$entries are simulated here only because the time-course and kpms
# blocks below reuse the same animal/day structure; fit Gamma/binomial/nbinom2 models on them with
# `mixed-models-glmm/scripts/glmm_templates.R`, not duplicated here.

# ---- 2. Latency to first entry: time-to-event with censoring (never entered = censored at session length) -----------
m_lat <- coxme(Surv(latency_s, event) ~ group + sex + (1 | animal), data = meta)
print(summary(m_lat)$coefficients |> round(3))                  # log hazard ratios; exp() for hazard ratios

# ---- 3. Time courses: binned values as a smooth in time with animal/recording random effects ------------------------
bins <- do.call(rbind, lapply(seq_len(nrow(meta)), function(i) {
  data.frame(recording = meta$recording[i], animal = meta$animal[i], group = meta$group[i], minute = 0:9,
             dist_bin = rgamma(10, shape = 10, rate = 10 / (60 * exp(eff_g[as.character(meta$group[i])] * (0:9) / 9 + meta$u_dist[i] - 0.03 * (0:9)))))
}))
bins$recording <- factor(bins$recording); bins$animal <- factor(bins$animal)
g_bin <- bam(dist_bin ~ group + s(minute, k = 6) + s(minute, by = group, k = 6, m = 1) + s(animal, bs = "re") + s(recording, bs = "re"),
             family = Gamma(link = "log"), data = bins, method = "fREML", discrete = TRUE)
print(round(summary(g_bin)$s.table, 3))
# interpretation and plotting of GAMs: see the gam-mgcv / gam-interpretation skills

# ---- 4. keypoint-MoSeq usage: simulate bout counts per syllable ------------------------------------------------------
n_syll <- 12
base <- rnorm(n_syll, 0, 1)
eff_s <- matrix(0, 3, n_syll, dimnames = list(levels(meta$group), NULL)); eff_s["odourA", 3] <- 1.0; eff_s["odourA", 5] <- -1.0
usage <- do.call(rbind, lapply(seq_len(nrow(meta)), function(i) {
  eta <- base + eff_s[as.character(meta$group[i]), ] + animals$u_roi[match(meta$animal[i], animals$animal)] * rnorm(n_syll, 0.5, 0.2) + rnorm(n_syll, 0, 0.3)
  pr <- exp(eta) / sum(exp(eta))
  n <- as.vector(rmultinom(1, 400, pr))                             # 400 bouts per recording
  data.frame(recording = meta$recording[i], syllable = seq_len(n_syll) - 1L, n_bouts = n)
}))
usage <- merge(usage, meta[, c("recording", "animal", "group", "sex", "day")], by = "recording")
usage$total <- ave(usage$n_bouts, usage$recording, FUN = sum)
usage$syllable <- factor(usage$syllable)

# 4a. one model per syllable (count with exposure offset), then adjust over syllables
fit_syllable_demo <- function(d) {
  m <- glmmTMB(n_bouts ~ group + day + sex + offset(log(total)) + (1 | animal), family = nbinom2, data = d)
  p <- unname(anova(update(m, . ~ . - group), m)$`Pr(>Chisq)`[2])          # overall group effect for this syllable
  ct <- as.data.frame(contrast(emmeans(m, ~ group), "trt.vs.ctrl", type = "response"))   # rate ratios vs control
  data.frame(syllable = d$syllable[1], lrt_p = p, ct[, c("contrast", "ratio", "SE")])
}
res <- do.call(rbind, lapply(split(usage, usage$syllable), fit_syllable_demo))
sp <- unique(res[, c("syllable", "lrt_p")])      # adjust over syllables, not over contrast rows
sp$p_adj <- p.adjust(sp$lrt_p, "BH")
res <- merge(res, sp[, c("syllable", "p_adj")], by = "syllable")
print(subset(res, p_adj < 0.1) |> transform(ratio = round(ratio, 2), lrt_p = signif(lrt_p, 2), p_adj = signif(p_adj, 2)))

# 4b. whole repertoire: PERMANOVA on Hellinger-transformed shares, permuting WHOLE ANIMALS (group is an animal-level factor)
wide <- reshape(usage[, c("recording", "syllable", "n_bouts")], idvar = "recording", timevar = "syllable", direction = "wide")
rownames(wide) <- wide$recording; wide$recording <- NULL
shares <- sweep(as.matrix(wide), 1, rowSums(wide), "/")
md <- meta[match(rownames(shares), meta$recording), ]
ctrl <- how(plots = Plots(strata = md$animal, type = "free"), within = Within(type = "none"), nperm = 999)
ad <- adonis2(sqrt(shares) ~ group, data = md, method = "euclidean", permutations = ctrl)   # sqrt = Hellinger on shares
print(ad)
print(anova(betadisper(dist(sqrt(shares)), md$group)))      # check dispersion differences; PERMANOVA is sensitive to them

# 4c. low-dimensional summary: centred log-ratio (pseudocount is a choice, report it), PCA, mixed model on scores
clr <- log(shares * 400 + 0.5); clr <- clr - rowMeans(clr)
pc <- prcomp(clr)
md$PC1 <- pc$x[, 1]; md$PC2 <- pc$x[, 2]
print(anova(lmer(PC1 ~ group * day + sex + (1 | animal), data = md)))

# ---- 5. Bout durations (dwell time): bout-level mixed model with nested random effects --------------------------------
bouts <- do.call(rbind, lapply(seq_len(nrow(meta)), function(i) {
  n <- rpois(1, 30)
  data.frame(recording = meta$recording[i], animal = meta$animal[i], group = meta$group[i],
             dur_s = rlnorm(n, log(0.5) + 0.3 * (meta$group[i] == "odourB") + animals$u_dist[match(meta$animal[i], animals$animal)], 0.5))
}))
m_dur <- lmer(log(dur_s) ~ group + (1 | animal / recording), data = bouts)   # recording nested in animal
print(round(summary(m_dur)$coefficients, 3))
print(pairs(emmeans(m_dur, ~ group), type = "response"))       # ratios of geometric-mean bout duration

# ---- 6. One transition: binomial GLMM, successes = transitions to B out of all exits from A -----------------------------
tr <- do.call(rbind, lapply(seq_len(nrow(meta)), function(i) {
  from_n <- rpois(1, 40); p <- plogis(-0.5 + 0.8 * (meta$group[i] == "odourA"))
  data.frame(recording = meta$recording[i], animal = meta$animal[i], group = meta$group[i], from_total = from_n, to_B = rbinom(1, from_n, p))
}))
m_tr <- glmmTMB(cbind(to_B, from_total - to_B) ~ group + (1 | animal), family = binomial, data = tr)
print(pairs(emmeans(m_tr, ~ group), type = "response"))
