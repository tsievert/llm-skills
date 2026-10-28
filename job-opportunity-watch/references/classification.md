# Classification, fields and statuses

Contents: fields to record; classes A-E; near-miss; reading eligibility wording; aggregator noise; final statuses; opportunity tracks;
evidence order; fallback defaults; stretch and mismatch method examples; deduplication.

## Fields to verify and record (per opportunity)

Title, employer, country, official page, reference number; opportunity type and whether it is paid;
publication date, deadline, deadline status, vacancy status; workload (FTE), contract duration,
permanence, start date, salary if given; focal species or system, scientific topic, main duties,
methods; mandatory qualifications, language, mobility and eligibility rules; application route;
the evidence (URL of the page that states each decisive fact). Write "not stated" rather than guessing.
Dates as ISO (`YYYY-MM-DD`).

## Classes

| Class | Meaning |
|---|---|
| A | Hard reject: violates a mandatory requirement from the profile |
| B | Conditional eligibility: may fit, needs a clarification (say which) |
| C | Plausible stretch: credible with learnable gaps |
| D | Strong match |
| E | Exceptional match: unusually strong scientific and contract fit |

Assess scientific fit, method fit, eligibility, contract fit, geographic fit, language and strategic value
separately (a short word per dimension is enough). Do not hide a weak dimension in an overall score. The
class is a summary of those dimensions, not a number. Distinguish learnable methods from expertise
required on day one. Keep language as its own dimension rather than folding it into eligibility: a local-
language requirement is often the second blocker after a hard FTE or contract-type rule, and naming it
separately is what makes a near-miss readable.

## Near-miss (one hard rule, otherwise strong)

An item that fails exactly one hard rule (FTE, language, geography, ...) while scoring well on every other
dimension is a near-miss, not a plain rejection: a rare permanent post can be lost to a single dimension
(for example a 100%-FTE rule rejecting an otherwise strong 30-50% post). Record it with `near_miss = TRUE`
and the failing rule in `near_miss_rule` ([stage-s4-classify.md](stage-s4-classify.md)'s "What to write"). The
rule still applies and the item is still rejected; surfacing the near-miss only shows the user what the rule
costs them, so relaxing it stays their decision. Where a stated range would change the outcome (for example
"30-50% by agreement"), record the range rather than collapsing it to one number.

## Reading eligibility wording (do not judge on the headline)

Three user corrections and one audit found the same mistake: a class A / `Irrelevant` or `Rejected` verdict
given from a headline, a field list or a method label instead of the full call text.

- A "priority areas", "especially" or named-fields list is **not an eligibility filter**. If the call also says
  "all fields", "related field" or is a broad institute or cluster call, score topic fit on the profile, not on
  the list. When role type, contract and geography fit, classify at most B with an explicit open question;
  never A / `Irrelevant` on topic alone for an open-field call.
- `Irrelevant` needs the **central duties** to be unrelated to the profile, not just the headline theme.
- A method-boundary rejection (for example wet-lab work) applies only when the work is mandatory for every
  candidate. If the call offers alternative tracks, assess the track that fits the profile.
- An explicit "expired" or "closed" marker on the vacancy page overrides a listed deadline that is still in
  the future (stale aggregator listings do this). Keep the status `Expired` and put the reason in `notes`; the
  summary and report show that note next to the status so it does not look like a data error.
- Rejecting from a mirror text or a form-only page: say the evidence is partial (status `Inaccessible` or a
  note), and do not cite species or duties the page did not show.

After s4, re-open every class A `Irrelevant` row that came from a broad (multi-position, institute or cluster)
call and read its full eligibility wording before closing the stage; a short audit of class A rows found 1 of
11 and 2 of 3 wrongly judged in two cases (reported, one project).

## Aggregator noise

General and field-category aggregators (a national employer-mirror site, a broad academic job board's
category pages) typically add far more noise than signal to the tier-2 queue: most new anchors on a first
save are site furniture (category pages, "post a job", field-count pages) or jobs outside the profile's
groups, and a page being probed `fine` only means it has vacancy-like links, not that they are relevant
([portal-quirks.md](portal-quirks.md), [stage-s1-probe.md](stage-s1-probe.md)). Generic titles ("Research
Position", "Wissenschaftlicher Mitarbeiter", "Curator") that a title-only filter lets through need a page
read to judge; treat opening a handful of plausible tier-2 titles as the cost of using an aggregator, not a
sign that the source is broken. Count one underlying opportunity once even when an aggregator mirrors an
employer's own posting (deduplication, below). Add a field-category aggregator as a link only where it
exposes structured deadlines; for a niche profile, a discipline society board or an employer's own page is
usually higher yield than a broad aggregator's category pages.

## Final statuses (exactly one per opportunity)

`Verified open`, `Probably open`, `Deadline conflict`, `Unresolved`, `Expired`, `Inaccessible`,
`Rejected`, `Irrelevant`, `Network only`, `Funding only`.

- A page being online does not prove the call is open: check deadline and an application route.
- Sources conflict: retain both claims, prefer the stronger source, label the conflict.
- Do not use `Verified open` unless the official employer or funder page shows an open call and a
  deadline in the future (or an open-ended call).
- A candidate reached only through a third-party aggregator/mirror, where the mirror's stated
  "official" link returns a not-found error: before marking it `Inaccessible`, try one fallback —
  search the employer's own careers page (or a site-restricted search for employer + title) for the
  same posting under its native URL. Only fall back to `Inaccessible` if that also turns up nothing;
  note which route was tried in the evidence field.

## Opportunity tracks (report separately)

- **Primary employment:** permanent, tenure-track, fixed-term research, postdoctoral, teaching-research.
- **Fellowship hosts:** record whether funding is secured or only host support is offered; eligibility,
  mobility rules, duration, internal deadline and funder deadline.
- **Supplementary:** consultancy, evaluator rosters, proposal review, monitoring, panels, committees,
  working groups, networks, conferences, awards. Roster registration does not guarantee paid work. Never
  rank unpaid items against salaried employment.

The `track` column in `opportunities.tsv` takes `primary`, `fellowship`, `supplementary`.

## Evidence order

1. Official employer page. 2. Official funder or government portal. 3. Professional society.
4. Established job board. 5. General aggregator. Aggregators are for discovery, not final evidence.

## Fallback defaults (only where the profile is silent)

These mirror a typical early-career academic profile and must not override the user's file:
full-time employment mandatory; contracts of at least one year and preferably two or more; a one-year
postdoc only when the topic is central to the user's core expertise; permanent and tenure-track roles
rank higher; the focal system must be central, not merely mentioned; behaviour must be a biological
question, not just an assay; reject on central duties rather than isolated words.

## Stretch versus mismatch (examples for method judgement)

Possible stretches when secondary: limited GIS, moderate Python development, camera trapping,
time-series or image analysis, machine learning, collaborator-supplied telemetry, collaborator-led
physiological work. Likely mismatches when central: advanced electrophysiology, optogenetics, molecular
wet-lab leadership, core GC-MS operation, immediate advanced Bayesian spatial modelling, plant-insect
chemical ecology, routine habitat surveys, regular hunting. The profile's own method boundaries win over
this list.

## Deduplication

One underlying opportunity is one ledger row (employer, title, reference number, project, location,
deadline). Keep the other links as evidence in `source_ids` and `notes`.

## Columns of `state/opportunities.tsv`

`opp_id` (short stable id you choose, e.g. employer-slug plus reference), `url`, `source_ids`, `employer`,
`title`, `country`, `ref_no`, `track`, `contract`, `deadline`, `class`, `status`, `evidence`,
`first_seen`, `last_seen`, `notes`. `jw_opp_upsert()` fills the seen dates and keeps non-empty old values
when a new row leaves a field blank.
