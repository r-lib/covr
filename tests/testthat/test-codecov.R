cov <- package_coverage(test_path("TestS4"))
cov_no_token <- code_coverage("f <- function() 1", "f()")

test_that("it generates a properly formatted json file", {
  json <- jsonlite::fromJSON(to_codecov(cov))

  expect_match(json$files$name, "R/TestS4.R")
  expect_equal(
    json$files$coverage[[1]],
    c(
      NA,
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
  expect_equal(json$uploader, "R")
})

test_that("it requests an upload and sends the coverage to the location it returns", {
  withr::local_envvar(codecov_ci_vars())
  recorded <- local_codecov_mocks()
  res <- codecov(coverage = cov, token = "codecov_test")

  expect_length(recorded$requests, 2)
  post <- codecov_post(recorded)
  expect_equal(post$verb, "POST")
  expect_equal(
    post$url,
    "https://ingest.codecov.io/upload/github/tester::::test/upload-coverage"
  )
  expect_equal(post$headers[["Authorization"]], "token codecov_test")
  expect_equal(post$headers[["Content-Type"]], "application/json")

  put <- codecov_put(recorded)
  expect_equal(put$verb, "PUT")
  expect_equal(put$url, "https://storage.example.com/upload?sig=1")
  expect_length(put$headers, 0)

  expect_equal(
    res,
    list(
      url = "https://app.codecov.io/github/tester/test/commit/abc",
      raw_upload_location = "https://storage.example.com/upload?sig=1"
    )
  )
})

test_that("it prints the url of the upload unless quiet", {
  withr::local_envvar(codecov_ci_vars())
  local_codecov_mocks()

  expect_silent(codecov(coverage = cov))
  expect_snapshot(res <- codecov(coverage = cov, quiet = FALSE))
})

test_that("it describes a local repository in the request", {
  withr::local_envvar(codecov_ci_vars())
  recorded <- local_codecov_mocks()
  codecov(coverage = cov)

  body <- codecov_post_body(recorded)
  expect_named(
    body,
    c(
      "ci_service",
      "ci_url",
      "cli_args",
      "env",
      "flags",
      "job_code",
      "name",
      "version",
      "file_not_found",
      "branch",
      "code",
      "commitid",
      "parent_commit_id",
      "pullid"
    )
  )
  expect_equal(body$branch, "master")
  expect_equal(body$commitid, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
  expect_equal(body$code, "default")
  expect_false(body$file_not_found)
  expect_equal(body$env, structure(list(), names = character()))
  expect_match(body$version, "^covr-")
  expect_null(body$ci_service)
  expect_null(body$flags)
  expect_null(body$pullid)
})

test_that("it sends an explicit branch, commit, pr and flags", {
  withr::local_envvar(codecov_ci_vars())
  recorded <- local_codecov_mocks()
  codecov(
    coverage = cov,
    branch = "feature",
    commit = "b94a8fe5ccb19ba61c4c0873d391e987982fbbd3",
    pr = 12,
    flags = c("R", "unit")
  )

  body <- codecov_post_body(recorded)
  expect_equal(body$branch, "feature")
  expect_equal(body$commitid, "b94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
  expect_equal(body$pullid, "12")
  expect_equal(body$flags, list("R", "unit"))
  expect_equal(
    codecov_post(recorded)$url,
    "https://ingest.codecov.io/upload/github/tester::::test/upload-coverage"
  )
})

test_that("the coverage file is covr's JSON, compressed and encoded", {
  withr::local_envvar(codecov_ci_vars())
  recorded <- local_codecov_mocks()
  codecov(coverage = cov)

  put <- codecov_put(recorded)
  expect_type(put$body, "raw")
  payload <- jsonlite::fromJSON(rawToChar(put$body), simplifyVector = FALSE)
  expect_named(
    payload,
    c("report_fixes", "network_files", "coverage_files", "metadata")
  )
  expect_equal(
    payload$report_fixes,
    list(format = "legacy", value = structure(list(), names = character()))
  )
  expect_equal(payload$network_files, list("DESCRIPTION", "R/TestS4.R"))
  expect_equal(payload$metadata, structure(list(), names = character()))

  expect_length(payload$coverage_files, 1)
  file <- payload$coverage_files[[1]]
  expect_equal(file$filename, "coverage.json")
  expect_equal(file$format, "base64+compressed")
  expect_equal(file$labels, "")
  expect_false(grepl("[\r\n]", file$data))

  decoded <- rawToChar(
    memDecompress(jsonlite::base64_dec(file$data), type = "gzip")
  )
  expect_equal(decoded, as.character(to_codecov(cov)))
  expect_equal(jsonlite::fromJSON(decoded)$uploader, "R")
})

test_that("it sends an empty list of network files outside of a git repository", {
  withr::local_envvar(codecov_ci_vars())
  recorded <- local_codecov_mocks()
  local_mocked_bindings(git_files = function(dir) character())
  codecov(coverage = cov)

  payload <- jsonlite::fromJSON(
    rawToChar(codecov_put(recorded)$body),
    simplifyVector = FALSE
  )
  expect_equal(payload$network_files, list())
})

test_that("it doesn't send a token if there is none", {
  withr::local_envvar(codecov_ci_vars())
  recorded <- local_codecov_mocks()
  codecov(coverage = cov_no_token, branch = "master")

  expect_equal(
    codecov_post(recorded)$headers,
    c("Content-Type" = "application/json")
  )
})

test_that("the token is looked up from the argument, the environment, then codecov.yml", {
  withr::local_envvar(codecov_ci_vars())
  recorded <- local_codecov_mocks()

  codecov(coverage = cov)
  expect_equal(
    codecov_post(recorded)$headers[["Authorization"]],
    "token codecov_token_from_yaml"
  )

  withr::local_envvar(CODECOV_TOKEN = "codecov_from_env")
  codecov(coverage = cov)
  expect_equal(
    recorded$requests[[3]]$headers[["Authorization"]],
    "token codecov_from_env"
  )

  codecov(coverage = cov, token = "codecov_from_argument")
  expect_equal(
    recorded$requests[[5]]$headers[["Authorization"]],
    "token codecov_from_argument"
  )

  withr::local_envvar(CODECOV_TOKEN = "")
  codecov(coverage = cov)
  expect_equal(
    recorded$requests[[7]]$headers[["Authorization"]],
    "token codecov_token_from_yaml"
  )
})

test_that("base_url is where coverage is uploaded to", {
  withr::local_envvar(codecov_ci_vars())
  recorded <- local_codecov_mocks()

  for (base_url in c(
    "https://codecov.io",
    "https://codecov.io/",
    "https://app.codecov.io"
  )) {
    codecov(coverage = cov, base_url = base_url)
  }
  codecov(coverage = cov, base_url = "https://codecov.example.com/")

  urls <- vapply(recorded$requests, `[[`, character(1), "url")[c(1, 3, 5, 7)]
  expect_equal(
    urls,
    c(
      rep(
        "https://ingest.codecov.io/upload/github/tester::::test/upload-coverage",
        3
      ),
      "https://codecov.example.com/upload/github/tester::::test/upload-coverage"
    )
  )
})

test_that("it works with jenkins", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "JENKINS_URL" = "jenkins.com",
    "GIT_BRANCH" = "test",
    "GIT_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",
    "BUILD_NUMBER" = "1",
    "BUILD_URL" = "http://test.com/tester/test"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov)

  body <- codecov_post_body(recorded)
  expect_equal(body$ci_service, "jenkins")
  expect_equal(body$branch, "test")
  expect_equal(body$commitid, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
  expect_equal(body$job_code, "1")
  expect_equal(body$ci_url, "http://test.com/tester/test")
})

test_that("it works with travis normal builds", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "CI" = "true",
    "TRAVIS" = "true",
    "TRAVIS_PULL_REQUEST" = "false",
    "TRAVIS_REPO_SLUG" = "tester/travis",
    "TRAVIS_BRANCH" = "master",
    "TRAVIS_JOB_ID" = "10",
    "TRAVIS_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov)

  body <- codecov_post_body(recorded)
  expect_match(codecov_post(recorded)$url, "/github/tester::::travis/")
  expect_equal(body$ci_service, "travis")
  expect_equal(body$branch, "master")
  expect_equal(body$job_code, "10")
  expect_null(body$pullid)
  expect_equal(body$commitid, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})

test_that("it works with travis pull requests", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "CI" = "true",
    "TRAVIS" = "true",
    "TRAVIS_PULL_REQUEST" = "5",
    "TRAVIS_REPO_SLUG" = "tester/test",
    "TRAVIS_BRANCH" = "master",
    "TRAVIS_JOB_ID" = "10",
    "TRAVIS_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov, token = "codecov_test")

  body <- codecov_post_body(recorded)
  expect_equal(body$pullid, "5")
  expect_equal(body$branch, "master")
})

test_that("it works with codeship", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "CI" = "true",
    "CI_NAME" = "codeship",
    "CI_BRANCH" = "master",
    "CI_BUILD_NUMBER" = "5",
    "CI_BUILD_URL" = "http://test.com/tester/test",
    "CI_COMMIT_ID" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov)

  body <- codecov_post_body(recorded)
  expect_equal(body$ci_service, "codeship")
  expect_equal(body$branch, "master")
  expect_equal(body$job_code, "5")
  expect_equal(body$ci_url, "http://test.com/tester/test")
  expect_equal(body$commitid, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})

test_that("it works with circleci", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "CI" = "true",
    "CIRCLECI" = "true",
    "CIRCLE_BRANCH" = "master",
    "CIRCLE_BUILD_NUM" = "5",
    "CIRCLE_BUILD_URL" = "https://circleci.com/gh/tester/circle/5",
    "CIRCLE_PROJECT_USERNAME" = "tester",
    "CIRCLE_PROJECT_REPONAME" = "circle",
    "CIRCLE_PR_NUMBER" = "7",
    "CIRCLE_SHA1" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov, token = "codecov_test")

  body <- codecov_post_body(recorded)
  expect_match(codecov_post(recorded)$url, "/github/tester::::circle/")
  expect_equal(body$ci_service, "circleci")
  expect_equal(body$branch, "master")
  expect_equal(body$job_code, "5")
  expect_equal(body$ci_url, "https://circleci.com/gh/tester/circle/5")
  expect_equal(body$pullid, "7")
  expect_equal(body$commitid, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})

test_that("it works with semaphore", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "CI" = "true",
    "SEMAPHORE" = "true",
    "BRANCH_NAME" = "master",
    "SEMAPHORE_BUILD_NUMBER" = "5",
    "SEMAPHORE_REPO_SLUG" = "tester/semaphore",
    "REVISION" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov)

  body <- codecov_post_body(recorded)
  expect_match(codecov_post(recorded)$url, "/github/tester::::semaphore/")
  expect_equal(body$ci_service, "semaphore")
  expect_equal(body$branch, "master")
  expect_equal(body$job_code, "5")
  expect_equal(body$commitid, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})

test_that("it works with drone", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "CI" = "true",
    "DRONE" = "true",
    "DRONE_BRANCH" = "master",
    "DRONE_BUILD_NUMBER" = "5",
    "DRONE_BUILD_URL" = "http://test.com/tester/test",
    "DRONE_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov)

  body <- codecov_post_body(recorded)
  expect_equal(body$ci_service, "drone.io")
  expect_equal(body$branch, "master")
  expect_equal(body$job_code, "5")
  expect_equal(body$ci_url, "http://test.com/tester/test")
  expect_equal(body$commitid, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})

test_that("it works with AppVeyor", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "CI" = "True",
    "APPVEYOR" = "True",
    "APPVEYOR_REPO_NAME" = "testspace/test",
    "APPVEYOR_REPO_PROVIDER" = "bitbucket",
    "APPVEYOR_REPO_BRANCH" = "master",
    "APPVEYOR_ACCOUNT_NAME" = "testuser", # not necessarily the same as testspace above
    "APPVEYOR_PROJECT_SLUG" = "test",
    "APPVEYOR_BUILD_VERSION" = "1.0.5",
    "APPVEYOR_REPO_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov)

  body <- codecov_post_body(recorded)
  expect_match(
    codecov_post(recorded)$url,
    "/upload/bitbucket/testspace::::test/"
  )
  expect_equal(body$ci_service, "appveyor")
  expect_equal(body$branch, "master")
  expect_equal(body$job_code, "testuser/test/1.0.5")
  expect_equal(body$commitid, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})

test_that("it works with Wercker", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "CI" = "true",
    "WERCKER_GIT_BRANCH" = "master",
    "WERCKER_MAIN_PIPELINE_STARTED" = "5",
    "WERCKER_GIT_OWNER" = "tester",
    "WERCKER_GIT_REPOSITORY" = "wercker",
    "WERCKER_GIT_COMMIT" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov)

  body <- codecov_post_body(recorded)
  expect_match(codecov_post(recorded)$url, "/github/tester::::wercker/")
  expect_equal(body$ci_service, "wercker")
  expect_equal(body$branch, "master")
  expect_equal(body$job_code, "5")
  expect_equal(body$commitid, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})

test_that("it works with Google Cloud Build", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "GCB_PROJECT_ID" = "project",
    "GCB_BUILD_ID" = "build-1",
    "GCB_BRANCH_NAME" = "master",
    "GCB_TAG_NAME" = "v1",
    "GCB_PR_NUMBER" = "3",
    "GCB_COMMIT_SHA" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov, token = "codecov_test")

  body <- codecov_post_body(recorded)
  expect_equal(body$ci_service, "google_cloud_build")
  expect_equal(body$branch, "master")
  expect_equal(body$job_code, "build-1")
  expect_equal(body$name, "v1")
  expect_equal(body$pullid, "3")
  expect_equal(
    body$ci_url,
    "https://console.cloud.google.com/cloud-build/builds/build-1?project=project"
  )
})

test_that("it works with GitLab", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "CI" = "true",
    "GITLAB_CI" = "true",
    "CI_PROJECT_PATH" = "group/subgroup/gitlab",
    "CI_COMMIT_REF_NAME" = "master",
    "CI_JOB_ID" = "5",
    "CI_JOB_URL" = "https://gitlab.com/group/subgroup/gitlab/-/jobs/5",
    "CI_MERGE_REQUEST_IID" = "9",
    "CI_COMMIT_SHA" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov, token = "codecov_test")

  body <- codecov_post_body(recorded)
  expect_equal(
    codecov_post(recorded)$url,
    "https://ingest.codecov.io/upload/gitlab/group:::subgroup::::gitlab/upload-coverage"
  )
  expect_equal(body$ci_service, "gitlab")
  expect_equal(body$branch, "master")
  expect_equal(body$job_code, "5")
  expect_equal(body$ci_url, "https://gitlab.com/group/subgroup/gitlab/-/jobs/5")
  expect_equal(body$pullid, "9")
  expect_equal(body$commitid, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})

test_that("it works with the variables of older GitLab versions", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "CI" = "true",
    "CI_SERVER_NAME" = "GitLab CI",
    "CI_SERVER_HOST" = "gitlab.example.com",
    "CI_BUILD_ID" = "5",
    "CI_BUILD_REPO" = "https://gitlab-ci-token:secret@gitlab.example.com/tester/test.git",
    "CI_BUILD_REF_NAME" = "master",
    "CI_BUILD_REF" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov, token = "codecov_test")

  body <- codecov_post_body(recorded)
  expect_match(
    codecov_post(recorded)$url,
    "/upload/gitlab_enterprise/tester::::test/"
  )
  expect_equal(body$branch, "master")
  expect_equal(body$job_code, "5")
  expect_equal(body$commitid, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})

test_that("it works with GitHub Actions pushes", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "GITHUB_ACTION" = "__run",
    "GITHUB_REPOSITORY" = "tester/actions",
    "GITHUB_SERVER_URL" = "https://github.com",
    "GITHUB_REF" = "refs/heads/feature/one",
    "GITHUB_RUN_ID" = "42",
    "GITHUB_SHA" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov, token = "codecov_test")

  body <- codecov_post_body(recorded)
  expect_equal(
    codecov_post(recorded)$url,
    "https://ingest.codecov.io/upload/github/tester::::actions/upload-coverage"
  )
  expect_equal(body$ci_service, "github-actions")
  expect_equal(body$ci_url, "https://github.com/tester/actions/actions/runs/42")
  expect_equal(body$job_code, "42")
  expect_equal(body$branch, "feature/one")
  expect_equal(body$commitid, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
  expect_null(body$pullid)
})

test_that("it works with GitHub Enterprise", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "GITHUB_ACTION" = "__run",
    "GITHUB_REPOSITORY" = "tester/actions",
    "GITHUB_SERVER_URL" = "https://github.example.com",
    "GITHUB_REF" = "refs/heads/main",
    "GITHUB_RUN_ID" = "42",
    "GITHUB_SHA" = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov, token = "codecov_test")

  expect_match(
    codecov_post(recorded)$url,
    "/upload/github_enterprise/tester::::actions/"
  )
  expect_equal(
    codecov_post_body(recorded)$ci_url,
    "https://github.example.com/tester/actions/actions/runs/42"
  )
})

github_pull_request_env <- function(frame = parent.frame()) {
  event <- withr::local_tempfile(fileext = ".json", .local_envir = frame)
  writeLines(
    paste0(
      '{"number": 7, "pull_request": {"number": 7, "head": {',
      '"sha": "c94a8fe5ccb19ba61c4c0873d391e987982fbbd3",',
      '"label": "forkowner:feature", "repo": {"full_name": "forkowner/actions"}}}}'
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

test_that("pull requests on GitHub Actions use the head commit of the event", {
  github_pull_request_env()
  recorded <- local_codecov_mocks()
  codecov(coverage = cov, token = "codecov_test")

  body <- codecov_post_body(recorded)
  expect_equal(body$branch, "feature")
  expect_equal(body$pullid, "7")
  expect_equal(body$commitid, "c94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
  expect_equal(
    codecov_post(recorded)$headers[["Authorization"]],
    "token codecov_test"
  )
})

test_that("tokenless pull requests from forks use an unprotected branch", {
  github_pull_request_env()
  recorded <- local_codecov_mocks()
  codecov(coverage = cov_no_token)

  body <- codecov_post_body(recorded)
  expect_equal(body$branch, "forkowner:feature")
  expect_equal(body$pullid, "7")
  expect_equal(body$commitid, "c94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
  expect_false("Authorization" %in% names(codecov_post(recorded)$headers))
})

test_that("tokenless pull requests without an event use the repository owner", {
  github_pull_request_env()
  withr::local_envvar(GITHUB_EVENT_PATH = NA)
  recorded <- local_codecov_mocks()
  codecov(coverage = cov_no_token)

  body <- codecov_post_body(recorded)
  expect_equal(body$branch, "tester:feature")
  expect_equal(body$pullid, "7")
  expect_equal(body$commitid, "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
})

test_that("an explicit branch is not changed for tokenless pull requests", {
  github_pull_request_env()
  recorded <- local_codecov_mocks()
  codecov(coverage = cov_no_token, branch = "explicit")

  expect_equal(codecov_post_body(recorded)$branch, "explicit")
})

test_that("tokenless pull requests of other services use the repository owner", {
  withr::local_envvar(c(
    codecov_ci_vars(),
    "CI" = "true",
    "TRAVIS" = "true",
    "TRAVIS_PULL_REQUEST" = "5",
    "TRAVIS_REPO_SLUG" = "tester/test",
    "TRAVIS_BRANCH" = "feature"
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov_no_token)

  expect_equal(codecov_post_body(recorded)$branch, "tester:feature")
})

test_that("tokenless uploads that aren't for pull requests use the branch", {
  github_pull_request_env()
  withr::local_envvar(c(
    GITHUB_HEAD_REF = NA,
    GITHUB_REF = "refs/heads/main",
    GITHUB_EVENT_PATH = NA
  ))
  recorded <- local_codecov_mocks()
  codecov(coverage = cov_no_token)

  expect_equal(codecov_post_body(recorded)$branch, "main")
})

test_that("it errors if the repository can't be determined", {
  withr::local_envvar(codecov_ci_vars())
  recorded <- local_codecov_mocks()
  local_mocked_bindings(git_remote_url = function(dir) NULL)

  expect_snapshot(codecov(coverage = cov), error = TRUE)
  expect_length(recorded$requests, 0)
})

test_that("it errors if the upload can't be requested, but only warns on 429 and 5xx", {
  withr::local_envvar(codecov_ci_vars())

  local_codecov_mocks(
    post = fake_response(400L, "Missing repository upload token")
  )
  expect_snapshot(codecov(coverage = cov), error = TRUE)
  expect_error(codecov(coverage = cov), class = "covr_codecov_error")

  local_codecov_mocks(post = fake_response(429L, "Rate limit reached"))
  expect_snapshot(res <- codecov(coverage = cov))
  expect_warning(codecov(coverage = cov), class = "covr_codecov_warning")
  expect_null(res)

  local_codecov_mocks(post = fake_response(503L, "Service unavailable"))
  expect_snapshot(res <- codecov(coverage = cov))
  expect_null(res)
})

test_that("it only sends coverage if an upload was requested", {
  withr::local_envvar(codecov_ci_vars())

  recorded <- local_codecov_mocks(post = fake_response(500L, "Oops"))
  suppressWarnings(codecov(coverage = cov))
  expect_length(recorded$requests, 1)

  recorded <- local_codecov_mocks(
    post = fake_response(200L, '{"url": "https://app.codecov.io"}')
  )
  expect_snapshot(codecov(coverage = cov), error = TRUE)
  expect_length(recorded$requests, 1)
})

test_that("it errors if the coverage can't be sent, but only warns on 429 and 5xx", {
  withr::local_envvar(codecov_ci_vars())

  local_codecov_mocks(
    put = fake_response(403L, "<Error><Code>AccessDenied</Code></Error>")
  )
  expect_snapshot(codecov(coverage = cov), error = TRUE)
  expect_error(codecov(coverage = cov), class = "covr_codecov_error")

  local_codecov_mocks(put = fake_response(429L, "Rate limit reached"))
  expect_snapshot(res <- codecov(coverage = cov, quiet = FALSE))
  expect_null(res)

  local_codecov_mocks(put = fake_response(503L, "Service unavailable"))
  expect_snapshot(res <- codecov(coverage = cov))
  expect_null(res)
})

test_that("git remote urls are parsed", {
  expect_equal(
    parse_git_remote("https://github.com/r-lib/covr.git"),
    list(slug = "r-lib/covr", git_service = "github")
  )
  expect_equal(
    parse_git_remote("git@github.com:r-lib/covr.git"),
    list(slug = "r-lib/covr", git_service = "github")
  )
  expect_equal(
    parse_git_remote("ssh://git@github.com:22/r-lib/covr"),
    list(slug = "r-lib/covr", git_service = "github")
  )
  expect_equal(
    parse_git_remote("https://user@bitbucket.org/team/repo.git"),
    list(slug = "team/repo", git_service = "bitbucket")
  )
  expect_equal(
    parse_git_remote("https://gitlab.com/group/subgroup/repo/"),
    list(slug = "group/subgroup/repo", git_service = "gitlab")
  )
  expect_equal(
    parse_git_remote("git@git.example.com:team/repo.git"),
    list(slug = "team/repo", git_service = NULL)
  )
  expect_equal(
    parse_git_remote("https://github.example.com/team/repo.git")$git_service,
    "github_enterprise"
  )
  expect_null(parse_git_remote("/home/user/repo"))
  expect_null(parse_git_remote("https://github.com/repo"))
  expect_null(parse_git_remote(NULL))
})

test_that("slugs are encoded for the upload url", {
  expect_equal(encode_slug("r-lib/covr"), "r-lib::::covr")
  expect_equal(encode_slug("group/sub/repo"), "group:::sub::::repo")
  expect_equal(encode_slug("a/b/c/d"), "a:::b:::c::::d")
})

test_that("httr is not a load time dependency of covr (#623)", {
  expect_false("httr" %in% names(getNamespaceImports("covr")))
})

test_that("a line is only covered if all its expressions ran (#620)", {
  json <- jsonlite::fromJSON(to_codecov(shared_line_coverage()))

  expect_equal(json$files$coverage[[1]], c(NA, NA, 1, 0, NA, NA, 0))
})
