#' Run covr on a package and upload the result to coveralls
#'
#' On GitHub Actions, use the official
#' [Coveralls action](https://github.com/coverallsapp/github-action) instead of
#' this function: write the coverage with [to_cobertura()] and upload
#' `cobertura.xml` with `coverallsapp/github-action@v2`. See the README for an
#' example workflow. With branch coverage, upload the LCOV file written by
#' [to_lcov()] instead, as the action reads which branches were taken from it.
#'
#' With branch coverage (see [covr.branch_coverage]), each source file sent to
#' Coveralls also has its `branches`: the line, block, branch and count of
#' each branch, as in [to_lcov()]. A branch that was never taken has a count of
#' zero.
#'
#' The CI service, job, pull request, branch and commit are detected from the
#' environment variables of the services [codecov()] supports. Anywhere else,
#' the branch, commit and remote are looked up from the local git repository.
#' The environment variables `CI_BRANCH` and `CI_REMOTE` override the detected
#' branch and remote.
#'
#' @param coverage an existing coverage object to submit, if `NULL`,
#' [package_coverage()] will be called with the arguments from
#' `...`
#' @param ... arguments passed to [package_coverage()]
#' @param repo_token The secret repo token for your repository, found on your
#' repository's page on Coveralls. Without a token (`""` or `NULL`), only the
#' CI service and job are submitted, which Coveralls only accepts from Travis
#' CI. With a token, information about the git commit, branch and remote is
#' also submitted.
#' @param service_name The name of the CI service. If `NULL`, the environment
#' variable `CI_NAME` is used if it is set, otherwise the CI service is
#' detected from the environment, e.g. \sQuote{github} on GitHub Actions and
#' \sQuote{travis-ci} on Travis CI. Outside a supported CI service it is
#' \sQuote{local}.
#' @param quiet if `FALSE`, print the coverage before submission.
#' @export
coveralls <- function(
  ...,
  coverage = NULL,
  repo_token = Sys.getenv("COVERALLS_TOKEN"),
  service_name = NULL,
  quiet = TRUE
) {
  if (is.null(coverage)) {
    coverage <- package_coverage(..., quiet = quiet)
  }

  if (!quiet) {
    print(coverage)
  }

  coveralls_url <- "https://coveralls.io/api/v1/jobs"
  coverage_json <- to_coveralls(
    coverage,
    repo_token = repo_token,
    service_name = service_name
  )

  result <- RETRY(
    "POST",
    url = coveralls_url,
    body = list(json_file = upload_file(to_file(coverage_json)))
  )

  content <- content(result)
  if (isTRUE(content$error)) {
    covr_abort(c(
      "Can't upload coverage to Coveralls.",
      x = "{content$message}"
    ))
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

to_coveralls <- function(x, repo_token = "", service_name = NULL) {
  coverages <- per_line(x)
  branches <- if (!is.null(attr(x, "branches"))) {
    tally_coverage(x, by = "branch")
  }

  res <- Map(
    function(coverage, name) {
      source_code <- paste(collapse = "\n", coverage$file$file_lines)
      file <- list(
        "name" = jsonlite::unbox(name),
        "source" = jsonlite::unbox(source_code),
        "source_digest" = jsonlite::unbox(digest::digest(
          source_code,
          algo = "md5",
          serialize = FALSE
        )),
        "coverage" = coverage$coverage
      )
      if (!is.null(branches)) {
        file_branches <- branches[branches$filename == name, , drop = FALSE]
        if (NROW(file_branches)) {
          file$branches <- coveralls_branches(file_branches)
        }
      }
      file
    },
    coverages,
    names(coverages),
    USE.NAMES = FALSE
  )

  info <- coveralls_ci_info(service_name)
  has_token <- !is.null(repo_token) && nzchar(repo_token)
  payload <- compact(list(
    "repo_token" = if (has_token) jsonlite::unbox(repo_token),
    "service_name" = jsonlite::unbox(info$service_name),
    "service_job_id" = unbox_or_null(info$job_code),
    "service_pull_request" = unbox_or_null(codecov_pr(info$pr)),
    "source_files" = res,
    "git" = if (has_token) git_info(info)
  ))

  jsonlite::toJSON(na = "null", payload)
}

# The `branches` of a Coveralls source file, a flat array with the line, block,
# branch and count of each branch, from the branches of the file from
# `tally_coverage(by = "branch")`. Blocks and branches are numbered from zero
# as in `to_lcov()`.
coveralls_branches <- function(df) {
  as.vector(rbind(df$line, branch_blocks(df), df$branch - 1L, df$value))
}

# What the CI service knows about the build, as for `codecov()`, with the name
# Coveralls' own uploader uses for the service.
coveralls_ci_info <- function(service_name = NULL) {
  info <- codecov_ci_info()
  info$service_name <- tolower(
    service_name %||%
      env_var("CI_NAME") %||%
      coveralls_service_name(info$ci_service)
  )
  info
}

coveralls_service_name <- function(ci_service) {
  if (is.null(ci_service)) {
    return("local")
  }
  switch(
    ci_service,
    travis = "travis-ci",
    drone.io = "drone",
    gitlab = "gitlab-ci",
    `github-actions` = "github",
    ci_service
  )
}

git_info <- function(info = list()) {
  # https://docs.coveralls.io/api-jobs-endpoint
  branch <- env_var("CI_BRANCH") %||% info$branch %||% try_git(local_branch())
  remote <- env_var("CI_REMOTE") %||% info$remote %||% try_git(git_remote_url())

  compact(list(
    branch = unbox_or_null(branch),
    head = git_head(info$commit),
    remotes = if (!is.null(remote)) {
      list(list(
        name = jsonlite::unbox("origin"),
        url = jsonlite::unbox(remote)
      ))
    }
  ))
}

# The commit's author and message, from the local repository. If the commit
# isn't there, e.g. the head of a pull request in a shallow clone, only its id.
git_head <- function(commit = NULL) {
  formats <- c(
    id = "%H",
    author_name = "%an",
    author_email = "%ae",
    committer_name = "%cn",
    committer_email = "%ce",
    message = "%s"
  )
  output <- try_git(system_output(
    "git",
    c(
      "log",
      "-n",
      "1",
      paste0("--pretty=format:", paste(collapse = "%n", formats)),
      commit
    ),
    quiet = TRUE
  ))
  values <- unlist(strsplit(output %||% character(), "\n", fixed = TRUE))
  head <- if (length(values) == length(formats)) {
    as.list(stats::setNames(values, names(formats)))
  } else if (!is.null(commit)) {
    list(id = commit)
  }
  lapply(head, jsonlite::unbox)
}

# `system_output()` signals a failed command as an error, or as its warning
try_git <- function(expr) {
  tryCatch(expr, error = function(e) NULL, warning = function(w) NULL)
}

unbox_or_null <- function(x) {
  if (!is.null(x)) jsonlite::unbox(x)
}
