# Pre-registration documents

## Tool choice

`preregr` (an R-native (pre)registration specification package considered during research for this skill) was
**archived from CRAN on 2026-07-28** ("issues were not corrected despite reminders") — do not recommend it.

Use `prereg` (CRAN, actively maintained, checks OK as of 2026-09-06) instead: a collection of R Markdown
templates that render to PDF.

```r
install.packages("prereg")   # CRAN

# Create a draft from a template, then fill it in by hand
rmarkdown::draft(
  "my_preregistration.Rmd",
  template = "cos_prereg",     # or aspredicted_prereg, vantveer_prereg, brandt_prereg,
                                # fmri_prereg, psyquant_prereg, prp_quant_prereg, rr_prereg
  package  = "prereg",
  create_dir = FALSE,
  edit = FALSE
)
rmarkdown::render("my_preregistration.Rmd")
```

`prereg` needs pandoc (bundled with RStudio) and a TeX distribution for the PDF step — `tinytex::install_tinytex()`
is the lightweight option if none is installed. This was not tested end to end on this machine; confirm the
render step works before the user relies on it.

## Template choice

| Template | Use for |
|---|---|
| `cos_prereg` | Center for Open Science Preregistration Challenge format — general quantitative studies |
| `aspredicted_prereg` | AsPredicted.org's shorter nine-question format |
| `vantveer_prereg` | van 't Veer & Giner-Sorolla (2016) social-psychology template |
| `brandt_prereg` | Brandt et al. (2014) Replication Recipe, for a planned replication |
| `prp_quant_prereg` | Psychological Research Preregistration-Quantitative (PRP-QUANT), the most comprehensive form |
| `fmri_prereg` | fMRI-specific preregistration |

If none fits the design (e.g. a systematic review, a qualitative study), say so rather than forcing a
quantitative template — the archived `preregr` package's bundled forms covered a wider range (systematic
review, qualitative, secondary-data-analysis templates) but is no longer installable from CRAN; a GitLab
install (`remotes::install_gitlab('r-packages/preregr')`) is possible but is a non-CRAN source and needs the
user's explicit permission first, per this repo's standing rule on non-CRAN installs.

## What goes in it, regardless of template

Primary outcome(s) and how they are measured; the planned model (family, fixed and random effects, exactly as
it will be fit — not "a mixed model" but the actual formula); the planned sample size and stopping rule;
planned multiplicity correction across endpoints (see [multiplicity.md](multiplicity.md)); and what counts as
a deviation worth disclosing later. These are the user's scientific decisions — this skill only supplies the
document scaffold, not the content.

## Division of labour with `manuscript-writing-quarto`

A pre-registration is itself a small document, but it is written and rendered through `prereg`'s own R
Markdown templates (PDF output), not through a Quarto manuscript project. If the user later wants it
restructured as a `.qmd` for a journal's own pre-registration report format, that structural step belongs to
`manuscript-writing-quarto`; this skill owns the content decisions (what to pre-specify) and the initial
`prereg` draft.
