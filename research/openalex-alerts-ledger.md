# OpenAlex alerts review ledger

Skill: `openalex`. Topic: auditing the user's weekly saved-search alerts (false positives, coverage gaps, repository
exclusion). Source of all facts: live OpenAlex API (keyed, 2026-11-26) unless noted. No personal data beyond alert names.

## Requirements

| # | Requirement | Date |
|---|---|---|
| 1 | Review weekly alerts with the openalex skill: find false positives, test extra keywords for missing coverage | 2026-11-26 |
| 2 | Exclude data repositories (Zenodo, Figshare, Dryad etc.) | 2026-11-26 |
| 3 | Keep `fear` in the predator alert, but cut noise; human studies are relevant when there is an odour aspect | 2026-11-26 |
| 4 | Apply the repository and topic exclusions to the three topic alerts | 2026-11-26 |
| 5 | Add the taxon name change (Myodes vs Clethrionomys) as a test for the skill | 2026-11-26 |

## Sources

| Source | Status |
|---|---|
| `GET https://api.openalex.org/saved-searches` (lists alerts; `api_url` holds the filter) | read |
| https://help.openalex.org/api/alerts.md (`PATCH /saved-searches/{id}`, body fields `name`, `description`, `url`, `alert`) | read |
| https://developers.openalex.org/llms.txt (index only) | meta |

## Facts

- Alerts listed: 4 (3 topic alerts, 1 citations-to-own-works; the last was not touched). All weekly.
- PATCH with a new `url` (full `https://api.openalex.org/works?filter=...`) kept the weekly alert and next-check date
  (verified by re-listing). The stored `api_url` is re-encoded and still runs.
- `httr2::req_url_query(filter = ...)` re-encodes `+` and silently returned 0 hits; build the URL string by hand.
- Wildcards inside quoted phrases (`"bank vole*"`) return HTTP 400; read `resp_body_string(e$resp)` for the message.
- Volume in the 60 days before 2026-11-26 (old filter): 21 / 12 / 411 matches; 13 / 4 / 164 were repository records
  (Zenodo 47 in the third alert, then bioRxiv, Research Square, Figshare, OSF, DRYAD, GBIF).
- Repository exclusion used: `type:!dataset|supplementary-materials|study-registration|peer-review|other` plus
  `primary_location.source.id:!` Zenodo S4306400562, Figshare S4377196282, DRYAD S7407051161, GBIF S4398183272,
  Harvard Dataverse S4377196806, OSF S7407050956. bioRxiv and other preprint servers kept on purpose.
- Noise in the predator alert came from the `(... cue OR cues OR chemical* OR secretion*) AND (predat* OR fear OR alarm)`
  branch: `fear` + `cue` matched human fear conditioning, fear of missing out, VR, marketing, reinforcement learning.
  Fix: in the fear/alarm branch require an explicit odour/pheromone term (`vomero* VNO odor* odour* smell* olfac* scent*
  chemosignal* pheromone*`); keep the generic cue/chemical terms only with `predat*`. 61 of 328 hits removed, nearly all
  noise; fear stays in the query. Human and lab studies with an odour term still match.
- Topic exclusions tested after that fix: removing T10448 (memory and neural mechanisms) and T10242 (PTSD) would also
  drop relevant items (a predator-based PTSD stress model, lab predator-threat studies), so they were **not** applied.
  Applied: T10853, T11536, T10883, T10462, T10648, T10315, T10042 (reinforcement learning, VR, consumer, ethics/AI,
  decision-making, approach-avoidance psychology). Dropped hits were noise.
- Result, 60-day counts old -> new: vole alert 21 -> 10, semiochemical alert 12 -> 10, predator alert 411 -> 257.
  257 includes repository removal (-83) and the odour fix and topic exclusions (-71 more).
- Vole alert: added `Clethrionomys` (OpenAlex now labels the bank vole *Clethrionomys glareolus*; the alert only had
  `Myodes`). In 12 months 118 records say "bank vole"/*Clethrionomys glareolus*, 88 were not in any alert (mostly
  virology, genomics, morphology; those need no behaviour term, so they remain out unless the user asks for them).
- Coverage gaps tested (12 months, repositories excluded, ids compared with the union of the old alert hits):

  | Candidate | Total | Not in alerts |
  |---|---|---|
  | vole/lemming population cycles (terms in the skill's query-refinement note) | 22 | 21 |
  | rodent predator odour / alarm cue terms | 49 | 5 |
  | rodent landscape of fear / predation risk / antipredator | 40 | 17 of first 100 |
  | rodent prenatal/transgenerational with predation | 8 | 2 |
  | "alarm pheromone" without a taxon restriction | 44 | 39 (mostly bees, ants, aphids; skipped) |

## Open research items

- Create a vole population-cycle alert (not created; user did not ask in this round).
- Decide whether a bank-vole-any-topic alert is wanted (about 10 per month, mostly virology).
- Re-measure alert volume after the first weekly email on 2026-12-02 and read the first batch for remaining noise.
- Mammal restriction of the wildlife/aquatic antipredator hits in the predator alert (fish, mollusc, primate) not tested.

## Old filters (for rollback)

Old predator alert positive clause: `( ( (behavior* OR behaviour*) AND (vomero* OR VNO OR odor* OR odour* OR smell* OR olfac* OR scent* OR chemosignal* OR cue OR cues OR chemical* OR secretion*) AND (predat* OR fear OR alarm) ) OR ( (behavior* OR behaviour* OR cue* OR odor* OR odour* OR smell* OR olfac* OR scent* OR chemosignal*) AND predat* ) )`.
Old topic exclusions (predator alert) were T10482|T10565|T10089|T10100|T10332|T10135|T11004|T11387|T11656|T10702; the new
ones are appended to these. Vole alert old taxon clause: `vole OR voles OR Myodes OR Microtus`. Semiochemical alert: only
the repository exclusion was added.

## Log

- 2026-11-26: listed alerts, profiled last 60 days by source type/type/topic, tested 10 candidate keywords, drafted
  and compared new filters, applied them with PATCH to the three topic alerts, verified alert frequency retained.
  Added `openalex/evals/evals.json` (taxon-name test) and notes to `openalex/references/query-refinement.md`.
