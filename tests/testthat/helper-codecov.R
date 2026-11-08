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
    "BRANCH_NAME",
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
    "CI_BUILD_NUMBER",
    "CI_BUILD_REF",
    "CI_BUILD_REF_NAME",
    "CI_BUILD_REPO",
    "CI_BUILD_URL",
    "CI_COMMIT_ID",
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
    "DRONE_BUILD_NUMBER",
    "DRONE_BUILD_URL",
    "DRONE_COMMIT",
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
    "REVISION",
    "SEMAPHORE",
    "SEMAPHORE_BUILD_NUMBER",
    "SEMAPHORE_REPO_SLUG",
    "TRAVIS",
    "TRAVIS_BRANCH",
    "TRAVIS_COMMIT",
    "TRAVIS_JOB_ID",
    "TRAVIS_JOB_WEB_URL",
    "TRAVIS_PULL_REQUEST",
    "TRAVIS_REPO_SLUG",
    "WERCKER_GIT_BRANCH",
    "WERCKER_GIT_COMMIT",
    "WERCKER_GIT_OWNER",
    "WERCKER_GIT_REPOSITORY",
    "WERCKER_MAIN_PIPELINE_STARTED"
  )
  stats::setNames(rep(NA_character_, length(vars)), vars)
}

fake_response <- function(status, body, type = "text/plain") {
  structure(
    list(
      url = "https://ingest.codecov.io",
      status_code = status,
      headers = list(`content-type` = type),
      content = charToRaw(body)
    ),
    class = "response"
  )
}

fake_upload_response <- function() {
  fake_response(
    200L,
    paste0(
      '{"url":"https://app.codecov.io/github/tester/test/commit/abc",',
      '"raw_upload_location":"https://storage.example.com/upload?sig=1"}'
    ),
    "application/json"
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
    RETRY = function(verb, url, body, encode, ...) {
      requests <- Filter(function(x) inherits(x, "request"), list(...))
      headers <- unlist(lapply(requests, function(x) as.list(x$headers)))
      recorded$requests[[length(recorded$requests) + 1L]] <- list(
        verb = verb,
        url = url,
        body = body,
        headers = headers
      )
      if (verb == "POST") post else put
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
