# Reporting guidelines, ethics statement, AI disclosure

Pointers and questions only. The skill never quotes item numbers or full checklists (versions change, and some pages
could not be read in full). Name the guideline, tell the user to download the current version from its own site or
the EQUATOR library, and check whether the journal requires it. Sources: ledger sections 8, 10, 11, 12.

## Contents

- Guideline pointers
- When nothing matches
- Ethics statement for animal studies
- Questions for tracking-based behaviour studies
- Supervised machine learning (DOME)
- AI use and disclosure

## Guideline pointers

| Study type | Pointer | Note |
|---|---|---|
| Live-animal experiments (incl. behaviour) | ARRIVE 2.0 (reporting), PREPARE (planning), ASAB/ABS ethics guidelines | Animal Behaviour and Animal Behavior and Cognition name these; invertebrate rules differ by journal |
| Meta-analysis in ecology and evolution | PRISMA-EcoEvo | General PRISMA 2020 for systematic reviews; ROSES for environmental evidence synthesis |
| Transparency in ecology and evolution | TTEE (Tools for Transparency in Ecology and Evolution) | Journal-level levels for data, code, materials, design and analysis; some journals use it in reporting summaries |
| Randomised trials, observational studies | CONSORT 2025, STROBE | Pointers only, outside the usual field; STROBE currency not re-checked |
| Supervised machine learning in biology | DOME | See below |

Journal instructions decide whether a checklist is required and where it goes (supplement, reporting summary).

## When nothing matches

Say so: "no matching reporting standard found; follow the journal's instructions". Do not invent a checklist. No
guideline specific to pose-estimation or tracking-based behaviour studies was found.

## Ethics statement for animal studies

Ask, do not draft: Which committee and approval reference? Which law or permit? Which guidelines does the journal ask
for (ASAB/ABS, ARRIVE)? Does the journal expect a statement for invertebrates? Where in the article does it belong?

## Questions for tracking-based behaviour studies

Derived from reviews of accelerometer classification and rodent pose estimation and from the SLEAP paper; no field
standard exists, so these are prompts. The first four are about reporting; the last four are method choices that sit
with the user and the tracking skills.

- Which software, version and model were used?
- How many labelled frames, from how many animals or videos?
- How was the training/test split made (by individual or by video, not random frames)?
- Is tracking accuracy reported, including identity switches where animals interact?
- Likelihood threshold, interpolation and smoothing choices: stated and justified?
- Calibration from pixels to length: stated?
- Were derived behaviours (freezing, immobility) checked against manual scoring?
- Blinding and randomisation of the trials: stated?

The work itself belongs to `animal-behaviour-tracking-analysis`, `deeplabcut-hpc` and `keypoint-moseq`; the same
validation questions apply to unsupervised syllables.

## Supervised machine learning (DOME)

DOME (Walsh et al. 2021, Nature Methods, doi 10.1038/s41592-021-01205-4) is a question-based reporting framework for
supervised machine learning in biology, organised as data, optimization, model and evaluation, with a summary table for
the supplement. It applies when the paper trains a supervised model, such as a behaviour classifier, not to plain
tracking. Data questions that matter most: where the data came from, how the training and test sets were split and
how overlap between them was prevented, and whether the exact splits are available. DOME is one community framework,
it is long and has been criticised for that, and it is not mandatory unless the journal says so.

## AI use and disclosure

Publisher policies differ and change (checked 2026-11-10 on primary pages): some ask for a declaration even for
language editing, some exempt basic grammar and language polish, one asks for disclosure of AI-generated analysis
code, and placement varies (before the references, Methods, Acknowledgments, figure captions, cover letter). ICMJE
asks for disclosure of AI-assisted technology in the submitted work. The skill therefore carries no policy wording:

- Tell the user once to read the target journal's current policy.
- Say what this coaching did: questions and feedback, no drafted text.
- Never write the declaration unprompted and never say the coaching "does not count".
- AI-generated material is not an acceptable primary source; this is one reason the skill never inserts references.
