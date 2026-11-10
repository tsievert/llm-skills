# Research: `manuscript-writing-coach` (planned skill; research round 1, 2026-11-10)

Status: research only, no skill written. Source statuses: read (page/excerpt read), search (result snippet only),
meta (commentary), skipped (project source rules, see `AGENTS.md`). Read this before searching again.

## 1. Requirements (user)

| # | Date | Requirement |
|---|---|---|
| R1 | 2026-11-10 | Chat-only coaching on the content of a scientific manuscript; every edit user-approved. Pattern follows `application-style-coach`. |
| R2 | 2026-11-10 | Split from `manuscript-writing-quarto` (that skill = document formatting/structure/mechanical lint; this skill = content). Boundary checked, split judged sensible (see section 5). |
| R3 | 2026-11-10 | Help with writer's block: offer a rough skeleton with leading questions the user can explore (questions, not drafted prose). |
| R4 | 2026-11-10 | Never insert references. May flag places in the text that probably need a reference. |
| R5 | 2026-11-10 | If possible, read the user's `.bib` and check which entries have full text available (HTML or other open access), so content can be checked against what the user cites. |

## 2. Sources

| Source | What it gives | Status |
|---|---|---|
| https://www.icmje.org/recommendations/browse/manuscript-preparation/preparing-for-submission.html | Primary. IMRAD = Introduction, Methods, Results, Discussion; "not an arbitrary publication format but a reflection of the process of scientific discovery"; subheadings allowed; meta-analyses and case reports/reviews may use other formats; section list (title page, abstract, intro, methods, results, discussion, references, tables, figures, units, abbreviations); reporting-guidelines subsection | read (excerpt) |
| https://www.icmje.org/icmje-recommendations.pdf | Same recommendations, full PDF; also lists AI-related rules (excerpt mentions editors/reviewers and AI in the editorial process; author-side AI disclosure wording NOT read) | search |
| https://equator-network.org/ | Primary. Hub for reporting guidelines; "most commonly used" panel: STROBE (observational), CONSORT/SPIRIT (randomised trials, protocols), COREQ/SRQR (qualitative), ARRIVE (animal research); describes guidelines as community-created recommendations for what to report | read (excerpt) |
| https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2874506/ (EQUATOR overview, peer-reviewed) | EQUATOR aims; online library of reporting guidelines | search |
| https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7359286/ (ARRIVE 2.0, PLOS Biology/BMC copy) | Primary. ARRIVE 2.0: "Essential 10" (minimum) plus 11-item "Recommended Set"; applies to in vivo experiments with live animals; endorsed by >1000 journals; reporting of randomisation, blinding, sample-size justification is poor in the literature | read (excerpt) |
| https://writinginthesciences.uoguelph.ca/discussion/ (University of Guelph) | Discussion = six components; every claim grounded in evidence; acknowledgement of limitations; Discussion is not a backwards Introduction; warns against letting the Discussion read as a literature review | read (excerpt) |
| https://libguides.usc.edu.au/scireport/discussion-conclusion (Univ. of the Sunshine Coast) | Discussion answers "what does it mean / so what"; start with a short summary of key findings, then meaning, then limitations; present key finding, relate to research question and literature, move on | read (excerpt) |
| https://tri.uams.edu/wp-content/uploads/2022/06/Writing-Papers-VI-Discussion-JCE.pdf (J Clin Epidemiol series "Effective writing and publishing scientific papers, part VI") | Peer-reviewed series. Intro as funnel, Discussion as inverted funnel (hourglass together); typical Discussion = main findings, comparison with literature, strengths and limitations, conclusion; no new results in the Discussion; state limitations frankly | read (excerpt) |
| https://cran.r-project.org/web/packages/roadoi/vignettes/intro.html (rOpenSci `roadoi`) | `oadoi_fetch(dois, email)` returns `is_oa`, `oa_status`, `best_oa_location`, `oa_locations` (url, url_for_pdf, license, version) from Unpaywall; free, email only | read (vignette excerpt) |
| https://ropensci.r-universe.dev/roadoi | roadoi 0.7.3 listed (r-universe mirror of CRAN package; install from CRAN) | read (excerpt) |
| `research/openalex-fulltext-ledger.md` (own, 2026-10-29) | Existing tested route: `openalex/scripts/fetch_fulltext.R` (OpenAlex OA locations, Unpaywall, Europe PMC XML via `europepmc`), `oa_ft_text()`/`oa_ft_grep()`. Findings: Unpaywall rarely beats OpenAlex locations; some `url_for_pdf` values are not PDFs (check `%PDF-`); non-PMC records lack `pmcid` | read (own ledger) |
| `research/application-style-coach-ledger.md`, `research/manuscript-writing-quarto-ledger.md` (own) | Design precedents: chat-only, one-sentence labelled examples, no references, "call wins" rule; Quarto skill = file, CRediT, mechanical lint | read (heads) |
| https://www.editage.com/..., https://www.aje.com/arc/..., https://paperguide.ai/..., https://scientificproofreading.uk/... | Discussion-section and ICMJE how-tos | skipped: commercial |
| https://casrai.org/guides/arrive-guidelines, https://casrai.org/dictionary/term/imrad-structure | IMRaD/ARRIVE explainers (templated, JSON-LD blobs, LLM-like) | skipped: LLM-like |
| https://libguides.usc.edu/writingguide/discussion (Univ. of Southern California), https://www.sjsu.edu/writingcenter/... | Discussion guides | skipped: US-tuned (content overlaps the sources used) |
| skills.rest, anysite, api-evangelist, zoharbabin issue | Unpaywall wrappers/third-party profiles | skipped: commercial/third-party; use Unpaywall docs or `roadoi` |

## 3. Facts usable for the skill

- IMRAD is the default structure for original research, per ICMJE; other article types (meta-analysis, narrative review, case report, editorial)
  use other formats. The coach must first ask the article type and the target journal's own structure (journal rules win, as the "call wins"
  rule in `application-style-coach`).
- Reporting guidelines depend on study design: STROBE (observational), CONSORT (randomised trials), SPIRIT (trial protocols), PRISMA (systematic
  reviews), COREQ/SRQR (qualitative), ARRIVE 2.0 (animal research; Essential 10 + Recommended Set). They are health/animal-research
  oriented; EQUATOR is a health-research library. For ecology, behaviour or chemistry papers outside these areas there may be no
  matching guideline; the coach should say so, not force one. Journal instructions decide whether a checklist is required.
- A coach can turn a guideline item into a question ("where does the text state the experimental unit?") without writing the content.
- Discussion pattern from three independent academic sources: main findings, comparison with literature, limitations, take-home message;
  no new results; claims grounded in evidence; end with implications. Introduction = funnel to the question. This gives coaching checks
  for claim-evidence fit and for "does the Discussion answer the question the Introduction posed".
- Full-text availability by DOI is a solved lookup: OpenAlex OA locations first, Unpaywall (`roadoi`) second, Europe PMC XML for PMC records
  (already implemented in `openalex/scripts/fetch_fulltext.R`). Availability is not universal; closed papers return `no_open_access_copy`.
  Metadata (Unpaywall) is CC0, but each paper keeps its own licence: the skill may read for the user's checking but must not redistribute or
  store text outside the user's project.

## 4. Design notes (my reading, to confirm with the user)

- **Skeleton for writer's block (R3).** Output a heading outline with prompts as questions ("What is the single claim of this paper?",
  "Which observation would change your mind?"), placeholders, no sentences about the user's results. Matches the `application-style-coach` rule that a prompt-only skeleton counts as a new file only when the user asks for it; otherwise chat only.
- **Flag reference-needed spots (R4).** Read-only heuristic script or chat check: sentences with comparative or general claims ("is known to",
  "previous studies", "widely", superlatives), method/tool names without a citation, numbers about other work, definitions. Output is a
  list of line numbers plus a question ("which source supports this?"). Never insert, suggest or look up a citation; this extends the
  `application-style-coach` "no references" rule consistently.
- **Bib reading (R5).** Reading the user's `.bib` is allowed (the Quarto skill already treats it as user-owned and read-only). Steps: parse
  entries (`bib2df`/`RefManageR` or base parsing, check CRAN), take DOIs, ask `openalex` skill's `fetch_fulltext.R` for OA availability, report a
  table (key, DOI, OA status, where). Then the user decides which papers to open; the coach can compare what the user's sentence says with
  what the user pasted or what an OA full text says, and flag mismatch as a question, not a verdict. The assistant reading a paper can misjudge
  nuance; every finding is a prompt. Conflict to resolve: `application-style-coach` rule 4 forbids checking references; here the
  scope differs (the user's own citation to claim fit), so state this explicitly in the new skill. Also: do not add entries to the `.bib`.
- **Delegation.** Per-entry full-text lookup over many bib entries is mechanical, low-judgment and noisy: a candidate for the repo's
  subagent-delegation rule (hand it to a low-effort subagent, return only the availability table).
- **Territory.** Spelling/grammar/bib duplicate and character linters stay in `manuscript-writing-quarto`; numbers and effect sizes in
  `stats-reporting-and-review`; literature search in `openalex`. The coach does not draft paragraphs, does not add facts, no LLM-style wording,
  user writes it (reuse rules 2, 3, 7, 9 of `application-style-coach`).

## 5. Boundary check vs `manuscript-writing-quarto` (2026-11-10, local read)

| Question | Finding |
|---|---|
| Overlap in triggers? | Moderate: both say "manuscript". Quarto triggers = set up/structure/format/submit, CRediT, spell/grammar/lint. Coach triggers = framing, argument, section content, writer's block, "does this overclaim". |
| Overlap in rules? | Quarto already has "no autonomous prose" and read-only `.bib`; the coach inherits both, adds one-sentence labelled examples and no-LLM-style rules. |
| Overlap in tools? | None: Quarto = R scripts; coach = chat first, optional read-only flag script and bib/full-text lookup reusing the `openalex` script. |
| Verdict | Split is sensible. Put spelling/grammar linting only in the Quarto skill; hand-off sentence in both descriptions; update `application-style-coach` description ("manuscript prose ... to") to name the coach. |

## 6. Open research items

| # | Item | Status |
|---|---|---|
| O1 | PRISMA 2020, CONSORT 2025, STROBE, SPIRIT, SRQR/COREQ: current versions and item counts (only EQUATOR front page read) | not researched |
| O2 | Reporting standards outside health/animal research (ecology/behaviour/chemistry): any community checklists? (e.g. for behaviour or metabolomics) | not researched |
| O3 | ICMJE and journal policy on AI assistance disclosure for authors (only an editor/reviewer excerpt seen) | search only |
| O4 | Writer's-block and outline guidance from universities/funders (outline/question-driven drafting); sources from this round were Discussion-section guides | not researched |
| O5 | IMRaD guidance for Introduction (funnel, gap statement), Methods (reproducibility), Results (no interpretation), Abstract (matches body) from non-commercial sources; Abstract/ICMJE selective-reporting point only seen on a commercial site (skipped) | not researched |
| O6 | CRAN `.bib` parsers (`bib2df`, `RefManageR`, `bibtex`) status and Windows behaviour; `roadoi` install/test with the Unpaywall email | not researched |
| O7 | Heuristics for "claim needs a reference" (any peer-reviewed work on citation-need detection) and false-positive rate on real text | not researched |
| O8 | Copyright/terms for reading full text of OA papers inside the assistant (licence by paper: CC-BY vs bronze) | not researched |
| O9 | Hedging and claim-strength language in scientific writing (peer-reviewed sources) for the overclaim check | not researched |

## 7. Log

- 2026-11-10: Read `manuscript-writing-quarto/SKILL.md`, `skill-boundaries.md`, `application-style-coach/SKILL.md`; added todo row in `AGENTS.md`.
- 2026-11-10: Search round (search budget of five queries used): EQUATOR guidelines, ICMJE/IMRaD, Unpaywall, ARRIVE 2.0, Discussion-section structure.
  Commercial, LLM-like and US-tuned results recorded as skipped in section 2. Read own ledgers for `openalex` full text, `application-style-coach` and
  `manuscript-writing-quarto`. No local code tests yet.
- 2026-11-10 (round 2): see section 8. Five more searches, local test of three `.bib` parsers.

## 8. Round 2 (2026-11-10): versions, non-health standards, AI policy, `.bib` parsers

### 8.1 New requirement

| # | Date | Requirement |
|---|---|---|
| R6 | 2026-11-10 | The "ignore US-tuned guidance" source rule is relaxed for this skill: scientific publishing is international, so US-origin sources are acceptable here. Commercial and LLM-like sources are still skipped. (Skill-specific scope limit; the repo-wide rule in `AGENTS.md` is unchanged.) |

### 8.2 Sources

| Source | What it gives | Status |
|---|---|---|
| https://pmc.ncbi.nlm.nih.gov/articles/PMC11996237 and https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11995449/ (CONSORT 2025, PLOS Med/BMJ copies; also Lancet, Nature Med) | Primary. CONSORT 2025: 30-item checklist plus flow diagram; 7 items added, 3 revised, 1 deleted, a new open-science section; supersedes CONSORT 2010 ("should no longer be used"); no rigid structure imposed; use with the 2025 explanation and elaboration (https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11995452/); BMJ 2025;389:e081123 | read (excerpts) |
| https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8005924/ (PRISMA 2020, BMJ 2021) | Primary. PRISMA 2020 replaces 2009; 27-item checklist, expanded checklist, abstract checklist, revised flow diagrams; new items include competing interests (26) and availability of data/code/materials (27) | read (excerpts) |
| https://pmc.ncbi.nlm.nih.gov/articles/PMC2034723/ (STROBE 2007) | Primary. 22 items; 18 common to cohort/case-control/cross-sectional, 4 design-specific; items 1 title/abstract, 2-3 intro, 4-12 methods, 13-17 results, 18-21 discussion, 22 funding; item 20 asks for a cautious overall interpretation | read (excerpt) |
| https://www.icmje.org/recommendations/browse/artificial-intelligence/ai-use-by-authors.html | Primary. Journals should require disclosure at submission of AI-assisted technology use (LLMs, chatbots, image creators); describe use in both cover letter and the relevant section of the submitted work; AI cannot be an author; humans responsible, must review AI output ("incorrect, incomplete, or biased"); citing AI-generated material as the primary source is not acceptable; non-disclosure may count as misconduct in some circumstances | read (excerpt) |
| https://link.springer.com/article/10.1007/s13312-026-00336-1 (Indian Pediatrics commentary on ICMJE 2026) | Peer-reviewed secondary summary of the January 2026 ICMJE revision: disclose if, where and how AI was used, including language/grammar correction; AI used for data handling or analysis goes in the methods | read (excerpt) |
| https://www.tandfonline.com/doi/full/10.1080/08989621.2025.2481949 (Accountability in Research) | Discussion of mandatory vs optional AI disclosure; ICMJE: writing assistance goes in acknowledgments; WAME wants tool version/prompt detail | read (excerpt) |
| https://pmc.ncbi.nlm.nih.gov/articles/PMC8518748/ and https://onlinelibrary.wiley.com/doi/10.1111/brv.12721 (PRISMA-EcoEvo, Biol Rev 2021) | Primary. 27-item PRISMA extension for meta-analyses in ecology and evolutionary biology; mentions ROSES (environmental evidence) and TTEE as other discipline checklists | read (excerpts) |
| https://onlinelibrary.wiley.com/doi/10.1111/ele.12610 (Parker et al. 2016, Ecol Lett) and https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4979694/ | Primary. TTEE (Tools for Transparency in Ecology and Evolution) adapts the TOP framework (data, code, materials, design/analysis transparency; levels 1-3) for ecology journals; https://osf.io/g65cb/ | read (excerpts) |
| https://www.nature.com/articles/s41559-018-0574-7 (Nat Ecol Evol editorial) | A Nature checklist tailored to ecology and evolution, built using TTEE; the reporting summary is published with the paper | read (excerpt) |
| https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0285478 (AgroEcoList 1.0) | Example of a field-specific checklist (42 variables, agricultural ecology); lists other checklists (microbiome, genome sequencing, arthropod abundance, ecological datasets) | read (excerpt) |
| https://onlinelibrary.wiley.com/page/journal/20457758/homepage/forauthors.html (Ecology and Evolution author guidelines) | Example of a journal that requires data, metadata and code on submission and points meta-analyses to PRISMA-EcoEvo | read (excerpt) |
| https://pmc.ncbi.nlm.nih.gov/articles/PMC11237169/ | Literature review of open-science instructions for ecologists and journal data policies (policy scores by journal) | search |
| https://www.journalmetrics.org/..., https://paperguide.ai/..., https://casrai.org/guides/..., https://peerreviewai.org/..., https://www.editage.com/..., https://lifesciences.enago.com/..., https://manusights.com/..., researchgate copies | Checklist/ICMJE explainers and ecology review tips | skipped: commercial/LLM-like |

### 8.3 Facts

- **Versions (2026-11-10).** CONSORT 2025 (30 items) replaced CONSORT 2010; PRISMA 2020 (27 items) is the current PRISMA; STROBE is the 2007
  22-item checklist (a newer base STROBE was not found in this round, but I did not search the STROBE site itself, so "still current" is unverified);
  SPIRIT 2013 for trial protocols (an update was not checked); ARRIVE 2.0 (2020) for animal research. The skill should name the guideline but tell
  the user to download the current checklist from the guideline's own site or EQUATOR rather than rely on item numbers from the skill.
- **Non-health fields.** Ecology/evolution has: PRISMA-EcoEvo (meta-analyses), TTEE (transparency, journal-level), ROSES (evidence syntheses in
  environmental management), journal reporting summaries (Nature Portfolio). No general "primary study" reporting checklist for field
  ecology or behaviour was found beyond TTEE and ARRIVE (when animals are used). Chemistry/metabolomics, behaviour tracking and others: not researched. The
  coach should say "no matching standard found; check the journal's instructions" rather than invent one.
- **AI disclosure (matters for this skill itself).** ICMJE requires disclosure of AI-assisted technology use in the submitted work, not only the cover
  letter; language and grammar help counts; data analysis uses go in the methods; writing assistance in acknowledgments. Journal policies vary
  (publishers and journals differ on placement). Consequence: a user who gets coaching from this skill may need to disclose it, depending on the target
  journal. The skill must tell the user to check the journal's AI policy (parallel to rule 7 in `application-style-coach`), never write the disclosure
  text unprompted, and never claim the coaching "does not count".
- **ICMJE note on references.** AI-generated material is not an acceptable primary source and authors must attribute quoted material with full citations.
  Supports the "never insert references, flag only" design.

### 8.4 `.bib` parser test (Windows 11, R 4.6.0, CRAN installs allowed: `bibtex` 0.5.3, `bib2df` 1.1.2.0, `roadoi` 0.7.3; `rbibutils` 2.4.1 already installed)

Test file in git-ignored `tmp-examples/sample.bib` (deleted afterwards): 5 entries, including an unbraced year (`year = 2014`), a quoted DOI
(`doi = "..."`), a missing DOI, a `@book`, LaTeX accents (`M{\"u}ller`), and a duplicate key whose DOI is a `https://doi.org/` URL in uppercase and which lacks `journal`.

| Parser | Result |
|---|---|
| `bib2df::bib2df()` | Returns a tibble with all 5 rows (duplicate key kept, no error). **Bug-like behaviour:** the entry with unbraced year and quoted DOI came back with empty `DOI` and `YEAR`. All fields are character; message about `YEAR`. Heavy imports (dplyr, stringr, httr, humaniformat) |
| `bibtex::read.bib()` | Parsed unbraced and quoted values correctly (DOI and year right for all kept entries); **silently drops** an entry that fails bibentry validation (the duplicate lacking `journal`) with only a console message, so incomplete entries vanish; DOI strings are raw (a URL form would need normalising). Light: imports only `utils`. Returns a `bibentry` object |
| `rbibutils::readBib()` | Renames duplicate keys (`wickham2019a`/`b`) and drops invalid entries with a message; `texChars = "convert"` left `M{\"u}ller` unconverted in the author field (not investigated further) |

Implications: use `bibtex::read.bib()` for fields (lightest, handles quoting), and keep a raw-text key/entry scan (as `check_bib_duplicates()` in the
Quarto skill already does) so dropped or duplicate entries are reported instead of lost. Normalise DOIs (strip `https://doi.org/`, lowercase) before any
lookup. A `.bib` with missing DOIs needs a title-based OpenAlex lookup, which is the `openalex` skill's territory. `roadoi::oadoi_fetch()` was installed but not run
(it needs the user's email for Unpaywall; the `openalex` script already covers the full-text step and was tested 2026-10-29).

### 8.5 Open items after round 2

| # | Item | Status |
|---|---|---|
| O1 | CONSORT/PRISMA/STROBE/ARRIVE versions | partly done: CONSORT 2025, PRISMA 2020, STROBE 2007, ARRIVE 2.0 confirmed; SPIRIT update, STROBE update, PRISMA extensions (ScR, EcoEvo) and checklist download links not checked |
| O2 | Standards outside health | partly done for ecology/evolution (PRISMA-EcoEvo, TTEE, ROSES, ARRIVE); behaviour tracking, chemical ecology/metabolomics, genomics (MIxS etc.), statistics-heavy papers not researched |
| O3 | AI disclosure | partly done: ICMJE primary page read; individual publisher policies (Springer Nature, Elsevier, Wiley, PLOS, Science) not read; COPE/WAME not read first-hand |
| O4 | Writer's-block / outline guidance | not researched |
| O5 | IMRaD guidance for Introduction, Methods, Results, Abstract from non-commercial sources | not researched |
| O6 | `.bib` parser | done (8.4); not tested on a real, large `.bib` with `@string`, `@comment`, or Zotero/Better BibTeX output |
| O7 | Citation-need heuristics | not researched |
| O8 | Terms for reading OA full text | not researched |
| O9 | Hedging/claim strength | not researched |
| O10 | (new) Name collision check of any new R helper functions with `openalex` (`oa_ft_*`) and Quarto skill (`check_bib_duplicates`) before writing scripts | open |
| O11 | (new) Decide whether the skill should include a short per-study-design "questions" table (CONSORT/PRISMA/STROBE/ARRIVE items turned into prompts) or only point to the official checklist | user decision |

## 9. Round 3 (2026-11-10): writer's block and outlines, Introduction, Methods, Abstract, hedging and claim strength

Source rules as in R6 (US-origin sources allowed; commercial and LLM-like skipped). Five searches, no code run. Most structure guidance below comes
from biomedical sources; ecology, chemistry, physics and computer-science papers can differ (see O12).

### 9.1 Sources

| Source | What it gives | Status |
|---|---|---|
| https://pmc.ncbi.nlm.nih.gov/articles/PMC3178846/ ("How to Write Your First Research Paper", Yale J Biol Med) | Start with a template-like outline, not a Roman-numeral one: Level 1 questions (topic, why important, hypothesis, results incl. visuals, major finding), Level 2 grouped by Introduction/Methods/Results/Discussion; include figures and tables in the outline; if stuck, write Materials and Methods first; Methods goal = others can evaluate and repeat; Discussion opens with the major findings that answer the Introduction's question; discuss ideas with colleagues/mentor; writing centres exist | read (excerpt) |
| https://pmc.ncbi.nlm.nih.gov/articles/PMC4260692/ ("Writing and Publishing Your Research Findings") | Realise most first-draft words will not survive; outline = title, abstract, intro, methods, results (with tables/figures), discussion, conclusions, references, acknowledgements, disclosures; tell the story (issues, why they matter, questions; how addressed; answers); results subheadings follow the questions at the end of the Introduction; build tables/figures first, then text around them; do not repeat table content in text | read (excerpt) |
| https://www.universityofgalway.ie/media/graduatestudies/files/writingascientificstylethesis/writing_a_scientific_thesis.pdf (University of Galway, thesis guide) | Writer's block: writing is drafting; plan by jotting thoughts then ordering them with resources per point; mind map of key points only; work on tables/figures first and write around them; write Methods first (most straightforward); talk to the supervisor and bring a list of techniques already tried; each figure/table self-contained | read (excerpt) |
| https://grad.rutgers.edu/news/systematic-approach-scientific-writing (Rutgers iJOBS workshop report) | Separate planning, drafting and revising; mind maps and post-its; start with figures ("the skeleton of your story"); story pattern goal, obstacle, approach, result, benefit | read (excerpt) |
| https://spie.org/news/photonics-focus/janfeb-2020/how-to-write-a-scientific-paper (SPIE, learned society) | One-sentence "vision statement" of the key message ("if you can't articulate it in a single sentence you're not ready to write"); storyboard the figures, order them to support the hypothesis (not necessarily the order data were taken; gaps become visible); per figure: result (no interpretation), relevance to hypothesis, relevance to the field | read (excerpt) |
| https://www.embs.org/pulse/articles/tips-scientific-writing-manuscript-preparation/ (IEEE EMBS) | Plan scope, objectives, audience; outline; to avoid blocks start with the easiest sections and put down key phrases; repeat the take-home message in title, abstract and main body | read (excerpt) |
| https://www.jclinepi.com/article/S0895-4356(13)00020-6/fulltext (J Clin Epidemiol writing-tips series, part III Introduction; Cals and Kotz 2013) | Peer-reviewed open-access series. Introduction = funnel; purpose = why the study was done and the research question; not a full review of the field; typically at most 10-15% of the paper's word count; last paragraph states the question or hypothesis and briefly what was done; clear, unemotional language; tailor to journal; check "is this the start of the storyline in my outline?" | read (excerpt) |
| https://www.jclinepi.com/article/S0895-4356(13)00019-X/fulltext (same series, part IV Methods) | Include design, setting, subjects, data collection, analysis, ethics; be honest about a priori versus exploratory analyses; keep results (e.g. numbers recruited) out of Methods; describe only methods whose results appear later; cite earlier work to show credibility; consider web-only supplement; test question: "could a researcher reproduce this study from what I wrote?" | read (excerpt) |
| https://www.jclinepi.com/article/S0895-4356(13)00193-5/fulltext (same series, part VI Discussion) | Hourglass: Introduction funnel, Discussion inverted funnel; open with the main findings answering the question in the same words as the Introduction; implications; do not "sell" future studies | read (excerpt) |
| https://plos.org/resource/how-to-write-your-methods/ (PLOS, non-profit publisher) | Detail sufficient for suitably skilled investigators to fully replicate; plan detail as if writing for your future self; use persistent identifiers for resources; put long protocols in a discoverable supplement | read (excerpt) |
| https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6058177/ (Mol Syst Biol editorial, "Structured Methods") | Reagents and tools table plus protocol-style methods as an option, to make methods reusable | read (excerpt) |
| https://openworks.mdanderson.org/... (MD Anderson Research Medical Library, writing course notes) | Methods purpose and reporting for reproducibility; statistical analysis subsection | search |
| https://pmc.ncbi.nlm.nih.gov/articles/PMC6398294/ ("Writing the title and abstract for a research paper") | Abstract must stay consistent with the main text (especially after revision), contain the key message, be drafted last, avoid abbreviations; no references/figures cited in it | read (excerpt) |
| https://pubmed.ncbi.nlm.nih.gov/40043542/ (methodological survey, surgical pilot RCTs, 2025) | 69.4% had abstract/main-text inconsistency; 19.4% conclusions stronger in the abstract; 26.4% omitted negative results; 37.5% different primary outcomes; 48.6% abstract content absent from the main text. One field (surgery pilot trials), so a prevalence from that field only | read (abstract) |
| https://bmcmedresmethodol.biomedcentral.com/articles/10.1186/s12874-017-0459-5 (scoping review, abstracts vs full reports) | Abstracts frequently inconsistent with full reports | read (abstract) |
| https://www.researchgate.net/publication/322364352... (RCT abstract structure study) | Significant P values 79.3% in abstracts vs 53.8% in main text (odds ratio 3.3); only a snippet, ResearchGate copy | search (lead only) |
| https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5976147/ (CLAIMS systematic review, PLOS ONE 2018) | 34% of academic studies used causal language reviewers judged too strong for the design; 70% of studies had low or very low strength of inference | read (abstract) |
| https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6745784/ (peer review and hedging in RCT discussions, BMC) | Hedges ("might", "could", "suggest", "appear") counter overstatement; a lexicon of 190 weighted hedges (weights 1-5) was used; mean hedging scores changed negligibly after peer review while limitation reporting improved; inferring causality beyond the design counts as spin | read (excerpt) |
| https://www.nature.com/articles/s41562-026-02553-x (Nat Hum Behav 2026, overreaching causal claims) | 194,631 cross-sectional social-science articles analysed with LLMs; unhedged causal claims are widespread, including full-text claims when title/abstract were not causal; AI summaries tended to amplify overstatement unless prompted carefully. Detection was LLM-based, so counts are estimates | read (excerpt) |
| https://pmc.ncbi.nlm.nih.gov/articles/PMC12584097/ (hedging in Med J Islamic Rep Iran) and https://files.eric.ed.gov/fulltext/EJ1201945.pdf (J Lang Linguist Stud) | Balance: too little hedging overstates, too much obscures the contribution; harder for second-language writers | read (excerpts) |
| https://arxiv.org/pdf/1710.08327 (preprint on uncertainty cue words) | Common hedge words: may, could, might, suggest, indicate, appear, seem, assume; citing a source can act as a hedge | read (excerpt, preprint) |
| JCE series part I (how to get started), part II (title and abstract), part V (results), part VII (tables and figures); Matthews, Bowen and Matthews, "Successful Scientific Writing" (book; an unauthorised OCR copy appeared in results and was not used) | Likely useful: JCE I, II, V in particular | not researched |
| https://www.cesarsotovalero.net/..., https://hellobio.com/..., https://casrai.org/guides/..., https://manusights.com/... | Personal blog (unvetted; low weight, one point matches the other sources: formulate questions, write around figures); reagent-vendor blog; templated guides; review-service blog | skipped: unvetted/commercial/LLM-like |

### 9.2 Facts and design implications

- **Writer's block and skeleton (R3).** Independent sources converge: start from a question-based outline that includes the figures; one-sentence key
  message; write what is easiest or most mechanical first (Methods and figure descriptions); treat the first draft as disposable; separate planning,
  drafting and revising. They disagree on order: some say outline and figures before prose, one expert says do not start writing too early, and one
  textbook notes outlines suit some writers for thinking and others for organising words. The coach should offer options and let the user pick,
  not prescribe a workflow.
- **Skeleton form.** The coach's skeleton is a list of questions per section (adapted from Level 1/Level 2 questions in PMC3178846 and the
  storyline pattern goal, obstacle, approach, result, benefit) with empty answer slots. It contains no drafted statements about the user's results.
  The user answers in their own words; the coach then asks follow-ups. Treat the skeleton as a new file only when the user asks (as in `application-style-coach`).
- **Introduction checks (questions, not verdicts):** funnel shape; length against 10-15% of the full paper (read-only word count is possible);
  final paragraph states the question and what was done; not a literature review; does the Discussion later answer the question in matching words.
  Spots where a reference is probably needed are flagged without suggesting a source (R4).
- **Methods checks:** can a reader reproduce it; a priori versus exploratory stated; no results in Methods; every method has a later result and every
  result a method (cross-check Methods against Results); statistics described; software and resource identifiers (relates to `reproducible-research-data`).
- **Abstract checks:** drafted last and re-checked after revisions; same primary outcome, numbers and direction as the body; conclusion not stronger than
  the body; negative results not dropped; nothing in the abstract that the body lacks. A read-only script could list numbers in the abstract that do not
  appear in the body; as a flag only. The empirical rates come from clinical trial reports, so say "reported in trials" if quoting.
- **Hedging and claim strength.** Both overclaiming (causal wording for associations; abstract stronger than body) and over-hedging (obscures the
  contribution) are problems. A hedge-word list (may, could, might, suggest, indicate, appear, seem) plus causal verbs (causes, leads to, improves, drives)
  gives read-only flags with line numbers; the question is "does your design support this wording?" Only the user knows the design; the coach must ask.
  Overlap: causal inference vs design belongs with the user's design and with `stats-reporting-and-review` for numbers. Flags count words and do not
  prove a claim is overstated. Context from the Nat Hum Behav result: examples written by an assistant can themselves drift toward stronger claims; the one-sentence example rule must
  keep to the user's facts and hedge level.
- **Peer review has limited effect on hedging** (BMC study: hedging scores barely changed) but improved limitation reporting; so a pre-submission coach
  question on limitations has some support. Evidence is from RCT reports.

### 9.3 Open items after round 3

| # | Item | Status |
|---|---|---|
| O4 | Writer's-block / outline guidance | done (9.1/9.2) |
| O5 | IMRaD Introduction, Methods, Abstract | done for biomedical sources; Results (JCE part V), Title (part II), Tables and figures (part VII) not read |
| O9 | Hedging / claim strength | done in outline: peer-reviewed prevalence and lexicon sources found; no validated open hedge lexicon file located (the 190-hedge lexicon is described, not obtained) |
| O12 | (new) Structure guidance outside biomedicine (ecology, chemistry, physics, computer science: e.g. Results-and-Discussion combined, conference papers, Letters) from non-commercial sources | not researched |
| O13 | (new) Titles, Results and tables/figures guidance (JCE parts II, V, VII) | not researched |
| O14 | (new) Test of any heuristic flag script (reference-needed, hedge/causal words, abstract-number check) on sample text; no code written yet | open |
| O7, O8 | Citation-need heuristics; terms for reading OA full text | still not researched |

### 9.4 Log

- 2026-11-10 (round 3): five searches (writer's block and outlines; Introduction; Methods; Abstract consistency; hedging and claim strength). Removed my leftover
  test variables (`r1`, `r2`, `r3`, `f`) from the R session. No code or package changes.

## 10. Round 4 (2026-11-10): ecology/behaviour structure, behaviour reporting standards, Results, AI policies, citation need

Source rules as in R6. Five searches (the per-turn search budget); no code run. Mostly search snippets, so status is "search" unless a page was opened; none was opened this round.

### 10.1 New requirement

| # | Date | Requirement |
|---|---|---|
| R7 | 2026-11-10 | User's field is mainly biology, ecology and animal behaviour. Prioritise these over biomedical wording; keep CONSORT/PRISMA/STROBE as pointers only. Resolves hand-off open question 3. |

### 10.2 Sources

| Source | What it gives | Status |
|---|---|---|
| https://www.britishecologicalsociety.org/content/how-to-get-your-research-published/ (British Ecological Society) | Ecology learned society advises IMRAD plus storytelling; abstract = background, questions, methods, findings, implications. Confirms IMRaD is the norm in ecology | search |
| https://flexiblelearning.auckland.ac.nz/ecology-writing-guide/menu/1/files/ecology_writing_guide_2015.pdf (Univ. of Auckland ecology writing guide) | Suggested writing order: Methods/Results, then Discussion/Conclusions, then Introduction; discussion subheadings and comparison with published results | search (fragments) |
| https://libguides.lib.miamioh.edu/environmental-sciences/writing-your-paper (Miami Univ., environmental sciences) | Order Results, Introduction, Discussion; Results has no interpretation; Discussion mirrors the Introduction and must not discuss results absent from Results | search |
| https://libguides.tamusa.edu/c.php?g=830372&p=10619145 (Texas A&M-SA ecology guide) | Same writing-order idea (Results first, Introduction last so it matches the Discussion); organise Results by topic or experiment | search |
| https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10077155/ ("Finding your scientific story by writing backwards", editorial) | Start from the main conclusions and write backwards: Results, Methods, Discussion, Introduction, Abstract, Title; stresses the IMRaD order of reading differs from writing order | search |
| https://www.researchgate.net/publication/281444470_How_to_Write_Ecology_Research_Papers (ecology course notes, Oikos-oriented) | Suggests an order for an experimental ecology paper (tables/figures and results text before Discussion, Introduction late); notes the Discussion has no standard structure, unlike Results; ResearchGate OCR copy, author unverified | search (lead only) |
| https://www.sciencedirect.com/journal/animal-behaviour/publish/guide-for-authors (Animal Behaviour, journal instructions) | Primary. Welfare of animals: follow ASAB/ABS guidelines (updated each January issue), legal and institutional rules; ASAB and ABS endorse PREPARE (planning) and ARRIVE (reporting) for live-animal studies; exceptionally high welfare standards for vertebrates and invertebrates | search (excerpt) |
| https://www.animalbehaviorandcognition.org/submissions.php (Animal Behavior and Cognition) | Primary journal instructions. ASAB guidelines plus ethical-review statement in the article; recommends ARRIVE; report effect sizes and confidence intervals where appropriate | search (excerpt) |
| https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0328931 (PLOS ONE, ethics reporting for insects) | Ethics statements are rare for invertebrate work except where a journal requires them (Animal Behaviour does) | search |
| https://pmc.ncbi.nlm.nih.gov/articles/PMC11867812/ (Animal Welfare editorial) | Typical ethics statement content: committee name plus approval reference ID; cites the 2023 ASAB/ABS guidelines (Animal Behaviour 195) | search |
| https://journals.sagepub.com/doi/10.1177/17470161231183100 (farm animal behaviour studies vs ARRIVE Essential 10, 2023) | Compliance with ARRIVE Essential 10 in animal behaviour and welfare studies was assessed; reporting gaps linked partly to low awareness of guidelines | search |
| https://www.jclinepi.com/article/S0895-4356(13)00129-7/fulltext and https://tri.uams.edu/wp-content/uploads/2022/06/Writing-Papers-V-Results-JCE.pdf (JCE part V, Results) | Peer-reviewed series. Results = objective findings in the past tense, no interpretation; mirror the Methods ("for every method a result"); primary analyses first in a new paragraph, then secondary, then unexpected findings; never report results with P values only; text and tables/figures interplay, do not duplicate; extra material to supplement | read (search excerpt, two copies) |
| https://www.jclinepi.com/content/jce-Writing-Tips-Series | Index of the series; Part VII (tables and figures) is open access; Part II (title and abstract) listed | search (index only) |
| https://arxiv.org/pdf/2110.05503 (astronomy writing guide) | Hourglass shape, keep IMRaD sections unmixed; rule of thumb for citations: textbook-level background needs none, specific statements or results do. Field is astronomy; used only for the citation heuristic | search |
| https://arxiv.org/pdf/1902.11116 (Redi et al. 2019, "Citation Needed") | Taxonomy of why citations are needed (e.g. scientific claims, quotations, controversial or surprising claims) and classifiers for Wikipedia sentences; trained on Wikipedia, not manuscripts; people without domain knowledge can judge citation need | search |
| https://arxiv.org/pdf/2604.08501 (sciwrite-lint, preprint) | Lists claim-citation support and retraction detection as checks; a tool concept, not evaluated here | search (lead only) |
| https://arxiv.org/pdf/2307.11918 (bibliometric analysis of publisher AI instructions), https://arxiv.org/pdf/2507.03216 (digital humanities disclosure study) | Secondary studies: publishers agree AI cannot be an author, but disclosure rules vary; STM advised copy-editing need not be declared but other use must; Springer Nature moderate, Wiley and Science stricter in 2023 | search (preprints, 2023 snapshot) |
| https://campus.kennesaw.edu/offices-services/research/ai-disclosure.php (university research office) | Secondary summary: Nature documents LLM use in Methods; copy-editing exempt; Elsevier needs a declaration, no AI images | search (secondary, dated) |
| Publisher policy pages themselves (Elsevier generative-AI policy, Springer Nature, Wiley, PLOS, Science) | Elsevier URL seen only as a citation inside a commercial page: https://www.elsevier.com/about/policies-and-standards/generative-ai-policies-for-journals | not read; policies change often (a result says Elsevier updated in 2026) |
| thesify.ai, enago.com, casrai.org (AI disclosure guides, news), editage.com, ecologiclife.com | AI-policy summaries and a "discussion in ecology" page | skipped: commercial/LLM-like |

### 10.3 Facts and design implications

- **Writing order in ecology guides.** Four independent university/society guides (Auckland, Miami, Texas A&M-SA, plus the "backwards" editorial) say to write Methods/Results first, then Discussion, then Introduction and Abstract last. Two earlier sources (round 3) said "start with the easiest section" or outline first. Consistent with the round 3 finding: offer options and let the user choose. Ecology uses IMRaD (BES), so the biomedical section checks transfer, but the order of writing is usually presented as Results-first.
- **Results checks (JCE part V; supports O13 for Results).** No interpretation; mirror the Methods both ways; primary analyses first; effect sizes or estimates, not P values alone (Animal Behavior and Cognition also asks for effect sizes and confidence intervals); do not repeat table content in prose. Ties to `stats-reporting-and-review`.
- **Behaviour and ecology reporting standards (O2, partly).** Animal behaviour journals point to: ASAB/ABS guidelines for the ethical treatment of animals in behavioural research (Animal Behaviour 195, 2023; updated annually in the journal), PREPARE (planning), ARRIVE (reporting, when live animals are used), and an ethics statement with committee and approval ID. Invertebrates are covered by some journals (Animal Behaviour) and not others. No community reporting checklist for field or tracking-based behavioural studies was found beyond ARRIVE and the earlier TTEE; say "none found; follow the journal's instructions" rather than invent one. Tracking/pose-estimation (DeepLabCut) reporting standards were not searched.
- **Ethics statement question.** For animal studies the coach can ask: which committee and approval ID, which law or permit, which guidelines (ASAB/ABS, ARRIVE) the journal asks for, and whether the journal requires a statement for invertebrates. Do not draft the statement.
- **Citation need (O7).** No validated detector for scientific manuscripts was found. Research models (Wikipedia-trained) classify sentences using language frames; people without domain expertise do the task reasonably. A transparent rule set for flagging: specific statements about other work, numbers from other studies, causal or general claims ("is known to", "previous work"), methods/tools/software/species introduced without a source, definitions that are not textbook knowledge; do not flag textbook-level background (astronomy guide rule of thumb). Flags are questions ("which source supports this?"), never a suggested source (R4). False-positive rate is untested (O14).
- **Citation verification tools** (sciwrite-lint, SemanticCite, CiteCheck) are preprints or prototypes, not evaluated here. The coach's check of a claim against full text (R5) stays a prompt, not a verdict.
- **AI disclosure (O3).** Still based on ICMJE (section 8). Secondary summaries disagree on details (exemption for copy-editing; placement in Methods vs a separate declaration before the references; snapshots from 2023 to 2026), which supports the existing rule: tell the user to read the target journal's current policy; never draft the disclosure unprompted. Several publisher policies forbid reviewers uploading unpublished manuscripts to AI tools; for authors this is not a stated ban, but the user should check the journal's policy and any data-sharing limits before pasting a manuscript into an assistant. This comes from secondary/commercial summaries only; verify at the publisher before stating it as fact in the skill.

### 10.4 Open items after round 4

| # | Item | Status |
|---|---|---|
| O2 | Standards outside health | ecology and behaviour: ARRIVE, PREPARE, ASAB/ABS, TTEE, PRISMA-EcoEvo; tracking/pose-estimation and chemical-ecology reporting not searched |
| O3 | Publisher AI policies | secondary only; primary pages (Elsevier, Springer Nature, Wiley, PLOS, Science) not read |
| O7 | Citation-need heuristics | rule set drafted from Wikipedia-based research and an astronomy guide; no validated tool; test in O14 |
| O8 | Terms for reading OA full text | not researched (search budget used) |
| O12 | Structure outside biomedicine | ecology/behaviour done at guide level (IMRaD plus writing order); journal-specific formats (combined Results and Discussion, short communications) not read: read the target journal's instructions |
| O13 | Titles, Results, tables/figures | Results done (JCE V); Title (JCE II) and Tables/figures (JCE VII, open access) not read |
| O1 | STROBE/SPIRIT updates | not researched; low priority for this field |
| O11 | Per-study-design question tables | user decision; suggestion for this field: pointers to ARRIVE/PREPARE/ASAB plus the journal's instructions, no full item tables |

### 10.5 Log

- 2026-11-10 (round 4): five searches (ecology paper structure; animal-behaviour reporting and ethics; JCE part V Results; publisher AI policies; citation-need detection). No code, no package changes. Commercial/LLM-like AI-policy pages skipped. Remaining for a later round: JCE parts II and VII, OA full-text terms (O8), primary publisher AI policies, tracking-study reporting. (Done in round 5, section 11, except O8.)

## 11. Round 5 (2026-11-10): primary publisher AI policies, JCE parts II and VII, reporting for tracking-based behaviour studies

Five web searches plus about ten page fetches (webfetch). No code run. Primary publisher pages were fetched this time.

### 11.1 Sources

| Source | What it gives | Status |
|---|---|---|
| https://www.elsevier.com/about/policies-and-standards/generative-ai-policies-for-journals | Primary. Disclose tool name, purpose and extent of oversight; separate AI declaration statement at submission, placed immediately before the references; Methods for AI used in research methods and data visualisations; image captions for AI images. Exempt: basic grammar, spelling and punctuation checks, built-in spell/grammar checkers, basic reference-manager functions without generative AI, accessibility assistive technology. "Policy updated June 2026" | read (fetch summary) |
| https://www.springernature.com/gp/policies/editorial-policies/ai-manuscript-preparation | Primary. Any AI use must be clearly described; authors confirm accountability. Green (low risk: grammar, language editing, readability, formatting, translation) and Amber uses must still be described and declared in an AI Declaration in the manuscript; visuals labelled in the caption. Red uses not permitted (writing results or discussion, AI as author). Does not say anything on uploading manuscripts. This differs from the older "copy-editing exempt" summaries, so those summaries are outdated | read (fetch summary) |
| https://www.springernature.com/gp/policies/editorial-policies | Parent page; an AI section stressing human accountability, transparency and confidentiality/data protection | read (fetch summary) |
| https://www.wiley.com/en-us/publish/article/ai-guidelines/ | Primary. Disclose at submission and keep documentation (purpose, effect on key arguments, how output was verified). Acknowledgments: drafting, editing, translation, formatting; Methods: study design, data collection, literature review, code development, data analysis (plus privacy/compliance for sensitive data); figure captions: visuals. Exempt: simple grammar/spelling, language polishing, word choice, conciseness edits, reference formatting, exploratory use not in the manuscript, debugging, code style, data cleaning, routine unit conversions. "When in doubt, disclose." First 90,000 of about 122,000 characters read | read (partial) |
| https://journals.plos.org/plosone/s/ethical-publishing-practice | Primary. Disclose tools, how used, which aspects affected, and how output validity was evaluated; location in a Methods subsection, Acknowledgements or figure legend; not required for language improvement (translation disclosure recommended); required for AI used to generate analysis scripts or code | read (fetch summary) |
| https://www.science.org/content/page/science-journals-editorial-policies | Primary (search excerpt; fetch returned 403). AI cannot be an author; AI-generated images not permitted without editor permission; note AI use in the cover letter and in Methods or Acknowledgments (details depend on use case); reviewers may not enter manuscript text into AI tools | search (primary excerpt) |
| https://www.nature.com/nature-portfolio/editorial-policies/ai | Nature Portfolio AI policy | blocked (bot-wall); the Springer Nature page above is the nearest primary |
| https://www.nature.com/articles/... and secondary lists (casrai, kennesaw, PMC12170296 comparative review, arXiv 2603.16159) | Older or conflicting summaries (e.g. "copy editing exempt", "Science bans all AI text"), now contradicted by the primary pages | skipped as authority: dated or commercial; PMC12170296 and arXiv 2603.16159 are peer-reviewed/preprint snapshots, read as snippets only |
| https://www.jclinepi.com/article/S0895-4356(13)00021-8/fulltext (JCE part II, title and abstract) | Stand-alone abstract with no reference to main text or literature; avoid abbreviations and passive voice; Results are the most important part of the abstract; build title and abstract from keywords from all sections; abstract effect sizes with confidence intervals; sample size when percentages are given; have three draft titles; revise title and abstract every time the main text is revised; check the 4 Ws | search (primary excerpts, several fragments combined) |
| https://pmc.ncbi.nlm.nih.gov/articles/PMC6398294/ (Indian J Psychiatry, title and abstract) | Title accurate, not misleading, avoids whimsical words, key terms first, SPICED elements (clinical, adapt for ecology: setting, population, condition, end-point, design); abstract stand-alone, honest, balanced, keywords | search (excerpt) |
| https://www.jclinepi.com/content/jce-Writing-Tips-Series and https://www.rama.mahidol.ac.th/.../Effective%20writing%207.pdf (JCE part VII, tables and figures) | Key findings go in tables and figures; they must be self-explanatory; decide early which data to show; the title reflects what is shown; do not repeat table content in text but highlight the important findings; same terms for groups in text and tables; journals often allow about 5-6 tables and figures in print; create empty tables and figures before writing full sentences (part I); check figures in black-and-white/grey-scale; extra material to web-only supplements. The PDF text was compressed, so details come from search excerpts | search (excerpts) |
| https://pmc.ncbi.nlm.nih.gov/articles/PMC12214441/ (Wilson et al. 2025, J Anim Ecol, validation of supervised ML for accelerometer behaviour classification) | Peer-reviewed. Systematic review: 79% of 119 studies did not validate well enough to detect overfitting; only 21% followed gold-standard validation. State explicitly: how data were split (random, chronological, by individual, stratified) with justification, the split proportions, validation method, performance metrics with the range across folds. A standardised reporting checklist for this field is missing; they point to DOME (Data Optimisation Model Evaluation; Walsh et al. 2021) as a general checklist for supervised ML in biology | read (fetch summary, first 90,000 of 118,525 characters) |
| https://www.frontiersin.org/journals/behavioral-neuroscience/articles/10.3389/fnbeh.2025.1663089/full (systematic review, rodent marker-less pose estimation, 2025) | Many studies omitted animal selection, age, housing, sleep-wake cycle, recording plan, blinding, randomisation and keypoint detection accuracy; the review names no reporting guideline and calls for standardised protocols and benchmarking | read (fetch summary, first 90,000 of 160,453 characters) |
| https://www.nature.com/articles/s41592-022-01426-1 (SLEAP) | Reports tracking accuracy including identity switches because they measure proofreading effort | search (excerpt) |
| https://www.biorxiv.org/content/10.1101/2024.10.18.618969v1.full (preprint, validation of ML in ecology) | Biological validation (checking expected patterns) can show imperfect models are useful; effects can be detected at F1 of 60-70% in simulations | search (preprint) |
| https://pmc.ncbi.nlm.nih.gov/articles/PMC13175066/ (accelerometer ML review) | Recommends reporting F1 for imbalanced behaviour data and the spread over cross-validation folds | search (excerpt) |

### 11.2 Facts and design implications

- **AI disclosure: the primary pages disagree with the older summaries.** Springer Nature now asks for an AI Declaration even for low-risk uses such as language editing, so the earlier "copy editing is exempt" statement (Springer Nature, Nature) is outdated or journal-specific. Elsevier and Wiley still exempt basic grammar and language polishing. PLOS exempts language improvement but requires disclosure of AI-generated analysis code. Science asks for a note in the cover letter plus Methods or Acknowledgments. Placement varies: Elsevier before the references, Wiley Acknowledgments/Methods/captions, PLOS body of the article. So the skill must not state a general rule; it tells the user to read the target journal's current policy (Elsevier's was updated in June 2026), and to say what the coaching did and did not do (questions and feedback, no drafted text). The skill never writes the declaration unprompted.
- **Confidentiality.** Elsevier/Springer/Wiley summaries did not state a rule for authors on pasting their own manuscript into an assistant; reviewer-side bans are documented (Science). Treat as the user's decision about unpublished data and journal policy; mention it once, briefly.
- **Title and abstract checks (JCE II).** Stand-alone abstract; results are its core; effect sizes with intervals and sample sizes next to percentages; no abbreviations; re-check title and abstract after every revision; key words early in the title; no whimsy. For ecology adapt the SPICED idea to: system or species, setting, condition, outcome, design (my adaptation, flagged as such).
- **Tables and figures checks (JCE VII).** Choose early which findings go in which table or figure; self-explanatory captions; title reflects what is shown; text highlights findings without repeating tables; consistent group names; grey-scale legibility. Ties to `manuscript-figures-ggplot` (format and export are there, the coach asks only about the message).
- **Reporting for tracking-based behaviour studies (O2).** No guideline specific to pose-estimation or tracking-based behaviour studies was found. Related evidence: ARRIVE/PREPARE/ASAB-ABS for animal aspects (round 4); DOME as a generic checklist for supervised ML (named in Wilson et al. 2025; not read first-hand); Wilson et al. validation items (split method, proportions, validation method, metrics with spread); the 2025 rodent pose-estimation review lists omitted items (animal, age, housing, recording plan, blinding, randomisation, keypoint accuracy). Coach questions derived from these, without writing content: which software and version and model; how many labelled frames and from how many animals or videos; how the training/test split was made (by individual or by video?); tracking accuracy and identity switches reported; likelihood threshold and interpolation or smoothing choices; calibration from pixels to length; manual scoring check of derived behaviours; blinding and randomisation of the behavioural trials. The last four items belong to the user's own method choices and overlap with `animal-behaviour-tracking-analysis` and `deeplabcut-hpc`; the coach asks, those skills do the work. For unsupervised syllables (`keypoint-moseq`) the same questions about validation apply.
- **O8 (terms for reading OA full text) is still not researched**; the `.bib` full-text check keeps to papers with an open licence and does not store text outside the project.

### 11.3 Open items after round 5

| # | Item | Status |
|---|---|---|
| O3 | Publisher AI policies | done for Elsevier, Springer Nature, Wiley, PLOS (primary); Science from a primary excerpt; Nature page blocked; policies change often, so the skill carries no wording |
| O13 | Titles, Results, tables/figures | done from excerpts (JCE II, V, VII); PDFs not read in full |
| O2 | Tracking-based behaviour reporting | done as far as found: no field-specific guideline; DOME not read first-hand |
| O15 (new) | Read DOME (Walsh et al. 2021) first-hand before naming it in the skill | open |
| O8 | OA full-text terms | open |
| O12 | Journal-specific formats in ecology (combined Results and Discussion, short communications) | open; defer to the journal's instructions |

### 11.4 Log

- 2026-11-10 (round 5): searches on tracking reporting, JCE VII, Science AI policy, JCE II, plus fetches of Elsevier, Springer Nature, Wiley, PLOS, the Frontiers review and Wilson et al.; Nature, Science and JCE pages returned 403 or a bot wall. No code or package changes.

## 12. Round 6 (2026-11-10): DOME first-hand (O15), terms for reading OA full text (O8)

### 12.1 New requirement

| # | Date | Requirement |
|---|---|---|
| R8 | 2026-11-10 | D7 confirmed by the user: study-design guidance = pointers to official checklists (ARRIVE, PREPARE, ASAB/ABS, DOME, the journal's instructions); no per-design item tables. Closes O11. |

### 12.2 Sources

| Source | What it gives | Status |
|---|---|---|
| https://www.nature.com/articles/s41592-021-01205-4 (Walsh et al. 2021, Nat Methods 18:1122) | Primary. Fetch hit a bot wall; read through search excerpts of the page. DOME = community recommendations for reporting supervised ML in biology, written as questions, four areas: Data, Optimization, Model, Evaluation. Data: provenance, data splits (sizes; do training and test distributions differ), redundancy between splits (how split, how enforced), availability (incl. exact splits). Model: interpretability (black box or transparent). Recommends an ML summary table in the supporting information and a fixed sentence in Methods. Scope: supervised learning "in the absence of direct experimental validation" | search (primary excerpts) |
| https://arxiv.org/abs/2006.16189 (preprint v3) and https://biofold.org/pages/documents/papers/walsh_nmeth2021.pdf (author copy) | Abstract: a structured methods description (data, optimization, model, evaluation) lets reviewers and readers assess performance and limitations; answers go into supplementary material. PDF text came back compressed or fragmentary | partial (abstract read) |
| https://pmc.ncbi.nlm.nih.gov/articles/PMC11633452/ (DOME Registry, 2024) and https://registry.dome-ml.org/ | Primary. Registry assigns IDs and DOME scores to ML papers; sections dataset, optimization, model, evaluation; example questions: how many splits, points per split, distribution per split, raw evaluation files available, classification or regression | search (excerpts) |
| https://pmc.ncbi.nlm.nih.gov/articles/PMC9552836/ (ABC recommendations, commentary) | Critique: DOME has 21 questions (Box 1), all weighted equally, possibly too complex for beginners; proposes three key aspects instead. One opinion, not a standard | search (excerpt) |
| https://datascience.codata.org/articles/10.5334/dsj-2026-001 (GigaScience editors, 2026) | Editors integrating DOME into submission; the model section also asks for execution time and where the source code is released | search (excerpt) |
| https://training.galaxyproject.org/training-material/topics/statistics/tutorials/dome/tutorial.html (Galaxy Training Network) | Teaching summary: independent optimisation and test sets; release data with exact splits; redundancy between splits inflates performance | search |
| https://docs.ropensci.org/roadoi/reference/oadoi_fetch.html and https://cran.r-project.org/web/packages/roadoi/roadoi.pdf | `email` mandatory in Unpaywall requests; 100k calls per day suggested, use the data dump beyond that; location fields `license`, `version`, `host_type`, `is_best` | read (excerpts) |
| https://libguides.ucalgary.ca/c.php?g=732144&p=5260801 and https://researchguides.smu.edu.sg/api-list/scholarly-metadata-api (university library guides) | Same: email parameter required, 100,000 calls per day | search |
| https://apis.io/apis/unpaywall/unpaywall-doi-lookup-api/ (OpenAPI spec of the Unpaywall API, third-party hosted) | `oa_status`: gold (fully OA journal), hybrid (OA in subscription journal), bronze (free to read, no explicit licence), green (repository copy), closed; `license` null when none stated; `version` published/accepted/submitted; Unpaywall data is CC0. Third-party copy of the spec | search (secondary) |
| https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6466485/ and https://guides.lib.utexas.edu/c.php?g=1414647&p=10484863 | Unpaywall points to free legal copies; PMC article datasets include only articles whose licence allows text mining and reuse | search |
| https://unpaywall.org/products/api, https://unpaywall.org/data-format | Unpaywall's own pages | blocked/empty: no text through fetch |
| goldmanmalka.com (law-firm blog), rag-repo.org, casrai.org Unpaywall guide, lobehub.com skill, skywork.ai | Compliance opinion, third-party listings and wrappers | skipped: commercial/LLM-like (one idea noted as opinion only: access is not reuse) |

### 12.3 Facts and design implications

- **DOME (O15 closed, with a limit).** A question-based reporting framework for supervised ML (data, optimization, model, evaluation), with a summary table for the supplement and a recommended Methods sentence. Its data questions (source, split sizes, how train/test redundancy was prevented, exact splits available) match the Wilson et al. 2025 split and validation points, so the pointer is sound. Limits: the Nature page and PDFs could not be read in full, so the skill must not quote item numbers or the full question list; it names DOME, says it applies to supervised ML (for example a behaviour classifier, not plain tracking), and points to doi 10.1038/s41592-021-01205-4 and the registry. DOME is one community framework, criticised as long; never call it mandatory. For keypoint tracking without a supervised classifier no checklist applies; borrow the split questions (by individual or video), as in section 11.2.
- **Terms for reading OA full text (O8; practical, not legal advice).** (1) Unpaywall needs an email in every request and suggests at most 100k calls per day; the user supplies the email, the skill never invents one. (2) OA status is not one permission: gold or hybrid with a `cc-by` style `license` allows reading and reuse with attribution; `bronze` or `license = null` means free to read but reuse rights unclear; green copies may be accepted or submitted versions that differ from the published text. (3) Reading a paper to check the user's own sentences against it is the normal use; storing, redistributing or bulk-mining is different and depends on licence and site terms. Resulting rule: use full text only for the user's own checking, for papers with an open licence or that the user opens or pastes; for `bronze`, no-licence or accepted-manuscript copies report "free to read, licence unclear / version differs" and let the user decide; keep downloaded text inside the user's git-ignored project folder, outside any shared deposit, and delete after the check; PMC's OA subset and Europe PMC are the clean programmatic sources (already used by `openalex/scripts/fetch_fulltext.R`); record the version (published, accepted, submitted) in the availability table because the content check differs by version.
- **Not verified:** Unpaywall's own terms page returned no text, so rate limit and email rule rest on library guides and `roadoi` docs (consistent with each other); publisher terms on automated fetching were not checked per publisher, which is why the skill leaves the choice to the user.

### 12.4 Open items after round 6

| # | Item | Status |
|---|---|---|
| O15 | DOME first-hand | done as far as reachable; full question list and summary table not read; skill names it as a pointer only |
| O8 | OA full-text terms | done at practical level (12.3); no legal review; publisher terms not checked |
| O11 | Per-design question tables | closed by R8: pointers only |
| O12 | Journal-specific formats | open; defer to the journal's instructions |
| O14 | Test of flag scripts | open (needs the user's decision on whether a script ships, then a local test) |
| Nature Portfolio AI page | blocked by bot wall | open, low value; skill carries no policy wording |

Research is now sufficient to start writing the skill; what remains are decisions and tests, not searches.

### 12.5 Log

- 2026-11-10 (round 6): five web searches (DOME twice, OA reuse terms, Unpaywall API docs, DOME registry) and about seven fetches. Nature DOME and Unpaywall pages blocked or empty; arXiv abstract read; one speculative fetch of a PMC id returned an unrelated paper and was discarded. No code or package changes.


## 13. Description trigger proxy test (2026-11-10)

Method: `github-skill-maintenance/references/testing-skills.md` proxy variant. 20 queries (10 should-trigger, 10 near misses; 12 train, 8 validation) in `github-skill-maintenance/assets/trigger-queries-manuscript-writing-coach.json`. Three low-effort subagents saw only the names and descriptions of the 34 skills plus the queries in a different shuffled order each, and named the skills they would load. Not the real loader; queries written by the same author as the description.

| Result | Value |
|---|---|
| Should-trigger: coach picked | 29 of 30 (miss: a .qmd-file discussion check went to `manuscript-writing-quarto` once) |
| Near miss: coach picked | 3 of 30 |
| Near-miss slips | "spell-check my manuscript.qmd" once to the coach (run 1); "rewrite my results paragraph to sound more professional" to the coach in 1 of 3 runs, and NONE in 2 of 3. No skill owns ghost-rewriting, so loading the coach (which declines to draft) is arguably correct and the label is ambiguous |
| Near misses routed correctly otherwise | Quarto template, CRediT, .bib duplicates -> quarto skill; cover letter -> `application-style-coach`; Cohen's d, reviewer response -> `stats-reporting-and-review`; figure sizing -> `manuscript-figures-ggplot`; literature search -> `openalex` |

Pass rate by split: train 97%, validation 93%. Decision: no description change; the single systematic risk is a `.qmd` file name pulling coaching requests to the Quarto skill, which the description already handles by naming content coaching. Still untested: real fresh conversations, and the (untestable here) effect of file-signal wording. Scratch files in `tmp-examples/` were deleted.
