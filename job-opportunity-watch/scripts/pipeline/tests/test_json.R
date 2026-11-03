# Offline tests for the JSON-source helpers in jobwatch.R (robots.txt check, link typing, JSON-LD, probe input check).
# Live endpoint calls are not tested here (see references/portal-quirks.md for what was checked by hand).
library(testthat)
here <- normalizePath(file.path(dirname(sys.frame(1)$ofile %||% "."), "..", "..", "..", ".."), mustWork = FALSE)
if (!file.exists(file.path(here, "web-fetching-r", "scripts", "polite_fetch.R"))) here <- normalizePath(file.path(getwd(), "..", "..", "..", ".."))
suppressMessages({
  source(file.path(here, "web-fetching-r", "scripts", "polite_fetch.R"))
  source(file.path(here, "job-opportunity-watch", "scripts", "jobwatch.R"))
})

test_that("robots.txt: longest match wins, allow beats disallow on a tie, 404 means allowed, unreachable is NA", {
  assign("https://a.test", "User-agent: *\nDisallow: /api/\nAllow: /api/public/\nDisallow: /tmp$\n", envir = .robots_cache)
  expect_false(jw_robots_allowed("https://a.test/api/x"))
  expect_true(jw_robots_allowed("https://a.test/api/public/x"))
  expect_false(jw_robots_allowed("https://a.test/tmp")); expect_true(jw_robots_allowed("https://a.test/tmp/file"))
  expect_true(jw_robots_allowed("https://a.test/other"))
  assign("https://b.test", "User-agent: *\nDisallow: /\n\nUser-agent: Googlebot\nAllow: /x\n", envir = .robots_cache)
  expect_false(jw_robots_allowed("https://b.test/jobs"))
  assign("https://c.test", "", envir = .robots_cache); expect_true(jw_robots_allowed("https://c.test/anything"))
  assign("https://d.test", NA_character_, envir = .robots_cache); expect_true(is.na(jw_robots_allowed("https://d.test/x")))
  assign("https://e.test", "User-agent: *\nDisallow: /a*/private\n", envir = .robots_cache)
  expect_false(jw_robots_allowed("https://e.test/abc/private")); expect_true(jw_robots_allowed("https://e.test/abc/public"))
})

test_that("links with json:eures / json:oracle in the note get a json type, others do not", {
  tf <- tempfile(fileext = ".csv")
  writeLines(c("url,section,note",
               "https://a.org/x,s,",
               "https://europa.eu/eures/portal/jv-se/search?page=1,s,json:eures",
               "https://b.oraclecloud.com/hcmUI/CandidateExperience/en/sites/CX_1/requisitions,s,use json:oracle here",
               "https://c.org/y,s,json:unknown"), tf)
  expect_equal(jw_read_links(tf)$type, c("portal", "json_eures", "json_oracle", "portal"))
})

test_that("JSON-LD JobPosting objects are found in @graph and ItemList, other types ignored", {
  html <- paste0('<html><head><script type="application/ld+json">{"@context":"https://schema.org","@graph":[',
    '{"@type":"Organization","name":"Uni X"},',
    '{"@type":"JobPosting","title":"Postdoc in chemical ecology","hiringOrganization":{"name":"Uni X"},"validThrough":"2026-12-01","url":"https://x.org/job/1"},',
    '{"@type":"ItemList","itemListElement":[{"@type":"JobPosting","title":"Lecturer in zoology","url":"https://x.org/job/2"}]}]}</script>',
    '<script type="application/ld+json">not json</script></head><body></body></html>')
  a <- .jsonld_anchors(xml2::read_html(html), "https://x.org/")
  expect_equal(a$href, c("https://x.org/job/1", "https://x.org/job/2"))
  expect_match(a$text[1], "deadline 2026-12-01")
  expect_equal(nrow(.jsonld_anchors(xml2::read_html("<html><body>none</body></html>"), "https://x.org/")), 0L)
})

test_that("jw_probe stops on a reduced links table instead of returning nothing", {
  expect_error(jw_probe(data.frame(url = "https://example.org", section = "x")), "missing columns")
})

test_that("search-engine links: operators and time filter kept, tracking parameters ignored", {
  g1 <- "https://www.google.com/search?q=%28olfaction+OR+smell%29+research+%28job%29+-wiley+-site%3Amsu.edu&newwindow=1&tbs=qdr%3Am&sxsrf=AAA%3A1&ved=0ah&gs_lp=Egxn#ip=1"
  g2 <- "https://www.google.com/search?q=%28olfaction+OR+smell%29+research+%28job%29+-wiley+-site%3Amsu.edu&client=firefox&tbs=qdr%3Am&sxsrf=BBB%3A2&sca_esv=9&ved=zz"
  sp <- jw_search_parts(g1)
  expect_equal(sp$query, "(olfaction OR smell) research (job) -wiley -site:msu.edu")
  expect_equal(sp$recency, "m"); expect_equal(jw_recency_label("m"), "past month")
  expect_equal(jw_recency_label("w2"), "past 2 weeks"); expect_true(is.na(jw_recency_label(NA_character_)))
  expect_equal(jw_key(g1), jw_key(g2))
  expect_false(identical(jw_key(g1), jw_key(sub("qdr%3Am", "qdr%3Aw", g2))))
  expect_false(identical(jw_key(g1), jw_key(sub("-wiley", "-jstor", g2))))
  expect_true(endsWith(jw_search_note(g1), "-site:msu.edu  [time filter: past month]"))
  expect_true(is.na(jw_search_note("https://www.google.com/search?tbs=qdr%3Am")))
  expect_equal(jw_search_parts("https://www.google.com/search?q=a+b&as_qdr=y")$recency, "y")
  expect_equal(jw_key("https://Example.org/jobs/#top"), "https://example.org/jobs")
  f <- tempfile(fileext = ".csv")
  writeLines(c("url,section,label,note,enabled", sprintf('"%s",S,g1,,', g1), sprintf('"%s",S,g2,,', g2)), f)
  l <- jw_read_links(f)
  expect_equal(l$type, rep("search_engine", 2)); expect_equal(l$dup_of, c(NA, 1L)); expect_match(l$query[1], "time filter")
})

test_that("jw_search_refine reruns with -site: for noisy domains, is bounded and never repeats exclusions", {
  q <- "(olfaction OR smell) job -wiley -site:msu.edu"
  noisy <- c("https://www.ziprecruiter.com/Jobs/Olfaction", "https://www.indeed.com/q-x.html",
             "https://arxiv.org/pdf/1", "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC1/", "https://uni.fi/job/1")
  r <- jw_search_refine(q, noisy, round = 1)
  expect_true(r$rerun); expect_equal(r$noise_share, 0.8)
  expect_true(all(c("ziprecruiter.com", "indeed.com", "arxiv.org", "ncbi.nlm.nih.gov") %in% r$noisy_domains))
  expect_match(r$query_next, "-site:ziprecruiter.com", fixed = TRUE)
  expect_false(jw_search_refine(r$query_next, noisy, round = 2)$rerun)
  expect_false(jw_search_refine(q, noisy, round = 3)$rerun)
  expect_false(jw_search_refine(q, c("https://uni.fi/a", "https://uni.se/b", "https://indeed.com/c"))$rerun)
  expect_false(jw_search_refine(q, character())$rerun)
})
