# Journal data policies (target journals of the owner)

**Status: search excerpts, not full pages.** The journal pages for Springer, OUP and Wiley titles returned 403 or a client challenge
when fetched on 2026-10-23. Always read the journal's live Instructions for Authors at trigger time. If the fetch fails, ask the user to
paste the data-availability and archiving section and work from that. Excerpt ages are the search tool's.

## Contents

- Table of policies
- What it means for timing and content
- Data availability statement: forms
- Anonymous review
- Checklist for reading a live policy

## Table of policies

| Journal | What the excerpts said | Timing |
|---|---|---|
| Oecologia (Springer Nature) | Follows the Springer Nature research data policy: sharing strongly encouraged; a **data availability statement is required** for original research; repositories preferred; datasets as Supplementary Information only after reading the policy. Instructions for Authors is a PDF | Statement at submission |
| Behavioral Ecology and Sociobiology (Springer Nature) | An editorial announced **mandatory data deposition** in repositories for papers with data and strongly recommended source code; defers to Instructions for Authors for repositories. Year and current wording not seen | Check live page; probably at submission |
| Ecosphere (ESA) | All underlying data and **novel statistical code** in a permanent public repository, enough to replicate tables, graphs and statistics; ESA staff verify before release; Dryad recommended with fee coverage up to 10 GB for material curated after 2026-01-01; a Zenodo DOI is accepted for GitHub material (sentence cut off in the excerpt); not uploaded as supporting files for most article types | **On acceptance** |
| Behavioral Ecology (OUP) | **Raw data in a permanent public repository; GitHub is not acceptable** (no DOI, files can be altered). Link required **at submission**; the repository is screened (data as **CSV** plus a README describing each file) before review; code not required but welcome; citation anonymised; a data editor re-checks before production; **from 2026-01-01 the journal no longer pays Dryad fees** (billed on acceptance); the paper is not published until the Dryad repository is published | **At submission** |
| Computers and Electronics in Agriculture (Elsevier) | **Option C** of Elsevier's research data guidelines: authors are required to deposit data in a relevant repository, cite and link it, or state why they cannot; a **data statement at submission**; "research data" explicitly includes software, code, models and protocols. The page with the option definitions returned 404; Elsevier's general policy page encourages Mendeley Data and statements | Statement at submission |

Sources (live pages to re-read): https://link.springer.com/journal/442/submission-guidelines (Oecologia), the Springer Nature research data policy,
https://www.esa.org/publications/data-policy/ , https://academic.oup.com/beheco/pages/information_for_authors ,
Elsevier's guide for authors for Computers and Electronics in Agriculture on ScienceDirect. An older ESA page that said public data were not strictly required is outdated.

## What it means for timing and content

- **Same deposit, different clocks.** Behavioral Ecology needs the repository and README at submission (so before review); Ecosphere on acceptance; CEA and Springer journals need a statement at submission. Ask where the manuscript is going first and in what order, because a resubmission to another journal changes the deadline and may change the format (CSV for Behavioral Ecology).
- **Code.** Required or expected for Ecosphere and CEA, welcome for Behavioral Ecology, encouraged for Springer journals. A code archive needs a DOI too (Zenodo, or Dryad's Zenodo hosting); GitHub alone never satisfies a DOI requirement.
- **Cost** is a decision for the user each time; policies on who pays changed in 2026.
- Open questions to resolve live: whether CEA accepts co-submission via Data in Brief or Mendeley Data, and the exact current Behavioral Ecology and Sociobiology rule and date.

## Data availability statement: forms

Springer Nature's statement types (from search excerpts): data in a named repository with a persistent link; data not public because of a stated reason but available on request; on request only; not applicable; included in the article. Templates for drafts are in [../assets/data-availability-statements.md](../assets/data-availability-statements.md). They are drafts for the user to adapt; the user approves the final text, and a DOI is inserted only after it exists.

## Anonymous review

Behavioral Ecology wants an anonymised repository citation during review. Dryad and other repositories offer private reviewer links or anonymised records; the README must then omit names, emails and ORCIDs until acceptance (rule already in `data-repository-readme`). Check each journal for double-anonymous review before filling author fields.

## Checklist for reading a live policy

1. When is the deposit needed (submission, revision, acceptance)? 2. Which repositories are named or excluded? 3. Data, code, both? 4. File formats? 5. Statement wording and where it goes. 6. Anonymisation. 7. Fees. 8. Whether a data editor or staff screens the deposit and what they look for. Report which page was read and its date, or that it could not be read.
