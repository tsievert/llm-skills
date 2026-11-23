# Offline tests for the generic fetch ladder in web-fetching-r/scripts/polite_fetch.R (httr2 mocked responses).
library(testthat)
here <- normalizePath(file.path(dirname(sys.frame(1)$ofile %||% "."), "..", "..", "..", ".."), mustWork = FALSE)
if (!file.exists(file.path(here, "web-fetching-r", "scripts", "polite_fetch.R"))) here <- normalizePath(file.path(getwd(), "..", "..", "..", ".."))
suppressMessages(source(file.path(here, "web-fetching-r", "scripts", "polite_fetch.R")))

resp <- function(status, body = "", headers = list(), url = "https://x.test/") {
  httr2::response(status_code = status, url = url, headers = c(list(`Content-Type` = "text/html"), headers), body = charToRaw(body))
}
ua <- "tool/0.1 (testing; low rate)"
fresh <- function() list(state = new.env(), learned = new.env())

test_that("compatible user agent keeps the tool name and purpose", {
  expect_equal(pf_ua_compat(ua), "Mozilla/5.0 (compatible; tool/0.1; testing; low rate)")
  expect_equal(pf_ua_compat("plain"), "Mozilla/5.0 (compatible; plain)")
})

test_that("failure classes: challenge page and header beat plain 403; 404, 5xx, other 4xx, network", {
  expect_equal(pf_failure_class(resp(200)), "ok")
  expect_equal(pf_failure_class(resp(403)), "forbidden")
  expect_equal(pf_failure_class(resp(403, "<title>Just a moment...</title>")), "challenge")
  expect_equal(pf_failure_class(resp(403, "x", list(`cf-mitigated` = "challenge"))), "challenge")
  expect_equal(pf_failure_class(resp(404)), "not_found")
  expect_equal(pf_failure_class(resp(503)), "transient")
  expect_equal(pf_failure_class(resp(418)), "client_error")
  expect_equal(pf_failure_class(NULL, simpleError("x")), "network")
})

test_that("URL variants: language subdomain/path, www, https, slash; query kept byte for byte", {
  v <- pf_url_variants("http://en.site.test/en/jobs?a=1&b=%5B0%5D", 10)
  expect_true("http://site.test/en/jobs?a=1&b=%5B0%5D" %in% v$url)
  expect_true("http://en.site.test/jobs?a=1&b=%5B0%5D" %in% v$url)
  expect_true("https://en.site.test/en/jobs?a=1&b=%5B0%5D" %in% v$url)
  expect_false("http://en.site.test/en/jobs?a=1&b=%5B0%5D" %in% v$url)
  expect_equal(anyDuplicated(v$url), 0L)
  expect_true(any(grepl("/jobs/\\?a=1", pf_url_variants("https://a.test/jobs?a=1", 10)$url)))
})

test_that("ladder: 403 then compatible user agent works and the host remembers it", {
  s <- fresh(); seen <- character()
  httr2::with_mocked_responses(function(req) { seen <<- c(seen, req$headers$`User-Agent` %||% req$options$useragent)
    if (grepl("compatible", req$options$useragent)) resp(200, "<html></html>") else resp(403) }, {
    r <- pf_fetch_ladder("https://a.test/jobs", ua, min_interval = 0, state = s$state, learned = s$learned)
    expect_true(r$ok); expect_equal(r$route, "ua_compat"); expect_equal(r$failure_class, "forbidden")
    r2 <- pf_fetch_ladder("https://a.test/other", ua, min_interval = 0, state = s$state, learned = s$learned)
    expect_equal(nrow(r2$attempts), 1L); expect_equal(r2$route, "ua_compat")
  })
})

test_that("ladder: a challenge stops at once, with no variants and no user-agent switch", {
  s <- fresh(); n <- 0L
  httr2::with_mocked_responses(function(req) { n <<- n + 1L; resp(403, "<title>Just a moment...</title>") }, {
    r <- pf_fetch_ladder("https://en.a.test/jobs", ua, min_interval = 0, state = s$state, learned = s$learned)
  })
  expect_false(r$ok); expect_equal(r$failure_class, "challenge"); expect_equal(n, 1L)
})

test_that("ladder: a failing language subdomain is recovered by the neutral host; 404 tries only language variants", {
  s <- fresh(); hosts <- character()
  httr2::with_mocked_responses(function(req) { hosts <<- c(hosts, httr2::url_parse(req$url)$hostname)
    if (httr2::url_parse(req$url)$hostname == "a.test") resp(200, "ok") else resp(502) }, {
    r <- pf_fetch_ladder("https://en.a.test/jobs", ua, min_interval = 0, state = s$state, learned = s$learned)
  })
  expect_true(r$ok); expect_equal(r$route, "variant:drop-language-subdomain")
  s <- fresh(); n <- 0L
  httr2::with_mocked_responses(function(req) { n <<- n + 1L; resp(404) }, {
    r <- pf_fetch_ladder("https://www.a.test/jobs", ua, min_interval = 0, state = s$state, learned = s$learned)
  })
  expect_false(r$ok); expect_equal(r$failure_class, "not_found"); expect_equal(n, 1L)
})
