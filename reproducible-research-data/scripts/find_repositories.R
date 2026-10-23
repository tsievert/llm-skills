# Look up data repositories in re3data (https://www.re3data.org), the registry of research data repositories.
# Source this file, then: re3data_search("Aarhus"); re3data_info("r3d100012617").
# Keyless public API (beta). Needs httr2 and xml2. Read-only. A registry entry can be outdated or incomplete:
# it tells you what to look at, not what is currently allowed. Open the repository's own pages before advising.

.re3_get <- function(url, query = list()) {
  r <- httr2::request(url) |>
    httr2::req_url_query(!!!query) |>
    httr2::req_user_agent("llm-skills research (R httr2)") |>
    httr2::req_timeout(30) |>
    httr2::req_error(is_error = function(x) FALSE) |>
    httr2::req_perform()
  if (httr2::resp_status(r) != 200) stop("re3data returned HTTP ", httr2::resp_status(r), " for ", url)
  xml2::read_xml(httr2::resp_body_string(r))
}

.re3_txt <- function(x, name, first = FALSE) {
  v <- xml2::xml_text(xml2::xml_find_all(x, sprintf(".//*[local-name()='%s']", name)))
  v <- unique(v[nzchar(v)])
  if (first && length(v)) v[1] else paste(v, collapse = "; ")
}

#' Search re3data by free text (repository name, institution, city, subject).
#' @return data frame: id, name, doi (registry DOI of the entry). Names only: use re3data_info() for details.
re3data_search <- function(query) {
  x <- .re3_get("https://www.re3data.org/api/beta/repositories", list(query = query))
  nodes <- xml2::xml_find_all(x, "//*[local-name()='repository']")
  if (!length(nodes)) return(data.frame(id = character(), name = character(), doi = character()))
  data.frame(
    id = vapply(nodes, function(n) .re3_txt(n, "id", TRUE), ""),
    name = vapply(nodes, function(n) .re3_txt(n, "name", TRUE), ""),
    doi = vapply(nodes, function(n) .re3_txt(n, "doi", TRUE), ""),
    stringsAsFactors = FALSE
  )
}

#' Details of one re3data entry (repository id such as "r3d100012617").
#' @return one-row data frame with the fields that matter for a deposit decision.
re3data_info <- function(id) {
  x <- .re3_get(paste0("https://www.re3data.org/api/beta/repository/", id))
  data.frame(
    id = id,
    name = .re3_txt(x, "repositoryName", TRUE),
    url = .re3_txt(x, "repositoryURL", TRUE),
    institution = .re3_txt(x, "institutionName"),
    country = .re3_txt(x, "institutionCountry"),
    content = .re3_txt(x, "contentType"),
    pid_system = .re3_txt(x, "pidSystem"),
    data_license = .re3_txt(x, "dataLicenseName"),
    upload = .re3_txt(x, "dataUploadType"),
    upload_restriction = .re3_txt(x, "dataUploadRestriction"),
    versioning = .re3_txt(x, "versioning"),
    last_update = .re3_txt(x, "lastUpdate", TRUE),
    stringsAsFactors = FALSE
  )
}

#' Search several terms and return the union with the terms that found each entry.
#' Typical terms: the institution, its city, and the country's national platform.
re3data_search_many <- function(queries) {
  res <- lapply(queries, function(q) {
    d <- tryCatch(re3data_search(q), error = function(e) NULL)
    if (is.null(d) || !nrow(d)) return(NULL)
    d$found_by <- q
    d
  })
  res <- do.call(rbind, res)
  if (is.null(res)) return(data.frame(id = character(), name = character(), doi = character(), found_by = character()))
  agg <- stats::aggregate(found_by ~ id + name + doi, data = res, FUN = function(z) paste(unique(z), collapse = " | "))
  agg[order(agg$name), ]
}
