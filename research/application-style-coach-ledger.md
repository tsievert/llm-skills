# Research: `application-style-coach` (planned skill; research round 2026-10-30)

Working name: `application-style-coach`. Status: research only, no skill written. Statuses in the source tables:
read / partial (abstract or snippet only) / search (result list only) / meta (commentary, not primary).

## 1. Requirements (user, 2026-10-30)

| # | Requirement |
|---|---|
| R1 | Help with job applications: formatting and style guidance and phrasing only. |
| R2 | No content editing. The assistant nudges the user in chat to rethink phrasing or framing; the user rewrites. |
| R3 | No adding of references, no looking up of scientific references (applies to the skill's behaviour, not to this research). |
| R4 | CV template = the TENK researcher's CV template. |
| R5 | Research may use scientific literature, social search, web. |
| R6 | (2026-10-30) Illustrative one-sentence rewrites ARE allowed, but only in the chat, never written into the user's document. Resolves O1. |
| R7 | (2026-10-30) Scope: academic applications only, English only for now. Resolves O5 and O6. |
| R8 | (2026-10-30) Also cover the research statement, teaching portfolio and list of publications. Resolves O9; see section 9. |

Implications for the design (my reading, to confirm with the user):
- Output is chat feedback (observations, questions, alternative framings as options), not a rewritten file. An open question is whether the
  assistant may show an example rewrite of one sentence as an illustration (see section 7, O1).
- Skill must not invent or "improve" facts, numbers, titles or merits, and must not add publications or citations (R3 plus TENK integrity rule below).
- Overlaps to define before writing: `job-opportunity-watch` (finding vacancies, not writing), `manuscript-writing-quarto` (also "never writes autonomous prose",
  flags-only), `openalex` (the skill must not call it), `stats-reporting-and-review` (reviewer-response drafting is a different genre).

## 2. TENK CV template: facts (primary source)

Source: https://tenk.fi/en/advice-and-materials/template-researchers-curriculum-vitae (read 2026-10-30). Files listed there:
`TENK_CV_template_2020_10.4.2026.docx` and `.pdf` (the page's file list shows a 10.4.2026 file revision; the template itself is dated 2020).
PDF of the 2020 recommendation: https://tenk.fi/sites/default/files/2021-06/TENK_CV_template_2020.pdf (partial read via search snippets).
Advice page (https://tenk.fi/en/advice-and-materials) notes an update on 9 December 2025: the term "data" was added to section 9 (Research output) to harmonise translations.

| Fact | Detail |
|---|---|
| Authors | TENK, Universities Finland UNIFI, Arene, Academy of Finland. First version 2012 (an English 2013 version exists), updated 2020. Languages: Finnish, Swedish, English. |
| Status | A recommendation. Organisations should adopt the headings and structure in original form but must give specific instructions on how to use it in each situation. Writers must follow the instructions of the organisation that requested the CV. |
| Purpose | Present merits "comprehensively, truthfully and comparably". Full details of all merits and commitments relevant to the career stage and the purpose of the CV. |
| Integrity | CV in an application is in principle a public document; content must be verifiable. Suspected exaggeration or distortion of merits (also in translations) can be treated as a suspected violation of responsible conduct of research. |
| Naming | Organisations and degrees by official names; job positions by the employer's or funder's titles. Translations of titles must be officially approved, used by the organisation itself, or otherwise justifiable (the 2013 version: self-composed translations must not be used). |
| Headings to keep | The 15 headings matter most; sub-bullets are illustrative. |
| Related | Used alongside "Good practice in researcher evaluation" (Federation of Finnish Learned Societies). Publications as a separate appendix following the Ministry of Education and Culture classification (A-I). Research.fi profile tool can generate a TENK-format Word CV (from April 2026; Aalto news item confirms the tool). |

The 15 headings (the page text numbers section 3 oddly; it is missing in the extract, probably "3. Other education/training, qualifications and skills"; confirm from the PDF, see O2):

| # | Heading | Style-relevant detail |
|---|---|---|
| 1 | Personal details and date of the CV | Surname incl. previous, first names, researcher ID (ORCID), date of CV |
| 2 | Degrees | Most recent first; date, title, major, institution, locality, country; docent title |
| 3 | Other education and expertise | Other education, professional competences/qualifications, supplementary training: date of completion, name, scope, provider (name and locality). Confirmed from the full PDF 2026-10-30. |
| 4 | Language skills | Native language; level achieved plus certificate date or justified self-assessment (Europass may be used) |
| 5 | Current employment | Start/end, title, employer, place; part-time stated; career stage I-IV |
| 6 | Previous work experience | Reverse chronological; grant periods; long-term visits abroad |
| 7 | Career breaks | Optional; dates and duration in months |
| 8 | Research funding and grants | Dates, type, source, amount, own role, name of PI |
| 9 | Research output | Total count plus e.g. ten most important/cited (name the database); OA links; tools, software, data; patents |
| 10 | Research supervision and leadership | Numbers of supervisees by programme; principal or co-supervisor |
| 11 | Teaching merits | Select carefully; separate teaching portfolio possible |
| 12 | Awards and honours | Includes recognition of teaching |
| 13 | Other key academic merits | Reviewing, committees, editorial roles, invited lectures, conferences |
| 14 | Scientific and societal impact | Open science, use of output, communication |
| 15 | Other merits | Company/organisation work, other expertise |

Style implications (from the template itself, usable as checks): reverse-chronological order; official titles; dates in consistent format; stating
part-time; counts and amounts rather than adjectives; naming the database for citation counts; marking own role versus PI; no self-translated titles.
These are formatting/phrasing checks the assistant can make without touching content.

Full PDF read 2026-10-30 (downloaded with curl to git-ignored `tmp-examples/`, text extracted with `pdftools::pdf_text`; `webfetch` only returns raw binary for this PDF; files deleted afterwards).
The 2020 PDF has 7 pages, English only, and confirms all 15 headings and wording above. Additional facts from the full text:
- The template may also be used for funding applications, Title of Docent applications, awards and other evaluations; usable in the arts.
- The integrity rule explicitly covers "applications, CVs, lists of publications, portfolios, research plans and statements" and their translations. So the research statement and teaching portfolio fall under the same exaggeration/distortion rule, not only the CV.
- Data protection must be taken into account by writer, recipient and evaluators, particularly for personal data. Footnote to heading 10 (update 21 May 2021): "or their names and graduation dates" was removed from the supervision item because of the GDPR. So the CV gives numbers of supervisees, not names.
- Heading 11: "Teaching merits should be carefully selected and presented as applicable"; a separate teaching portfolio can be used.
- Heading 7 (career breaks) is explicitly optional and "may have a positive impact".
- The page text of the 2020 PDF says the recommendation is to adopt the template "in its original format", with organisation-specific instructions (the earlier 2020 print said "unaltered", changed 22 June 2021).

Full 2020 PDF read 2026-10-30 (7 pages, English). It confirms all 15 headings above. Extra facts:
- The template can also be used for funding applications, Title of Docent applications, awards and other evaluations, and in the arts.
- The integrity rule explicitly covers "applications, CVs, lists of publications, portfolios, research plans and statements" and their translations, so research statements and teaching portfolios fall under the same exaggeration rule.
- Data protection applies to writer, recipient and evaluators. Update 21 May 2021 (GDPR): supervisee names and graduation dates were removed from heading 10, so the CV gives numbers only.
- Heading 11: teaching merits "carefully selected"; a separate teaching portfolio is possible. Heading 7 is optional.
- The 9 Dec 2025 change (the word "data" added to heading 9) is on the TENK advice page but is not in the 2020 PDF; the revised docx was not read.

## 3. Other formal sources (Finland context)

| Source | Status | Finding |
|---|---|---|
| https://career-advice.jobs.ac.uk/career-development/postdoctoral-careers-in-europe-finland/ | read (search snippet) | Finnish applications usually: CV, online form, cover letter, publication list, copies of qualifications, recommendation letters; keep CV and letter brief; "showiness and boasting would be frowned upon"; shortlisting merit-based; teaching expected to be showcased. Secondary (career-advice site, not official). |
| https://studies.helsinki.fi/instructions/article/tips-job-search | read (snippet) | Academic CV must list all merits, refer to TENK; cover letter: catch attention in the first sentence, link to the organisation's priorities, concrete concise examples, state benefit to employer, layout shows contact, date, recipient, position; ask someone to proofread. University careers service, general (not research-specific). |
| https://tieteentekijat.fi/en/membership/membership-benefits/career-services/job-application-and-curriculum-vitae/ | read (snippet) | Union of Finnish researchers: doctoral skills must be put into words the employer understands (mostly non-academic job context). |
| https://www.uwasa.fi/en/open-positions/application-attachments | read (snippet) | Example of a university requiring TENK-format CV and publication list; research plan 5-10 pages; teaching portfolio. Shows that organisation instructions override the template. |
| https://gethiredinfinland.com/blogs/tipsandtricks/crafting-the-perfect-cover-letter-in-finland-examples-templates-and-guidelines-for-success | search (snippet) | Blog (non-academic): no fixed cover-letter format in Finland; CV is read first; 4-5 paragraphs; scanning readers; "write the way you speak"; caution about uniform AI-generated letters. Low authority. |
| https://github.com/MohaAya/FinlandCV_Academic | read (snippet) | Existing third-party Claude skill that BUILDS a TENK CV. Opposite design (generates content); useful only for the header advice (no photo, no date of birth) and honesty rules. Not copied. Note: it omits the CV date the TENK template asks for (item 1), so do not adopt its header rules without checking TENK. |

## 4. Scientific literature (OpenAlex; used for research only, to be cited nowhere in the skill)

OpenAlex was queried through R (`httr2`), the `openalex` MCP tools were not available in this session. All status "partial" = abstract read, full text not.

| OpenAlex ID | DOI | Finding relevant to phrasing | Status |
|---|---|---|---|
| W2995486208 | 10.1136/bmj.l6573 | Lerchenmueller et al. 2019, BMJ: in 101,720 clinical articles, women first/last authors used 25 positive terms ("novel", "excellent" etc.) less often (12.3% relative difference); positive framing associated with about 9% more citations. Observational. Suggests the same language trade-off applies to self-presentation, but it is about article abstracts, not applications. | partial |
| W2978871172 | 10.3386/w26345 | Exley and Kessler 2019 (NBER WP): experiments, >4,000 online workers: women describe their own ability less favourably than equally performing men, even without incentives. Evidence for a self-description gap. | partial |
| W4381512849 | 10.1093/ej/uead045 | Eberhardt et al. 2023, Economic Journal: 12,000 reference letters, economics job market; women described more with "grindstone" terms and at times less praised for ability. Relevant to how letters are worded, not to the applicant's own text. | partial |
| W4413447322 | 10.1111/ijsa.70022 | 2025: 183 co-op students; cover letters and resumes written with more detail, clarity and structure led to more interviews per application. Student, Canadian co-op context, not academia. | partial |
| W4416868046 | 10.12688/f1000research.170507.1 | Scoping review of funders' Narrative CV templates. Context only; the TENK template is not a narrative CV. | partial |
| W7213578534, W7140284253 | 10.17863/cam.134343, 10.17863/cam.128546 | ARRC Narrative CV Study resources for postdoc recruitment: guidance for applicants and panels, "evidence on effectiveness limited". Context only (UKRI style, not Finnish). | partial |
| W4415551108 | 10.1007/s11192-025-05442-8 | Readability and jargon in successful lay summaries of grant proposals (Hong Kong): high reading levels. Weak support for a "write for the non-specialist panel member" nudge. | partial |

Evidence quality summary: no direct experimental evidence was found that specific phrasing changes in academic cover letters or CVs improve hiring outcomes.
The gender-gap studies (W2995486208, W2978871172, W4381512849) support one careful nudge (see section 5, N4) but only as a non-directive
observation; none supports "use more superlatives". Searches run: gendered language in applications/letters; self-promotion; reference letters;
narrative CV; hedging; cover letters and hiring (the last returned little academic evidence).

## 5. Candidate nudge catalogue (hypotheses for the skill, not yet validated with the user)

All are questions or observations the assistant raises in chat; the user decides and writes.

| # | Nudge | Basis |
|---|---|---|
| N1 | Claim-evidence check: does a evaluative adjective ("strong", "extensive") have an observable fact next to it (number, role, output)? | TENK "truthfully ... verifiable"; edukatesg/UNC-style career guides (secondary) |
| N2 | Own role versus team: is it clear what the applicant personally did? | TENK headings 8, 10 ask for role; career guides |
| N3 | Status words: published, accepted, submitted, planned kept distinct; no "under review" ambiguity. | TENK integrity rule; career guides |
| N4 | Self-description register: flag both inflation (vague superlatives, "passionate") and understatement (hedges such as "helped with", "just", "only", "a little") for the user to weigh against the facts. Do not tell the user which way to move without the facts. | W2978871172, W2995486208 plus Finnish norm against boasting (jobs.ac.uk, secondary) |
| N5 | Cover letter does not repeat the CV: what does the letter add that the CV cannot show? | Several career guides; Helsinki careers service; blog |
| N6 | First sentence and each paragraph leads with its point; one job per paragraph. | Career guides (secondary) |
| N7 | Tailoring: any sentence that could be pasted into another application unchanged? (flag only; user supplies the specific content). | Several career guides; Bluesky post (watershedlab, single anecdote) |
| N8 | Jargon: would a panel member from another subfield follow this? | W4415551108 (weak); UNC via blog (secondary) |
| N9 | Tone consistency, tense consistency, active versus passive voice, consistent date format, spelling of institution names. | General style practice |
| N10 | Length versus the call's limits; organisation instructions override any template. | TENK page; uwasa example |
| N11 | CV formatting against TENK: heading order 1-15 and wording, reverse chronology, official titles, no self-made translations, dates, part-time stated, database named for citation numbers, publication list as appendix with A-I classes, CV date present. | TENK (primary) |
| N12 | Cover-letter and CV consistency (same titles, dates, spelling). | General practice |
| N13 | AI-assisted text: remind that wording is the user's and verifiable; generic LLM-style phrasing is a flag. | Blog snippet only (low authority), see O3 |

## 6. Social search (round 2026-10-30)

`bsky_search` (social-research-search helper), queries "academic job application cover letter tips" and "postdoc application cover letter", since 2025-10-01, English,
top-ranked, 80 posts requested. Result: mostly vacancy announcements; one relevant post
(https://bsky.app/profile/watershedlab.bsky.social/post/3mbm4h3cjzc2m, 35 likes, advice to tailor CV and cover letter to the posting). Mastodon not queried. Conclusion:
social search is low-yield for this topic; a more targeted pass (hashtags such as #academicjobsearch, replies to PI advice threads) is possible but not needed now.

## 7. Open research items

| # | Item | Why |
|---|---|---|
| O1 | CLOSED (R6): chat-only illustrative rewrites. Design: label as example, one sentence, never inserted into files. | |
| O2 | CLOSED: full 2020 PDF read, heading 3 found. The 2026 docx (Dec 2025 "data" wording in heading 9) was not read; use the 2020 wording and say so. | |
| O3 | Find primary evidence on AI-written application documents and recruiter or committee views (OpenAlex found only a 2026 preprint without abstract, W7221038963). | N13 currently rests on a blog. |
| O4 | Check Academy of Finland and Finnish university call instructions for CV and cover letter length or layout limits (varies by call). | N10; template says instructions override. |
| O5 | CLOSED (R7): English only. | |
| O6 | CLOSED (R7): academic only; the skill states industry CVs are out of scope. | |
| O7 | Skill clash check (`check_skill_clashes`) against `manuscript-writing-quarto`, `job-opportunity-watch`, `stats-reporting-and-review`, `openalex`. | Standing repo rule. |
| O8 | CRAN check for a helper: nothing searched yet. Candidates only for mechanical checks (for example `spelling`, `stringr`, `quanteda`/`koRpus` for readability); the assistant could run a read-only flag script. Not researched. | Standing repo rule to check CRAN. |
| O9 | CLOSED (R8): researched in section 9; remaining gaps are O10, O12-O14. | |

## 8. Log

- 2026-10-30: first round. Searches: TENK CV template (web, 3 queries including Academy of Finland/narrative CV and Finnish academic cover-letter tips); OpenAlex (R) 6 topic queries,
  then 5 targeted title queries and 3 more; Bluesky 2 queries. Read ledger conventions from `research/staged-assistant-workflow-ledger.md` and the ownership table in
  `github-skill-maintenance/references/skill-boundaries.md`. No tokens or secrets recorded. No skill files created or edited. Web search budget for the turn was used up (one query left unused).

## 9. Round 2 (2026-10-30): other academic documents (requirement R8)

### 9.1 List of publications and publication-related CV rules

| Source | Status | Facts |
|---|---|---|
| https://www.aka.fi/en/research-funding/apply-for-funding/how-to-apply-for-funding/az-index-of-application-guidelines/list-of-publications/ | read (search snippet) | Research Council of Finland (RCF) list: applicant name and list date; published works and works accepted for publication, sorted by the Ministry of Education and Culture classes A-I; full literature reference (authors, title, publisher); no length limit; public document, no confidential information; no manuscripts not yet accepted; only publications published by the call deadline; journal-based metrics (JIF, JUFO classes, h-index) prohibited and may not be added; file name pattern `publications_RCFyear_surname.pdf`. |
| Same page, classes | read (snippet) | A peer-reviewed scientific articles (doctoral dissertation articles also under G); B non-refereed; C scientific books (monographs only in G if doctoral); D professional-community publications; E general-public publications linked to the research (no letters to the editor, short commentaries, self-published); F artistic/design; G theses; H patents and invention disclosures; I audiovisual and ICT software. |
| https://www.aka.fi/en/research-funding/apply-for-funding/how-to-apply-for-funding/az-index-of-application-guidelines/cv-guidelines-for-academy-research-fellow-applicants/ | read (search snippet; direct fetch gave 404 later) | RCF CV template is based on TENK's. Research output: total number of publications; up to 10 most important with author(s), title, year, series/journal, type, link; no journal rankings, impact factors or citation metrics (h-index) in the CV; justify your role and choice in terms of the project and/or career; full list is a separate appendix. Other research outputs (methods, software, infrastructures, materials, guides, tools, teaching content): up to 10, justify role and choice. |
| https://www.utu.fi/sites/default/files/public:/media/file/Guidelines%20for%20list%20of%20publications.pdf | read (snippet) | University of Turku copy of the same list guidelines; adds "clearly indicate the ten most important publications in terms of the research plan". |
| https://www.abo.fi/en/about-abo-akademi-university/come-work-with-us/instructions-appendices-in-applications-reserach-and-teaching-staff/ | read (snippet) | Abo Akademi: usual appendices CV, full publication list, teaching portfolio; CV follows TENK; extra specifications are in the advertisement; name appendices like "Research plan [Name]". |
| https://www.aka.fi/en/research-funding/apply-for-funding/calls-for-applications/for-researchers/2027-academy-research-fellowships-all-research-fields/ | read (snippet) | 2027 call: the application must say how the research idea differs from the doctoral dissertation; full publication list mandatory. Shows that independence-from-previous-work is an explicit funder criterion. |
| https://libguides.tuni.fi/researchers-guide/impact-and-visibility | read (snippet) | JUFO: from 2026 level 0 is called "other identified publication channels", level 3 discontinued in 2027 (relevant only if a call asks for JUFO). |

Finding (tension to handle, O11): TENK heading 9 suggests naming the "most cited" publications and the database, whereas RCF forbids citation metrics, journal impact factors and h-index in its CV and list. Rule for the skill: the call's instructions win; if the call is silent, mention that metrics are a choice and some funders forbid them. Do not choose for the user.

### 9.2 Teaching portfolio

| Source | Status | Facts |
|---|---|---|
| https://www.utu.fi/en/teaching-portfolio | read (snippet) | Turku: supplements application and CV; presents teaching experience, pedagogical thinking, development as a teacher in the context of the open position; author must verify information if asked; "comprehensive, short and concise"; required for teaching-focused positions. |
| https://www.jyu.fi/en/file/university-of-jyvaskylas-instructions-for-the-teaching-portfoliopdf | read (snippet) | Jyvaskyla: 2-3 pages; written from the perspective of the position; sections for pedagogical thinking and training, teaching and supervision experience, contribution to teaching development, teaching competence evidence; at most three samples with reasons for choosing them. |
| https://www.aalto.fi/sites/default/files/2024-04/Teaching-competence-assessment_Guidelines-for-a-candidate_2024_Aalto-University.pdf | partial (snippet; fetch gave 406) | Aalto: portfolio as a narrative text, follow the given structure, includes formal pedagogical studies (credits, where, when), experience and approach in developing teaching. |
| https://www.helsinki.fi/en/about-us/careers/open-positions/instructions-applicants-teaching-and-research-positions | read (full page via webfetch summary) | Helsinki "academic portfolio" 4-7 pages plus enclosures; example structure: 1 basic information, 2 research and scientific activities (incl. research philosophy and ethics, visions and development plans), 3 teaching and supervision (incl. strengths, development challenges and visions), 4 administration and other activities. Units may set their own rules; the page gives no style guidance, no research-plan guidance. |
| https://www.abo.fi/wp-content/uploads/2019/05/academic_portfolio.pdf | read (snippet) | Abo Akademi academic portfolio: teaching sections list pedagogical training, teaching experience (extent, time, level, forms), teaching material, IT use, assessment, prizes with a short explanatory statement, international cooperation. |
| https://www.uniarts.fi/en/guides/instructions-for-compiling-a-teaching-portfolio/ | read (snippet) | Uniarts Helsinki: 5-10 pages, reflect and justify teaching choices, give concrete examples of how the approach supported students' learning, add table of contents and numbered appendices. Older (about 2020), arts context. |
| https://ulapland.fi/en/university/work-with-us/ | read (snippet) | Lapland: teaching merits to be shown in a teaching portfolio per university guidelines; also lists a trial lecture. |

Patterns across Finnish portfolios (usable as style checks): length differs widely (2-3 pages at Jyvaskyla, 4-7 at Helsinki incl. research, 5-10 at Uniarts), so the call/unit instructions decide; written in the first person as narrative; written for the position; concrete examples and evidence rather than statements of philosophy; reflection including development areas; claims verifiable (Turku); TENK heading 11 asks for "carefully selected" teaching merits.

### 9.3 Research statement / research plan

All sources below are generic career-advice pages (university career offices and commercial services), not Finnish and not primary research. Treat as low-to-medium authority; use only where several agree.

| Source | Status | Facts |
|---|---|---|
| https://gradschool.cornell.edu/career-and-professional-development/pathways-to-success/prepare-for-your-career/take-action/research-statement/ | read (snippet) | Avoid jargon, write clearly, concisely, concretely; summary level; ask people inside and outside the field to read; flags overly ambitious proposals, lack of clear direction, lack of big-picture focus, little attention to the department's needs; use language showing independence. |
| https://www.cmu.edu/student-success/other-resources/handouts/comm-supp-pdfs/writing-research-statement.pdf | read (snippet) | One to three pages; busy readers, so state the bottom line first; trajectory past, current, future with the main focus on the future. |
| https://manusights.com/resources/research-statement-guide | read (snippet) | Commercial. Lead with the finding, not the tool; define acronyms; active voice; avoid hedging such as "this may potentially suggest"; no independence from mentor is a flaw; vague aims; generic openers; over-length. |
| https://customuniversitypapers.com/research-statement/ | read (snippet) | Commercial/low authority. Contribution statements versus activity statements; avoid "I hope to explore" language; two register errors: false modesty and unfounded grandiosity (the same pair as nudge N4); distinguishes "research statement" (retrospective plus prospective) from "research proposal" (prospective, with methods and timeline): check which one the call wants. |
| https://casrai.org/guides/how-to-write-a-research-statement-for-a-faculty-application | read (snippet) | Past-present-future; length by field; write for generalists; common mistakes: front-loading the past, no independence signal, too many projects, ignoring fit, jargon. |
| https://www.alfredscholar.com/blog/how-to-write-a-research-statement-for-the-academic-job-market/ | read (snippet) | Commercial. First person, active voice, avoid vague plans, proofread; advice that "at least half" is future (a rule of thumb from one source, not general). |

Nudges derived (to add to section 5, all chat-only):

| # | Nudge | Basis |
|---|---|---|
| N14 | Research statement: is the future part visible and specific (a question or aim, not "I will continue to study X")? Is the balance between past and future a conscious choice? | Cornell, CMU, Casrai, others agree |
| N15 | Independence signal: could a sentence appear unchanged in the supervisor's grant? Where is "I" versus "we"? (Funders ask it explicitly: RCF 2027 fellowships.) | RCF call text; career guides |
| N16 | Lead with the finding or question rather than the method or the credentials; contribution sentences versus activity sentences. | Manusights, customuniversitypapers, Cornell |
| N17 | Hedging sweep ("may potentially", "I hope to", "I would like to"): flag for the user to weigh against actual uncertainty; do not push toward overclaiming. | Manusights, customuniversitypapers; pairs with N4 |
| N18 | Define acronyms on first use; check for the "other-subfield reader". | Several |
| N19 | "Statement" versus "proposal": check the call's document type, length and required headings first. | customuniversitypapers; Vaasa research plan 5-10 pages with listed headings |
| N20 | Teaching portfolio: written for this position; concrete examples of how the approach worked; reflection including development areas; selected merits only; first-person narrative. | Jyvaskyla, Aalto, Turku, Uniarts; TENK heading 11 |
| N21 | List of publications: format checks only (classes A-I, complete references, list date and name, no unaccepted manuscripts, metrics only if the call allows, consistent reference style); mark "ten most important" only if requested. | RCF guideline; Turku |
| N22 | CV "ten most important" publications: is the reason for the choice (role, relevance) stated if the call asks for justification? | RCF CV guidelines |

Evidence note: for 9.3 no primary research was searched; the OpenAlex studies in section 4 only support N4 and N8 weakly (O12).

### 9.4 New open items

| # | Item |
|---|---|
| O10 | Check the current Academy CV guidelines URL (fetch returned 404) and whether a 2027 version exists; metric ban and justification rules may have changed. |
| O11 | Treat the TENK/RCF metrics tension (9.1): the call wins; if silent, tell the user metrics are a choice. |
| O12 | Optional OpenAlex pass on grant/proposal language (hedging, readability, novelty words) only to calibrate N17/N8 wording, not to cite. |
| O13 | Read the Aalto portfolio PDF and the RCF CV page in full (both failed to fetch). |
| O14 | Check job ads from 2-3 Finnish universities for what each asks (CV, list, research plan, portfolio) to give the skill a "what calls usually want" table. |

### 9.5 Log (round 2)

- 2026-10-30 (round 3, see section 10 for facts): closed O2, O4, O10, O13 (partly), O14, O8 and O3 (partly); details below.
- 2026-10-30: user answered R6-R8. TENK 2020 PDF downloaded with curl into git-ignored `tmp-examples/`, text extracted with `pdftools::pdf_text`, all 7 pages read (webfetch only returns raw binary for this PDF). Web searches: Academy of Finland list of publications, Finnish teaching portfolio guidelines, research statement guidance. Fetches: aka.fi CV guidelines (404), Helsinki instructions (ok), Aalto portfolio PDF (406). Temp files deleted after the round. No tokens or secrets recorded. No skill files created.

## 10. Round 3 (2026-10-30): revised TENK files, Academy CV page, real Finnish calls, CRAN helpers

### 10.1 Revised TENK files (closes O2)

TENK page links (found by scraping the page HTML with curl): `.../sites/default/files/2026-04/TENK_CV_template_2020_10.4.2026.docx` and `.pdf` (current), and `.../2025-12/TENK_CV_template_2020.docx` and `.pdf` (December 2025 version). Both docx files were downloaded and their paragraph text extracted with `xml2` (`word/document.xml`). Result:
- The 2026-04 file differs from the 2025-12 file by exactly one paragraph: a new notice that from April 2026 a CV in this template can be downloaded from the researcher's expert profile in the Research.fi service (https://research.fi/en/mydata). No heading or bullet changed between them.
- Heading 9 in both: "Total number of publications and for example the ten most important and/or most cited publications (identify the database); links to open-access publications; list of publications categorised according to the classification by the Ministry of Education and Culture as a separate appendix" / "Methods, software, infrastructures, data, materials, guides and tools developed" / "Patents and inventions" / "Most significant artistic works and processes". So the December 2025 change is the word "data" in the second bullet (confirmed).
- All other headings and wording match the 2020 PDF text read in round 2 (headings 1-15 unchanged).
- Local files were in the git-ignored `tmp-examples/` and are deleted after this round.

### 10.2 Research Council of Finland (closes O10, most of O13)

| Source | Status | Facts |
|---|---|---|
| https://www.aka.fi/en/research-funding/apply-for-funding/how-to-apply-for-funding/az-index-of-application-guidelines/cv-guidelines-for-academy-research-fellow-applicants/ | read (search result text; the page is the same URL that gave 404 on direct fetch earlier) | CV template based on the TENK template; "should not give journal rankings, journal impact factors or citation metrics (h-index)"; write on the RCF Word/LaTeX template; text must not exceed three pages; no images or photographs; follow the given instructions and structure for equal treatment; PDF named `cv_RCFyear_surname.pdf`; include the headings necessary for the call type, review and own career development; only merits achieved by the call deadline. The RCF headings list has no separate headings for other education, language skills, career breaks or awards (a reduced set compared with TENK's 15). |
| https://www.aka.fi/en/research-funding/apply-for-funding/how-to-apply-for-funding/az-index-of-application-guidelines/merits-and-increased-competencies-academy-research-fellowship/ | read (search result text) | "Merits and increased competencies" is essentially a narrative CV: up to 2 pages on the personal research career path with concrete examples, plus 1 page with up to ten most important publications or other outputs; total 3 pages; no journal rankings, JIF or citation metrics; consider collaboration, mobility, data sharing, team building, supervision and teaching, expert positions, impact. |
| https://www.aka.fi/en/research-funding/apply-for-funding/frequently-asked-questions-about-the-winter-call/ | read (search result text) | 2027 winter call: no separate CV template for Fellowship applicants (same as Project applicants); the merits template was revised; "use the latest templates". |
| https://www.aka.fi/en/research-funding/apply-for-funding/calls-for-applications/for-researchers/2027-academy-research-fellowships-all-research-fields/ | read (search result text) | Application should preferably be written in English; CV is a public document (Finnish Act on the Openness of Government Activities) and must contain no non-disclosable information; review factors include clarity and credibility of the career plan and how the idea differs from the doctorate. |

RCF page ages differ (the CV guideline page is dated about 20 months ago in the search index); the skill must tell the user to check the current call and template. An older Academy page (about 6 years) said the CV was at most two pages; that is outdated.

### 10.3 Real Finnish calls (closes O4 and O14)

| Call | Status | Documents and limits asked |
|---|---|---|
| University of Helsinki, three tenure-track assistant/associate professors, HiLIFE (the example the user gave), deadline 16 Nov 2026 | read (webfetch summary of the vacancy page) | One single PDF; motivation letter max 1 page; CV including teaching experience (format not specified, TENK not mentioned); publication list max 20 items with five highlighted key publications and a brief summary of their importance at the top, plus ORCID; research plan max 2 pages excluding references (acts as research statement); no separate teaching portfolio (teaching shown in the CV); whole package max 10 pages, other attachments not considered; criteria: scientific excellence, early-career track record, external funding, readiness for independence; shortlisted: external referee statements, interview, research seminar, teaching demonstration. **It states that AI-generated applications do not meet expectations and applicants should write their own application.** |
| Aalto University tenure-track ad 2024 (https://bridgingtransport.org/job-board/assistant-professor-transportation-engineering/ mirror; Aalto original not re-fetched) | read (search result text) | Cover letter max 2 pages (summary of merits, key achievements, motivation); CV covering the major TENK headings, complete publication list, 2-4 referees; five most significant publications in full text; research portfolio max 5 pages (past research, future plans, emerging issues); teaching statement max 2 pages; all in English; PDFs named `documentname_lastname_firstname.pdf`; teaching portfolio later for shortlisted. |
| Aalto 2025 strategic-management ad (https://www.aalto.fi/en/open-positions/assistant-or-associate-professor-tenure-track-in-strategic-management) | read (search result text) | Single PDF `lastname_firstname_application.pdf`; cover letter; CV with the TENK sections "though it does not need to follow this format"; publication list with most significant highlighted; research portfolio 4-10 pages (reflection on merits, long-term vision, research plan); teaching portfolio per Aalto guidelines; job market paper; four referees. |
| Aalto general tenure-track instructions (https://www.aalto.fi/en/tenure-track/interested-in-joining-our-tenure-track) | read (search result text) | Candidates follow responsible conduct of research; use TENK CV template; submit only documents requested in the ad; no sensitive personal data (health, religion, political opinions, family circumstances); all material in English. |
| University of Turku tenure-track instructions 2025 (https://www.utu.fi/sites/default/files/public:/media/file/Guidelines%20and%20information%20about%20applying%20and%20recruitment%20of%20professors%202025.pdf) | read (search result text) | CV (for example TENK) with clear reporting of career breaks; selected numbered publications (max 10); research plan about 3 pages; teaching portfolio per Turku guidelines (max 25 MB); size limits per file. |
| Tampere University tenure-track ad (via Glassdoor listing) | partial (search result text) | CV; letter of motivation max 2 pages on why suited and how the applicant would develop research and teaching; profile alignment with university strategy. |
| University of Turku Futures Studies tenure-track ad (https://ats.talentadore.com/apply/tulevaisuudentutkimuksen-apulaisprofessorin-tenure-track-tehtava/ZLnKbg?lang=en) | read (search result text) | Merits and Finnish-language requirement are stated in the ad; shows that ad text sets the criteria the letter should address. |

Findings for the skill:
1. Limits differ strongly (cover letter 1 page at Helsinki, 2 pages at Aalto/Tampere; research plan 2, 3 or 5-10 pages; Helsinki caps the whole package at 10 pages). The skill must read the user's actual call first and measure documents against it; its own numbers are examples only.
2. Many calls say the CV "should follow" or "may follow" TENK; one (Helsinki HiLIFE) does not mention it. The skill must not insist on all 15 headings when the call says otherwise: TENK is the default for a CV when a call names no format.
3. "Highlighted key publications with a short summary of importance" (Helsinki) and "justify role and choice" (RCF) both ask for a short justification, which is a phrasing task (own role and relevance, not impact claims).
4. Tension on sensitive data: TENK heading 7 career breaks are optional and Turku wants clear reporting, while Aalto says not to include family circumstances. Rule: the call's instruction wins, otherwise it is the user's choice; mention the trade-off, do not decide.
5. AI: a major Finnish ad states AI-generated applications do not meet expectations, which supports a strict "assistant does not draft, user writes" design and a reminder in the skill (closes O3 partly: employer statement found, no systematic evidence).

### 10.4 CRAN check for helpers (closes O8)

Checked 2026-10-30 with `available.packages()`: `spelling` 2.3.2 (installed), `hunspell` 3.0.6, `stringi` 1.8.9 (installed), `quanteda.textstats` 0.97.2, `koRpus` 0.13-9, `officer` 0.7.7, `docxtractr` 0.6.5, `pdftools` (installed). `readability` and `textstat` are not on CRAN. Decision: the optional flag script uses base R plus `stringi` (word and sentence splitting), `xml2` for docx text (already used above, no `officer` needed) and `pdftools` for PDF text; no new dependency. Spelling stays with `spelling`/`hunspell` as in `manuscript-writing-quarto` (pointed to, not copied). Readability indices are not used: no evidence was found that they are valid for application documents and they would push towards content changes. The script only flags; it never writes into the user's document.

### 10.5 Open after round 3

| # | Item |
|---|---|
| O15 | Helsinki ad read only through a webfetch summary; the vacancy page may contain further wording (for example about references or the research seminar). |
| O16 | Aalto originals and the Tampere ad were seen as search-result text or mirrors, not re-fetched. |
| O17 | Call limits are time-bound; the skill treats them as examples only. |
| O12 | OpenAlex pass on proposal language still not done (optional). |

## 11. Round 4 (2026-10-30): Finnish-language resources, PDF export, LLM-wording guard

### 11.1 New requirements (user, 2026-10-30)

| # | Requirement |
|---|---|
| R9 | Look for Finnish-language resources for the research statement. Add a caveat (skill and also `job-opportunity-watch`): although the material is in English, research in the language of the target country for more specific wording and extra resources; the user has often found local-language material more informative than the English translation. |
| R10 | Export target for CV, research statement etc. is PDF. |
| R11 | Guards so the assistant never suggests LLM-specific wording or style. |

### 11.2 Finnish-language sources found (research plan = tutkimussuunnitelma)

Finnish terms searched: tutkimussuunnitelma ohjeet, tutkimussuunnitelman rakenne, opetusportfolio ohje, hakemuskirje/motivaatiokirje. Status "read (snippet)" = search result text.

| Source | Status | Facts |
|---|---|---|
| https://www.aka.fi/tutkimusrahoitus/hae-rahoitusta/nain-haet-rahoitusta/ohjehakemisto/tutkimussuunnitelma/2022/tutkimussuunnitelman-rakenne--akatemiatutkija/ (Suomen Akatemia, 2022 version, Academy Research Fellow) | read (snippet) | Plan as PDF appendix; max 12 pages; Source Sans Pro 12 pt, spacing 1, margins 20 mm, A4; in-text references only (author, year or [number]), no footnotes; headings must not be edited and the application cannot be submitted if the system finds page or structure errors; "describe the parts as applicable according to the practice of your own discipline"; five numbered sections (Tarkoitus ja tavoitteet, Toteutus, Hakija ja yhteistyötahot, Vastuullinen tiede, Yhteiskunnalliset vaikutukset), reference list counts towards the length in 2022 but not in the older 2021 version (max 2 pages excluded). Older versions differ by year: fonts and spacing change (Times New Roman 12 pt/1.15; Calibri/Carlito 12 pt in ICT 2023). |
| https://www.aka.fi/en/research-funding/apply-for-funding/how-to-apply-for-funding/az-index-of-application-guidelines/research-plan-structure/2022/structure-of-research-plan-projects/ (English counterpart) | read (snippet) | Same limits and font; the English snippet shows the same rules, so no systematic divergence was found for this page. This is a sample of one page; the user's experience that local-language pages are more detailed was not disproved. |
| https://www.helsinki.fi/assets/drupal/2026-03/OneHealth_Ohjeita_tutkimussuunnitelman_laatimiseen_0.pdf (University of Helsinki doctoral programme, March 2026, Finnish) | read (snippet) | Per-field character limits (2000, 3500, 1500, 2500 characters); evaluation criteria listed (scientific quality, suitability of methods, novelty, feasibility, fit with programme, realistic funding, readiness to develop into an independent researcher); advice to avoid unnecessary repetition and keep each section within its field; **section 12 "Tekoälyn käyttö hakemuksessa": if AI tools were used in preparing the application, briefly describe how**. English version not checked. |
| https://blogs.helsinki.fi/strahasto/apurahan-hakeminen/tutkimussuunitelma-ohje/ (Helsinki funding office, updated 1 Feb 2026) | read (snippet) | Plan max 8 pages including references (A4, spacing 1, font 12); sections summary, design/questions/methods/materials, researchers; points to Kai Hakkarainen (2014) guide on the structure and content of an academic research plan (lead only; not read). |
| https://www.utu.fi/sites/default/files/public://media/file/TUTKIMUSSUUNNITELMAOHJE%20OPPI2024_0.pdf (Turku, OPPI doctoral programme, 2024) | read (snippet) | 10-12 pages, 4,500 words including tables and sources; page budget per section; not following the instructions may lead to rejection; if the thesis is written in English the plan should be too. |
| https://www.utu.fi/sites/default/files/public:/media/file/Vaitoskirjan_tutkimussuunnitelma_ohje.pdf (Turku law, doctoral plan) | read (snippet) | Plan is written for an expert evaluator and must show that the project is scientifically interesting, meaningful and feasible and that the applicant has the capability; 20,000 characters, 1,000-character summary. |
| https://content-webapi.tuni.fi/proxy/public/2022-12/met-tutkimussuunnitelmaohje-paivitetty-syksy-2020.pdf (Tampere MET) | read (snippet) | Plan may be written in Finnish or English; structure with background, aims and significance, methods ("principle, no technical details", justify method choices), schedule, ethics, references. |
| https://www.uniarts.fi/app/uploads/2019/11/e95d0afb-tutkimussuunnitelmaohje-tutkijakoulutus-siba.pdf (Uniarts, 2019) | read (snippet) | Research question at most one sentence; keep the plan no longer than necessary. |
| https://mehu.site.jyu.fi/fi/tutkimusprosessi/tutkimuksen-suunnittelu (Jyvaskyla, methodology portal) | read (snippet) | Key points in a plan: clear structure, good language, consistency; structure varies by topic; a short timed work plan. |
| https://www.aka.fi/tutkimusrahoitus/hae-rahoitusta/nain-haet-rahoitusta/ohjehakemisto/tutkimussuunnitelma/2022/tutkimus--ja-vuorovaikutussuunnitelma-strategisen-tutkimuksen-varsinainen-haku/ | read (snippet) | Strategic Research Council plans are written in English because reviewers are from different fields and countries (shows that the language of the plan is set by the call). |
| https://akatemianjalkavaki.fi/2019/03/22/portfolio-omien-vahvuuksien-tunnistamisen-tukena/ (Finnish researcher-union blog) | read (snippet) | Teaching portfolio: not only to show excellence but development, learning and change as a teacher; student feedback and how it changed the teaching; recommended length 5-10 pages (varies). Secondary source. |
| https://www.ulapland.fi/FI/Yksikot/Taiteiden-tiedekunta/Hallinto/Opetusportfolio-ohje (Lapland arts faculty) | read (snippet) | Finnish guiding questions for the teaching portfolio ("what did I learn from it?", "what feedback have I received?"); portfolio is a public description and must be verifiable on request. |
| https://studies.helsinki.fi/system/files/inline-files/Ty%C3%B6nhaun-opas_A5.pdf (Helsinki career services job-search guide, Finnish, older) and https://www.utu.fi/en/research/utugs/for-doctoral-researcher/career (Turku, English) | read (snippet) | Cover letter one page, tailored, shows motivation and understanding of the organisation, avoid clichés; do not repeat the CV. These are general (non-academic leaning) and agree with the English guidance. |
| Commercial Finnish sites (cvapp.fi, livecareer.fi, cvpohjat.fi and similar) | search (snippets only) | Generic and partly machine-translated style; low authority, not used. |

Findings:
1. Finnish pages exist for each document and are specific about format (fonts, pages, headings that must not change, no footnotes, in-text references); English pages mostly mirror them, but many university and programme guides (for example the Helsinki doctoral programme guide with an AI-use section) were found in Finnish only. Consistent with the user's experience; the skill gets a standing caveat to check the local-language material, with a short glossary.
2. The Academy's rules change by year and scheme (fonts, line spacing, whether references count towards pages); always use the current call's template.
3. A programme-level guide can ask the applicant to state how AI was used in preparing the application (Helsinki, 2026). Another ad (HiLIFE) says AI-generated applications do not meet expectations. So AI rules vary by call; the assistant must tell the user to check and never decide.
4. Hakkarainen (2014) is a known Finnish guide for plan structure; not read, only a lead (O18).

### 11.3 PDF export (R10)

| Source | Status | Facts |
|---|---|---|
| https://www.aka.fi/en/research-funding/apply-for-funding/how-to-apply-for-funding/az-index-of-application-guidelines/research-security/ | read (snippet) | "Save the appendix in PDF format. Do not 'print to PDF' as it makes it more difficult to process the attachment." (stated for the research-security appendix; likely applies to RCF attachments but the page says so for that one). Also file naming rules (`research security_<number>_<year>_<surname>.pdf`). |
| RCF CV and plan pages (see 10.2, 11.2) | read (snippet) | PDF appendices; templates in Word or LaTeX; named files; the system rejects page or structure errors; no images in the CV. |
| University of Turku tenure-track instructions (see 10.3) | read (snippet) | File size caps per document (5 MB; 25 MB for the portfolio). |
| Helsinki HiLIFE and Aalto ads (see 10.3) | read | One single PDF; Aalto file naming patterns. |
| https://cihr-irsc.gc.ca/e/29300.html | read (snippet) | Not Finnish. Example of another funder: attachments uploaded as unprotected PDF, minimum font size, size limit per file; included only to show that unprotected/size rules are common. |

PDF checks derived (mechanical, read-only): page count and page size (A4) measured in the PDF itself, fonts embedded, text selectable (not a scan), file size, no encryption or password, document title/author metadata not leaking old file names or other names, file name per call, links working (ORCID, DOI, OA links), single PDF when the call says so, name and page numbers on every page when documents will be merged. No source for PDF/A was found, so the skill does not claim it is required.

### 11.4 LLM-style guard (R11)

Basis: the user's rule, plus the two Finnish calls that restrict or require disclosure of AI use (11.2), plus the HiLIFE statement. No research on detectability of LLM text was searched, and the skill must not claim that any phrase proves AI authorship. The guard is about the assistant's own suggestions: do not offer wording or structures typical of LLM output, which reads as generic boilerplate to a panel and works against the call rule "write your own application". Patterns to avoid in examples (judgement, not evidence): stock words (delve, leverage, tapestry, testament, realm, landscape, spearhead, foster, underscore, pivotal, vibrant, showcase, multifaceted), "not only X but also Y" constructions, triplets in every sentence, stacked transition adverbs (Moreover, Furthermore, Additionally, In conclusion), em dashes used for rhythm, bold lead-in bullets, symmetric uniform sentence length, formulaic openers and closers ("I am excited to", "I look forward to the opportunity to"), flattering adjectives ("passionate", "dynamic"). Positive rule: mirror the user's own vocabulary, sentence length and register; use plain concrete verbs and nouns; keep examples short and fact-bound; if a suggestion cannot be built from the user's own words, give the question instead of an example.

### 11.5 Open after round 4

| # | Item |
|---|---|
| O18 | Read Hakkarainen (2014) research plan guide (Finnish) if it can be found openly. |
| O19 | Compare more Finnish and English versions of the same call or guide systematically (only one Academy page pair was compared). |
| O20 | Teaching portfolio Finnish guides (Turku, Jyvaskyla originals) were seen as snippets only. |
| O21 | Check whether Finnish-language versions of the Helsinki HiLIFE-type ad contain extra requirements (the user's local-language caveat). |

## 12. Round 5 (2026-10-30): role scope (postdoc and tenure track) and role-specific advice

### 12.1 Requirements added

| # | Requirement |
|---|---|
| R12 | (2026-10-30) The skill serves **postdoc** and **tenure-track / faculty** applications only. Future research for the skill must **ignore advice written specifically for doctoral (PhD student, doctoral candidate, graduate programme) positions**. |
| R13 | (2026-10-30) Sweep for role-specific info; search with alternative names: assistant / associate professor, tenure-track, faculty, junior/early-career PI; postdoctoral researcher / fellow / tutkijatohtori. |

Role names used for searching: tenure track assistant professor, tenure-track associate professor (Finland: apulaisprofessori, nuorempi apulaisprofessori, "tenure track -tutkija", tenure track level 2/3), faculty position, assistant/associate professor, postdoctoral researcher / fellow, Academy Research Fellow, tutkijatohtori. Searches that return doctoral-position advice are discarded (R12).

### 12.2 Sources

| Source | Status | Role | Facts |
|---|---|---|---|
| https://www.mordecailab.com/blog/2021/10/11/how-to-apply-for-a-tenure-track-faculty-job-in-ecology | read (snippet) | TT | Package: cover letter, research and teaching statements, CV, (DEI), letters. Cover letter short (1 to 1.5 pages); research statement 2-3 pages organised around 2-3 big questions; teaching statement 1-2 pages. Author's view: research statement is the most important. Opinion, US. |
| https://www.sciencedirect.com/science/article/pii/S0962892422000095 | read (snippet) | TT | Research statement ~3-4 pages (also "1 to 3"); committees want an independent, fundable vision for 5 to 10 years; extending only the postdoc work is a disadvantage; avoid jargon; teaching statement should make explicit what one could teach; cover letter school-specific, 1-2 pages. |
| https://casrai.org/guides/how-to-write-a-research-statement-for-a-faculty-application | read (snippet) | TT | Past-present-future with largest weight on future; independence from the former advisor's programme; institutional fit; generalist readers; mistakes: front-loading the past, too many projects, jargon, unadapted reuse. Commercial guide. |
| https://postdocs.cornell.edu/postdoc-careers/academic-job-search/research-statement/ | read (snippet) | TT | Realistic, readable agenda fitting the department; point to possible collaborators in the department; avoid over-ambition. |
| https://www.embl.org/files/wp-content/uploads/research-assessment-cover-letter-tips.pdf | read (snippet) | postdoc and faculty | Distinguishes the two. Postdoc letter: skills and experience relevant to the lab, signal independence, collaboration, finishing projects, propose a project direction (esp. unsolicited), "why this lab". Faculty letter: short preview of the research statement, track record, funding record, fit to institute and collaborators, link to teaching statement. Do not copy template wording. |
| https://astrobites.org/2022/08/03/guide-to-postdoc-apps-part2/ | read (snippet) | postdoc | Field-specific (astronomy). Research statement is the main document; cover letter at most 1 page; fit to institution's people and tools. Its advice to "hype up" work conflicts with the TENK integrity rule: do not pass that on. |
| https://math.berkeley.edu/~katrin/slides/Williams-FindingJob.pdf | read (snippet) | postdoc (maths) | Cover letter minor, research statement ~5 pages for a general reader, teaching statement matters little for a postdoc. Slides, 2013, one field. |
| https://theprofessorisin.com/2013/05/28/the-postdoc-app-how-its-different-and-why/ | read (snippet) | postdoc (humanities) | Postdoc judged on whether the work plan gets finished in the time: a timeline of what is completed when. "Statement of interest" is ambiguous, ask the recruiter what is wanted. Commercial. |
| https://www.goldbio.com/blogs/articles/a-detailed-guide-to-your-postdoc-application-plus-printable-companion-checklist | read (snippet) | postdoc | Cover letter 1 page, tailored; may address a gap briefly; research statement past, present, future. Company blog. |
| https://www.hanken.fi/en/faculty-staff/job-opportunities/job-opportunities/hankens-tenure-track-system/research-track-0 | read (snippet) | TT, Finland | Assistant professor (level 2): TENK-based CV with publication list, personal statement (research, impact, service, societal impact; written for the announced position), up to five publications incl. a job-market paper, teaching portfolio, three reference letters. Research weighted above teaching, then service and societal impact. Fixed term 5 (+2) years. |
| https://oulunyliopisto.varbi.com/en/what:job/jobID:705153/ (and 595177) | read (snippet) | TT, Finland | Cover letter stating the career level to be evaluated at; TENK CV; Academy-format publication list with ten marked; research and action plan (2 pages); teaching account (1 page assistant, 2 associate); doctorate within the last ten years for assistant level. |
| https://academicpositions.com/ad/university-of-jyvaskyla/2026/assistantassociate-professor-tenure-track-in-art-research/248482 | read (snippet) | TT, Finland | Cover letter max 2 pages; research plan max 4 pages incl. leadership and funding; teaching portfolio per guidelines; societal interaction evidence max 2 pages. |
| https://www.utu.fi/en/research/researcher-career | read (snippet) | postdoc and TT, Finland | Turku four-stage model; evaluation in research, teaching, academic leadership and societal interaction, overall. Postdoc stage: independent research, teaching skills. |
| https://en.wikipedia.org/wiki/Academic_ranks_in_Finland | meta | titles | Finnish titles: apulaisprofessori, nuorempi apulaisprofessori, tenure track -tutkija for assistant professor; tutkijatohtori for postdoc; translations vary. |
| https://www.aka.fi/en/research-funding/apply-for-funding/calls-for-applications/apply-now2/2026-academy-research-fellowships-all-research-fields/ | read (snippet) | postdoc and early PI funding | Academy Research Fellowship needs research plan, CV, "merits and increased competencies" appendix on templates; those in a fixed-term tenure track can apply. |

### 12.3 Findings that shaped the skill

- Postdoc vs faculty differ in what the cover letter and statement must show: postdoc = fit with a lab or project, skills, ability to finish; faculty = independent, fundable programme, funding record, department fit, teaching. Teaching matters little for most postdocs, much for tenure track.
- The faculty research statement is weighed on the future section and on independence from the postdoc supervisor; judged by a mixed panel, so jargon is a recurring flag.
- Finnish tenure-track calls ask for the career level to be named in the letter, a TENK CV, an Academy-format publication list with highlights, a research plan, a teaching portfolio and sometimes societal-interaction evidence; limits differ per call.
- Most advice found is US, commercial or blog-level and field-specific; none is a peer-reviewed study. Advice to "hype" results conflicts with TENK integrity wording.
- No doctoral-position material was used.

### 12.4 Open after round 5

| # | Item |
|---|---|
| O22 | Postdoc advice is mostly field-specific (astro, maths, humanities); no Finnish postdoc-ad sample set was read beyond Turku and the Academy. |
| O23 | Finnish-language tenure-track guides (tutkijatohtori, apulaisprofessori) not searched yet (extends O19 to O21). |
| O24 | Hanken, Oulu and Jyvaskyla pages seen as snippets only. |
| O25 | Search limit hit (4 searches in the round), so sweeps on associate professor and "junior group leader" names are not done. |

### 12.5 Round 6 (2026-10-30): source-quality rules, Finnish-language sweep, associate professor, junior group leader

New requirements:

| # | Requirement |
|---|---|
| R14 | (2026-10-30) Ignore US-specific guidance (general-purpose guidance is fine). Project-wide, now in `AGENTS.md`. |
| R15 | (2026-10-30) Ignore commercial sites (often snake oil). Project-wide, now in `AGENTS.md`. |
| R16 | (2026-10-30) Ignore sites with clear signs of LLM-generated text. Project-wide, now in `AGENTS.md`. |

Retroactive screening of section 12.2 (round 5) against R14 to R16. These rows are **not to be used** as support in the skill:

| Source | Verdict | Reason |
|---|---|---|
| hiration.com (assistant professor cover letter) | skipped: commercial, LLM-like, US | Resume-service product page, templated sample. Not read for facts used. |
| resumeoptimizerpro.com (TT, NTT, postdoc cover letters) | skipped: commercial, LLM-like, US | Resume-optimizer vendor; invented-looking sample letters with US grants. Its page-length figures were not used. |
| goldbio.com (postdoc guide) | skipped: commercial, US | Reagent company blog. |
| besteditproof.com (postdoc cover letter) | skipped: commercial, LLM-like | Editing service, generic filler. |
| casrai.org research statement guide | skipped: commercial, LLM-like | Reads as templated generic guide with US NIH framing; the "future-direction largest, independence from advisor" point is also in the Cell Press piece, so nothing is lost. |
| theprofessorisin.com | skipped: commercial, US | Paid coaching business, US humanities. |
| astrobites, Berkeley maths slides, Mordecai Lab, Cornell, Harvard postdoc office, MIT CommKit | US-specific | Kept only as general observations that are also in non-US sources (EMBL, Cell Press piece); not cited for US norms (Interfolio, R1/SLAC, NSF/NIH, DEI statement, teaching evaluation scores). |
| bestresumehelp.com, grantbite.com (appeared in round 6 searches) | skipped: commercial, LLM-like | Vendor pages. |
| Kept as acceptable | read | EMBL Fellows Career Service (intergovernmental institute), Cell Press Trends article (peer reviewed, US-based authors but general), university and funder pages (Hanken, Oulu, Jyvaskyla, Tampere, Turku, Helsinki, Aalto, Research Council of Finland, TENK). |

Round 6 sources (all non-commercial primary pages; job-board mirrors such as duunitori.fi, jobly.fi, academicpositions.com are used only as mirrors of the university ads and marked "mirror"):

| Source | Status | Role | Facts |
|---|---|---|---|
| https://www.aka.fi/tutkimusrahoitus/hae-rahoitusta/nain-haet-rahoitusta/ohjehakemisto/tutkimussuunnitelma/2020/tutkijatohtorit-ja-kliniiset/ (Finnish) | read (snippet) | postdoc funding | Research plan max 12 pages unless the call says otherwise; Times New Roman 12 pt, line spacing 1.15, 20 mm margins; sections on significance and state of the art, methods and data, research environment, applicant merits relevant to the project, own career and independence, ethics, data management, societal impact. Academy format (2020 version; check the current call). |
| https://www.aka.fi/tutkimusrahoitus/hae-rahoitusta/haut/haut/tutkijatohtorin-tehtava-kaikki-tutkimusalat/ (Finnish) | read (snippet) | postdoc funding | Special weight on the international dimension, collaborators and their merits described in plan section 3.2, mobility requirement (at least 6 months after the doctorate, justified), CV max 2 pages on the template, abstract max 2500 characters, public description 1000 characters in English and Finnish or Swedish, research plan max 12 pages. The application is a public document except the research plan, abstract and similar; the CV must not contain confidential information. Assessment: scientific quality and novelty, applicant competence, feasibility incl. ethics, research environment and networks. |
| https://ats.talentadore.com/apply/tutkijatohtori-korkeakoulututkimus/8R25l0 (mirror of a Finnish ad) | read (snippet) | postdoc ad | CV per TENK where possible; free-form cover letter 1 page; Academy-format numbered publication list; research description max 2 pages (methods, theory, background); highest degree certificate. |
| JYU postdoc ads (duunitori.fi, jobly.fi mirrors; Finnish) | read (snippet, mirror) | postdoc ads | Cover letter up to 2 pages with research interests, career goals, experience and merits in relation to the qualifications; numbered Academy-format publication list; degree certificate; research plan not mandatory in these examples; some ads require an ORCID profile. Limits differ even within one university. |
| https://www.lastentautientutkimussaatio.fi/wp-content/uploads/2018/02/Ansioluettelomalli.pdf (Finnish) | read (snippet) | CV | Older Finnish CV guide of a foundation; lists career stage "tutkijatohtori (post doc)" among the career stages; same logic as the TENK template (public document, verifiable). 2018, superseded by the 2020 TENK template. |
| https://tuni.rekrytointi.com ads (Finnish and English; psychology, media studies, health services research) | read (snippet) | TT ads, Tampere | Open to assistant and associate professor levels; attachments in English as PDF: TENK CV, Academy-format publication list with ten marked (own role marked, links allowed), teaching portfolio 3 to 5 pages per Tampere guidelines, research plan max 5 pages, cover letter 1 to 2 pages, two referees; some ads add a 1 to 2 page vision paper. Key criteria in the ads: internationally high-level research and breadth of teaching or supervision. Level of the position: assistant = demand level 6, associate = 7. |
| https://content-webapi.tuni.fi/proxy/public/2022-11/tenure-track_malli_ohje_finnishversion_final.pdf (Finnish) | read (snippet) | TT policy, Tampere | 2022 policy. Positions are usually open at several levels. Applies DORA and the national responsible-evaluation recommendation. Associate level requires significant merits already, not only potential. Three goal areas: research, teaching and supervision, societal and university-community interaction. Recommended material for experts: research plan max 4 pages, teaching portfolio. |
| JYU ads: Associate Professor in literature (https://academicpositions.com/ad/university-of-jyvaskyla/2026/associate-professor-tenure-track-in-literature/248473, mirror; Finnish version on duunitori/jobly mirrors) | read (snippet, mirror) | TT ad (associate) | Same package as the assistant ad (round 5): TENK CV, cover letter max 2 pages, Academy-format list, max 5 publications, research plan max 4 pages incl. merits, leadership and funding experience, teaching portfolio, societal-interaction evidence max 2 pages. Finnish and English texts match on these points. Associate level asks for evidence of funding and leadership, assistant level for potential. |
| https://www.jyu.fi/en/file/general-requirements-for-appointing-an-assistant-professor-or-associate-professor-tenure-track and .../tenure-track-model-for-professors | read (snippet) | TT policy, Jyvaskyla | Weighting: scientific merits 60 to 70 percent, teaching 20 to 30, societal impact and community 10. Assistant = start of research career, evidence of potential, activity to get competitive funding; associate = considerable merits already. Doctorate typically 3 to 9 years ago at assistant level. At least two external experts evaluate. Language requirement and university-pedagogy studies after appointment. |
| https://www.helsinki.fi/en/about-us/careers/academic-careers/university-helsinki-tenure-track | read (snippet) | TT policy | Open-rank recruitment is common; the career level is judged during recruitment; assessment in three areas (research, teaching and supervision, public and academic engagement); associate level needs significant qualifications, not only potential. |
| https://www.oulu.fi/en/tenure-track | read (snippet) | TT policy | Required: excellent scientific quality on the Academy scale, external evaluation by at least 3 evaluators, teaching competence via portfolio and teaching demonstration; appointment at assistant or associate level by merits; criteria list (outputs, funding, international activity, teaching and supervision, societal relevance, leadership and service). |
| https://www.aalto.fi/en/services/tenure-track-evaluation-criteria | read (snippet) | TT policy | Quantitative indicators may support but not replace expert judgement; associate level needs demonstrated independence, ability to build and lead, competitive funding, supervision, teaching. |
| https://www.elgaronline.com/edcollchap-oa/book/9781035302451/chapter5.xml | read (snippet) | TT in Finland (open access chapter) | No national guidelines; most universities use three levels; all use external evaluation; criteria agreed beforehand; some weight criteria (example 60/30/10 research/teaching/societal impact). Peer-reviewed publisher chapter. |
| https://www.embl.org/about/info/embl-fellows-career-service/info-resources/job-applications/ | read (snippet) | group leader (Europe) | Europe: cover letter, CV, research proposal, recommendation letters, occasionally a teaching statement; committees look for work that is exciting and beneficial to the institution; materials vary by country and track. |
| https://www.iimcb.gov.pl/en/news-press-office/apply-junior-group-leader-professor-position | read (snippet) | junior group leader ad, Poland | Cover letter, CV with publication list, statement of 1 to 3 achievements from the last 10 years, two-page research plan summary, two references; criteria: quality of achievements, excitement and feasibility of plans, fit to institute, leadership and team-building. |
| https://fgu.cas.cz/en/students-and-career/career/junior-research-group-leader/ and the Nature Careers listing of the same call | read (snippet) | junior group leader ad, Czech Republic | CV, two-page research proposal, degree copy, two letters; the 2023 call stages: 2-page letter of intent, then full 6-page proposal and public lecture. Selection stresses intellectual independence (own corresponding-author papers, grants). The 2025 text of this call targets researchers based in the US; ignore that part (R14). |
| https://www.irbbarcelona.org/en/news/what-makes-a-good-cover-letter | read (snippet) | postdoc cover letter, institute | Research institute guidance (old, 2019): tailor to the group, mention key papers, funding. Weak; not used for rules. |
| https://www.khrono.no/files/2018/02/28/NIFUreport2018-4.pdf | meta (snippet) | Europe titles | NIFU 2018 report on career structures in Europe, shows assistant/associate titles differ by country (Sweden has no tenure; "tillsvidare" posts). Useful only to say that role names do not map one to one. |

Findings from round 6:

- Finnish calls for tutkijatohtori are lighter than for tenure track: 1-page or 2-page letter, TENK CV, Academy-format publication list, sometimes a 2-page research description, often no full plan; Academy postdoc funding needs a 12-page plan, 2-page CV, collaborators and mobility argued.
- Finnish tenure-track calls ask for a research plan of 4 to 5 pages (different from the 2 pages seen at Oulu), a teaching portfolio (Tampere 3 to 5 pages; Jyvaskyla and others by guideline), the ten or five key publications, and sometimes societal-interaction evidence or a vision paper. The call overrides any rule of thumb.
- The assistant versus associate difference is the evidence required: potential and independence at assistant level, already significant merits, funding and leadership at associate level. Most Finnish ads are open to both levels; the letter should say the level for evaluation (Oulu) and the CV must support it.
- Evaluation weights are published at some universities (JYU: scientific 60 to 70, teaching 20 to 30, societal 10). Use as a prompt to balance the documents, not as a rule.
- Junior group leader calls are mostly at research institutes in Europe; the research proposal is short (2 pages) and independence plus fit with the institute are criteria. They are not the same as a Finnish tenure-track call; treat as an adjacent role name.
- Title mapping: Finnish and English titles do not map one to one across countries (Sweden has no tenure, Finland has several translations). Use the employer title.
- Searches for non-Finnish "associate professor" guidance returned mostly US or commercial pages and were not used.

### 12.6 Open after round 6

| # | Item |
|---|---|
| O26 | All Finnish pages were read as snippets; the Tampere and JYU teaching-portfolio guideline PDFs themselves were not opened. |
| O27 | No Finnish-language guide on writing a postdoc cover letter or research plan from a university career service was found (only funder and call pages). A search of Finnish career-service pages (e.g. uraohjaus, tohtorikoulutus) is still open. |
| O28 | Junior group leader and Nordic (Sweden, Denmark, Norway) tenure-track or "universitetslektor" routes: only a few ads read. |
| O29 | Search budget per turn is 4; this round used all four plus the Finnish and English ones. A further sweep needs a new turn. |

## 13. Round 7 (2026-10-30): Tampere and JYU teaching-portfolio documents, career-service sweep

Search budget used: 5 searches (4 English/Finnish on Tampere portfolio and career services, 1 Finnish on Tampere opetusportfolio). Closes O26 (partly), O27 stays open.

### 13.1 Sources

| Source | Status | Facts |
|---|---|---|
| https://www.jyu.fi/en/file/university-of-jyvaskylas-instructions-for-the-teaching-portfoliopdf (created 5 Oct 2023, 1 page) | read (full text, curl + pdftools) | Portfolio supplements the online application and CV; presents teaching, pedagogical ideology and development as a teacher "from the perspective of the position". About 2-3 pages, structured by the table; up to 3 samples, each with the reason for choosing it; file max 100 Mb. Six sections (merits, then what to document): (1) pedagogical thinking and training: own teaching philosophy, pedagogical studies; (2) teaching and supervision experience: positions, practical teaching and supervision, how feedback received on teaching was used; (3) contribution to teaching development: development work, planning and evaluation of teaching, projects, research on teaching, teaching-related administration; (4) teaching competence: date of latest trial lecture (mm/yyyy), place, purpose, grade; (5) production of learning materials: characterise own production; (6) other merits: significant awards, networks most significant for the position. |
| https://www.tuni.fi/en/about-us/working-at-tampere-universities/tampere-university-as-an-employer/assessment-of-teaching-competence | read (full page via curl) | Teaching competence is assessed at recruitment (instructors, lecturers, professors, tenure track), docent title, and tenure-track advancement. Means: portfolio, teaching demonstration, development assignment, or a combination; interview used to verify claims in the documents (for example how the pedagogical philosophy shows in practice). Portfolio areas (5): pedagogical philosophy (conception of learning and how teaching promotes it); pedagogical training and maintaining skills; teaching and supervision experience (courses, theses, academic or PSP tutor, practices that promote learning, materials and environments); development of teaching (materials, feedback, research findings, making own development work visible); teacher collaboration and community-based development (teachers, students, employers, networks, interdisciplinary and international). |
| https://content-webapi.tuni.fi/proxy/public/2025-02/assessment-matrix-for-teaching-competence.pdf | read (full text, 5 pages; portfolio part read) | Five levels (poor to excellent) per area; applied flexibly, target level depends on the position. Wording that separates levels is useful as style checks: pedagogical thinking "presented and justified" with a convincing link to own practice and planning (levels 3-5) versus presented without justification (2); pedagogical studies counted in ECTS (up to 10, 11-20, 21-40, 40+); evidence of systematic collection and use of student or peer feedback; own or others' research used in developing teaching; collaboration described with own role. Teaching demonstration criteria (structure, research orientation, interaction) are not relevant to the written portfolio. |
| https://content-webapi.tuni.fi/proxy/public/2025-06/soc-yleisohje-dosentin-arvon-myontamisesta-ml-opetustaito-31-03-2025.pdf (Faculty of Social Sciences, docent guidance, dean's decision 31 Mar 2025) | read (full text, 4 pages; Finnish) | Quotes the Tampere portfolio structure: portfolio of 3-5 pages with five sections "in the order below": 1 pedagogical thinking (teaching philosophy), 2 pedagogical training and maintaining pedagogical competence, 3 teaching and supervision experience, 4 development of teaching and supervision, 5 teaching cooperation and community-based development. Same five areas as the web page, so this is the structure behind "Tampere guidelines". Docent context: teaching demonstration of 20 min if needed (at least grade good), public, in Finnish or English. |
| https://content-webapi.tuni.fi/proxy/public/2024-07/edu-dosentin-arvon-hakuohje-28.6.2024.pdf (Faculty of Education and Culture) | partial (search snippet; downloaded, not read in full) | Portfolio of at most 5 pages; structure begins with teaching and educational-philosophical views (learning, teaching, supervision and their theory), then pedagogical training and competence (awards, earlier demonstration grades). A faculty variant of the same structure. |
| https://content-webapi.tuni.fi/proxy/public/2025-09/met-dosenttiohje-suomi-final-4_2025.pdf | search (snippet) | Engineering faculty docent guidance: portfolio with "concise" descriptions, plus earlier assessments of teaching competence and other teaching merits. |
| https://content-webapi.tuni.fi/proxy/public/2022-11/tenure-track_malli_ohje_finnishversion_final.pdf | search (snippet) | Tampere tenure-track advancement: teaching ability assessed under the university's teaching-competence guidance; a teaching portfolio covering the assessed period goes with the summary of goals. |
| https://www.utu.fi/sites/default/files/public://media/file/Ohje%20opetustaidon%20arvioinnista%202026.pdf | search (snippet) | Turku, Faculty of Social Sciences, 2026 guidance for teaching posts and docent: CV plus teaching portfolio; documents must show earlier teaching experience, university pedagogical training, production of learning material and other teaching merits; the demonstration is graded excellent, good, satisfactory, insufficient. |
| https://www.tuni.fi/tlc/en/evolve-in-teaching/advancement-in-a-teachers-career/ | read (snippet + page fetch) | Says the portfolio is "a more concise, official document" and advises starting to collect material early; the link to "Tampere University instructions for creating a teaching portfolio" was not in the fetched text, and the standalone instruction PDF was not found. |
| https://www.academia.edu, Max Ryynanen portfolio, halttunen.info portfolio | skipped: personal examples, not guidance | Individual portfolios, useful only as shape examples; not used. |
| tcu.edu, slu.edu, wsu.edu, openlecture.com, wix.com, scribd and tamuk/tamut pages | skipped: commercial/LLM-like/US | Generic or US teaching-portfolio pages. |

### 13.2 Findings

- The Tampere portfolio structure is now known from a primary source: 3-5 pages, five sections in a fixed order (see 13.1). Call-ad length statements (3-5 pages in tenure-track ads, 2-3 pages in one older Health Data Science ad) agree with the faculty documents; the call wins.
- JYU portfolio: 2-3 pages, six topic rows, up to three samples with reasons for choice, trial-lecture details formatted mm/yyyy. Written from the perspective of the position.
- Both universities ask for the same core: philosophy that is justified and connected to practice, pedagogical studies (named, with scope), experience with supervision, use of feedback, development work made visible, collaboration. Both offer a verification route (interview, trial lecture, demonstration), so claims must be checkable (matches TENK integrity rule).
- Style checks derived (chat-only, added to the skill's teaching-portfolio section): section order and headings against the university's own; page limit; pedagogical studies named with credits; feedback use stated, not just collected; development work with the user's own role; dates in the format the guide asks (JYU mm/yyyy); samples at JYU each with a reason; philosophy linked to a concrete practice.
- Finnish career-service pages (round search `uraohjaus tutkijan työhakemus tutkimussuunnitelma`): returned doctoral-programme research-plan instructions (Oulu doctoral training plan: abstract 1 page, plan at most 10 pages, section list, and a required statement on whether generative AI was used; UEF doctoral programmes: 4-page plan; Academy postdoc plan: 12 pages, Source Sans Pro 12 pt, line spacing 1.15, 20 mm margins, no footnotes, reference list up to 2 pages outside the limit) but no career-service guide for a postdoc or tenure-track application. These are doctoral-admission or funder formats, not career services, so they are not used for cover-letter or teaching guidance (the Academy layout rules apply only to Academy applications).
- Helsinki careers service (studies.helsinki.fi tips-job-search) and the tieteentekijat.fi pages were already in section 3; no new career-service source was found in this round.
- AI-use disclosure: Oulu's doctoral plan instructions require stating whether generative AI was used; Helsinki's tenure-track ad (section 10) says AI-generated applications do not meet expectations. Consistent with nudge N13: wording stays the user's, and the call's AI rules apply.

### 13.3 Open after round 7

| # | Item |
|---|---|
| O26 | PARTLY CLOSED: JYU PDF read in full; Tampere structure read from a faculty document, and the matrix read. The standalone Tampere "instructions for creating a teaching portfolio" PDF was not found (may be intranet). The Education and Culture docent PDF was downloaded but not read in full. |
| O27 | STILL OPEN: no Finnish career-service guide for postdoc or tenure-track documents found (searched `uraohjaus` and doctoral-plan terms). Try Aalto, Helsinki or Jyvaskyla career-service pages by name in a later turn. |
| O30 | Aalto "Teaching competence assessment: guidelines for a candidate" PDF (O13) still unread in full. |
| O31 | Search budget for the turn was exhausted (5 searches). |

### 13.4 Log

- 2026-10-30: round 7. Downloaded the JYU portfolio PDF, the Tampere criteria matrix, and two Tampere faculty docent guidance PDFs with curl into git-ignored `tmp-examples/`, extracted text with `pdftools`, then deleted the files. `webfetch` cannot read these PDFs (compressed streams or 406); use curl with a browser user agent, then `pdftools::pdf_text`. No tokens or secrets recorded.

## 14. Round 8 (2026-10-30): Aalto teaching-competence PDF and career-service pages (O27, O30)

Searches this round: 3 (Aalto, JYU, Helsinki career services). Aalto PDF fetched with curl and read in full (2024 guidelines, valid from 1 Apr 2024); temporary file deleted.

### 14.1 Aalto teaching portfolio (read in full)

Source: https://www.aalto.fi/sites/default/files/2024-04/Teaching-competence-assessment_Guidelines-for-a-candidate_2024_Aalto-University.pdf

| Fact | Detail |
|---|---|
| Process | Portfolio, teaching demonstration and interview; a teaching competence assessment committee (TCAC) issues a written statement with a holistic grade. For advancement, an authentic teaching session is preferred. |
| Length | Portfolio at most 5-8 pages plus 6-10 pages of selected appendices. Cover page (name, date, purpose, contact, highest degree) and table of contents with appendix list. |
| Style rules | Narrative text, first person, document all relevant experience, provide evidence for claims, support with reflection and appropriate references. Long careers may focus on the last 5-10 years, with a full course list as an appendix. Tenure or lecturer track: in each section, summarise development since the latest appointment. Not all components must be equally covered. |
| Structure | 1 Approach to teaching and learning (how you teach; evidence, examples, reflection incl. effect on students' learning and how the approach developed); 2 Teaching experience (teaching with own role, supervision and advising, materials, course development); 3 Curriculum development and educational leadership; 4 Development as a teacher (pedagogical studies with credits, where and when; research on teaching; key learnings, strengths and development areas); 5 Feedback (how it was collected and used, student and peer feedback, awards). |
| Appendices | Expected, as tables: teaching activities (course, students, level, credits, year, institution, overall feedback grade, own role), supervised students (level, years, titles, own role, status), a sample syllabus, list of pedagogical training (year, course, credits, institution). Optional: selected feedback and teaching materials. Appendices numbered and referred to in the text. |

Style checks this supports (chat-only): claims paired with evidence; own role stated per course and thesis; reflection present, not only description; strengths and development areas both named; feedback use, not only collection; appendices numbered and referenced; length against the 5-8 page limit; tenure-track candidates show development since the last appointment.

### 14.2 Career-service and similar pages

| Source | Status | Facts |
|---|---|---|
| https://studies.helsinki.fi/instructions/article/job-seeking and the Helsinki Career Services job-seeking guide PDF (older, about 2018) | read (snippet) | General (non-academic) guidance from a university career service: tailor CV and letter to the position, profile text at the start, reverse chronological order, one letter per position, a "meta-CV" for yourself, ask someone to proofread, "Be honest, don't exaggerate or belittle your achievements" (guide), letter about one page, CV one to two pages. The Helsinki CV self-study PDF states an academic CV differs (must list all merits, TENK). Mostly non-academic, so use only the honesty and tailoring points. |
| https://www.helsinki.fi/en/about-us/careers/open-positions/instructions-applicants-teaching-and-research-positions | read (snippet) | Recommends the TENK CV model; no date of birth or home address needed; academic portfolio 4-7 pages plus enclosures, unit rules may differ. |
| https://studies.helsinki.fi/instructions/article/grant-funded-doctoral-studies | read (snippet) | For grant applications: be precise, concise and understandable, reviewers may be outside your field; justify topicality and societal significance; keep plan and CV current; check each funder's length and format; "be honest, realistic and optimistic", do not understate abilities and do not promise what you cannot keep. Supports N4, N8, N17. |
| Aalto Career Design Lab and School of Business Career Services (aalto.fi/en/career-design-lab/career-coaching, /services/job-search-skills) | read (snippet) | Student-oriented; coaching is not CV advice; weekly drop-in for CV and cover letter feedback; JobTeaser guide. No academic-application guidance published there. |
| https://aaltoscicomp.github.io/blog/2023/aalto-rse-hiring-process/ | read (snippet) | One Aalto unit (research software engineers, not a faculty role): the cover letter is read before the CV, interprets skills for the job, anonymised (no name or signature), do not assume the reader knows your background, state your role in collaborative projects. Single unit, non-faculty; weak evidence, use only as a pointer to what some panels do. |
| https://www.jyu.fi/en/about-us/work-with-us/academic-career-at-university-of-jyvaskyla | read (snippet) | Career options overview only; no application-writing advice. Jyvaskyla has no academic career-service guide in the results; its published guidance is in the call text and the portfolio and recruitment PDFs. |
| researchersjob.com, careershelpdesk, scholaridea, academicpositions mirrors of JYU ads | skipped: commercial/LLM-like | Mirrors and listings; the underlying ad (a physics postdoc) asks for a CV in a scientific template, a cover letter of at most 2 pages, a numbered publication list and an up-to-date ORCID. Seen only through a mirror, so not relied on. |
| Aalto "CV, Cover Letter and Skills" slides (aalto.fi, 2020) | skipped: commercial (author's own book) and non-academic | Generic job-search slide deck. |
| Oulu and Helsinki RESDOC doctoral-admission pages | skipped: doctoral admission, not postdoc or tenure track | Out of the skill's role scope. |

### 14.3 Findings

- O27 result: none of the three universities publishes an academic-application guide through its career service. Helsinki's career-service material is general and student-oriented; Aalto's is student coaching; JYU's guidance sits in the recruitment pages and portfolio PDF. The useful guidance for postdoc and tenure-track documents remains the call text, TENK, and funder or faculty instructions already recorded.
- Two Helsinki sources add support for existing nudges: honesty in both directions (N4) and write for a reviewer outside the field (N8).
- Aalto's guide is the strictest on evidence and appendices (tables for courses and supervision with own role); useful for the teaching-portfolio checks.

### 14.4 Open after round 8

| # | Item |
|---|---|
| O27 | CLOSED for Aalto, Helsinki and JYU: no academic-application career-service guide found. Other Finnish universities (Turku, Oulu, UEF, Tampere career services) not searched. |
| O30 | CLOSED: Aalto PDF read in full. |
| O32 | Search budget for the turn: 3 used, 2 left unused. |

### 14.5 Log

- 2026-10-30: round 8. Three searches; Aalto PDF via curl and `pdftools`; temporary file deleted. No tokens or secrets recorded.
