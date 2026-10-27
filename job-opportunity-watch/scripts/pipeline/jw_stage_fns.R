# jw_stage_fns.R -- the mechanical stage functions of the weekly pipeline (s1-s3). Each returns the data
# frame its contract (jw_contracts.R) defines; jw_stage_run() writes, validates and records it.
#   jw_s1_probe(week)      s1 sources (+ side file s1_anchors): probe every unique link, flag navigation-only pages
#   jw_s1_expected_n(week) number of unique enabled links; the s1 completeness gate compares against it
#   jw_s2_queue(week)      s2 queue: anchors not seen in an earlier week, profile-derived prefilter with a reason
#   jw_s3_deadlines(week)  s3 deadlines: stated deadline for every s2 item (text first, then page for topic hits)
# Needs jobwatch.R (and web-fetching-r's polite_fetch.R before it) and jw_checks.R sourced. Network access is
# injected (probe_fn, links_fn, fetch_fn) so the tests run offline.

jw_input_path <- function(f, week = jw_week_id(), root = jw_root()) {   # frozen copy first, then the live file
  fz <- file.path(jw_run_dir(week, root), "inputs", f)
  if (file.exists(fz)) fz else file.path(root, f)
}
.read_profile <- function(week, root) {
  p <- jw_input_path("job_profile.yml", week, root)
  if (file.exists(p)) yaml::read_yaml(p) else NULL
}
.href_key <- function(u) sub("/+$", "", sub("#.*$", "", u))

# ---- s1 ------------------------------------------------------------------------------------------
jw_s1_expected_n <- function(week = jw_week_id(), root = jw_root(), links_fn = jw_read_links) {
  l <- links_fn(jw_input_path("links.csv", week, root))
  sum(is.na(l$dup_of))
}

jw_s1_probe <- function(week = jw_week_id(), root = jw_root(), today = Sys.Date(), delay = 1.5,
                        probe_fn = jw_probe, links_fn = jw_read_links, verbose = !nzchar(Sys.getenv("JW_QUIET"))) {
  links <- links_fn(jw_input_path("links.csv", week, root))
  run <- probe_fn(links, delay = delay, profile = .read_profile(week, root), verbose = verbose)
  uniq <- links[is.na(links$dup_of), ]
  a <- run$anchors
  a$job_like <- if (nrow(a)) jw_anchor_job_like(a$text, a$href, a$role_hit, a$topic_hit) else logical()
  a <- a[!duplicated(paste(a$source_id, .href_key(a$href))), c("source_id", "text", "href", "job_like")]
  n_job <- vapply(uniq$id, function(i) sum(a$job_like[a$source_id == i]), 0)
  m <- match(uniq$id, run$sources$id); s <- run$sources[m, ]
  lost <- is.na(m)                                              # a link the probe returned nothing for is an error row
  status <- ifelse(lost, "error", s$status)
  out <- data.frame(source_id = uniq$id, url = uniq$url, section = uniq$section, type = uniq$type, status = status,
                    http = as.integer(s$http), n_anchors = as.integer(ifelse(lost, 0L, s$n_anchors)),
                    n_job_like = as.integer(n_job), flag = jw_source_flag(status, n_job),
                    note = ifelse(lost, "no probe result", as.character(s$note)), checked = as.Date(today),
                    stringsAsFactors = FALSE)
  jw_write_stage(a, "s1_anchors", week, root)
  out
}

# ---- s2 ------------------------------------------------------------------------------------------
# hrefs seen in earlier, finished weeks (stateless: derived from their s1_anchors files, so a rerun of the same
# week gives the same queue and an unfinished earlier week does not count as "seen").
.prior_hrefs <- function(week, root) {
  wk <- sort(grep("^\\d{4}-W\\d{2}$", list.files(file.path(root, "runs")), value = TRUE)); wk <- wk[wk < week]
  hrefs <- character(); used <- character()
  for (w in wk) {
    rd <- jw_run_dir(w, root); f <- file.path(rd, jw_contracts()$s1_anchors$file)
    if (!identical(jw_manifest_read(rd)$stages$s1$status, "done") || !file.exists(f)) next
    hrefs <- c(hrefs, .read_pq(f)$href); used <- c(used, w)
  }
  list(keys = unique(.href_key(hrefs)), weeks = used)
}

jw_s2_queue <- function(week = jw_week_id(), root = jw_root(), today = Sys.Date()) {
  a <- jw_read_stage("s1_anchors", week, root)
  prior <- .prior_hrefs(week, root)
  if (!length(prior$weeks))
    jw_problem("s2", "s2_baseline", "no earlier finished week: every link counts as new (baseline week)", "info", 1L, week, root)
  new <- a[!.href_key(a$href) %in% prior$keys & !duplicated(.href_key(a$href)), ]
  cl <- jw_prefilter(new, jw_profile_terms(.read_profile(week, root) %||% list()))
  drop <- cl[is.na(cl$tier), ]
  if (nrow(drop))
    jw_problem("s2", "s2_dropped", paste0(nrow(drop), " new link(s) dropped by the prefilter: ",
               paste(names(table(drop$reason)), table(drop$reason), sep = " x", collapse = "; ")), "info", nrow(drop), week, root)
  kept <- cl[!is.na(cl$tier), ]
  data.frame(item_id = vapply(kept$href, function(h) substr(rlang::hash(.href_key(h)), 1, 12), "", USE.NAMES = FALSE),
             source_id = kept$source_id, text = kept$text, href = kept$href, tier = as.integer(kept$tier),
             reason = kept$reason, first_seen = rep(as.Date(today), nrow(kept)), stringsAsFactors = FALSE)
}

# ---- s3 ------------------------------------------------------------------------------------------
# Page text for one URL, or NULL when unreadable (error or HTTP >= 400). Polite: waits between requests per host.
jw_page_text <- function(url, timeout = 20, delay = 1.5, state = .jw_s3_state) {
  pf_wait(pf_host(url), delay, state = state)
  r <- pf_perform(url, jw_ua, timeout = timeout, max_tries = 1)
  if (!is.null(r$error) || httr2::resp_status(r$response) >= 400) return(NULL)
  tryCatch(jw_html_text(.clean(httr2::resp_body_string(r$response))), error = function(e) NULL)
}
.jw_s3_state <- new.env()

# Step 1 reads only the link text: an expired date next to a deadline cue settles an item without a request.
# Step 2 fetches the page for items with topic words (tier 1), in chunks, saving progress after every chunk so a
# stopped run resumes. Tier-2 items (role or job-like title only) are "not_checked": the title skim in s4 decides
# whether they deserve a look. Dates in the URL are not used: they are usually posting dates, not deadlines.
jw_s3_deadlines <- function(week = jw_week_id(), root = jw_root(), today = Sys.Date(), chunk = 150,
                            fetch_fn = jw_page_text) {
  s2 <- jw_read_stage("s2", week, root)
  empty <- function() data.frame(item_id = character(), deadline = as.Date(character()), verdict = character(),
                                 flag = character(), dates = character(), stringsAsFactors = FALSE)
  if (!nrow(s2)) return(empty())
  rows <- function(ids, d) cbind(item_id = ids, d)
  pre <- do.call(rbind, lapply(s2$text, function(t) jw_deadline_row(jw_deadline_from_text(t, today), today)))
  settled <- pre$verdict == "expired"
  res <- rows(s2$item_id[settled], pre[settled, ])
  todo <- s2[!settled & s2$tier == 1L, ]
  part_f <- file.path(jw_run_dir(week, root), "s3_partial.parquet")
  done <- if (file.exists(part_f)) as.data.frame(.read_pq(part_f)) else empty()
  done <- done[done$item_id %in% todo$item_id, ]
  todo <- todo[!todo$item_id %in% done$item_id, ]
  t_loop <- Sys.time(); n_done <- 0L; n_todo <- nrow(todo)
  if (n_todo) message(sprintf("s3: %d settled from link text, %d pages to read", sum(settled), n_todo))
  for (i in split(seq_len(nrow(todo)), ceiling(seq_len(nrow(todo)) / chunk))) {
    got <- lapply(todo$href[i], function(u) {
      n_done <<- n_done + 1L
      # jw_tick lives in jobwatch.R, which the offline tests do not source
      if ((n_done %% 10 == 0 || n_done == n_todo) && exists("jw_tick", mode = "function")) jw_tick(n_done, n_todo, t_loop, substr(u, 1, 70))
      b <- tryCatch(fetch_fn(u), error = function(e) NULL)
      if (is.null(b)) data.frame(deadline = as.Date(NA), verdict = "unreadable", flag = NA_character_, dates = NA_character_)
      else tryCatch(jw_deadline_row(jw_deadline_from_text(b, today), today),
                    error = function(e) data.frame(deadline = as.Date(NA), verdict = "parse_error", flag = NA_character_, dates = NA_character_))
    })
    done <- rbind(done, rows(todo$item_id[i], do.call(rbind, got)))
    jw_write_parquet(done, part_f, jw_contracts()$s3$schema)
  }
  unchecked <- !s2$item_id %in% c(res$item_id, done$item_id)
  res <- rbind(res, done, rows(s2$item_id[unchecked], data.frame(deadline = as.Date(NA), verdict = "not_checked",
                                                                    flag = NA_character_, dates = NA_character_)[rep(1, sum(unchecked)), ]))
  unlink(part_f)
  res[match(s2$item_id, res$item_id), ]
}
