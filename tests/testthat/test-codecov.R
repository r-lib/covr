context("codecov")
ci_vars <- c(
  "APPVEYOR" = NA,
  "APPVEYOR_BUILD_NUMBER" = NA,
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
  "WERCKER_MAIN_PIPELINE_STARTED" = NA)

test_that("it generates a properly formatted json file", {

  with_envvar(ci_vars, {
    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),
      `covr:::local_branch` = function() "master",
      `covr:::current_commit` = function() "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",

      res <- codecov("TestS4"),
      json <- jsonlite::fromJSON(res[[5]][[1]]),

      expect_match(json$files$name, rex::rex("R", one_of("/", "\\"), "TestS4.R")),
      expect_equal(json$files$coverage[[1]],
        c(NA, NA, NA, NA, NA, 5, 2, 5, 3, 5, NA, NA, NA, NA, NA, NA, NA, NA, NA,
          NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1, NA)
        ),
      expect_equal(json$uploader, "R")
      )
})
  })

test_that("it works with local repos", {
  with_envvar(ci_vars, {

    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),
      `covr:::local_branch` = function() "master",
      `covr:::current_commit` = function() "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",

      res <- codecov("TestS4"),

      url <- res[[4]]$url,

      expect_match(url, "/upload/v2"), # nolint
      expect_match(url, "branch=master"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
      )
    })
  })
test_that("it works with local repos and explicit branch and commit", {
  with_envvar(ci_vars, {

    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),

      res <- codecov("TestS4", branch = "master", commit = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"),

      url <- res[[4]]$url,

      expect_match(url, "/upload/v2"), # nolint
      expect_match(url, "branch=master"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
      )
    })
  })
test_that("it adds the token to the query if available", {
  with_envvar(c(
      ci_vars,
      "CODECOV_TOKEN" = "codecov_test"
      ),
    with_mock(
      .env = environment(),
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),
      `covr:::local_branch` = function() "master",
      `covr:::current_commit` = function() "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",

      res <- codecov("TestS4"),

      url <- res[[4]]$url,

      expect_match(url, "/upload/v2"), # nolint
      expect_match(url, "branch=master"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"),
      expect_match(url, "token=codecov_test")
      )
    )
  })
test_that("it works with jenkins", {
  with_envvar(c(
      ci_vars,
      "JENKINS_URL" = "jenkins.com",
      "GIT_BRANCH" = "test",
      "GIT_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",
      "BUILD_NUMBER" = "1",
      "BUILD_URL" = "http://test.com/tester/test"
      ),

    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),

      res <- codecov("TestS4"),

      url <- res[[4]]$url,

      expect_match(url, "service=jenkins"),
      expect_match(url, "branch=test"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"),
      expect_match(url, "build=1"),
      expect_match(url, "build_url=http%3A%2F%2Ftest.com%2Ftester%2Ftest")
      )
    )
  })

test_that("it works with travis normal builds", {
  with_envvar(c(
      ci_vars,
      "CI" = "true",
      "TRAVIS" = "true",
      "TRAVIS_PULL_REQUEST" = "false",
      "TRAVIS_REPO_SLUG" = "tester/test",
      "TRAVIS_BRANCH" = "master",
      "TRAVIS_JOB_NUMBER" = "100",
      "TRAVIS_JOB_ID" = "10",
      "TRAVIS_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
      ),

    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),

      res <- codecov("TestS4"),

      url <- res[[4]]$url,

      expect_match(url, "service=travis-org"),
      expect_match(url, "branch=master"),
      expect_match(url, "travis_job_id=10"),
      expect_match(url, "pull_request=&"),
      expect_match(url, "owner=tester"),
      expect_match(url, "repo=test"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"),
      expect_match(url, "build=100")
      )
    )
  })

test_that("it works with travis pull requests", {
  with_envvar(c(
      ci_vars,
      "CI" = "true",
      "TRAVIS" = "true",
      "TRAVIS_PULL_REQUEST" = "5",
      "TRAVIS_REPO_SLUG" = "tester/test",
      "TRAVIS_BRANCH" = "master",
      "TRAVIS_JOB_NUMBER" = "100",
      "TRAVIS_JOB_ID" = "10",
      "TRAVIS_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
      ),

    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),

      res <- codecov("TestS4"),

      url <- res[[4]]$url,

      expect_match(url, "service=travis-org"),
      expect_match(url, "branch=master"),
      expect_match(url, "travis_job_id=10"),
      expect_match(url, "pull_request=5"),
      expect_match(url, "owner=tester"),
      expect_match(url, "repo=test"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"),
      expect_match(url, "build=100")
      )
    )
  })

test_that("it works with codeship", {
  with_envvar(c(
      ci_vars,
      "CI" = "true",
      "CI_NAME" = "codeship",
      "CI_BRANCH" = "master",
      "CI_BUILD_NUMBER" = "5",
      "CI_BUILD_URL" = "http://test.com/tester/test",
      "CI_COMMIT_ID" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
      ),

    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),

      res <- codecov("TestS4"),

      url <- res[[4]]$url,

      expect_match(url, "service=codeship"),
      expect_match(url, "branch=master"),
      expect_match(url, "build=5"),
      expect_match(url, "build_url=http%3A%2F%2Ftest.com%2Ftester%2Ftest"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
      )
    )
  })
test_that("it works with circleci", {
  with_envvar(c(
      ci_vars,
      "CI" = "true",
      "CIRCLECI" = "true",
      "CIRCLE_BRANCH" = "master",
      "CIRCLE_BUILD_NUM" = "5",
      "CIRCLE_PROJECT_USERNAME" = "tester",
      "CIRCLE_PROJECT_REPONAME" = "test",
      "CIRCLE_SHA1" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
      ),

    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),

      res <- codecov("TestS4"),

      url <- res[[4]]$url,

      expect_match(url, "service=circleci"),
      expect_match(url, "branch=master"),
      expect_match(url, "build=5"),
      expect_match(url, "owner=tester"),
      expect_match(url, "repo=test"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
      )
    )
  })
test_that("it works with semaphore", {
  with_envvar(c(
      ci_vars,
      "CI" = "true",
      "SEMAPHORE" = "true",
      "BRANCH_NAME" = "master",
      "SEMAPHORE_BUILD_NUMBER" = "5",
      "SEMAPHORE_REPO_SLUG" = "tester/test",
      "REVISION" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
      ),

    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),

      res <- codecov("TestS4"),

      url <- res[[4]]$url,

      expect_match(url, "service=semaphore"),
      expect_match(url, "branch=master"),
      expect_match(url, "build=5"),
      expect_match(url, "owner=tester"),
      expect_match(url, "repo=test"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
      )
    )
  })
test_that("it works with drone", {
  with_envvar(c(
      ci_vars,
      "CI" = "true",
      "DRONE" = "true",
      "DRONE_BRANCH" = "master",
      "DRONE_BUILD_NUMBER" = "5",
      "DRONE_BUILD_URL" = "http://test.com/tester/test",
      "DRONE_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
      ),

    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),

      res <- codecov("TestS4"),

      url <- res[[4]]$url,

      expect_match(url, "service=drone.io"),
      expect_match(url, "branch=master"),
      expect_match(url, "build=5"),
      expect_match(url, "build_url=http%3A%2F%2Ftest.com%2Ftester%2Ftest"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
      )
    )
  })
test_that("it works with AppVeyor", {
  with_envvar(c(
      ci_vars,
      "CI" = "True",
      "APPVEYOR" = "True",
      "APPVEYOR_REPO_NAME" = "tester/test",
      "APPVEYOR_REPO_BRANCH" = "master",
      "APPVEYOR_BUILD_NUMBER" = "5",
      "APPVEYOR_REPO_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
      ),

    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),

      res <- codecov("TestS4"),

      url <- res[[4]]$url,

      expect_match(url, "service=AppVeyor"),
      expect_match(url, "branch=master"),
      expect_match(url, "build=5"),
      expect_match(url, "owner=tester"),
      expect_match(url, "repo=test"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
      )
    )
  })
test_that("it works with Wercker", {
  with_envvar(c(
      ci_vars,
      "CI" = "true",
      "WERCKER_GIT_BRANCH" = "master",
      "WERCKER_MAIN_PIPELINE_STARTED" = "5",
      "WERCKER_GIT_OWNER" = "tester",
      "WERCKER_GIT_REPOSITORY" = "test",
      "WERCKER_GIT_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
      ),

    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),

      res <- codecov("TestS4"),

      url <- res[[4]]$url,

      expect_match(url, "service=wercker"),
      expect_match(url, "branch=master"),
      expect_match(url, "build=5"),
      expect_match(url, "owner=tester"),
      expect_match(url, "repo=test"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
      )
    )
  })
