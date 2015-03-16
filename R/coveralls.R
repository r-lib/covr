#' Run covr on a package and upload the result to coveralls
#' @param path file path to the package
#' @param repo_token The secret repo token for your repository,
#' found at the bottom of your repository's page on Coveralls. This is useful
#' if your job is running on a service Coveralls doesn't support out-of-the-box.
#' If set to NULL, it is assumed that the job is running on travis-ci
#' @param ... additional arguments passed to \code{\link{package_coverage}}
#' @export
coveralls <- function(path = ".", repo_token = NULL, ...) {
  coveralls_url <- "https://coveralls.io/api/v1/jobs"
  coverage <- to_coveralls(package_coverage(path, relative_path = TRUE, ...), repo_token = repo_token)

  name <- tempfile()
  con <- file(name)
  writeChar(con = con, coverage, eos = NULL)
  close(con)
  on.exit(unlink(name))
  httr::content(httr::POST(coveralls_url, body = list(json_file = httr::upload_file(name))))
}

to_coveralls <- function(x, service_job_id = Sys.getenv("TRAVIS_JOB_ID"), service_name = "travis-ci", repo_token = repo_token) {
  coverages <- per_line(x)

  coverage_names <- names(coverages)

  if (!is.null(attr(x, "path"))) {
    coverage_names <- file.path(attr(x, "path"), coverage_names)
  }

  sources <- lapply(coverage_names,
    function(x) {
      readChar(x, file.info(x)$size, useBytes=TRUE)
    })

  res <- mapply(
    function(name, source, coverage) {
      list("name" = jsonlite::unbox(name),
        "source" = jsonlite::unbox(source),
        "coverage" = coverage)
    },
    coverage_names,
    sources,
    coverages,
    SIMPLIFY = FALSE,
    USE.NAMES = FALSE)

  payload <- if (is.null(repo_token)) {
    list(
      "service_job_id" = jsonlite::unbox(service_job_id),
      "service_name" = jsonlite::unbox(service_name),
      "source_files" = res)
  } else {
    list(
      "repo_token" = jsonlite::unbox(repo_token),
      "source_files" = res)
  }

  jsonlite::toJSON(na = "null", payload)
}

per_line <- function(x) {

  df <- as.data.frame(x)

  filenames <- unique(df$filename)

  if (!is.null(attr(x, "path"))) {
    filenames <- file.path(attr(x, "path"), filenames)
  }

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
