context("codecov")
robustr::with_envvar(c(
  "APPVEYOR" = NULL,
  "APPVEYOR_BUILD_NUMBER" = NULL,
  "APPVEYOR_REPO_BRANCH" = NULL,
  "APPVEYOR_REPO_COMMIT" = NULL,
  "APPVEYOR_REPO_NAME" = NULL,
  "BRANCH_NAME" = NULL,
  "BUILD_NUMBER" = NULL,
  "BUILD_URL" = NULL,
  "CI" = NULL,
  "CIRCLECI" = NULL,
  "CIRCLE_BRANCH" = NULL,
  "CIRCLE_BUILD_NUM" = NULL,
  "CIRCLE_PROJECT_REPONAME" = NULL,
  "CIRCLE_PROJECT_USERNAME" = NULL,
  "CIRCLE_SHA1" = NULL,
  "CI_BRANCH" = NULL,
  "CI_BUILD_NUMBER" = NULL,
  "CI_BUILD_URL" = NULL,
  "CI_COMMIT_ID" = NULL,
  "CI_NAME" = NULL,
  "CODECOV_TOKEN" = NULL,
  "DRONE" = NULL,
  "DRONE_BRANCH" = NULL,
  "DRONE_BUILD_NUMBER" = NULL,
  "DRONE_BUILD_URL" = NULL,
  "DRONE_COMMIT" = NULL,
  "GIT_BRANCH" = NULL,
  "GIT_COMMIT" = NULL,
  "JENKINS_URL" = NULL,
  "REVISION" = NULL,
  "SEMAPHORE" = NULL,
  "SEMAPHORE_BUILD_NUMBER" = NULL,
  "SEMAPHORE_REPO_SLUG" = NULL,
  "TRAVIS" = NULL,
  "TRAVIS_BRANCH" = NULL,
  "TRAVIS_COMMIT" = NULL,
  "TRAVIS_JOB_ID" = NULL,
  "TRAVIS_JOB_NUMBER" = NULL,
  "TRAVIS_PULL_REQUEST" = NULL,
  "TRAVIS_REPO_SLUG" = NULL,
  "WERCKER_GIT_BRANCH" = NULL,
  "WERCKER_GIT_COMMIT" = NULL,
  "WERCKER_GIT_OWNER" = NULL,
  "WERCKER_GIT_REPOSITORY" = NULL,
  "WERCKER_MAIN_PIPELINE_STARTED" = NULL), {
  test_that("it generates a properly formatted json file", {

    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),

      res <<- codecov("TestS4"),
      json <<- jsonlite::fromJSON(res[[5]][[1]]),

      expect_equal(json$files$name, "R/TestS4.R"),
      expect_equal(json$files$coverage[[1]],
        c(NA, NA, NA, 5, 2, 5, 3, 5, NA, NA, NA, NA, NA, NA, NA, NA, NA,
          NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1, NA)
        ),
      expect_equal(json$uploader, "R")
    )
  })

  test_that("it works with local repos", {
    system3 <- duplicate(base::system)

    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr:::body_config` = function(...) list(...),
      `covr:::local_branch` = function() "master",
      `base::system` = function(x, ...) {
        if (grepl("^git", x)) {
          "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3 "
        } else {
          system3(x, ...)
        }
      },

      res <- codecov("TestS4"),

      url <- res[[4]]$url,

      expect_match(url, "/upload/v2"), # nolint
      expect_match(url, "branch=master"),
      expect_match(url, "commit=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
      )
  })
  test_that("it adds the token to the query if available", {
    system3 <- duplicate(base::system)
    devtools::with_envvar(c(
        "CODECOV_TOKEN" = "codecov_test"
        ),
      with_mock(
        .env = environment(),
        `httr:::perform` = function(...) list(...),
        `httr::content` = identity,
        `httr:::body_config` = function(...) list(...),
        `covr:::local_branch` = function() "master",
        `base::system` = function(x, ...) {
          if (grepl("^git", x)) {
            "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3 "
          } else {
            system3(x, ...)
          }
        },

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
})
