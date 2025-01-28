#' Run covr on a package and upload the result to codecov.io
#' @param coverage an existing coverage object to submit, if `NULL`,
#' [package_coverage()] will be called with the arguments from
#' `...`
#' @param ... arguments passed to [package_coverage()]
#' @param base_url Codecov url (change for Enterprise)
#' @param quiet if `FALSE`, print the coverage before submission.
#' @param token a codecov upload token, if `NULL` then following external
#'   sources will be checked in this order:
#'   1. the environment variable \sQuote{CODECOV_TOKEN}. If it is empty, then
#'   1. package will look at directory of the package for a file `codecov.yml`.
#'   File must have `codecov` section where field `token` is set to a token that
#'   will be used.
#' @param commit explicitly set the commit this coverage result object
#' corresponds to. Is looked up from the service or locally if it is
#' `NULL`.
#' @param branch explicitly set the branch this coverage result object
#' corresponds to, this is looked up from the service or locally if it is
#' `NULL`.
#' @param pr explicitly set the pr this coverage result object corresponds to,
#'   this is looked up from the service if it is `NULL`.
#' @param flags A flag to use for this coverage upload see
#'   <https://docs.codecov.com/docs/flags> for details.
#' @export
#' @examples
#' \dontrun{
#' codecov(path = "test")
#' }
codecov <- function(...,
                    coverage = NULL,
                    base_url = "https://codecov.io",
                    token = NULL,
                    commit = NULL,
                    branch = NULL,
                    pr = NULL,
                    flags = NULL,
                    quiet = TRUE) {

  if (is.null(coverage)) {
    coverage <- package_coverage(quiet = quiet, ...)
  }

  if (!quiet) {
    print(coverage)
  }

  # -------
  # Jenkins
  # -------
  if (Sys.getenv("JENKINS_URL") != "") {
    # https://wiki.jenkins-ci.org/display/JENKINS/Building+a+software+project
    codecov_url <- paste0(base_url, "/upload/v2") # nolint
    codecov_query <- list(service = "jenkins",
                          branch = branch %||% Sys.getenv("GIT_BRANCH"),
                          commit = commit %||% Sys.getenv("GIT_COMMIT"),
                          build = Sys.getenv("BUILD_NUMBER"),
                          build_url = utils::URLencode(Sys.getenv("BUILD_URL")))
  # ---------
  # Travis CI
  # ---------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("TRAVIS") == "true") {
    # https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables
    codecov_url <- paste0(base_url, "/upload/v2") # nolint
    codecov_query <- list(branch = branch %||% Sys.getenv("TRAVIS_BRANCH"),
                          service = "travis",
                          build = Sys.getenv("TRAVIS_JOB_NUMBER"),
                          pr = pr %||% Sys.getenv("TRAVIS_PULL_REQUEST"),
                          job = Sys.getenv("TRAVIS_JOB_ID"),
                          slug = Sys.getenv("TRAVIS_REPO_SLUG"),
                          root = Sys.getenv("TRAVIS_BUILD_DIR"),
                          commit = commit %||% Sys.getenv("TRAVIS_COMMIT"))
  # --------
  # Codeship
  # --------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("CI_NAME") == "codeship") {
    # https://www.codeship.io/documentation/continuous-integration/set-environment-variables/
    codecov_url <- paste0(base_url, "/upload/v2") # nolint
    codecov_query <- list(service = "codeship",
                          branch = branch %||% Sys.getenv("CI_BRANCH"),
                          build = Sys.getenv("CI_BUILD_NUMBER"),
                          build_url = utils::URLencode(Sys.getenv("CI_BUILD_URL")),
                          commit = commit %||% Sys.getenv("CI_COMMIT_ID"))
  # ---------
  # Circle CI
  # ---------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("CIRCLECI") == "true") {
    # https://circleci.com/docs/environment-variables
    codecov_url <- paste0(base_url, "/upload/v2") # nolint
    codecov_query <- list(service = "circleci",
                          branch = branch %||% Sys.getenv("CIRCLE_BRANCH"),
                          build = Sys.getenv("CIRCLE_BUILD_NUM"),
                          owner = Sys.getenv("CIRCLE_PROJECT_USERNAME"),
                          repo = Sys.getenv("CIRCLE_PROJECT_REPONAME"),
                          pr = pr %||% Sys.getenv("CIRCLE_PR_NUMBER"),
                          commit = commit %||% Sys.getenv("CIRCLE_SHA1"))
  # ---------
  # Semaphore
  # ---------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("SEMAPHORE") == "true") {
    # https://semaphoreapp.com/docs/available-environment-variables.html
    codecov_url <- paste0(base_url, "/upload/v2") # nolint
    slug_info <- strsplit(Sys.getenv("SEMAPHORE_REPO_SLUG"), "/")[[1]]
    codecov_query <- list(service = "semaphore",
                          branch = branch %||% Sys.getenv("BRANCH_NAME"),
                          build = Sys.getenv("SEMAPHORE_BUILD_NUMBER"),
                          owner = slug_info[1],
                          repo = slug_info[2],
                          commit = commit %||% Sys.getenv("REVISION"))
  # --------
  # drone.io
  # --------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("DRONE") == "true") {
    # http://docs.drone.io/env.html
    codecov_url <- paste0(base_url, "/upload/v2") # nolint
    codecov_query <- list(service = "drone.io",
                          branch = branch %||% Sys.getenv("DRONE_BRANCH"),
                          build = Sys.getenv("DRONE_BUILD_NUMBER"),
                          build_url = utils::URLencode(Sys.getenv("DRONE_BUILD_URL")),
                          pr = pr %||% Sys.getenv("DRONE_PULL_REQUEST"),
                          commit = commit %||% Sys.getenv("DRONE_COMMIT"))
  # --------
  # AppVeyor
  # --------
  } else if (Sys.getenv("CI") == "True" && Sys.getenv("APPVEYOR") == "True") {
    # http://www.appveyor.com/docs/environment-variables
    codecov_url <- paste0(base_url, "/upload/v2") # nolint
    codecov_query <- list(service = "appveyor",
                          branch = branch %||% Sys.getenv("APPVEYOR_REPO_BRANCH"),
                          job = paste(Sys.getenv("APPVEYOR_ACCOUNT_NAME"), Sys.getenv("APPVEYOR_PROJECT_SLUG"), Sys.getenv("APPVEYOR_BUILD_VERSION"), sep = "/"),
                          build = Sys.getenv("APPVEYOR_JOB_ID"),
                          pr = pr %||% Sys.getenv("APPVEYOR_PULL_REQUEST_NUMBER"),
                          slug = Sys.getenv("APPVEYOR_REPO_NAME"),
                          commit = commit %||% Sys.getenv("APPVEYOR_REPO_COMMIT"))
  # -------
  # Wercker
  # -------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("WERCKER_GIT_BRANCH") != "") {
    # http://devcenter.wercker.com/articles/steps/variables.html
    codecov_url <- paste0(base_url, "/upload/v2") # nolint
    codecov_query <- list(service = "wercker",
                          branch = branch %||% Sys.getenv("WERCKER_GIT_BRANCH"),
                          build = Sys.getenv("WERCKER_MAIN_PIPELINE_STARTED"),
                          owner = Sys.getenv("WERCKER_GIT_OWNER"),
                          repo = Sys.getenv("WERCKER_GIT_REPOSITORY"),
                          commit = commit %||% Sys.getenv("WERCKER_GIT_COMMIT"))
  # ---------
  # GitLab-CI
  # ---------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("CI_SERVER_NAME") == "GitLab CI") {
    # http://docs.gitlab.com/ce/ci/variables/README.html
    slug <- sub(".*/([^/]+/[^/]+)[.]git", "\\1", Sys.getenv("CI_BUILD_REPO"))
    codecov_url <- paste0(base_url, "/upload/v2") # nolint
    codecov_query <- list(service = "gitlab",
                          branch = branch %||% Sys.getenv("CI_BUILD_REF_NAME"),
                          build = Sys.getenv("CI_BUILD_ID"),
                          slug = slug,
                          commit = commit %||% Sys.getenv("CI_BUILD_REF"))
  # ---------
  # GitHub Actions
  # ---------
  } else if (nzchar(Sys.getenv("GITHUB_ACTION"))) {
    # Adapted from
    # https://github.com/codecov/codecov-bash/blob/3316b21c8fe0ca7ada543fb8473ac616822ce27a/codecov#L763-L783
    slug <- Sys.getenv("GITHUB_REPOSITORY")
    github_ref <- Sys.getenv("GITHUB_REF")
    github_head_ref <- Sys.getenv("GITHUB_HEAD_REF")
    github_run_id <- Sys.getenv("GITHUB_RUN_ID")

    is_fork_pr <- nzchar(github_head_ref)
    if (is_fork_pr) {
      pr <- pr %||% sub("^refs/pull/(.*)/merge", "\\1", github_ref)
      branch <- branch %||% github_head_ref
    } else {
      branch <- branch %||% sub("^refs/heads/", "", github_ref)
    }

    codecov_url <- paste0(base_url, "/upload/v2") # nolint
    codecov_query <- list(service = "github-actions",
                          branch = branch,
                          build = github_run_id,
                          build_url = utils::URLencode(sprintf("https://github.com/%s/actions/runs/%s", slug, github_run_id)),
                          pr = pr,
                          slug = slug,
                          commit = commit %||% Sys.getenv("GITHUB_SHA"))
  # ---------
  # Google Cloud Build
  # ---------
  } else if (nzchar(Sys.getenv("GCB_PROJECT_ID"))) {

    # https://cloud.google.com/build/docs/configuring-builds/substitute-variable-values
    codecov_url <- paste0(base_url, "/upload/v2") # nolint

    build_url <- sprintf("https://console.cloud.google.com/cloud-build/builds/%s?project=%s",
                         Sys.getenv("GCB_BUILD_ID"), Sys.getenv("GCB_PROJECT_ID"))

    name <- NULL
    pr <- NULL
    if(nzchar(Sys.getenv("GCB_TAG_NAME"))) name <- Sys.getenv("GCB_TAG_NAME")
    if(nzchar(Sys.getenv("GCB_PR_NUMBER"))) pr <- Sys.getenv("GCB_PR_NUMBER")

    codecov_query <- list(
      branch = branch %||% Sys.getenv("GCB_BRANCH_NAME"),
      service = "custom",
      build = Sys.getenv("GCB_BUILD_ID"),
      build_url = build_url,
      name = name,
      pr = pr,
      commit = commit %||% Sys.getenv("GCB_COMMIT_SHA")
    )

  # ---------
  # Local GIT
  # ---------
  } else {
    codecov_url <- paste0(base_url, "/upload/v2") # nolint
    codecov_query <- list(branch = branch %||% local_branch(),
                          commit = commit %||% current_commit())
  }

  # Add flags parameter
  codecov_query$flags <- flags

  token <- token %||% Sys.getenv("CODECOV_TOKEN", extract_from_yaml(attr(coverage, "package")$path))

  if (nzchar(token)) {
    codecov_query$token <- token
  }

  coverage_json <- to_codecov(coverage)

  content(RETRY("POST",
                url = codecov_url,
                query = codecov_query,
                body = coverage_json,
                encode = "json",
                httr::config(http_version = curl_http_1_1())))
}

curl_http_1_1 <- function() {
  symbols <- curl::curl_symbols()
  symbols$value[symbols$name == "CURL_HTTP_VERSION_1_1"]
}

extract_from_yaml <- function(path){
  if (is.null(path)) {
    return("")
  }

  path_to_yaml <- file.path(path, "codecov.yml")
  if (file.exists(path_to_yaml)) {
    yaml::read_yaml(path_to_yaml)[["codecov"]][["token"]] %||% ""
  } else {
    ""
  }
}

to_codecov <- function(x) {
  coverages <- lapply(per_line(x),
    function(xx) {
      xx$coverage <- c(NA, xx$coverage)
      xx
    })

  res <- Map(function(coverage, name) {
      list(
        "name" = jsonlite::unbox(name),
        "coverage" = coverage$coverage
      )
    }, coverages, names(coverages), USE.NAMES = FALSE)

  jsonlite::toJSON(na = "null", list("files" = res, "uploader" = jsonlite::unbox("R")))
}
