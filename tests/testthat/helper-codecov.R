codecov_ci_vars <- function() {
  vars <- c(
    "APPVEYOR",
    "APPVEYOR_ACCOUNT_NAME",
    "APPVEYOR_BUILD_VERSION",
    "APPVEYOR_PROJECT_SLUG",
    "APPVEYOR_PULL_REQUEST_NUMBER",
    "APPVEYOR_REPO_BRANCH",
    "APPVEYOR_REPO_COMMIT",
    "APPVEYOR_REPO_NAME",
    "APPVEYOR_REPO_PROVIDER",
    "BUILD_NUMBER",
    "BUILD_URL",
    "CI",
    "CIRCLECI",
    "CIRCLE_BRANCH",
    "CIRCLE_BUILD_NUM",
    "CIRCLE_BUILD_URL",
    "CIRCLE_PROJECT_REPONAME",
    "CIRCLE_PROJECT_USERNAME",
    "CIRCLE_PR_NUMBER",
    "CIRCLE_SHA1",
    "CI_BRANCH",
    "CI_BUILD_ID",
    "CI_BUILD_REF",
    "CI_BUILD_REF_NAME",
    "CI_BUILD_REPO",
    "CI_COMMIT_REF_NAME",
    "CI_COMMIT_SHA",
    "CI_JOB_ID",
    "CI_JOB_URL",
    "CI_MERGE_REQUEST_IID",
    "CI_NAME",
    "CI_PROJECT_PATH",
    "CI_SERVER_HOST",
    "CI_SERVER_NAME",
    "CODECOV_TOKEN",
    "DRONE",
    "DRONE_BRANCH",
    "DRONE_BUILD_LINK",
    "DRONE_BUILD_NUMBER",
    "DRONE_BUILD_URL",
    "DRONE_COMMIT",
    "DRONE_COMMIT_BRANCH",
    "DRONE_COMMIT_SHA",
    "DRONE_PULL_REQUEST",
    "GCB_BRANCH_NAME",
    "GCB_BUILD_ID",
    "GCB_COMMIT_SHA",
    "GCB_PROJECT_ID",
    "GCB_PR_NUMBER",
    "GCB_TAG_NAME",
    "GITHUB_ACTION",
    "GITHUB_EVENT_PATH",
    "GITHUB_HEAD_REF",
    "GITHUB_REF",
    "GITHUB_REPOSITORY",
    "GITHUB_RUN_ID",
    "GITHUB_SERVER_URL",
    "GITHUB_SHA",
    "GITLAB_CI",
    "GIT_BRANCH",
    "GIT_COMMIT",
    "JENKINS_URL",
    "TRAVIS",
    "TRAVIS_BRANCH",
    "TRAVIS_COMMIT",
    "TRAVIS_JOB_ID",
    "TRAVIS_JOB_WEB_URL",
    "TRAVIS_PULL_REQUEST",
    "TRAVIS_REPO_SLUG"
  )
  stats::setNames(rep(NA_character_, length(vars)), vars)
}

# What `http_request()` returns
fake_response <- function(status, body) {
  list(
    status = status,
    reason = httr2::resp_status_desc(httr2::response(status)),
    body = body
  )
}

fake_upload_response <- function() {
  fake_response(
    200L,
    paste0(
      '{"url":"https://app.codecov.io/github/tester/test/commit/abc",',
      '"raw_upload_location":"https://storage.example.com/upload?sig=1"}'
    )
  )
}

# Replaces covr's HTTP and git calls, and returns an environment that records
# the requests of `codecov()`.
local_codecov_mocks <- function(
  post = fake_upload_response(),
  put = fake_response(200L, ""),
  frame = parent.frame()
) {
  recorded <- new.env()
  recorded$requests <- list()
  local_mocked_bindings(
    http_request = function(
      method,
      url,
      body = NULL,
      headers = character(),
      files = character()
    ) {
      recorded$requests[[length(recorded$requests) + 1L]] <- list(
        verb = method,
        url = url,
        body = body,
        headers = headers
      )
      if (method == "POST") post else put
    },
    git_remote_url = function(dir) "https://github.com/tester/test.git",
    git_files = function(dir) c("DESCRIPTION", "R/TestS4.R"),
    local_branch = function(dir) "master",
    current_commit = function(dir) "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",
    .env = frame
  )
  recorded
}

codecov_post <- function(recorded) {
  recorded$requests[[1]]
}

codecov_put <- function(recorded) {
  recorded$requests[[2]]
}

codecov_post_body <- function(recorded) {
  jsonlite::fromJSON(codecov_post(recorded)$body, simplifyVector = FALSE)
}

# `package_coverage()` of TestS4 is slow, and read-only for its consumers, so
# it is computed on first use and reused by the tests that need it.
s4_coverage <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      cache <<- package_coverage(test_path("TestS4"))
    }
    cache
  }
})

simple_coverage <- function() code_coverage("f <- function() 1", "f()")

github_pull_request_env <- function(
  head_repo = "forkowner/actions",
  label = '"label": "forkowner:feature", ',
  frame = parent.frame()
) {
  event <- withr::local_tempfile(fileext = ".json", .local_envir = frame)
  writeLines(
    paste0(
      '{"number": 7, "pull_request": {"number": 7, "head": {',
      '"sha": "c94a8fe5ccb19ba61c4c0873d391e987982fbbd3",',
      label,
      '"repo": {"full_name": "',
      head_repo,
      '"}}}}'
    ),
    event
  )
  withr::local_envvar(
    c(
      codecov_ci_vars(),
      "GITHUB_ACTION" = "__run",
      "GITHUB_REPOSITORY" = "tester/actions",
      "GITHUB_REF" = "refs/pull/7/merge",
      "GITHUB_HEAD_REF" = "feature",
      "GITHUB_RUN_ID" = "42",
      "GITHUB_SHA" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",
      "GITHUB_EVENT_PATH" = event
    ),
    .local_envir = frame
  )
}
