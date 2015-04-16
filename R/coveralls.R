#' Run covr on a package and upload the result to coveralls
#' @param path file path to the package
#' @param repo_token The secret repo token for your repository,
#' found at the bottom of your repository's page on Coveralls. This is useful
#' if your job is running on a service Coveralls doesn't support out-of-the-box.
#' If set to NULL, it is assumed that the job is running on travis-ci
#' @param ... additional arguments passed to \code{\link{package_coverage}}
#' @export
coveralls <- function(path = ".", repo_token = NULL, ...) {

  find_ci_name <- function() {
    service <- tolower(Sys.getenv("CI_NAME"))
    ifelse(service == "", "travis-ci", service)
  }
  coveralls_url <- "https://coveralls.io/api/v1/jobs"
  coverage <- to_coveralls(package_coverage(path, relative_path = TRUE, ...),
    repo_token = repo_token, service_name = find_ci_name())

  result <- httr::POST(url = coveralls_url, body = coverage, encode = "json")
  content <- httr::content(result)
  if (isTRUE(content$error)) {
    stop("Failed to upload coverage data. Reply by Coveralls: ", content$message)
  }
  content
}

to_coveralls <- function(x, service_job_id = Sys.getenv("TRAVIS_JOB_ID"),
                         service_name, repo_token = NULL) {

  coverages <- per_line(x)

  res <- lapply(coverages,
    function(coverage) {
      list(
        "name" = jsonlite::unbox(coverage$file$filename),
        "source" = jsonlite::unbox(paste(collapse = "\n", coverage$file$lines)),
        "coverage" = coverage$coverage)
    })

  git_info <- switch(service_name,
    drone = jenkins_git_info(), # drone has the same env vars as jenkins
    jenkins = jenkins_git_info(),
    NULL
  )

  payload <- if (is.null(repo_token)) {
    list(
      "service_job_id" = jsonlite::unbox(service_job_id),
      "service_name" = jsonlite::unbox(service_name),
      "source_files" = res)
  } else {
    tmp <- list(
      "repo_token" = jsonlite::unbox(repo_token),
      "source_files" = res)
    tmp$git <- list(git_info)
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
      sep="\n",
      what = "character",
      text=system(intern=TRUE,
        paste0("git log -n 1 --pretty=format:",
          paste(collapse="%n", formats)
        )
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

per_line <- function(coverage) {

  files <- traced_files(coverage)

  blank_lines <- lapply(files, function(file) {
    which(rex::re_matches(file$lines, rex::rex(start, any_spaces, maybe("#", anything), end)))
    })

  file_lengths <- lapply(files, function(file) {
    length(file$lines)
  })

  res <- lapply(file_lengths,
    function(x) {
      rep(NA_real_, length.out = x)
    })

  for (i in seq_along(coverage)) {
    x <- coverage[[i]]
    file_address <- address(attr(x$srcref, "srcfile"))
    value <- x$value
    for (line in seq(x$srcref[1], x$srcref[3])) {
      # if it is not a blank line
      if (!line %in% blank_lines[[file_address]]) {

      # if current coverage is na or coverage is less than current coverage
        if (is.na(res[[file_address]][line]) || value < res[[file_address]][line]) {
          res[[file_address]][line] <- value
        }
      }
    }
  }
  Map(function(file, coverage) {
      list(file=file, coverage=coverage)
    },
    files, res)
}
