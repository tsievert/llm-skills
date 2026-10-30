# keypoint-MoSeq: publication, use cases and open questions

## Contents

- [Source and method](#source-and-method)
- [Use cases found in citing papers](#use-cases-found-in-citing-papers)
- [Species beyond the mouse](#species-beyond-the-mouse)
- [Kappa and keypoint choices in published studies](#kappa-and-keypoint-choices-in-published-studies)
- [Comparisons with other tools](#comparisons-with-other-tools)
- [Cautions when reading the literature](#cautions-when-reading-the-literature)
- [Open questions](#open-questions)

Gathered 2026-10-29 with OpenAlex (works citing the paper and its preprint), Europe PMC full texts and open-access PDFs, and the upstream repository. Abstract-level unless stated. Full record, IDs and sources: `research/keypoint-moseq-ledger.md` in the llm-skills repo (rounds 3, 4, 7). Re-run the search (see `openalex`) before relying on counts.

## Source and method

Weinreb et al. 2024, Nature Methods (doi 10.1038/s41592-024-02318-2; OpenAlex W4400580347, 228 citations at the time; bioRxiv preprint W4327861594). The method is a generative model that separates keypoint jitter from behaviour so that syllables are not triggered by tracking noise; it replaces the depth-video input of the earlier MoSeq with keypoints. Validated against accelerometry, neural recordings and human labels, and benchmarked against other clustering tools. Demonstrated in mice (2D and 3D keypoints), rats (published 3D motion capture, including a lever-press syllable) and fruit flies (published LEAP keypoints, 100 fps).

There were 264 distinct citing works (2022: 2, 2023: 14, 2024: 49, 2025: 103, 2026: 96). 130 mention "moseq" in the full text; only 15 name MoSeq or syllables in the title or abstract. A full-text mention is mostly a citation, not use.

## Use cases found in citing papers

| Area | Examples (OpenAlex IDs) |
|---|---|
| Drug and treatment response | L-DOPA in Parkinsonian mice (W4412727576); THC (W4414581453); trihexyphenidyl in a dystonia model (W4413380326); Huntington model (W7211903820); compound discrimination across contexts (W7170964837) |
| Disease models | Shank3B and other genetic models (W7164179139, W4396812056); Parkinsonian mice and vestibular stimulation (W7172424495) |
| Injury and recovery | spinal cord injury (W4388211385 uses depth MoSeq; W7134134185 keypoint-based) |
| Stress, depression, social context | early life stress (W4413908225); depressive-like behaviour (W7117580436); social context changes 25% of syllables, mostly stationary and undirected (W4415982955) |
| Learning and ageing | second-order conditioning with DLC, kpms and DeepOF (W4413789606); frailty and ageing clocks (W7140377619); open-field entropy and spectral metrics (W7130817800) |
| Brain-behaviour | striatal lesions and recordings (W4387669747); arousal and movement transitions (W4416591260); behaviour alignment with imaging (W4387896146) |

Typical workflow: DLC or SLEAP tracking, kpms syllables, group comparison of usage and transitions, then relation to neural data or an intervention. Pose-defined closed-loop stimulation also appears.

## Species beyond the mouse

Documented use is limited to the paper itself (rat, fruit fly). Of 14 citing works on other species or fields that were screened or read (infants, zebrafish, flies, macaques, marmosets, human activity recognition, cattle video analytics), **none was confirmed to apply kpms to its own data**: most cite it or use their own state-space or classifier models. Four had no reachable open text (marmoset Current Biology paper, killifish, a cattle analytics preprint, zebrafish social-state preprint) and their abstracts do not name kpms. A title/abstract search of 2024-26 found 15 works naming kpms, all mouse neuroscience except benchmarks and datasets. So for any other species the skill's guidance is a set of checks (see "Species and frame-rate checks" in `SKILL.md`), not a verified recipe.

## Kappa and keypoint choices in published studies

| Study | Kappa and model choice | Keypoints |
|---|---|---|
| Parkinsonian mice (eNeuro 2025) | Kappa scan; chose the model whose syllable duration matched about 400 ms (12 frames at 30 fps) and whose grid movies an experienced observer found recognisable | not recorded here |
| Social context (Frontiers 2025, kpms 0.4.1) | Kappa chosen iteratively so the median syllable length was 10 frames (about 400 ms) | 10 of 12 SLEAP points, tail excluded |
| Tool benchmark (Patterns 2025) | kappa 1e-6, median motif 520 ms; states that kappa changes number of clusters and median duration | not recorded here |
| Second-order conditioning (Cell Rep Methods 2025) | kappa 1e10 and 1e4 (two models), nine latent dimensions (90% variance) | tail excluded for low reliability |

Lessons: kappa is chosen by target duration, not by a metric; the values span many orders of magnitude, so never reuse one; the rodent target is about 400 ms; kpms versions, latent dimension and seeds were usually not reported (the provenance step in `SKILL.md` exists for this).

## Comparisons with other tools

A 2025 benchmark (Patterns, W4409654348) compared B-SOiD, BFA, VAME and kpms on 10-minute mouse recordings with manual labels from three experts. Reported there: kpms and BFA gave longer motifs (median 0.72 and 0.68 s) than B-SOiD and VAME (0.44 and 0.46 s), and the authors credit kpms with tunable timescale through kappa, noise handling and a location-aware mode; B-SOiD was the most consistent method at the cost of resolution. Other works that include kpms among compared methods: DeepOF (W4380368899), an action-segmentation comparison (W4401413035), and the toolbox papers OpenLabCluster, TASC and GESTURE. When a user asks "kpms or B-SOiD/VAME?", the reasons that follow from this are: kpms for unsupervised sub-second modules where jitter is a concern and the timescale should be controllable; supervised or hand-labelled approaches when specific named behaviours are the endpoint. This skill does not cover the other tools.

## Cautions when reading the literature

- "MoSeq" may mean depth-camera MoSeq. Check for depth cameras, `moseq2-pca` or Kinect.
- A citation is not use: do not cite a paper as an application of kpms without reading its methods.
- Reporting is thin (versions, latent dimension, seeds), so published numbers cannot be reproduced from the text alone.
- Statistics in published kpms studies are mostly rank-based tests with syllables or recordings as units; see `syllable-statistics.md`.

## Open questions

- Use outside neuroscience (ethology, wildlife, agriculture) was not found; different wording ("autoregressive hidden Markov", "switching linear dynamical system") or species-specific tracking terms might find it.
- Closed-access papers (marmoset, killifish, early life stress preprint) were not read.
- The Nature Protocols paper (Motion Sequencing, 2024) was not read; it is probably the depth-camera version.
- Whether kpms 0.8.3 and 0.8.4 changed the calibration widget or fixed the jitter and NaN behaviour in issue #153 is untested.
