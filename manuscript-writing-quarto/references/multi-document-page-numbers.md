# Continuous page numbers across standalone Quarto typst documents

Use when an application or submission package is several separate Quarto (typst) PDFs (for example letter, CV,
list, plan) and the page numbers must run on across them. Reported once, worked; not tested here on other formats.

Each PDF restarts at 1 by default. Recipe:

1. In each document, an R chunk (`echo: false`, `results: asis`) reads `Sys.getenv("PAGE_START", "1")` and emits a
   raw typst block that sets the counter: `#counter(page).update(<N>)`.
2. A driver script, per document in order: set `PAGE_START` (previous start + previous page count), call
   `quarto::quarto_render(input, output_file = "<name>_pkg.pdf")`, move the output, and read the page count
   (`pdftools::pdf_info()$pages`) for the next start.
3. Check the page total against the call's page limit; merge the parts only if the call wants one file
   (for example with `qpdf::pdf_combine()`).

Quarto renders into the project folder by default, so move each result right away; the next render overwrites it
when documents share an output name. Page numbers in the footer must use the page counter, not a fixed number.
