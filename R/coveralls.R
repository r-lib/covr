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
per_line <- function(x) {

  df <- as.data.frame(x)

  filenames <- unique(df$filename)
  sources <- lapply(filenames, readLines)

  blank_lines <- lapply(sources, function(file) {
    which(rex::re_matches(file, rex::rex(start, any_spaces, maybe("#", anything), end)))
    })
  names(blank_lines) <- filenames

  file_lengths <- tapply(df$last_line, df$filename,

    function(x) {
      max(unlist(x))
    })

  res <- lapply(file_lengths,
    function(x) {
      rep(NA_real_, length.out = x)
    })

  # get the minimum coverage per line
  for (i in seq_len(NROW(df))) {
    for (line in seq(df[i, "first_line"], df[i, "last_line"])) {
      filename <- df[i, "filename"]
      value <- df[i, "value"]
      if (!line %in% blank_lines[[filename]]) {
        if (is.na(res[[filename]][line]) || value < res[[filename]][line]) {
          res[[filename]][line] <- value
        }
      }
    }
  }
  res
}
