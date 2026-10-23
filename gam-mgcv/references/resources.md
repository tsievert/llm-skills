# Resources for GAMs in R

## Contents
- Gavin Simpson (check first)
- mgcv documentation
- Tutorials, courses, papers
- Related packages
- When to look things up online

## Gavin Simpson (check first)

Gavin L. Simpson (Aarhus University) is the author of gratia and publishes tutorials, course materials and related packages. When a task involves gratia, plotting GAMs, posterior simulation, difference smooths, derivatives, or an unusual smooth, look here before relying on memory.

- gratia site, reference index, articles, changelog: https://gavinsimpson.github.io/gratia/
  - Articles worth reading: model checking (distributions, uncertainty, dependence), prediction comparisons and rates of change, smooth effects/interactions/surfaces, variance components, data slices, posterior simulation and the sampling migration guide, spatial smooths, shape-constrained models, glmmTMB and sdmTMB support.
  - Changelog: https://gavinsimpson.github.io/gratia/news/index.html (read before using older code; sampling arguments, `draw()` colour arguments and parametric-term defaults have changed).
- gratia repo and issues: https://github.com/gavinsimpson/gratia
- Blog (From the bottom of the heap): https://fromthebottomoftheheap.net/ . Posts include random effects in GAMs with mgcv, extrapolating with B splines, gratia release notes, and a 2026 post on GAMs in livestock animal science.
- GitHub profile: https://github.com/gavinsimpson . Relevant repos seen in October 2026: `gratia`, `physalia-gam-course` (course materials), `au-viborg-gam-course`, `naboer` (neighbourhoods for mgcv's neighbourhood cross-validation, NCV), `palaeopen-sofia-2026` (training materials), `gams-in-animal-science-manuscript`. Re-list the profile for newer repositories.
- Introductory GAM talks and course materials are linked from the physalia repo and from https://github.com/eco4cast/Statistical-Methods-Seminar-Series (folder `simpson-gams`).
- Paper: Simpson (2018), Modelling palaeoecological time series using generalised additive models.

## mgcv documentation

- Help pages: `?gam`, `?gam.models`, `?smooth.terms`, `?choose.k`, `?gam.check`, `?k.check`, `?concurvity`, `?random.effects`, `?family.mgcv`, `?bam`, `?mgcv.FAQ`, `?predict.gam`.
- Index: https://stat.ethz.ch/R-manual/R-devel/library/mgcv/html/00Index.html
- Book: Wood, S.N. Generalized Additive Models: An Introduction with R (2nd ed.), the reference for theory and mgcv.

## Tutorials, courses, papers

- Pedersen, Miller, Simpson and Ross (2019), Hierarchical generalized additive models in ecology: an introduction with mgcv, PeerJ 7:e6876, https://peerj.com/articles/6876/ . Code: https://github.com/eric-pedersen/mixed-effect-gams
- Noam Ross, free interactive course: https://noamross.github.io/gams-in-r-course/
- Noam Ross, curated list: https://github.com/noamross/gam-resources
- Sóskuthy (2021) GAMMs in linguistics (dynamic data); Dave Miller's note on Bayesian views of GAMs (both in Ross's list).

## Related packages

| Package | Use |
|---|---|
| gratia | ggplot2 plots, diagnostics, smooth estimates, differences, derivatives, posterior simulation |
| gamm4 | GAMMs with lme4 (random slopes, correlated effects) |
| glmmTMB | smooths via `s()`, many families, zero inflation |
| brms | fully Bayesian GAMs with `s()`, `t2()` |
| scam | shape-constrained GAMs (also `mgcv::scasm()`) |
| DHARMa | simulation-based residual checks |
| marginaleffects | predictions, contrasts, slopes on the response scale |
| mgcViz | alternative visualisation and checks |

## When to look things up online

- gratia function not found, argument unused, or deprecation warning: check the changelog and reference index above.
- Unusual family, smooth, or spatial question: search Simpson's blog and the gratia articles, then the mgcv help.
- Package versions matter: confirm installed versions before suggesting syntax.
