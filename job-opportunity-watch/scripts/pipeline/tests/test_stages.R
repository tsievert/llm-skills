# Unit tests for the mechanical stage functions (s1-s3) and the text checks. Offline: network access is injected.
# Run: testthat::test_dir("<skill-dir>/scripts/pipeline/tests")
library(testthat)
here <- normalizePath(file.path(dirname(sys.frame(1)$ofile %||% "."), ".."), mustWork = FALSE)
if (!file.exists(file.path(here, "jw_contracts.R"))) here <- normalizePath(file.path(getwd(), ".."))
for (f in c("jw_contracts.R", "jw_pipeline.R", "jw_checks.R", "jw_stage_fns.R")) source(file.path(here, f))

TODAY <- as.Date("2026-10-27")
dl <- function(txt) jw_deadline_from_text(txt, TODAY)

PROFILE <- list(career_search_profile = list(
  target_search = list(accepted_job_titles = c("Postdoctoral researcher", "Assistant professor with tenure track"),
                       conditional_job_titles = list(research_assistant = list(status = "Conditional")),
                       excluded_job_titles = c("Full professor", "PhD researcher", "Technician")),
  animal_systems = list(very_high_fit = list(small_mammals = list(), carnivores = list()),
                        medium_fit = list(birds = list()), excluded_as_primary_system = c("Insects")),
  scientific_topics = list(very_high_priority = list(chemical_communication = list()), excluded_if_central = c("Neuroscience")),
  search_synonyms = list(small_mammals = "rodent|\\bvoles?\\b|small mammal", Insects = "insect|beetle|\\bbees?\\b",
                         Neuroscience = "neuroscien")))
TERMS <- jw_profile_terms(PROFILE)
pf <- function(...) { x <- data.frame(text = c(...)); x$job_like <- FALSE; jw_prefilter(x, TERMS) }

test_that("job-like flag: menu text is not a vacancy, vacancy words and hits are", {
  expect_equal(jw_anchor_job_like(c("Apply to our programmes", "Postdoctoral fellow in x", "About us", "x"),
                                  c("https://a.example/p", "https://a.example/q", "https://a.example/about", "https://a.example/vacancies/7"),
                                  c(FALSE, FALSE, FALSE, FALSE), c(FALSE, FALSE, FALSE, FALSE)), c(FALSE, TRUE, FALSE, TRUE))
  expect_true(jw_anchor_job_like("anything", "https://a.example", role_hit = TRUE, topic_hit = FALSE))
  # stems start at a word boundary: author names are not vacancies
  expect_false(any(jw_anchor_job_like(c("Geoffrey Cantor", "Estelle Clarke"), c("https://a.example/author/geoffrey-cantor", "https://a.example/author/estelle-clarke"))))
  expect_true(jw_anchor_job_like("Stellenangebot Biologie", "https://a.example/x"))
  # category (filter) pages repeat their slug as link text; vacancies carry an id or a longer title
  expect_false(any(jw_anchor_job_like(c("Life Science", "Faculty Member", "Postdoc"),
    c("https://a.example/jobs/life-science/", "https://a.example/jobs/faculty-member", "https://a.example/jobs/postdoc/"),
    role_hit = c(FALSE, FALSE, TRUE))))
  expect_false(jw_anchor_job_like("Life Science", "https://a.example/careers/jobs/life-science/"))   # path prefix before the job word
  expect_true(all(jw_anchor_job_like(c("Postdoc in vole ecology", "Research Fellow"),
    c("https://a.example/jobs/postdoc-in-vole-ecology-2026/", "https://a.example/job/AB123/research-fellow"))))
})

test_that("source flag: fine, weak, nav_only, not_assessed", {
  expect_equal(jw_source_flag(c("ok", "ok", "ok_js_suspect", "blocked", "search_engine"), c(5, 2, 0, 0, 0)),
               c("fine", "weak", "nav_only", "not_assessed", "not_assessed"))
})

test_that("profile terms never contain an empty alternative (would match everything)", {
  t0 <- jw_profile_terms(list(career_search_profile = list()))
  expect_false(grepl("^\\||\\|\\||\\|$", t0$strong)); expect_false(grepl("a postdoc", t0$strong, perl = TRUE))
  expect_false(grepl(t0$strong, "anything at all", perl = TRUE)); expect_false(isTRUE(t0$excl_full_prof))
  expect_true(grepl(TERMS$strong, "vole", perl = TRUE)); expect_true(TERMS$excl_full_prof)
})

test_that("prefilter: tiers, exclusions and reasons", {
  x <- pf("Postdoctoral researcher in vole ecology", "Postdoc on birds", "PhD student in rodent biology",
          "Full Professor of ecology", "Assistant professor of ecology", "Postdoc working on beetles", "Postdoc on beetles and voles",
          "Postdoc in neuroscience of birds", "Welcome to our news page", "Research assistant")
  expect_equal(x$tier, c(1L, 1L, NA, NA, 2L, NA, 1L, NA, NA, 2L))
  expect_equal(x$reason[3], "excluded title (PhD, doctoral or technician)")
  expect_equal(x$reason[4], "full professor"); expect_equal(x$reason[6], "excluded system")
  expect_equal(x$reason[8], "excluded if central"); expect_equal(x$reason[9], "no role or topic word")
  expect_equal(x$reason[1], "topic: strong"); expect_equal(x$reason[2], "topic: broad")
})

test_that("deadline text: first date after each cue, three languages, contract dates ignored", {
  expect_equal(dl("Deadline: 15 November 2026. Start 1 January 2027")$deadline, as.Date("2026-11-15"))
  expect_equal(dl("Closing date November 15, 2026")$verdict, "open")
  expect_equal(dl("Bewerbungsfrist: 15. M\u00e4rz 2027, befristet bis 31.12.2029")$deadline, as.Date("2027-03-15"))
  expect_equal(dl("Hakuaika p\u00e4\u00e4ttyy 20.11.2026")$deadline, as.Date("2026-11-20"))
  expect_equal(dl("Sista ans\u00f6kningsdag: 5 januari 2027")$deadline, as.Date("2027-01-05"))
  expect_equal(dl("Ans\u00f6k senast 2026-12-01")$deadline, as.Date("2026-12-01"))
  expect_equal(dl("Hakuaika p\u00e4\u00e4ttyy 3. lokakuuta 2026")$verdict, "expired")
  z <- dl("Deadline 1 September 2026 (extended: deadline 30 November 2026)")
  expect_equal(c(z$verdict, z$flag), c("open", "mixed_past_future")); expect_equal(z$deadline, as.Date("2026-11-30"))
  expect_equal(dl("Deadline 1 March 2026")$verdict, "expired")
  expect_equal(dl("befristet bis 31.12.2029, Stellenbeginn 1 Mai 2027")$verdict, "no_deadline_found")
  expect_equal(dl(NA_character_)$verdict, "no_deadline_found")
  expect_equal(dl("Deadline 31 February 2027")$verdict, "no_deadline_found")   # impossible date is dropped
})

test_that("implausible deadline becomes parse_error, dates are kept", {
  r <- jw_deadline_row(dl("Deadline 1 March 2099"), TODAY)
  expect_equal(r$verdict, "parse_error"); expect_true(is.na(r$deadline)); expect_match(r$dates, "2099")
})

test_that("html text drops scripts and styles", {
  expect_equal(jw_html_text("<p>Deadline <b>1 Dec 2026</b></p><script>var d='1 Jan 2020'</script><style>.a{}</style>"), "Deadline 1 Dec 2026")
})

# ---- stage functions with injected network -------------------------------------------------------
new_root <- function() { r <- tempfile("jwroot"); dir.create(r); r }
WK1 <- "2026-W43"; WK2 <- "2026-W44"
LINKS <- data.frame(n = 1:4, id = c("a1", "b2", "c3", "d4"), section = "s", url = paste0("https://", c("a", "b", "c", "c"), ".example/jobs"),
                    type = c("portal", "portal", "search_engine", "portal"), dup_of = c(NA, NA, NA, 3L), stringsAsFactors = FALSE)
fake_links <- function(path) LINKS
anc <- function(...) data.frame(source_id = "a1", text = c(...), href = paste0("https://a.example/page/", seq_along(c(...))),
                                role_hit = FALSE, topic_hit = FALSE, excluded = FALSE, stringsAsFactors = FALSE)
fake_probe <- function(texts) function(links, ...) list(
  sources = data.frame(id = c("a1", "c3"), n = c(1L, 3L), status = c("ok", "search_engine"), http = c(200L, NA), final_url = NA,
                       text_hash = NA, n_anchors = c(length(texts), 0L), note = c(NA, "some query")),
  anchors = anc(texts), links = links)
dir_with_profile <- function() { r <- new_root(); dir.create(file.path(r, "runs"))
  yaml::write_yaml(PROFILE, file.path(r, "job_profile.yml")); r }

test_that("s1: one row per unique link, lost probes become error rows, anchors side file, expected_n", {
  r <- dir_with_profile()
  expect_equal(jw_s1_expected_n(WK2, r, links_fn = fake_links), 3L)
  jw_manifest_update(jw_run_dir(WK2, r), "s0", status = "done")
  jw_stage_run("s1", function() jw_s1_probe(WK2, r, TODAY, probe_fn = fake_probe(c("Postdoc in vole ecology", "Researcher x", "Postdoc y")), links_fn = fake_links),
               WK2, r, expected_n = jw_s1_expected_n(WK2, r, links_fn = fake_links))
  s1 <- jw_read_stage("s1", WK2, r)
  expect_equal(s1$status, c("ok", "error", "search_engine")); expect_equal(s1$flag, c("fine", "not_assessed", "not_assessed"))
  expect_equal(s1$note[2], "no probe result"); expect_equal(s1$n_job_like[1], 3L)
  expect_equal(jw_manifest_read(jw_run_dir(WK2, r))$stages$s1$status, "done")
  expect_equal(nrow(jw_read_stage("s1_anchors", WK2, r)), 3L)
})

run_to_s1 <- function(r, wk, texts) {
  jw_manifest_update(jw_run_dir(wk, r), "s0", status = "done")
  jw_stage_run("s1", function() jw_s1_probe(wk, r, TODAY, probe_fn = fake_probe(texts), links_fn = fake_links), wk, r, expected_n = 3L)
}

test_that("s2: first week is a baseline, later weeks queue only links not seen in finished earlier weeks", {
  r <- dir_with_profile()
  run_to_s1(r, WK1, c("Postdoc in vole ecology", "Researcher x", "Welcome page"))
  jw_stage_run("s2", function() jw_s2_queue(WK1, r, TODAY), WK1, r)
  q1 <- jw_read_stage("s2", WK1, r); expect_equal(nrow(q1), 2L); expect_equal(q1$tier[q1$text == "Postdoc in vole ecology"], 1L)
  expect_true("s2_baseline" %in% jw_problems_read(WK1, r)$code); expect_true("s2_dropped" %in% jw_problems_read(WK1, r)$code)
  # week 2: the same three links plus one new one; rerunning s2 gives the same queue
  run_to_s1(r, WK2, c("Postdoc in vole ecology", "Researcher x", "Welcome page", "Postdoc in carnivore ecology"))
  q2 <- jw_s2_queue(WK2, r, TODAY); expect_equal(q2$text, "Postdoc in carnivore ecology")
  expect_equal(jw_s2_queue(WK2, r, TODAY)$item_id, q2$item_id)
  expect_false("s2_baseline" %in% jw_problems_read(WK2, r)$code)
  # an earlier week that never finished s1 does not count as seen
  jw_manifest_update(jw_run_dir(WK1, r), "s1", status = "failed")
  expect_equal(nrow(jw_s2_queue(WK2, r, TODAY)), 4L - 1L)   # welcome page is still dropped by the prefilter
})

test_that("s2 returns an empty, schema-valid queue when the prefilter drops everything", {
  r <- dir_with_profile(); run_to_s1(r, WK1, c("Welcome page", "Contact us"))
  jw_stage_run("s2", function() jw_s2_queue(WK1, r, TODAY), WK1, r)
  expect_equal(nrow(jw_read_stage("s2", WK1, r)), 0L); expect_equal(jw_manifest_read(jw_run_dir(WK1, r))$stages$s2$status, "done")
})

test_that("s3: text pre-check, page fetch for tier 1 only, chunked resume, gate passes", {
  r <- dir_with_profile(); wk <- WK2
  for (s in c("s0", "s1")) jw_manifest_update(jw_run_dir(wk, r), s, status = "done")
  s2 <- data.frame(item_id = paste0("i", 1:6), source_id = "a1",
                   text = c("Postdoc vole (deadline 1 March 2026)", "Postdoc vole A", "Postdoc vole B", "Postdoc vole C", "Researcher plain", "Postdoc vole D"),
                   href = paste0("https://a.example/job/", 1:6), tier = c(1L, 1L, 1L, 1L, 2L, 1L), reason = "x", first_seen = TODAY)
  jw_write_stage(s2, "s2", wk, r); jw_manifest_update(jw_run_dir(wk, r), "s2", status = "done")
  calls <- character()
  fetch <- function(u) { calls <<- c(calls, u)
    switch(basename(u), `2` = "Deadline: 20 November 2026", `3` = "Deadline 1 June 2026", `4` = NULL, `6` = "no date here", "x") }
  jw_stage_run("s3", function() jw_s3_deadlines(wk, r, TODAY, chunk = 2, fetch_fn = fetch), wk, r)
  s3 <- jw_read_stage("s3", wk, r)
  expect_equal(s3$verdict, c("expired", "open", "expired", "unreadable", "not_checked", "no_deadline_found"))
  expect_false("https://a.example/job/1" %in% calls); expect_false("https://a.example/job/5" %in% calls)
  expect_equal(jw_manifest_read(jw_run_dir(wk, r))$stages$s3$status, "done")
  expect_false(file.exists(file.path(jw_run_dir(wk, r), "s3_partial.parquet")))
  # resume: a partial file for ids 2 and 3 means only 4 and 6 are fetched
  jw_write_parquet(data.frame(item_id = c("i2", "i3"), deadline = as.Date(c("2026-11-20", "2026-06-01")),
                              verdict = c("open", "expired"), flag = NA, dates = NA), file.path(jw_run_dir(wk, r), "s3_partial.parquet"), jw_contracts()$s3$schema)
  calls <- character(); again <- jw_s3_deadlines(wk, r, TODAY, chunk = 2, fetch_fn = fetch)
  expect_equal(sort(basename(calls)), c("4", "6")); expect_equal(again$item_id, s2$item_id)
})

test_that("s3 with an empty queue returns an empty, valid frame", {
  r <- dir_with_profile(); jw_write_stage(data.frame()[0, ], "s2", WK2, r)
  expect_equal(nrow(jw_s3_deadlines(WK2, r, TODAY, fetch_fn = function(u) stop("no fetch"))), 0L)
})

test_that("sitemap anchors: whole-site sitemap is filtered to vacancy-like URLs, scheme-less locs are repaired", {
  jw <- file.path(here, "..", "jobwatch.R"); skip_if_not(file.exists(jw))
  ex <- parse(jw, keep.source = FALSE)
  for (e in ex) if (is.call(e) && identical(e[[1]], as.name("<-")) && as.character(e[[2]])[1] %in% c(".slug_text", ".sitemap_job_re", ".sitemap_anchors")) eval(e)
  locs <- c("www.a.example/job/DTE475/postdoc-vole-ecology-fixed-term", "https://a.example/author/geoffrey-cantor",
            "https://a.example/news/some-long-article-title", "https://a.example/vacancies/research-assistant-ecology/55",
            "https://a.example/vacancies/research-assistant-ecology/56", NA)
  a <- .sitemap_anchors(locs)$anchors
  expect_equal(nrow(a), 2L)
  expect_true("https://www.a.example/job/DTE475/postdoc-vole-ecology-fixed-term" %in% a$href)
  expect_true("postdoc vole ecology fixed term" %in% a$text)
})
