# Tested templates for mixed models / GLMMs on SIMULATED repeated-measures behaviour data.
# Blocks 1-5 are taken from animal-behaviour-tracking-analysis/scripts/stats_demo.R (same simulation design).
# Blocks 6-9 are additions: zero inflation, dispersion model, random slopes, singular fits, repeatability.
# Run: source("scripts/glmm_templates.R", local = new.env()). Each block is a template to adapt, not a recipe.
# Packages (CRAN): glmmTMB, DHARMa, emmeans, lme4, lmerTest, performance.

suppressPackageStartupMessages({
  library(glmmTMB); library(DHARMa); library(emmeans); library(lme4); library(lmerTest); library(performance)
})
set.seed(2931)

# ---- 1. Simulated data: 24 animals (3 groups x 8, both sexes), 2 sessions (d1, d2) -------------------------------------
animals <- data.frame(animal = sprintf("a%02d", 1:24),
                      group = factor(rep(c("ctrl", "odourA", "odourB"), each = 8), levels = c("ctrl", "odourA", "odourB")),
                      sex = factor(rep(c("F", "M"), 12)))
animals$u_dist <- rnorm(24, 0, 0.2)
animals$u_roi  <- rnorm(24, 0, 0.4)
meta <- do.call(rbind, lapply(1:24, function(i) cbind(animals[rep(i, 2), ], day = factor(c("d1", "d2")))))
meta$duration_s <- 300
meta$n_valid <- round(meta$duration_s * 30 * (1 - runif(nrow(meta), 0, 0.05)))
eff_g <- c(ctrl = 0, odourA = -0.25, odourB = 0)
meta$distance <- rgamma(nrow(meta), shape = 20,
                        rate = 20 / (600 * exp(eff_g[as.character(meta$group)] + meta$u_dist - 0.1 * (meta$day == "d2"))))
p_roi <- plogis(-1.5 + c(ctrl = 0, odourA = -0.6, odourB = 0.1)[as.character(meta$group)] + meta$u_roi)
meta$n_roi <- rbinom(nrow(meta), meta$n_valid, rbeta(nrow(meta), p_roi * 30, (1 - p_roi) * 30))
meta$entries <- rnbinom(nrow(meta), mu = 0.05 * meta$duration_s * exp(c(0, -0.4, 0)[as.integer(meta$group)] + meta$u_roi / 2), size = 5)

# ---- 2. Continuous positive response: Gamma GLMM (log link) ----------------------------------------------------------
m_dist <- glmmTMB(distance ~ group * day + sex + (1 | animal), family = Gamma(link = "log"), data = meta)
print(testUniformity(simulateResiduals(m_dist), plot = FALSE)$p.value)       # DHARMa residual check; also plot() it
print(pairs(emmeans(m_dist, ~ group), type = "response"))                    # ratios with CIs
m_dist0 <- update(m_dist, . ~ . - group - group:day)                         # overall group effect: LRT, ML fits
print(anova(m_dist0, m_dist))

# ---- 3. Proportion of frames: binomial GLMM, then beta-binomial if overdispersed ------------------------------------
m_roi <- glmmTMB(cbind(n_roi, n_valid - n_roi) ~ group * day + (1 | animal), family = binomial, data = meta)
print(testDispersion(simulateResiduals(m_roi), plot = FALSE)$p.value)
m_roi_bb <- update(m_roi, family = betabinomial)
print(AIC(m_roi, m_roi_bb))
print(pairs(emmeans(m_roi_bb, ~ group), type = "response"))                  # odds ratios

# ---- 4. Counts with exposure: negative binomial + offset -------------------------------------------------------------
m_ent <- glmmTMB(entries ~ group * day + offset(log(duration_s)) + (1 | animal), family = nbinom2, data = meta)
print(pairs(emmeans(m_ent, ~ group, offset = 0), type = "response"))         # rate ratios per unit exposure

# ---- 5. Several endpoints: adjust the family of tests ----------------------------------------------------------------
pvals <- c(distance = anova(m_dist0, m_dist)$`Pr(>Chisq)`[2],
           roi_share = anova(update(m_roi_bb, . ~ . - group - group:day), m_roi_bb)$`Pr(>Chisq)`[2],
           entries = anova(update(m_ent, . ~ . - group - group:day), m_ent)$`Pr(>Chisq)`[2])
print(round(rbind(raw = pvals, holm = p.adjust(pvals, "holm")), 4))

# ---- 6. Zero-inflated counts (e.g. freezing bouts per trial, many structural zeros) -----------------------------------
# 12 trials per animal so random slopes in block 8 are estimable
trials <- do.call(rbind, lapply(seq_len(nrow(animals)), function(i) {
  data.frame(animal = animals$animal[i], group = animals$group[i], trial = 1:12)
}))
trials$trial_c <- trials$trial - 6.5
a_int <- rnorm(24, 0, 0.4); a_slp <- rnorm(24, 0, 0.08)                      # animal intercepts and trial slopes
ai <- match(trials$animal, animals$animal)
mu <- exp(1.2 + c(0, -0.5, 0)[as.integer(trials$group)] + a_int[ai] + (-0.05 + a_slp[ai]) * trials$trial_c)
zero <- rbinom(nrow(trials), 1, plogis(-1 + 0.9 * (trials$group == "odourA")))   # structural zeros more likely in odourA
trials$freeze_n <- ifelse(zero == 1, 0L, rnbinom(nrow(trials), mu = mu, size = 4))
trials$latency <- rgamma(nrow(trials), shape = 8, rate = 8 / exp(2 + a_int[ai] + 0.1 * trials$trial_c))

m_nb  <- glmmTMB(freeze_n ~ group * trial_c + (1 | animal), family = nbinom2, data = trials)
m_zi  <- update(m_nb, ziformula = ~ group)                                   # zero-inflation part may depend on predictors
sim_nb <- simulateResiduals(m_nb)
print(testZeroInflation(sim_nb, plot = FALSE)$p.value)                       # significant: more zeros than the NB expects
print(AIC(m_nb, m_zi))
print(summary(m_zi)$coefficients$zi |> round(3))                             # logit scale: P(structural zero)
print(pairs(emmeans(m_zi, ~ group, component = "cond"), type = "response"))  # count part, given not structural zero
print(pairs(emmeans(m_zi, ~ group, component = "response")))                 # overall expected count (cond x (1 - zi))
print(pairs(emmeans(m_zi, ~ group, component = "zi"), type = "response"))    # odds ratios for structural zeros

# ---- 7. Dispersion model: variance differs between groups ------------------------------------------------------------
m_gam  <- glmmTMB(latency ~ group * trial_c + (1 | animal), family = Gamma(link = "log"), data = trials)
m_gam_d <- update(m_gam, dispformula = ~ group)
print(AIC(m_gam, m_gam_d))
# Residual spread per group (Levene-like test on scaled residuals). DHARMa::testCategorical(plot = FALSE) errored
# in DHARMa 0.5.0 ("plot.new has not been called yet"), so use plain base R here.
print(anova(lm(abs(residuals(simulateResiduals(m_gam)) - 0.5) ~ group, data = trials)))
# plotResiduals(simulateResiduals(m_gam), trials$group) draws the same comparison

# ---- 8. Random intercepts vs slopes; singular fits -------------------------------------------------------------------
m_ri <- glmmTMB(freeze_n ~ group * trial_c + (1 | animal),            family = nbinom2, data = trials)
m_rs <- glmmTMB(freeze_n ~ group * trial_c + (1 + trial_c | animal),  family = nbinom2, data = trials)
print(anova(m_ri, m_rs))                                                     # LRT on variance components is conservative
print(VarCorr(m_rs))
print(check_singularity(m_rs))                                               # TRUE = boundary fit: simplify, do not ignore
m_rs0 <- update(m_rs, . ~ . - (1 + trial_c | animal) + (1 | animal) + (0 + trial_c | animal))   # uncorrelated slope
print(AIC(m_ri, m_rs, m_rs0))
# Gaussian equivalent with Satterthwaite df (lmerTest): fine for approx. normal responses
m_lm <- lmer(log(latency) ~ group * trial_c + (1 + trial_c | animal), data = trials)
print(anova(m_lm))                                                           # Type III, Satterthwaite

# ---- 9. Repeatability (ICC) and variance partition -------------------------------------------------------------------
print(icc(m_dist))                                                           # adjusted and unadjusted ICC on link scale
print(icc(m_dist, by_group = FALSE)$ICC_adjusted)
print(r2(m_ri))                                                              # marginal (fixed) and conditional R2

# ---- 9b. Repeatability with bootstrap CIs (rptR 0.9.23, CRAN). Use nboot >= 1000 for real work; 200 here for speed ----------
# Gaussian on log scale; Poisson datatype adds an observation-level term internally and reports link- and original-scale R.
# rptR prints a progress bar (noisy in logs). Bootstrap fits can warn about singular fits when the among-animal variance is small.
if (requireNamespace("rptR", quietly = TRUE)) {
  tr2 <- trials; tr2$log_lat <- log(tr2$latency)
  print(rptR::rpt(log_lat ~ group + (1 | animal), grname = "animal", data = tr2, datatype = "Gaussian", nboot = 200, npermut = 0))
  print(rptR::rpt(freeze_n ~ group + (1 | animal), grname = "animal", data = tr2, datatype = "Poisson", link = "log", nboot = 100, npermut = 0))
}

# ---- 10. Reporting helpers --------------------------------------------------------------------------------------------
print(confint(m_dist)[1:3, ])                                                # Wald CIs; profile = confint(m, method = "profile")
print(model_performance(m_roi_bb))
