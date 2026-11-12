test_that("coveralls generates a properly formatted json file", {
  cov <- s4_coverage()
  withr::local_envvar(c(
    ci_vars,
    "CI_NAME" = "FAKECI"
  ))
  recorded <- local_coveralls_mocks()
  coveralls(coverage = cov)
  json <- coveralls_json(recorded)

  expect_equal(nrow(json$source_files), 1)
  expect_equal(json$service_name, "fakeci")
  expect_match(
    json$source_files$name,
    rex::rex("R", one_of("/", "\\"), "TestS4.R")
  )
  expect_equal(json$source_files$source, read_file("TestS4/R/TestS4.R"))
  expect_equal(
    json$source_files$source_digest,
    "1233f2eca5d84704101cb9d9b928f2e9"
  )
  expect_equal(
    json$source_files$coverage[[1]],
    c(
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      5,
      2,
      NA,
      3,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      1,
      NA,
      NA,
      NA,
      NA,
      NA,
      1,
      NA,
      NA,
      NA,
      NA,
      NA,
      1,
      NA
    )
  )
})

test_that("coveralls works with repo_token = NULL", {
  cov <- s4_coverage()
  withr::local_envvar(c(ci_vars, "CI_NAME" = "FAKECI"))
  recorded <- local_coveralls_mocks()
  coveralls(coverage = cov, repo_token = NULL)
  json <- coveralls_json(recorded)
  expect_null(json$repo_token)
  expect_null(json$git)
  expect_equal(json$service_name, "fakeci")
})

test_that("coveralls can spawn a job using repo_token", {
  cov <- s4_coverage()
  withr::local_envvar(c(
    ci_vars,
    "CI_NAME" = "DRONE"
  ))
  recorded <- local_coveralls_mocks()
  coveralls(coverage = cov, repo_token = "mytoken")
  json <- coveralls_json(recorded)

  expect_equal(is.null(json$git), FALSE)
  expect_equal(nrow(json$source_files), 1)
  # service_name set #285
  expect_equal(json$service_name, "drone")
  expect_equal(json$repo_token, "mytoken")
  expect_match(
    json$source_files$name,
    rex::rex("R", one_of("/", "\\"), "TestS4.R")
  )
  expect_equal(json$source_files$source, read_file("TestS4/R/TestS4.R"))
  expect_equal(
    json$source_files$source_digest,
    "1233f2eca5d84704101cb9d9b928f2e9"
  )
  expect_equal(
    json$source_files$coverage[[1]],
    c(
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      5,
      2,
      NA,
      3,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      1,
      NA,
      NA,
      NA,
      NA,
      NA,
      1,
      NA,
      NA,
      NA,
      NA,
      NA,
      1,
      NA
    )
  )
})

test_that("generates correct payload for Drone and Jenkins", {
  withr::local_envvar(c(
    ci_vars,
    "CI_NAME" = "FAKECI",
    "CI_BRANCH" = "fakebranch",
    "CI_REMOTE" = "covr"
  ))
  local_mocked_bindings(
    system_output = function(...) {
      paste0(c("a", "b", "c", "d", "e", "f"), collapse = "\n")
    }
  )
  git <- git_info()

  expect_equal(git$head$id, jsonlite::unbox("a"))
  expect_equal(git$head$author_name, jsonlite::unbox("b"))
  expect_equal(git$head$author_email, jsonlite::unbox("c"))
  expect_equal(git$head$committer_name, jsonlite::unbox("d"))
  expect_equal(git$head$committer_email, jsonlite::unbox("e"))
  expect_equal(git$head$message, jsonlite::unbox("f"))
  expect_equal(git$branch, jsonlite::unbox("fakebranch"))
  expect_equal(git$remotes[[1]]$name, jsonlite::unbox("origin"))
  expect_equal(git$remotes[[1]]$url, jsonlite::unbox("covr"))
})

test_that("coveralls detects GitHub Actions #535", {
  cov <- s4_coverage()
  withr::local_envvar(c(
    ci_vars,
    "GITHUB_ACTION" = "run",
    "GITHUB_REF" = "refs/heads/main",
    "GITHUB_SERVER_URL" = "https://github.com",
    "GITHUB_REPOSITORY" = "r-lib/covr",
    "GITHUB_RUN_ID" = "42",
    "GITHUB_SHA" = "abc"
  ))
  recorded <- local_coveralls_mocks()
  coveralls(coverage = cov, repo_token = "mytoken")
  json <- coveralls_json(recorded)

  expect_equal(json$service_name, "github")
  expect_equal(json$service_job_id, "42")
  expect_null(json$service_pull_request)
  expect_equal(json$git$branch, "main")
  expect_equal(json$git$head$id, "a")
  expect_equal(json$git$remotes$name, "origin")
  expect_equal(json$git$remotes$url, "https://github.com/r-lib/covr")

  # Pull requests use the source branch rather than `<number>/merge`
  withr::local_envvar(
    "GITHUB_HEAD_REF" = "feature",
    "GITHUB_REF" = "refs/pull/123/merge"
  )
  coveralls(coverage = cov, repo_token = "mytoken")
  json <- coveralls_json(recorded)
  expect_equal(json$git$branch, "feature")
  expect_equal(json$service_pull_request, "123")

  # An explicit service name is still used
  coveralls(
    coverage = cov,
    repo_token = "mytoken",
    service_name = "github-actions"
  )
  json <- coveralls_json(recorded)
  expect_equal(json$service_name, "github-actions")
  expect_equal(json$git$branch, "feature")
})

test_that("coveralls detects the services codecov() supports", {
  cov <- s4_coverage()
  recorded <- local_coveralls_mocks()
  detect <- function(...) {
    withr::local_envvar(c(ci_vars, ...))
    coveralls(coverage = cov)
    json <- coveralls_json(recorded)
    c(json$service_name, json$service_job_id)
  }

  expect_equal(
    detect(CI = "true", TRAVIS = "true", TRAVIS_JOB_ID = "1"),
    c("travis-ci", "1")
  )
  expect_equal(
    detect(CI = "true", CIRCLECI = "true", CIRCLE_BUILD_NUM = "2"),
    c("circleci", "2")
  )
  expect_equal(
    detect(GITLAB_CI = "true", CI = "true", CI_JOB_ID = "3"),
    c("gitlab-ci", "3")
  )
  expect_equal(
    detect(JENKINS_URL = "http://jenkins", BUILD_NUMBER = "4"),
    c("jenkins", "4")
  )
  expect_equal(
    detect(CI = "true", DRONE = "true", DRONE_BUILD_NUMBER = "5"),
    c("drone", "5")
  )
  expect_equal(detect(), "local")
})

test_that("coveralls submits the local git info outside CI", {
  cov <- s4_coverage()
  withr::local_envvar(ci_vars)
  recorded <- local_coveralls_mocks()
  local_mocked_bindings(
    git_remote_url = function(dir) "git@github.com:r-lib/covr.git",
    local_branch = function(dir) "main"
  )
  coveralls(coverage = cov, repo_token = "mytoken")
  json <- coveralls_json(recorded)

  expect_equal(json$service_name, "local")
  expect_equal(json$git$branch, "main")
  expect_equal(json$git$head$id, "a")
  expect_equal(json$git$remotes$url, "git@github.com:r-lib/covr.git")
})

test_that("coveralls submits no git info outside a git repository", {
  cov <- s4_coverage()
  withr::local_envvar(ci_vars)
  withr::local_dir(withr::local_tempdir())
  recorded <- local_coveralls_mocks()
  local_mocked_bindings(
    system_output = function(...) stop("not a git repository"),
    # As `system_output()` does, without git's message on stderr
    local_branch = function(dir) warning("had status 128")
  )
  coveralls(coverage = cov, repo_token = "mytoken")
  json <- coveralls_json(recorded)
  expect_equal(json$service_name, "local")
  expect_null(json$git)
})

test_that("coveralls computes the coverage when none is given", {
  cov <- s4_coverage()
  withr::local_envvar(ci_vars)
  recorded <- local_coveralls_mocks()
  args <- NULL
  local_mocked_bindings(
    package_coverage = function(...) {
      args <<- list(...)
      cov
    }
  )
  coveralls("TestS4", repo_token = NULL)
  json <- coveralls_json(recorded)

  expect_equal(args, list("TestS4", quiet = TRUE))
  expect_equal(nrow(json$source_files), 1)
})

test_that("coveralls prints the coverage unless quiet", {
  cov <- s4_coverage()
  withr::local_envvar(ci_vars)
  local_coveralls_mocks()
  expect_silent(coveralls(coverage = cov))
  expect_snapshot(res <- coveralls(coverage = cov, quiet = FALSE))
})

test_that("coveralls returns the response of Coveralls invisibly", {
  cov <- s4_coverage()
  withr::local_envvar(ci_vars)
  local_coveralls_mocks()
  res <- expect_invisible(coveralls(coverage = cov))
  expect_equal(
    res,
    list(message = "Job #1.1", url = "https://coveralls.io/jobs/1")
  )
})

test_that("coveralls posts the coverage to Coveralls as a file", {
  cov <- s4_coverage()
  withr::local_envvar(ci_vars)
  recorded <- local_coveralls_mocks()
  coveralls(coverage = cov)
  expect_equal(recorded$requests[[1]]$method, "POST")
  expect_equal(recorded$requests[[1]]$url, "https://coveralls.io/api/v1/jobs")
})

test_that("coveralls errors if Coveralls doesn't accept the upload", {
  cov <- s4_coverage()
  withr::local_envvar(ci_vars)

  # A JSON reply
  local_coveralls_mocks(
    fake_response(422L, '{"message":"Bad repo token","error":true}')
  )
  expect_snapshot(coveralls(coverage = cov), error = TRUE)
  expect_error(
    coveralls(coverage = cov),
    class = "covr_coveralls_error"
  )

  # A failure that isn't marked with `error`
  local_coveralls_mocks(fake_response(500L, '{"message":"Oops"}'))
  expect_snapshot(coveralls(coverage = cov), error = TRUE)

  # A reply that isn't JSON
  local_coveralls_mocks(fake_response(502L, "<html>Bad Gateway</html>"))
  expect_snapshot(coveralls(coverage = cov), error = TRUE)
  local_coveralls_mocks(fake_response(503L, ""))
  expect_snapshot(coveralls(coverage = cov), error = TRUE)

  # Coveralls also reports errors with a successful status
  local_coveralls_mocks(
    fake_response(200L, '{"message":"Bad repo token","error":true}')
  )
  expect_error(
    coveralls(coverage = cov),
    class = "covr_coveralls_error"
  )
  local_coveralls_mocks(fake_response(200L, "OK"))
  expect_error(
    coveralls(coverage = cov),
    class = "covr_coveralls_error"
  )
})

test_that("coveralls deletes the file it uploads", {
  cov <- s4_coverage()
  withr::local_envvar(ci_vars)
  recorded <- local_coveralls_mocks()
  coveralls(coverage = cov)
  # The file is there during the request, as the mock reads it
  expect_match(recorded$requests[[1]]$json, "source_files", fixed = TRUE)
  expect_false(file.exists(recorded$requests[[1]]$path))

  recorded <- local_coveralls_mocks(fake_response(500L, "Oops"))
  expect_error(
    coveralls(coverage = cov),
    class = "covr_coveralls_error"
  )
  expect_false(file.exists(recorded$requests[[1]]$path))
})

test_that("coveralls uses COVERALLS_TOKEN, then COVERALLS_REPO_TOKEN", {
  cov <- s4_coverage()
  withr::local_envvar(ci_vars)
  recorded <- local_coveralls_mocks()

  coveralls(coverage = cov)
  expect_null(coveralls_json(recorded)$repo_token)

  withr::local_envvar(COVERALLS_REPO_TOKEN = "repo")
  coveralls(coverage = cov)
  expect_equal(coveralls_json(recorded)$repo_token, "repo")

  withr::local_envvar(COVERALLS_TOKEN = "token")
  coveralls(coverage = cov)
  expect_equal(coveralls_json(recorded)$repo_token, "token")

  withr::local_envvar(COVERALLS_TOKEN = "")
  coveralls(coverage = cov)
  expect_equal(coveralls_json(recorded)$repo_token, "repo")

  coveralls(coverage = cov, repo_token = "explicit")
  expect_equal(coveralls_json(recorded)$repo_token, "explicit")
})

test_that("git_head gives the id of a commit that isn't in the repository", {
  local_mocked_bindings(system_output = function(...) stop("bad object"))
  expect_equal(git_head("abc123"), list(id = jsonlite::unbox("abc123")))
  expect_equal(git_head(), list())
})

test_that("coveralls can spawn a job using repo_token - travis-pro #285", {
  cov <- s4_coverage()
  withr::local_envvar(
    c(ci_vars, "CI_NAME" = "travis-pro")
  )
  recorded <- local_coveralls_mocks()
  coveralls(coverage = cov, repo_token = "mytoken")
  json <- coveralls_json(recorded)

  expect_equal(is.null(json$git), FALSE)
  expect_equal(nrow(json$source_files), 1)
  expect_equal(json$service_name, "travis-pro")
  expect_equal(json$repo_token, "mytoken")
  expect_match(
    json$source_files$name,
    rex::rex("R", one_of("/", "\\"), "TestS4.R")
  )
  expect_equal(json$source_files$source, read_file("TestS4/R/TestS4.R"))
  expect_equal(
    json$source_files$source_digest,
    "1233f2eca5d84704101cb9d9b928f2e9"
  )
  expect_equal(
    json$source_files$coverage[[1]],
    c(
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      5,
      2,
      NA,
      3,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      NA,
      1,
      NA,
      NA,
      NA,
      NA,
      NA,
      1,
      NA,
      NA,
      NA,
      NA,
      NA,
      1,
      NA
    )
  )
  # git correct #285
  expect_equal(json$git$head$id, "a")
  expect_equal(json$git$head$author_name, "b")
  expect_equal(json$git$head$author_email, "c")
  expect_equal(json$git$head$committer_name, "d")
  expect_equal(json$git$head$committer_email, "e")
  expect_equal(json$git$head$message, "f")
})

test_that("a line is only covered if all its expressions ran (#620)", {
  withr::local_envvar(c(ci_vars, "CI_NAME" = "FAKECI"))
  recorded <- local_coveralls_mocks()
  coveralls(coverage = shared_line_coverage())
  json <- coveralls_json(recorded)

  expect_equal(json$source_files$coverage[[1]], c(NA, 1, 0, NA, NA, 0))
})

test_that("with branch coverage, source files have their branches", {
  cov <- branch_coverage(
    c(
      "f <- function(x) {",
      "  if (x) 'yes' else if (!x) 'no'",
      "  switch(as.character(x), 'TRUE' = 1)",
      "}",
      "g <- function() 1"
    ),
    "f(TRUE)"
  )
  json <- jsonlite::fromJSON(to_coveralls(cov, service_name = "travis-ci"))
  file <- json$source_files

  expect_equal(file$coverage[[1]], c(NA, 0, 1, NA, 0))
  expect_equal(
    file$branches[[1]],
    c(
      c(2, 0, 0, 1),
      c(2, 0, 1, 0),
      c(2, 1, 0, 0),
      c(2, 1, 1, 0),
      c(3, 0, 0, 1),
      c(3, 0, 1, 0)
    )
  )
})

test_that("without branch coverage, source files have no branches", {
  cov <- code_coverage("f <- function(x) if (x) 1", "f(TRUE)")
  json <- jsonlite::fromJSON(to_coveralls(cov, service_name = "travis-ci"))
  expect_named(
    json$source_files,
    c("name", "source", "source_digest", "coverage")
  )
})
