#' Run covr on a package and upload the result to coveralls
#' @param path file path to the package
#' @param ... additional arguments passed to \code{\link{package_coverage}}
#' @export
coveralls <- function(path = ".", ...) {
  coveralls_url <- "https://coveralls.io/api/v1/jobs"
  coverage <- to_coveralls(package_coverage(path, relative_path = TRUE, ...))

  name <- tempfile()
  con <- file(name)
  writeChar(con = con, coverage, eos = NULL)
  close(con)
  on.exit(unlink(name))
  httr::content(httr::POST(coveralls_url, body = list(json_file = httr::upload_file(name))))
}

to_coveralls <- function(x, service_job_id = Sys.getenv("TRAVIS_JOB_ID"), service_name = "travis-ci") {
  coverages <- per_line(x)

  names <- names(coverages)

  sources <- lapply(names(coverages),
    function(x) {
      readChar(x, file.info(x)$size)
    })

  res <- mapply(
    function(name, source, coverage) {
      list("name" = jsonlite::unbox(name),
        "source" = jsonlite::unbox(source),
        "coverage" = coverage)
    },
    names,
    sources,
    coverages,
    SIMPLIFY = FALSE,
    USE.NAMES = FALSE)

  jsonlite::toJSON(na = "null", list(
    "service_job_id" = jsonlite::unbox(service_job_id),
    "service_name" = jsonlite::unbox(service_name),
    "source_files" = res))
}
