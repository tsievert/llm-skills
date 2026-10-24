# Skill roadmap ledger

Research for "what skills should we build next" questions (not tied to one skill under active
development; append future rounds here rather than starting a new file).

## 1. Requirements / triggering question

- R1 (2026-10-24): user asked, outside of plan mode, for new skill recommendations beyond the
  existing `Todo: skills to create` list in `AGENTS.md`, explicitly asking to look online for
  inspiration first.

## 2. Sources (status: search excerpts only, no full pages fetched)

| Source | What it covers | Status |
| --- | --- | --- |
| aibuilderclub.com "Claude Code for Data Scientists" | Generic data-science skill marketplace (EDA, SQL, ML, dashboards) | search excerpt |
| K-Dense-AI/scientific-agent-skills (GitHub) | 177 skills: bioinformatics, cheminformatics, clinical, materials, geospatial, neuroscience | search excerpt |
| browseract.com "Top 10 Claude Skills for Researchers" | Paper search, PKM, literature skills | search excerpt |
| awesomeclaude.ai / BehiSecc/awesome-claude-skills | Directory of community skills | search excerpt |
| prstats.org BIAC05/BIAC06 course pages | Bioacoustics in R: warbleR, seewave, Rraven, baRulho; spectrograms, MFCCs, cross-correlation, song_analysis | search excerpt |
| ResearchGate "Bioacoustics" topic thread | Tool list: seewave, warbleR, Bioacoustics pkg, Raven, Kaleidoscope, PAMGuide | search excerpt |
| ourcodingclub.github.io | Ecologist R training streams (stats, dataviz, modelling incl. GEE) | search excerpt |
| ecoevorxiv.org "Challenges and solutions for ecologists adopting AI" | ML/AI tool survey for ecology (OpenSoundscapes, SDMs, camera traps) | search excerpt |

## 3. Facts

- The large generic "scientific agent skills" marketplaces (K-Dense-AI, awesome-claude-skills,
  etc.) are overwhelmingly bioinformatics/cheminformatics/materials-science/finance focused;
  <cite index="4-1">the skills cover biology, chemistry, medicine, physics, engineering, Earth science, data analysis, and scientific communication</cite>
  — none target behavioural-ecology/field-biology statistics (GLMM, GAM, tracking, pheromones)
  the way this repo's existing skills do, so they are inspiration for *categories*, not
  skills to copy directly.
- Bioacoustics in R is an established, taught workflow distinct from DLC/pose tracking:
  <cite index="14-8">warbleR, Rraven, and baRulho... support the manipulation, measurement, and quality assessment of annotated sound data</cite>,
  covering <cite index="14-10,14-11">MFCCs... and freq_DTW() to compare signals through cross-correlation and dynamic time warping</cite>.
- Community discussion converges on the same R toolchain for ecoacoustics:
  <cite index="16-13,16-14">seewave, Bioacoustics, warbleR... help automate feature extraction and statistical analysis</cite>.
- Generic literature-support skills exist upstream (paper-search/OpenAlex clones) but the user's
  own `openalex` skill already covers this; no gap found there.

## 4. Candidate skills considered and disposition

| Candidate | Fit rationale | Disposition |
| --- | --- | --- |
| `bioacoustics-analysis-r` | warbleR/seewave/Rraven/baRulho; natural sibling of `animal-behaviour-tracking-analysis` (DLC) and `mixed-models-glmm`; matches behavioural-ecology profile | **Recommended** |
| `population-dynamics-time-series` | User has an Oecologia review on rodent population cycles; state-space/time-series tools (MARSS, pomp, or GAM-based trend/cyclicity already touches `gam-mgcv`) | **Recommended, lower priority** — check for real current need first (just a hypothesis from the OpenAlex profile) |
| `bayesian-multilevel-models` (brms/Stan) | Natural complement to `mixed-models-glmm`/`gam-mgcv`; PR Stats courses popular with this user's peer group mention Bayesian mixing models | **Recommended** |
| Generic bioinformatics/cheminformatics/materials skills (from K-Dense-AI etc.) | No evidence of relevance to this user's work | **Rejected** |
| Finance/quant, SQL/dashboard, PKM/Obsidian-second-brain skills | Already covered by existing narrower skills (`recipe-notes-formatter` is the only Obsidian skill; no evidence of a broader PKM need) or out of domain | **Rejected** |
| Joint species distribution modelling (HMSC), general GIS/remote sensing | Plausible ecology adjacent but no evidence in the user's OpenAlex profile (small-mammal behaviour, not community/spatial ecology) | **Parked** — ask before building |
| Camera-trap workflow (camtrapR) | Adjacent to tracking skill but different data type; no evidence of current need | **Parked** |

## 5. Open items

- None of the three recommended skills confirmed by the user yet; this is advisory only, no
  files created.
- If the user confirms `bioacoustics-analysis-r`, check CRAN first (`warbleR`, `seewave`,
  `Rraven`, `baRulho`, `tuneR`, `soundecology`) per the working rules, and read current
  warbleR/baRulho vignettes before writing (versions not checked here).

## 6. Log

- 2026-10-24: Round 1 (this file created). Two web searches only; no page fetches, no local
  tests, no skill files written.
- 2026-10-24: Round 2, "general purpose skills" follow-up. Searched Anthropic's official skill
  set (docx/pdf/pptx/xlsx) as a gap check: those Skills exist in Claude.ai/the API but
  (cite) built-in pptx, xlsx, docx, and pdf Skills are not available in Claude Code — this
  repo's host (Posit Assistant/RStudio) likewise ships none, so an `office-documents-r` skill
  (officer/flextable/openxlsx) was recommended as genuinely new territory. A `web-scraping-r`
  idea was raised but flagged as needing an overlap check against `job-opportunity-watch` and
  `recipe-notes-formatter` before building.
- 2026-10-24: Round 3, restructuring question for the "web fetching" cluster
  (`job-opportunity-watch`, `recipe-notes-formatter`, `social-research-search`, `openalex`, plus
  the parked `web-scraping-r` idea). Read best-practice sources (sitepoint Agent Skills tutorial,
  Anthropic's own "Equipping agents" post, groff.dev CLAUDE.md piece, agentskill.wiki
  skill-creator guide, TrueFoundry skills-registry piece) and directly inspected the three
  scripts (`jobwatch.R`, `rn_web.R`, `social_search.R`). Finding: this is not just a description-
  level clash risk, it is **confirmed code duplication** — all three independently hand-roll the
  same "polite R HTTP fetch" pattern (a custom `user_agent` string, a manual per-host rate limiter
  via a stored last-request timestamp and `Sys.sleep`, `req_timeout`); only `job-opportunity-watch`
  additionally checks `robots.txt` (for sitemap discovery, not as a compliance gate). None of the
  three use the CRAN `polite` package, which already packages this exact pattern (`bow`/`scrape`/
  `nod` with built-in robots/rate-limit/caching) — not checked whether `polite` would be a
  drop-in replacement, only that it exists and is unused. Best-practice sources converge on: shared
  rules should live in one place and be referenced, not copied, because duplicated content drifts
  (groff.dev: "A skill should point to an agent guide, not copy its content... they will drift
  apart"; TrueFoundry: "the same skill gets copied into three repos and slowly drifts out of
  sync"); the sitepoint tutorial's "base skill + specialization skills" pattern is the closest
  precedent, with the caveat that in the generic Claude Skills spec a cross-reference is a natural-
  language hint only, not a programmatic import — but this repo's R skills already demonstrate real
  programmatic reuse (`job-opportunity-watch` sources `social-research-search`'s `bsky_search()`/
  `masto_tag()` helpers directly), so the stronger pattern is available here. Recommendation given
  to the user: a new `web-fetching-r` skill owning the shared polite-fetch mechanics (as a tested,
  sourceable helper script) plus the generic one-off "scrape this page" use case (absorbing the
  earlier `web-scraping-r` idea), with `job-opportunity-watch`/`recipe-notes-formatter`/
  `social-research-search` kept as the domain-logic owners but refactored to source the shared
  helper instead of each maintaining its own copy. Not yet approved or built; a refactor of three
  tested, committed skills needs explicit user go-ahead and regression testing before any file
  changes.
