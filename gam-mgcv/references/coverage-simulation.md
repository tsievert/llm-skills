# Coverage simulations for GAM bands and standard errors

Contents: when to run one, planning (ADEMP), how many replicates, seeds and parallel runs, driver design, failures, summaries,
what was seen in one project. Planning rules come from Morris, White and Crowther (2019, Stat Med 38:2074-2102,
[10.1002/sim.8086](https://doi.org/10.1002/sim.8086), full text read via Europe PMC). Driver design and the project results are
single reports from one project (mgcv 1.9-5, synthetic data), not reproduced here.

Run one only when the question is "are these bands or SEs too narrow for this design?" (clustered repeated measures, few units,
fixed-sp bootstrap). It is expensive: a Gamma(log) `bam` fit took 2 to 5 minutes, about 70 fits in the report. For bootstrap
max-t bands see [model-comparison.md](model-comparison.md); for the clustered sandwich recipe see
[ncv-and-bam-notes.md](ncv-and-bam-notes.md).

## Plan it with ADEMP (Morris et al. 2019)

| Letter | Write down |
|---|---|
| Aims | The question, for example "does the animal-level bootstrap band cover the true contrast at its nominal level?" |
| Data-generating mechanisms | A generator with a closed-form true curve or contrast, so truth is known without fitting. Vary one factor at a time (units, sessions, noise). |
| Estimands | The curve or contrast being covered, on the response scale you report. |
| Methods | Every band method compared on the same simulated data sets (model `Vp`, cluster-robust, bootstrap at fixed sp). |
| Performance measures | Coverage (pointwise and simultaneous), bias, empirical SD of the estimate, mean model SE over empirical SD, plus the Monte Carlo SE of each. |

## How many replicates

- Monte Carlo SE of a coverage estimate: `sqrt(c * (1 - c) / n_sim)`. Replicates needed for a target SE:
  `n_sim = c * (1 - c) / SE_target^2` (paper: 1,900 for 95% coverage at SE 0.5 percentage points; 10,000 at worst case c = 0.5).
- Arithmetic for expensive fits (computed here): at 95% coverage, 9 replicates give SE about 7 percentage points, 50 give about 3.1,
  100 give about 2.2. With 50 replicates a coverage of 0.93 and 0.95 cannot be told apart.
- Monte Carlo SE of an empirical SD is about `SD / sqrt(2 * (n_sim - 1))`, about 10% at 50 replicates (paper's formula; the 10% is
  computed here). So a model-SE-over-empirical-SD ratio of 0.93 from 50 replicates is within about one Monte Carlo SE of 1 and 0.83
  is about 1.7 away; report the interval, not just the ratio.
- Report the Monte Carlo SE next to every performance number. There is no safe replicate count: the SE is the statement. A 9-replicate pilot in the report looked well calibrated (SE ratio 1.04 to 1.14, pointwise coverage 0.93 to
  0.95); 50 replicates gave ratios 0.83 to 0.93 and coverage 0.86 to 0.94. Use a pilot to time and debug, not to conclude.
- More replicates can be added cheaply if the end state of the random-number generator was stored (below).

## Seeds, states and parallel runs

- Paper's advice: set the seed once at the start (not before every replicate), and store the random-number state at the start of each
  replicate and after the last. A stored state lets you re-run a failed replicate alone and continue the study later.
- Do not parallelise replicates within one data-generating mechanism if they share one seed path; give each shard its own stream.
  In R, `RNGkind("L'Ecuyer-CMRG")` with `parallel::nextRNGStream()` creates independent streams (checked here: consecutive streams
  differ). Save the stream state with each result.
- Same starting seed across design settings makes comparisons between settings paired.

## Driver design (one project, not reproduced)

- Generator and fit in separate scripts from the summary script; the summary reads saved per-replicate files only.
- One result file and one error file per replicate (error text kept per seed), so a killed run resumes by skipping files that exist.
- Budget memory per worker when sharding on one machine (NCV fits can exhaust memory); retry an allocation error once.
- Start with 2 to 3 replicates and checks that the generator's truth is what you meant, then scale up.

## Failed fits

Count failed fits per method and report them with the results (intermittent non-finite NCV score seen once). Compare methods on
the replicates where all converged, and say how many dropped. Morris et al. note that dropping failures evaluates a "converged
only" method; an analyst would try another model, which can itself be the method under study. Treat a nontrivial share of
missing estimates as a reason for tentative conclusions.

## Summaries that separate causes

- Mean model SE over empirical SD below 1 means bands are too narrow; above 1, too wide.
- Bias-eliminated coverage (coverage of the replicate mean instead of the truth) separates bias from SE miscalibration.
- Coverage by tertile of the model SE (paper's example) shows whether wide or narrow intervals are the miscalibrated ones.
- For outcomes starting at zero (cumulative curves) do not summarise relative differences; use absolute differences scaled by the
  range or SD (see ncv-and-bam-notes.md).

## What one project saw (one design; treat as a caution)

Repeated sessions within animals, 50 data sets: `sandwich::vcovCL()` by session was about twice the empirical SD; by animal about
1.14 times with poor simultaneous coverage; a bootstrap by the clustering unit at fixed sp (fREML refit) was best calibrated
(about 0.93). Given the Monte Carlo SE above, treat the ranking as suggestive.
