#' Run covr on a package and upload the result to coveralls
#'
#' On GitHub Actions, use the official
#' [Coveralls action](https://github.com/coverallsapp/github-action) instead of
#' this function: write the coverage with [to_cobertura()] and upload
#' `cobertura.xml` with `coverallsapp/github-action@v2`. See the README for an
#' example workflow.
#'
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
#' When `repo_token` is set and `service_name` is \sQuote{drone},
#' \sQuote{jenkins}, \sQuote{travis-pro} or \sQuote{github-actions},
#' information about the current git commit, branch and remote is also
#' submitted.
#' @param quiet if `FALSE`, print the coverage before submission.
#' @export
coveralls <- function(
  ...,
  coverage = NULL,
  repo_token = Sys.getenv("COVERALLS_TOKEN"),
  service_name = Sys.getenv("CI_NAME", "travis-ci"),
  quiet = TRUE
) {
  if (is.null(coverage)) {
    coverage <- package_coverage(..., quiet = quiet)
  }

  if (!quiet) {
    print(coverage)
  }

  service <- tolower(service_name)

  coveralls_url <- "https://coveralls.io/api/v1/jobs"
  coverage_json <- to_coveralls(
    coverage,
    repo_token = repo_token,
    service_name = service
  )

  result <- RETRY(
    "POST",
    url = coveralls_url,
    body = list(json_file = upload_file(to_file(coverage_json)))
  )

  content <- content(result)
  if (isTRUE(content$error)) {
    stop(
      "Failed to upload coverage data. Reply by Coveralls: ",
      content$message
    )
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

to_coveralls <- function(
  x,
  service_job_id = Sys.getenv("TRAVIS_JOB_ID"),
  service_name,
  repo_token = ""
) {
  coverages <- per_line(x)

  res <- Map(
    function(coverage, name) {
      source_code <- paste(collapse = "\n", coverage$file$file_lines)
      list(
        "name" = jsonlite::unbox(name),
        "source" = jsonlite::unbox(source_code),
        "source_digest" = jsonlite::unbox(digest::digest(
          source_code,
          algo = "md5",
          serialize = FALSE
        )),
        "coverage" = coverage$coverage
      )
    },
    coverages,
    names(coverages),
    USE.NAMES = FALSE
  )

  git <- switch(
    service_name,
    drone = git_info(), # drone has the same env vars as jenkins
    jenkins = git_info(),
    'travis-pro' = git_info(),
    'github-actions' = git_info(
      branch = github_actions_branch(),
      remote = system_output("git", c("config", "--get", "remote.origin.url"))
    ),
    list(NULL)
  )

  payload <- if (!nzchar(repo_token)) {
    list(
      "service_job_id" = jsonlite::unbox(service_job_id),
      "service_name" = jsonlite::unbox(service_name),
      "source_files" = res
    )
  } else {
    tmp <- list(
      "repo_token" = jsonlite::unbox(repo_token),
      "service_name" = jsonlite::unbox(service_name),
      "source_files" = res
    )
    tmp$git <- git
    tmp
  }

  jsonlite::toJSON(na = "null", payload)
}

git_info <- function(
  branch = Sys.getenv("CI_BRANCH"),
  remote = Sys.getenv("CI_REMOTE")
) {
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
  head <- lapply(
    structure(
      scan(
        sep = "\n",
        what = "character",
        text = system_output(
          "git",
          c(
            "log",
            "-n",
            "1",
            paste0("--pretty=format:", paste(collapse = "%n", formats))
          )
        ),
        quiet = TRUE
      ),
      names = names(formats)
    ),
    jsonlite::unbox
  )

  remotes <- list(list(
    name = jsonlite::unbox("origin"),
    url = jsonlite::unbox(remote)
  ))

  c(
    list(branch = jsonlite::unbox(branch)),
    head = list(head),
    remotes = list(remotes)
  )
}

# `GITHUB_REF_NAME` is `<pr_number>/merge` for pull requests, so use the source
# branch in `GITHUB_HEAD_REF` when it is set.
github_actions_branch <- function() {
  branch <- Sys.getenv("GITHUB_HEAD_REF")
  if (nzchar(branch)) {
    return(branch)
  }
  Sys.getenv("GITHUB_REF_NAME")
}
