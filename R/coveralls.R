#' Run covr on a package and upload the result to coveralls
#' @param coverage an existing coverage object to submit, if `NULL`,
#' [package_coverage()] will be called with the arguments from
#' `...`
#' @param ... arguments passed to [package_coverage()]
#' @param repo_token The secret repo token for your repository,
#' found at the bottom of your repository's page on Coveralls. This is useful
#' if your job is running on a service Coveralls doesn't support out-of-the-box.
#' If set to NULL, it is assumed that the job is running on travis-ci
#' @param service_name the CI service to use, if environment variable
#' \sQuote{CI_NAME} is set that is used, otherwise \sQuote{travis-ci} is used.
#' @param quiet if `FALSE`, print the coverage before submission.
#' @export
coveralls <- function(..., coverage = NULL,
                      repo_token = Sys.getenv("COVERALLS_TOKEN"),
                      service_name = Sys.getenv("CI_NAME", "travis-ci"),
                      quiet = TRUE) {

  if (is.null(coverage)) {
    coverage <- package_coverage(..., quiet = quiet)
  }

  if (!quiet) {
    print(coverage)
  }

  service <- tolower(service_name)

  coveralls_url <- "https://coveralls.io/api/v1/jobs"
  coverage_json <- to_coveralls(coverage,
    repo_token = repo_token, service_name = service)

  result <- RETRY("POST", url = coveralls_url,
    body = list(json_file = upload_file(to_file(coverage_json))))

  content <- content(result)
  if (isTRUE(content$error)) {
    stop("Failed to upload coverage data. Reply by Coveralls: ", content$message)
  }
  content
}

to_file <- function(x) {
  name <- temp_file()
  con <- file(name)
  writeChar(con = con, x, eos = NULL)
  close(con)
  name
}

to_coveralls <- function(x, service_job_id = Sys.getenv("TRAVIS_JOB_ID"),
                         service_name, repo_token = "") {

  coverages <- per_line(x)

  res <- Map(function(coverage, name) {
      source_code <- paste(collapse = "\n", coverage$file$file_lines)
      list(
        "name" = jsonlite::unbox(name),
        "source" = jsonlite::unbox(source_code),
        "source_digest" = jsonlite::unbox(digest::digest(source_code, algo = "md5", serialize = FALSE)),
        "coverage" = coverage$coverage)
    }, coverages, names(coverages), USE.NAMES = FALSE)

  git_info <- switch(service_name,
    drone = jenkins_git_info(), # drone has the same env vars as jenkins
    jenkins = jenkins_git_info(),
    'travis-pro' = jenkins_git_info(),
    list(NULL)
  )

  payload <- if (!nzchar(repo_token)) {
    list(
      "service_job_id" = jsonlite::unbox(service_job_id),
      "service_name" = jsonlite::unbox(service_name),
      "source_files" = res)
  } else {
    tmp <- list(
      "repo_token" = jsonlite::unbox(repo_token),
      "service_name" = jsonlite::unbox(service_name),
      "source_files" = res)
    tmp$git <- git_info
    tmp
  }

  jsonlite::toJSON(na = "null", payload)
}

jenkins_git_info <- function() {
  # check https://coveralls.zendesk.com/hc/en-us/articles/201350799-API-Reference
  # for why and how we are doing this
  formats <- c(
    id = "%H",
    author_name = "%an",
    author_email = "%ae",
    commiter_name = "%cn",
    commiter_email = "%ce",
    message = "%s"
  )
  head <- lapply(structure(
    scan(
      sep = "\n",
      what = "character",
      text = system_output("git", c("log", "-n", "1",
          paste0("--pretty=format:", paste(collapse = "%n", formats)))
        ),
      quiet = TRUE
    ),
    names = names(formats)
  ), jsonlite::unbox)

  remotes <- list(list(
    name = jsonlite::unbox("origin"),
    url = jsonlite::unbox(Sys.getenv("CI_REMOTE"))
  ))

  c(list(branch = jsonlite::unbox(Sys.getenv("CI_BRANCH"))),
    head = list(head),
    remotes = list(remotes))
}
