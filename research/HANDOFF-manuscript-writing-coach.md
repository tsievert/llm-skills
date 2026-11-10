# Hand-off: manuscript-writing-coach (drafted skill)

Written 2026-11-10 to restart in a fresh conversation. Read this file first, then only what "Outstanding issues" names.
Move or delete it when the work stream ends (same convention as `HANDOFF-job-watch-refactor.md`).

## Status (2026-11-10, end of day)

Research is finished: six rounds in `research/manuscript-writing-coach-ledger.md` (sections 1-12). Do not repeat a search that has a row there.
The skill is **drafted, not verified, not cross-linked, not committed**. It exists at `manuscript-writing-coach/`:

- `SKILL.md` (description 902 characters), `references/section-checks.md`, `skeleton-and-writers-block.md`, `reporting-and-ethics.md`, `bib-and-fulltext.md`.
- `scripts/number_consistency.R`: read-only abstract-versus-body number check (`mc_abstract_numbers()`, `mc_abstract_summary()`). Per decision D8, the reference-needed and hedge/causal checks stay chat-only; there is no script for them.
- `lint_skills()` is clean. Line endings of the new files are LF (the script had CRLF once and was normalised; re-check after any edit, `.gitattributes` expects LF for `*.R` and `*.md`).
- `AGENTS.md` todo row updated to "drafted 2026-11-10, not yet verified or cross-linked". `HISTORY.md` has no entry yet.
- Untracked in git: `manuscript-writing-coach/`, the ledger and this file; `AGENTS.md` is modified.

## Outstanding issues (do these next, in this order)

| # | Issue | Detail and what to do |
|---|---|---|
| 1 | Clash warn vs `application-style-coach` | `check_skill_clashes(new = "manuscript-writing-coach")` scores 0.174, hand-off `none`, level warn (shared words: coaches, framing, chat, facts, responses, wording). Add a hand-off sentence to both descriptions. In `application-style-coach` the phrase "manuscript prose and Quarto checks to manuscript-writing-quarto" should become: manuscript content coaching to `manuscript-writing-coach`, Quarto and mechanical checks to `manuscript-writing-quarto`. Keep that description under about 950 characters. Re-run the clash check; otherwise record `accepted` with a reason in `github-skill-maintenance/references/clash-decisions.tsv`. This edits another skill, so say what changes first. |
| 2 | Info clash vs `manuscript-writing-quarto` | Score 0.185, hand-off one-way (the coach names the Quarto skill, not the reverse; shared words: numbers, .bib, credit, spelling, grammar, linting). Add to the Quarto skill: a description hand-off sentence (content coaching: `manuscript-writing-coach`), a line in Related skills, and a note that spelling and grammar linting stay there. |
| 3 | Ownership table | Add a Manuscript-cluster row for `manuscript-writing-coach` in `github-skill-maintenance/references/skill-boundaries.md` (owns: chat-only content coaching of scientific manuscripts, abstract number check, reporting-guideline pointers; hands off to `manuscript-writing-quarto`, `manuscript-figures-ggplot`, `stats-reporting-and-review`, `openalex`, `application-style-coach`), and update the Quarto and `application-style-coach` rows. |
| 4 | Eight one-way links (`check_skill_links()`) | The coach names these, they do not name the coach: `animal-behaviour-tracking-analysis`, `application-style-coach`, `deeplabcut-hpc`, `keypoint-moseq`, `manuscript-figures-ggplot`, `manuscript-writing-quarto`, `openalex`, `stats-reporting-and-review`. Each is a decision. Suggested: add backlinks for `manuscript-writing-quarto` and `application-style-coach` (issues 1-2) and possibly `manuscript-figures-ggplot` and `stats-reporting-and-review`; record `no-backlink` rows with reasons in `references/link-decisions.tsv` for the tracking skills and `openalex` (generic skills must not collect pointers to every domain skill). |
| 5 | Independent spec check not run | `uvx` is not on PATH in the assistant's bash or R session. Ask the user to run, from the repo root in their own shell: `uvx --from skills-ref agentskills validate manuscript-writing-coach`, and paste the output. Until then, do not call the skill ready. |
| 6 | `check_versions()` not run | The skill names guideline versions (CONSORT 2025, PRISMA 2020, ARRIVE 2.0, DOME 2021) but no R package versions, so it likely has nothing to flag; still run it and filter to `manuscript-writing-coach/` files. |
| 7 | Number script only tested on synthetic files | Run `mc_abstract_numbers()` on one real manuscript of the user (`.qmd`, `.md` or `.tex`). Check: abstract found correctly, false `missing` rows (words for numbers, units, ranges such as "12-15", thousands or decimal-comma formats), `weak` handling, behaviour with Quarto includes or an abstract set outside the file, `.docx`/`.pdf` input (not supported; export to text). Record results in the ledger (new dated section) and in the skill's "Tested and not tested". |
| 8 | `.bib` full-text check never run end to end | The workflow in `references/bib-and-fulltext.md` reuses `bibtex::read.bib()`, `check_bib_duplicates()` and the `openalex` script `fetch_fulltext.R`; it needs the user's Unpaywall email and a real `.bib`. Not yet tested on Zotero or Better BibTeX output, `@string` or `@comment`. Test in the git-ignored `tmp-examples/`, delete afterwards. Check the `fetch_fulltext()` argument names and its confirmation gates against what `bib-and-fulltext.md` says; I described the flow from memory of the script header only. |
| 9 | No live trigger test | Description-trigger test per `github-skill-maintenance/references/testing-skills.md` (`assets/trigger-queries.template.json`): queries for "does this overclaim", "help me outline my paper", "check my abstract numbers" should load the coach; "set up a Quarto manuscript", "spell-check my manuscript", "polish my cover letter" should not. Include near misses. |
| 10 | Wording and fact checks in the skill text | (a) Re-read `SKILL.md` and the references once for LLM-style wording and for any claim not backed by the ledger. (b) Guideline pointers in `reporting-and-ethics.md` (CONSORT 2025, STROBE currency, TTEE, ROSES) rest on 2026-11-10 searches; STROBE and SPIRIT updates were never checked. (c) Section-checks figures such as "about 10 to 15%" of words for the Introduction come from clinical-writing sources; the text says it is a prompt, keep that. |
| 11 | Close-out | Append a dated entry to `HISTORY.md` (what was built, tested, not tested); update the `AGENTS.md` todo row to the final status; mention the ledger path. Do not commit unless the user asks. Do not use the words "ready" or "done" while errors remain; load `github-skill-maintenance` and follow its verify step. |

Optional, low priority: Nature Portfolio AI policy page (blocked by a bot wall); journal-specific structures in ecology (defer to the journal); STROBE/SPIRIT updates; a possible later script for the hedge/causal word list if chat-only use shows it is worth automating (decided against for now, D8).

## Decisions (user)

| # | Decision |
|---|---|
| D1 | New skill `manuscript-writing-coach` = content coaching, chat only, every edit user-approved. `manuscript-writing-quarto` stays the formatting/structure/mechanical-lint skill (it keeps spelling, grammar, bibliography, character linting). |
| D2 | Writer's block: offer a rough skeleton with leading questions to explore (questions with empty answer slots, no drafted statements about the user's results). |
| D3 | Never insert references. May flag places in the text that probably need one. |
| D4 | If possible, read the user's `.bib` and check which entries have open full text, to check content against what is cited. Never edit the `.bib`. |
| D5 | The "ignore US-tuned sources" rule is relaxed for this skill only. Commercial and LLM-like sources are still skipped. |
| D6 | User's field is mainly biology, ecology and animal behaviour (2026-11-10). Prioritise these; biomedical guidelines (CONSORT, PRISMA, STROBE) stay pointers only. |
| D7 (confirmed 2026-11-10) | Study-design guidance = pointers to ARRIVE, PREPARE, ASAB/ABS, DOME and the journal's instructions, no item-by-item tables (ledger O11, R8). |
| Round 6 (2026-11-10) | DOME (O15) and OA full-text terms (O8) researched, ledger section 12. Research is sufficient to start writing; the remaining open items are decisions (flag script) and tests (O14), not searches. Rules for the `.bib` check: Unpaywall needs the user's email; use full text only for the user's own checking; `bronze`/no licence or accepted-manuscript copies are reported as "licence unclear/version differs"; text stays in the project and is deleted after the check; record the version in the availability table. |

## Where things stand (details in the ledger)

- **Boundary (ledger section 5):** triggers differ (set up/format/submit vs framing/argument/section content/writer's block). Put a hand-off sentence in both descriptions; point `application-style-coach`'s "manuscript prose ... to manuscript-writing-quarto" wording to the coach where it means content.
- **Reuse from `application-style-coach`:** chat only; facts belong to the user; one-sentence examples labelled "Example (your facts may differ)", at most two, never a paragraph; no references; the journal's instructions win; no LLM-style wording; the user writes it; line numbers in feedback on text files; "Explain the reasoning" and "Capture lessons" sections.
- **Guidelines (ledger 8):** CONSORT 2025 (30 items), PRISMA 2020 (27), STROBE 2007 (22, "still current" unverified), ARRIVE 2.0, PRISMA-EcoEvo, TTEE, ROSES. Name the guideline, point to the current checklist, do not quote item numbers. Say plainly when no standard matches.
- **AI disclosure (ledger 8):** ICMJE wants disclosure of AI tool use in the submitted work. The skill must tell the user to check the journal's policy, never write the disclosure unprompted, never claim coaching "does not count".
- **`.bib` (ledger 8.4):** `bibtex::read.bib()` is the best parser (quoted/unbraced values fine, light) but silently drops invalid entries; `bib2df` returned empty DOI/year for an unbraced year plus quoted DOI; `rbibutils` renames duplicate keys. Pair the parser with a raw key scan (reuse `check_bib_duplicates()` in `manuscript-writing-quarto/scripts/check_manuscript.R`), normalise DOIs (strip `https://doi.org/`, lowercase), and use the `openalex` skill's `scripts/fetch_fulltext.R` (OpenAlex locations, then Unpaywall, then Europe PMC XML) for availability. CRAN `bibtex`, `bib2df`, `roadoi` are installed; `roadoi` was not run (needs an Unpaywall email).
- **Writing guidance (ledger 9):** question-based outline including figures; one-sentence key message; start with the easiest sections; first draft is disposable. Sources disagree on order, so offer options. Introduction: funnel, about 10-15% of the words, last paragraph states question and approach, not a review. Methods: could a reader reproduce it, a priori vs exploratory, no results in Methods, every method has a result and vice versa. Abstract: written last, consistent with the body (same primary outcome, numbers, no stronger conclusion, no dropped negatives). Claim strength: both overclaiming (causal wording for associations) and over-hedging; hedge-word and causal-verb flags are prompts, not verdicts; assistant examples must not drift stronger than the user's facts.

- **Ecology/behaviour structure (ledger 10):** IMRaD is the norm (British Ecological Society). Ecology guides mostly suggest writing Methods/Results first, Discussion next, Introduction and Abstract last; offer as an option beside "outline first". Results: no interpretation, mirror Methods both ways, primary analyses first, estimates with intervals not P alone, do not repeat tables in text (JCE V). Journal-specific formats (combined Results and Discussion, short communications): defer to the journal's instructions.
- **Title, abstract, tables and figures (ledger 11):** JCE II: stand-alone abstract, results at its core, effect sizes with intervals, sample size beside percentages, no abbreviations, re-check after every revision; adapt "SPICED" to system/setting/condition/outcome/design for ecology (my adaptation). JCE VII: decide early which findings go in which table or figure, self-explanatory, title reflects what is shown, consistent group names, grey-scale check. Format and export belong to `manuscript-figures-ggplot`.
- **Behaviour reporting (ledger 10, 11):** Journals (Animal Behaviour, Animal Behavior and Cognition) point to ASAB/ABS ethics guidelines, PREPARE, ARRIVE and an ethics statement with committee and approval ID; invertebrate rules differ by journal. No guideline specific to pose-estimation or tracking studies was found. Question source for tracking studies: Wilson et al. 2025 (split method, proportions, validation method, metrics with spread across folds), a 2025 rodent pose-estimation review (animal, age, housing, blinding, randomisation, keypoint accuracy omitted), SLEAP identity switches; DOME named as a generic ML checklist but not read first-hand (O15). Coach asks, never writes; the work stays with `animal-behaviour-tracking-analysis`, `deeplabcut-hpc`, `keypoint-moseq`.
- **AI policies (ledger 11, supersedes round 2 summary):** primary pages differ. Springer Nature wants a declaration even for language editing (the "copy editing exempt" claim is outdated); Elsevier (updated June 2026) and Wiley exempt basic grammar/language polish; PLOS requires disclosure of AI-generated analysis code; Science asks for a cover-letter note plus Methods/Acknowledgments. The skill carries no policy wording: tell the user to read the target journal's current policy, state what the coaching did (questions and feedback, no drafted text), never write the declaration unprompted. Mention once that pasting unpublished data into any assistant is the user's decision under journal policy and data-sharing limits.
- **Citation need (ledger 10.3):** no validated tool. Use a transparent rule set as questions: claims about other work, numbers from other studies, causal/general claims, tools/software/species without a source; not textbook background. Untested false-positive rate (O14).

## Hard rules to keep in mind

No secrets, no personal data or `context-inbox/` content in the repo (anonymise lessons). Installs: CRAN and Bioconductor are allowed; GitHub or other sources (for example R-universe) need explicit permission first. The skill must stay chat-only with no autonomous prose and must never edit the user's manuscript or `.bib`. R run from the assistant cannot write to the assistant scratch dir; use the git-ignored `tmp-examples/` for tests and delete afterwards. Before editing a file check for CRLF (`file <path>`) and normalise with `sed -i 's/\r$//'`.

## Answered questions

- D6: field = biology, ecology, animal behaviour.
- D7: pointers to official checklists only, no per-design tables (confirmed 2026-11-10).
- Remaining research (DOME, OA full-text terms) done in round 6 (ledger section 12).
- D8 (2026-11-10): only the abstract-versus-body number check ships as a script; reference-needed and hedge/causal checks stay chat-only, because they depend on context a word list cannot see.

## Open questions for the user

1. Issue 1: may the hand-off sentence be added to the `application-style-coach` description (another skill's file)?
2. Issue 4: which backlinks to add, and which `no-backlink` decisions to record (suggested split above)?
3. Issue 7 and 8: which real manuscript and `.bib` may be used for testing, and is an Unpaywall email available in `UNPAYWALL_EMAIL` (check that it exists; do not print it)?
