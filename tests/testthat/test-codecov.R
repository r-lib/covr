ci_vars <- c(
  "APPVEYOR" = NA,
  "APPVEYOR_ACCOUNT_NAME" = NA,
  "APPVEYOR_PROJECT_SLUG" = NA,
  "APPVEYOR_BUILD_VERSION" = NA,
  "APPVEYOR_JOB_ID" = NA,
  "APPVEYOR_REPO_BRANCH" = NA,
  "APPVEYOR_REPO_COMMIT" = NA,
  "APPVEYOR_REPO_NAME" = NA,
  "BRANCH_NAME" = NA,
  "BUILD_NUMBER" = NA,
  "BUILD_URL" = NA,
  "CI" = NA,
  "CIRCLECI" = NA,
  "CIRCLE_BRANCH" = NA,
  "CIRCLE_BUILD_NUM" = NA,
  "CIRCLE_PROJECT_REPONAME" = NA,
  "CIRCLE_PROJECT_USERNAME" = NA,
  "CIRCLE_SHA1" = NA,
  "CI_BRANCH" = NA,
  "CI_BUILD_NUMBER" = NA,
  "CI_BUILD_URL" = NA,
  "CI_COMMIT_ID" = NA,
  "CI_NAME" = NA,
  "CODECOV_TOKEN" = NA,
  "DRONE" = NA,
  "DRONE_BRANCH" = NA,
  "DRONE_BUILD_NUMBER" = NA,
  "DRONE_BUILD_URL" = NA,
  "DRONE_COMMIT" = NA,
  "GIT_BRANCH" = NA,
  "GIT_COMMIT" = NA,
  "GITHUB_ACTION" = NA,
  "GITHUB_REPOSTIORY" = NA,
  "JENKINS_URL" = NA,
  "REVISION" = NA,
  "SEMAPHORE" = NA,
  "SEMAPHORE_BUILD_NUMBER" = NA,
  "SEMAPHORE_REPO_SLUG" = NA,
  "TRAVIS" = NA,
  "TRAVIS_BRANCH" = NA,
  "TRAVIS_COMMIT" = NA,
  "TRAVIS_JOB_ID" = NA,
  "TRAVIS_JOB_NUMBER" = NA,
  "TRAVIS_PULL_REQUEST" = NA,
  "TRAVIS_REPO_SLUG" = NA,
  "WERCKER_GIT_BRANCH" = NA,
  "WERCKER_GIT_COMMIT" = NA,
  "WERCKER_GIT_OWNER" = NA,
  "WERCKER_GIT_REPOSITORY" = NA,
  "WERCKER_MAIN_PIPELINE_STARTED" = NA
)

cov <- package_coverage(test_path("TestS4"))

test_that("it generates a properly formatted json file", {
  withr::local_envvar(ci_vars)
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity,
    local_branch = function(dir) "master",
    current_commit = function(dir) "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  )
  res <- codecov(coverage = cov)
  json <- jsonlite::fromJSON(res$body)

  expect_match(json$files$name, "R/TestS4.R")
  expect_equal(
    json$files$coverage[[1]],
    c(
      NA, NA, NA, NA, NA, NA, NA, 5, 2, NA, 3, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,
      NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1, NA
    )
  )
  expect_equal(json$uploader, "R")
})

test_that("it adds a flags argument to the query if specified", {
  withr::local_envvar(ci_vars)
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity,
    local_branch = function(dir) "master",
    current_commit = function(dir) "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  )
  res <- codecov(coverage = cov, flags = "R")
  expect_equal(res$query$flags, "R")
})

test_that("it works with local repos", {
  withr::local_envvar(ci_vars)
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity,
    local_branch = function(dir) "master",
    current_commit = function(dir) "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  )
  res <- codecov(coverage = cov)

  expect_match(res$url, "2") # nolint
  expect_match(res$query$branch, "master")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})
test_that("it works with local repos and explicit branch and commit", {
  withr::local_envvar(ci_vars)
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity
  )
  res <- codecov(coverage = cov, branch = "master", commit = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")

  expect_match(res$url, "/upload/v2") # nolint
  expect_match(res$query$branch, "master")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})
test_that("it adds the token to the query if available", {
  withr::local_envvar(c(ci_vars, "CODECOV_TOKEN" = "codecov_test"))
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity,
    local_branch = function(dir) "master",
    current_commit = function(dir) "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  )
  res <- codecov(coverage = cov)

  expect_match(res$url, "/upload/v2") # nolint
  expect_match(res$query$branch, "master")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
  expect_match(res$query$token, "codecov_test")
})
test_that("it looks for token in a .yml file", {
  withr::local_envvar(ci_vars)
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity,
    local_branch = function(dir) "master",
    current_commit = function(dir) "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  )
  res <- codecov(coverage = cov)

  expect_match(res$url, "/upload/v2") # nolint
  expect_match(res$query$branch, "master")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
  expect_match(res$query$token, "codecov_token_from_yaml")
})

test_that("it works with jenkins", {
  withr::local_envvar(c(
    ci_vars,
    "JENKINS_URL" = "jenkins.com",
    "GIT_BRANCH" = "test",
    "GIT_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",
    "BUILD_NUMBER" = "1",
    "BUILD_URL" = "http://test.com/tester/test"
  ))
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity
  )
  res <- codecov(coverage = cov)

  expect_match(res$query$service, "jenkins")
  expect_match(res$query$branch, "test")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
  expect_match(res$query$build, "1")
  expect_match(res$query$build_url, "http://test.com/tester/test")
})

test_that("it works with travis normal builds", {
  withr::local_envvar(c(
    ci_vars,
    "CI" = "true",
    "TRAVIS" = "true",
    "TRAVIS_PULL_REQUEST" = "false",
    "TRAVIS_REPO_SLUG" = "tester/test",
    "TRAVIS_BRANCH" = "master",
    "TRAVIS_JOB_NUMBER" = "100",
    "TRAVIS_JOB_ID" = "10",
    "TRAVIS_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity
  )
  res <- codecov(coverage = cov)

  expect_match(res$query$service, "travis")
  expect_match(res$query$branch, "master")
  expect_match(res$query$job, "10")
  expect_match(res$query$pr, "")
  expect_match(res$query$slug, "tester/test")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
  expect_match(res$query$build, "100")
})

test_that("it works with travis pull requests", {
  withr::local_envvar(c(
    ci_vars,
    "CI" = "true",
    "TRAVIS" = "true",
    "TRAVIS_PULL_REQUEST" = "5",
    "TRAVIS_REPO_SLUG" = "tester/test",
    "TRAVIS_BRANCH" = "master",
    "TRAVIS_JOB_NUMBER" = "100",
    "TRAVIS_JOB_ID" = "10",
    "TRAVIS_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity
  )
  res <- codecov(coverage = cov)

  expect_match(res$query$service, "travis")
  expect_match(res$query$branch, "master")
  expect_match(res$query$job, "10")
  expect_match(res$query$pr, "5")
  expect_match(res$query$slug, "tester/test")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
  expect_match(res$query$build, "100")
})

test_that("it works with codeship", {
  withr::local_envvar(c(
    ci_vars,
    "CI" = "true",
    "CI_NAME" = "codeship",
    "CI_BRANCH" = "master",
    "CI_BUILD_NUMBER" = "5",
    "CI_BUILD_URL" = "http://test.com/tester/test",
    "CI_COMMIT_ID" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity
  )
  res <- codecov(coverage = cov)

  expect_match(res$query$service, "codeship")
  expect_match(res$query$branch, "master")
  expect_match(res$query$build, "5")
  expect_match(res$query$build_url, "http://test.com/tester/test")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})
test_that("it works with circleci", {
  withr::local_envvar(c(
    ci_vars,
    "CI" = "true",
    "CIRCLECI" = "true",
    "CIRCLE_BRANCH" = "master",
    "CIRCLE_BUILD_NUM" = "5",
    "CIRCLE_PROJECT_USERNAME" = "tester",
    "CIRCLE_PROJECT_REPONAME" = "test",
    "CIRCLE_SHA1" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity
  )
  res <- codecov(coverage = cov)

  expect_match(res$query$service, "circleci")
  expect_match(res$query$branch, "master")
  expect_match(res$query$build, "5")
  expect_match(res$query$owner, "tester")
  expect_match(res$query$repo, "test")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})
test_that("it works with semaphore", {
  withr::local_envvar(c(
    ci_vars,
    "CI" = "true",
    "SEMAPHORE" = "true",
    "BRANCH_NAME" = "master",
    "SEMAPHORE_BUILD_NUMBER" = "5",
    "SEMAPHORE_REPO_SLUG" = "tester/test",
    "REVISION" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity
  )
  res <- codecov(coverage = cov)

  expect_match(res$query$service, "semaphore")
  expect_match(res$query$branch, "master")
  expect_match(res$query$build, "5")
  expect_match(res$query$owner, "tester")
  expect_match(res$query$repo, "test")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})
test_that("it works with drone", {
  withr::local_envvar(c(
    ci_vars,
    "CI" = "true",
    "DRONE" = "true",
    "DRONE_BRANCH" = "master",
    "DRONE_BUILD_NUMBER" = "5",
    "DRONE_BUILD_URL" = "http://test.com/tester/test",
    "DRONE_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity
  )
  res <- codecov(coverage = cov)

  expect_match(res$query$service, "drone.io")
  expect_match(res$query$branch, "master")
  expect_match(res$query$build, "5")
  expect_match(res$query$build_url, "http://test.com/tester/test")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})
test_that("it works with AppVeyor", {
  withr::local_envvar(c(
    ci_vars,
    "CI" = "True",
    "APPVEYOR" = "True",
    "APPVEYOR_REPO_NAME" = "testspace/test",
    "APPVEYOR_REPO_BRANCH" = "master",
    "APPVEYOR_ACCOUNT_NAME" = "testuser", # not necessarily the same as testspace above
    "APPVEYOR_PROJECT_SLUG" = "test",
    "APPVEYOR_BUILD_VERSION" = "1.0.5",
    "APPVEYOR_JOB_ID" = "225apqggpmlkn5pr",
    "APPVEYOR_REPO_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity
  )
  res <- codecov(coverage = cov)

  expect_match(res$query$service, "appveyor")
  expect_match(res$query$branch, "master")
  expect_match(res$query$job, "testuser/test/1.0.5")
  expect_match(res$query$build, "225apqggpmlkn5pr")
  expect_match(res$query$slug, "testspace/test")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})
test_that("it works with Wercker", {
  withr::local_envvar(c(
    ci_vars,
    "CI" = "true",
    "WERCKER_GIT_BRANCH" = "master",
    "WERCKER_MAIN_PIPELINE_STARTED" = "5",
    "WERCKER_GIT_OWNER" = "tester",
    "WERCKER_GIT_REPOSITORY" = "test",
    "WERCKER_GIT_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity
  )
  res <- codecov(coverage = cov)

  expect_match(res$query$service, "wercker")
  expect_match(res$query$branch, "master")
  expect_match(res$query$build, "5")
  expect_match(res$query$owner, "tester")
  expect_match(res$query$repo, "test")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})

test_that("it works with GitLab", {
  withr::local_envvar(c(
    ci_vars,
    "CI" = "true",
    "CI_SERVER_NAME" = "GitLab CI",
    "CI_BUILD_ID" = "5",
    "CI_BUILD_REPO" = "https://gitlab.com/tester/test.git",
    "CI_BUILD_REF_NAME" = "master",
    "CI_BUILD_REF" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity
  )
  res <- codecov(coverage = cov)

  expect_match(res$query$service, "gitlab")
  expect_match(res$query$branch, "master")
  expect_match(res$query$build, "5")
  expect_match(res$query$slug, "tester/test")
  expect_match(res$query$commit, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})
