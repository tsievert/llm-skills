# Section checks and nudges

Each nudge is a question tied to a quote, not a verdict. Basis: peer-reviewed writing series (J Clin Epidemiol,
parts II to VII), ICMJE, ecology society and university guides; sources and gaps are in
`research/manuscript-writing-coach-ledger.md` (sections 3, 9 to 11). Most prevalence figures in that research come
from clinical trial reports, so do not quote them as facts about ecology.

## Contents

- Nudge format
- Title
- Abstract
- Introduction
- Methods
- Results
- Discussion
- Tables and figures
- Claim strength
- Reference-needed spots
- Order of nudges

## Nudge format

1. Quote (with line number for text files).
2. Pattern ("the abstract reports a result the Results section does not").
3. Question ("which analysis produced this number?").
4. Optional example, only if the user's facts allow it: "Example (your facts may differ): ...".

## Title

- Does it say what was studied and in what system, without whimsy? Key terms early.
- Does it reflect what the paper shows, not more? Ask for two or three alternative titles from the user, not from you.
- For ecology, adapt the clinical "SPICED" idea (my adaptation): system or species, setting, condition, outcome,
  design. Offer it as a prompt only.
- Re-check title and abstract after every revision of the body.

## Abstract

- Written last; stands alone (no citations, no figure references, no abbreviations without definition).
- Same primary outcome, numbers and direction as the body; conclusion no stronger than the body; negative results not
  dropped; nothing in it that the body lacks. Run the number script first.
- Results are its core: estimates with intervals rather than P alone; sample size next to percentages.
- Does the one-sentence key message appear in title, abstract and Discussion?

## Introduction

- Funnel: broad context, what is known, the gap, the question. Not a literature review.
- Rough length: about 10 to 15% of the words (read-only word count is possible); a prompt, not a rule.
- Does the last paragraph state the question or hypothesis and briefly what was done?
- Will the Discussion answer that question in matching words?
- Where a claim is about other work, flag "source?" (see reference-needed rules).

## Methods

- Could a skilled reader reproduce the study from this text? Species, system, sampling, design, measurements,
  software and versions, statistical models.
- Which analyses were planned (a priori) and which exploratory? Is that stated?
- No results in Methods (numbers recruited, outcomes). Every method has a result later, and every result has a
  method: cross-check the two sections.
- Animal work: ethics approval, permits and guidelines in the journal's expected place (see reporting-and-ethics).
- Long protocols can go to a supplement if the journal allows it.

## Results

- No interpretation; past tense; findings in the order of the Methods and of the questions at the end of the
  Introduction. Primary analyses first, then secondary, then unexpected findings.
- Estimates with intervals, not P values alone; effect sizes where the journal asks. Numbers and models belong to
  `stats-reporting-and-review`, `mixed-models-glmm` and `gam-interpretation`; this skill asks only whether the text
  reports them.
- Text highlights what the tables and figures show, without repeating them.
- Same group names in text, tables and figures.

## Discussion

- Opens with the main findings answering the Introduction's question, in the same words.
- Then comparison with other work, strengths and limitations stated frankly, implications, take-home message.
- No new results; every claim grounded in a reported result; not a backwards Introduction or a literature review.
- Limitations: which ones could change the conclusion, and are they in the text?
- Does it "sell" further studies instead of saying what this one shows?

## Tables and figures

- Decide early which finding goes in which table or figure; the title says what is shown; self-explanatory captions.
- Legible in grey scale. Format, size and export belong to `manuscript-figures-ggplot`.
- Extra material to a supplement where the journal allows.

## Claim strength

Ask, per quote: does the design support this verb? Causal wording ("drives", "leads to") for correlational or
observational data, unhedged generalisation beyond the sampled species or setting, and an abstract stronger than the
body are the usual cases. The reverse also matters: stacked hedges that make the contribution unreadable. Peer review
changes hedging little, but it improves how limitations are reported, so ask about limitations. Hedge lists are a
prompt generator; only the user knows the design.

## Reference-needed spots

Ask "which source supports this?" for: statements about other studies' findings; numbers that come from other work;
causal or general claims ("is known to", "previous work shows", "widely used"); tools, software, species identities or
methods introduced without a source. Do not flag textbook-level background. Never propose a source. This is a
transparent rule set, not a validated detector.

## Order of nudges

Journal requirements, then claim-evidence fit and the central message, then structure (section roles), then
reference-needed spots, then polish. Offer more on request.
