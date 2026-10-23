# Classification, fields and statuses

Contents: fields to record; classes A-E; final statuses; opportunity tracks; evidence order; fallback
defaults; stretch and mismatch method examples; deduplication.

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

Assess scientific fit, method fit, eligibility, contract fit, geographic fit and strategic value
separately (a short word per dimension is enough). Do not hide a weak dimension in an overall score. The
class is a summary of those dimensions, not a number. Distinguish learnable methods from expertise
required on day one.

## Final statuses (exactly one per opportunity)

`Verified open`, `Probably open`, `Deadline conflict`, `Unresolved`, `Expired`, `Inaccessible`,
`Rejected`, `Irrelevant`, `Network only`, `Funding only`.

- A page being online does not prove the call is open: check deadline and an application route.
- Sources conflict: retain both claims, prefer the stronger source, label the conflict.
- Do not use `Verified open` unless the official employer or funder page shows an open call and a
  deadline in the future (or an open-ended call).

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
