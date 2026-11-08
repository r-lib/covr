ci_vars <- c(
  codecov_ci_vars(),
  "CI_REMOTE" = NA,
  "COVERALLS_TOKEN" = NA,
  "GITHUB_REF_NAME" = NA
)

read_file <- function(file) paste(collapse = "\n", readLines(file))

cov <- package_coverage(test_path("TestS4"))

test_that("coveralls generates a properly formatted json file", {
  withr::local_envvar(c(
    ci_vars,
    "CI_NAME" = "FAKECI"
  ))
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity,
    upload_file = function(file) readChar(file, file.info(file)$size)
  )
  res <- coveralls(coverage = cov)
  json <- jsonlite::fromJSON(res$body$json_file)

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
  withr::local_envvar(c(ci_vars, "CI_NAME" = "FAKECI"))
  local_coveralls_mocks()
  json <- coveralls_json(coveralls(coverage = cov, repo_token = NULL))
  expect_null(json$repo_token)
  expect_null(json$git)
  expect_equal(json$service_name, "fakeci")
})

test_that("coveralls can spawn a job using repo_token", {
  withr::local_envvar(c(
    ci_vars,
    "CI_NAME" = "DRONE"
  ))
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity,
    upload_file = function(file) readChar(file, file.info(file)$size),
    system_output = function(...) {
      paste0(c("a", "b", "c", "d", "e", "f"), collapse = "\n")
    }
  )
  res <- coveralls(coverage = cov, repo_token = "mytoken")
  json <- jsonlite::fromJSON(res$body$json_file)

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
  withr::local_envvar(c(
    ci_vars,
    "GITHUB_ACTION" = "run",
    "GITHUB_REF" = "refs/heads/main",
    "GITHUB_SERVER_URL" = "https://github.com",
    "GITHUB_REPOSITORY" = "r-lib/covr",
    "GITHUB_RUN_ID" = "42",
    "GITHUB_SHA" = "abc"
  ))
  local_coveralls_mocks()
  json <- coveralls_json(coveralls(coverage = cov, repo_token = "mytoken"))

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
  json <- coveralls_json(coveralls(coverage = cov, repo_token = "mytoken"))
  expect_equal(json$git$branch, "feature")
  expect_equal(json$service_pull_request, "123")

  # An explicit service name is still used
  json <- coveralls_json(coveralls(
    coverage = cov,
    repo_token = "mytoken",
    service_name = "github-actions"
  ))
  expect_equal(json$service_name, "github-actions")
  expect_equal(json$git$branch, "feature")
})

test_that("coveralls detects the services codecov() supports", {
  local_coveralls_mocks()
  detect <- function(...) {
    withr::local_envvar(c(ci_vars, ...))
    json <- coveralls_json(coveralls(coverage = cov))
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
  withr::local_envvar(ci_vars)
  local_coveralls_mocks()
  local_mocked_bindings(
    git_remote_url = function(dir) "git@github.com:r-lib/covr.git",
    local_branch = function(dir) "main"
  )
  json <- coveralls_json(coveralls(coverage = cov, repo_token = "mytoken"))

  expect_equal(json$service_name, "local")
  expect_equal(json$git$branch, "main")
  expect_equal(json$git$head$id, "a")
  expect_equal(json$git$remotes$url, "git@github.com:r-lib/covr.git")
})

test_that("coveralls submits no git info outside a git repository", {
  withr::local_envvar(ci_vars)
  withr::local_dir(withr::local_tempdir())
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity,
    upload_file = function(file) readChar(file, file.info(file)$size),
    # As `system_output()` does, without git's message on stderr
    local_branch = function(dir) warning("had status 128")
  )
  json <- coveralls_json(coveralls(coverage = cov, repo_token = "mytoken"))
  expect_equal(json$service_name, "local")
  expect_null(json$git)
})

test_that("coveralls can spawn a job using repo_token - travis-pro #285", {
  withr::local_envvar(
    c(ci_vars, "CI_NAME" = "travis-pro")
  )
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity,
    upload_file = function(file) readChar(file, file.info(file)$size),
    system_output = function(...) {
      paste0(c("a", "b", "c", "d", "e", "f"), collapse = "\n")
    }
  )
  res <- coveralls(coverage = cov, repo_token = "mytoken")
  json <- jsonlite::fromJSON(res$body$json_file)

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
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity,
    upload_file = function(file) readChar(file, file.info(file)$size)
  )
  res <- coveralls(coverage = shared_line_coverage())
  json <- jsonlite::fromJSON(res$body$json_file)

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
