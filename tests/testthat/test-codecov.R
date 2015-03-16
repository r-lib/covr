context("codecov")
test_that("it generates a properly formatted json file", {

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
})

test_that("it works with jenkins", {
  devtools::with_envvar(c(
    "JENKINS_URL" = "jenkins.com",
    "GIT_BRANCH" = "test",
    "GIT_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",
    "BUILD_NUMBER" = "1",
    "BUILD_URL" = "http://test.com"
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
      expect_match(url, "build_url=http%3A%2F%2Ftest.com")
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
