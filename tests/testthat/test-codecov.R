context("codecov")
test_that("it generates a properly formatted json file", {

  devtools::with_envvar(c(
      "TRAVIS" = "false"
      ),
    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),

      res <- codecov("TestS4"),
      json <- jsonlite::fromJSON(res[[5]][[1]]),

      expect_equal(json$files$name, "TestS4/R/TestS4.R"),
      expect_equal(json$files$coverage[[1]],
        c(NA, NA, NA, 5, 2, 5, 3, 5, NA, NA, NA, NA, NA, NA, NA, NA, NA,
          NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1)
        ),
      expect_equal(json$uploader, "R")
      )
    )
})

test_that("it works with local repos", {
  devtools::with_envvar(c(
      "TRAVIS" = "false"
    ),
    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),
      `covr:::local_branch` = function() "master",
      `base::system` = function(...) "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3 ",

      res <- codecov("TestS4"),

      url <- res[[4]]$url,

      expect_match(url, "/upload/v2"), # nolint
      expect_match(url, "branch=master"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
      )
    )
})
test_that("it adds the token to the query if available", {
  devtools::with_envvar(c(
      "TRAVIS" = "false",
      "CODECOV_TOKEN" = "codecov_test"
    ),
    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),
      `local_branch` = function() "master",
      `base::system` = function(...) "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3 ",

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
  devtools::with_envvar(c(
      "TRAVIS" = "false",
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
  devtools::with_envvar(c(
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
  devtools::with_envvar(c(
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
  devtools::with_envvar(c(
      "TRAVIS" = "false",
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
  devtools::with_envvar(c(
      "TRAVIS" = "false",
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
  devtools::with_envvar(c(
      "TRAVIS" = "false",
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
  devtools::with_envvar(c(
      "TRAVIS" = "false",
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
  devtools::with_envvar(c(
      "TRAVIS" = "false",
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
  devtools::with_envvar(c(
      "TRAVIS" = "false",
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
