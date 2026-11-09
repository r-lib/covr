#' Run covr on a package and upload the result to codecov.io
#'
#' Uploads coverage to Codecov with the current upload protocol, the one used
#' by the [Codecov CLI](https://github.com/codecov/codecov-cli) and the
#' `codecov/codecov-action` GitHub Action. This takes two requests:
#'
#' 1. `POST <base_url>/upload/<git service>/<owner>::::<repo>/upload-coverage`
#'    (for a repository in nested groups, `owner/group/repo` is
#'    `owner:::group::::repo`) tells Codecov about the commit, branch, pull request and CI job. The
#'    response contains a `url` for the upload on Codecov and a pre-signed
#'    location to send the coverage report to.
#' 1. `PUT` sends the report, covr's JSON coverage format (processed by
#'    Codecov as an `R` report), to that location. With branch coverage (see
#'    [covr.branch_coverage]), the report uses Codecov's [generic JSON
#'    format](https://docs.codecov.com/docs/codecov-custom-coverage-format)
#'    instead, as the `R` format only takes line hits. A line with branches
#'    then has the number of its branches taken and the number of branches,
#'    e.g. `"1/2"`, so Codecov shows it as partly covered unless all were
#'    taken.
#'
#' If `quiet` is `FALSE`, the url of the upload on Codecov is printed after a
#' successful upload.
#'
#' The commit, branch, pull request, job, build URL and repository are looked up
#' from the environment variables of the CI service, which is one of Jenkins,
#' Travis, Codeship, CircleCI, Semaphore, Drone, AppVeyor, Wercker, GitLab CI,
#' GitHub Actions or Google Cloud Build. Anywhere else, or for values the
#' service does not provide, they are looked up from the local git repository
#' in the working directory. The repository (`owner/repo`) and the git service
#' (`github`, `gitlab`, `bitbucket`, ...) come from the CI service when it
#' provides them, otherwise from the `origin` remote of the local git
#' repository, otherwise the git service is assumed to be `github`.
#'
#' @section Tokens:
#' Codecov authenticates uploads with an upload token, passed in the
#' `Authorization` header. Both the token of a repository and an organization
#' (global) upload token, which is shared by all of an organization's
#' repositories, can be used. The token is looked up as described for `token`.
#' See <https://docs.codecov.com/docs/codecov-tokens>.
#'
#' Without a token, Codecov only accepts uploads for public repositories, and
#' only for an unprotected branch, which is a branch name with an owner prefix
#' such as `owner:branch`. Pull requests from forks do not have access to the
#' token as a CI secret, so on GitHub Actions, when there is no token, `branch`
#' is `NULL` and the head repository of the pull request (the
#' `pull_request.head.repo.full_name` of the event in `GITHUB_EVENT_PATH`)
#' differs from `GITHUB_REPOSITORY`, `codecov()` uses the label of the head of
#' the pull request, `owner:branch`, as the branch name, as
#' `codecov/codecov-action` does. Pull requests from the same repository, other
#' CI services and uploads from other branches use the plain branch name, so
#' without a token Codecov rejects them unless the branch is already
#' unprotected.
#'
#' @section Alternative:
#' Instead of uploading from R, write the coverage to a file and upload it with
#' the `codecov/codecov-action` GitHub Action, or any other Codecov uploader.
#' `to_lcov()` has no dependencies and writes `lcov.info`, which the action
#' uploads without further configuration:
#'
#' ```
#' - name: Test coverage
#'   run: covr::to_lcov(covr::package_coverage())
#'   shell: Rscript {0}
#'
#' - uses: codecov/codecov-action@v5
#'   with:
#'     token: ${{ secrets.CODECOV_TOKEN }}
#' ```
#'
#' [to_cobertura()] writes the Cobertura XML format, for which the xml2 package
#' is needed.
#'
#' @param coverage an existing coverage object to submit, if `NULL`,
#' [package_coverage()] will be called with the arguments from
#' `...`
#' @param ... arguments passed to [package_coverage()]
#' @param base_url the url coverage is uploaded to. The default is Codecov's
#'   upload API; change it for Codecov Enterprise. The former default
#'   `"https://codecov.io"` is the website, not the API, so it (and
#'   `"https://app.codecov.io"`) is replaced by the default.
#' @param quiet if `FALSE`, print the coverage before submission.
#' @param token a codecov upload token, if `NULL` then following external
#'   sources will be checked in this order:
#'   1. the environment variable \sQuote{CODECOV_TOKEN}. If it is empty, then
#'   1. package will look at directory of the package for a file `codecov.yml`.
#'   File must have `codecov` section where field `token` is set to a token that
#'   will be used.
#'
#'   If there is no token, the upload is sent without one, see the section
#'   \dQuote{Tokens}.
#' @param commit explicitly set the commit this coverage result object
#' corresponds to. Is looked up from the service or locally if it is
#' `NULL`.
#' @param branch explicitly set the branch this coverage result object
#' corresponds to, this is looked up from the service or locally if it is
#' `NULL`.
#' @param pr explicitly set the pr this coverage result object corresponds to,
#'   this is looked up from the service if it is `NULL`.
#' @param flags A flag to use for this coverage upload see
#'   <https://docs.codecov.com/docs/flags> for details.
#' @return The response of Codecov to the request for an upload, invisibly: a
#'   list that includes `url`, the url of the upload on Codecov. If Codecov
#'   rejects either request, `codecov()` throws an error of class
#'   `covr_codecov_error` with the response of Codecov in its message, except
#'   when Codecov is rate limiting requests (HTTP 429) or is unavailable (HTTP
#'   5xx), when it gives a warning of class `covr_codecov_warning` and returns
#'   `NULL` instead, so CI does not fail because of a transient Codecov problem.
#' @export
#' @examples
#' \dontrun{
#' codecov(path = "test")
#' }
codecov <- function(
  ...,
  coverage = NULL,
  base_url = "https://ingest.codecov.io",
  token = NULL,
  commit = NULL,
  branch = NULL,
  pr = NULL,
  flags = NULL,
  quiet = TRUE
) {
  if (is.null(coverage)) {
    coverage <- package_coverage(quiet = quiet, ...)
  }

  if (!quiet) {
    print(coverage)
  }

  token <- codecov_token(token, coverage)

  info <- codecov_ci_info()
  info$commit <- commit %||% info$commit %||% current_commit()
  info$pr <- codecov_pr(pr %||% info$pr)

  # Only an unprotected branch can be uploaded to without a token
  if (is.null(branch)) {
    info$branch <- info$branch %||% local_branch()
    if (is.null(token)) {
      info$branch <- info$fork_branch %||% info$branch
    }
  } else {
    info$branch <- branch
  }

  if (is.null(info$slug) || is.null(info$git_service)) {
    remote <- parse_git_remote(git_remote_url())
    info$slug <- info$slug %||% remote$slug
    info$git_service <- info$git_service %||% remote$git_service
  }
  info$git_service <- info$git_service %||% "github"
  if (is.null(info$slug) || !grepl("^[^/ ]+(/[^/ ]+)+$", info$slug)) {
    covr_abort(c(
      "Can't determine the repository ({.code owner/repo}) to upload coverage for.",
      i = "Run {.fn codecov} on a CI service or in a git repository with an {.code origin} remote."
    ))
  }

  url <- paste0(
    codecov_ingest_url(base_url),
    "/upload/",
    info$git_service,
    "/",
    encode_slug(info$slug),
    "/upload-coverage"
  )
  # Codecov's serializer rejects null for `flags`, `ci_service` and `version`
  request <- jsonlite::toJSON(
    list(
      ci_service = info$ci_service %||% "local",
      ci_url = info$ci_url,
      cli_args = NULL,
      env = empty_object(),
      flags = I(as.character(flags)),
      job_code = info$job_code,
      name = info$name,
      version = paste0("covr-", utils::packageVersion("covr")),
      file_not_found = FALSE,
      branch = info$branch,
      code = "default",
      commitid = info$commit,
      parent_commit_id = NULL,
      pullid = info$pr
    ),
    auto_unbox = TRUE,
    null = "null"
  )

  res <- codecov_request(
    "POST",
    url,
    body = as.character(request),
    headers = c(
      "Content-Type" = "application/json",
      if (!is.null(token)) c("Authorization" = paste("token", token))
    )
  )
  if (!codecov_response_ok(res, "Can't request an upload from Codecov.")) {
    return(invisible(NULL))
  }
  upload <- tryCatch(
    jsonlite::fromJSON(
      content(res, as = "text", encoding = "UTF-8"),
      simplifyVector = FALSE
    ),
    error = function(e) NULL
  )
  if (!is.character(upload$raw_upload_location)) {
    covr_abort(
      c(
        "Can't find an upload location in Codecov's reply.",
        i = "Codecov replied:"
      ),
      output = content(res, as = "text", encoding = "UTF-8")
    )
  }

  res <- codecov_request(
    "PUT",
    upload$raw_upload_location,
    body = codecov_payload(to_codecov(coverage), git_files())
  )
  if (!codecov_response_ok(res, "Can't send coverage to Codecov.")) {
    return(invisible(NULL))
  }

  if (!quiet && is.character(upload$url)) {
    message("Coverage uploaded to Codecov: ", upload$url)
  }
  invisible(upload)
}

codecov_token <- function(token, coverage) {
  token <- token %||% Sys.getenv("CODECOV_TOKEN")
  if (!nzchar(token)) {
    token <- extract_from_yaml(attr(coverage, "package")$path)
  }
  if (nzchar(token)) token
}

# The upload API only works with the `https://ingest.codecov.io` host. Before
# it was used, `base_url` was the website.
codecov_ingest_url <- function(base_url) {
  base_url <- sub("/+$", "", base_url)
  if (grepl("^https?://(www[.]|app[.])?codecov[.]io$", base_url)) {
    "https://ingest.codecov.io"
  } else {
    base_url
  }
}

# `owner/repo` is encoded as `owner::::repo` in the path of the upload API, and
# `owner/subgroup/repo` as `owner:::subgroup::::repo`.
encode_slug <- function(slug) {
  parts <- strsplit(slug, "/", fixed = TRUE)[[1]]
  n <- length(parts)
  paste0(paste(parts[-n], collapse = ":::"), "::::", parts[[n]])
}

# The uploaded file is covr's own JSON format, which Codecov processes with its
# `RlangProcessor`. It is sent in the format `base64+compressed`, which is the
# base64 encoding of the zlib compressed file.
codecov_payload <- function(coverage_json, network_files) {
  compressed <- memCompress(
    charToRaw(enc2utf8(as.character(coverage_json))),
    "gzip"
  )
  payload <- jsonlite::toJSON(
    list(
      report_fixes = list(format = "legacy", value = empty_object()),
      network_files = I(network_files),
      coverage_files = list(list(
        filename = "coverage.json",
        format = "base64+compressed",
        data = gsub("[\r\n]", "", jsonlite::base64_enc(compressed)),
        labels = ""
      )),
      metadata = empty_object()
    ),
    auto_unbox = TRUE,
    null = "null"
  )
  charToRaw(enc2utf8(as.character(payload)))
}

empty_object <- function() {
  structure(list(), names = character())
}

codecov_request <- function(verb, url, body, headers = character()) {
  RETRY(
    verb,
    url = url,
    body = body,
    encode = "raw",
    httr::add_headers(.headers = headers),
    httr::config(http_version = curl_http_1_1())
  )
}

# Returns `FALSE` after warning about rate limits and outages, which are
# transient Codecov problems, so don't fail CI. Other errors are thrown.
codecov_response_ok <- function(res, what) {
  if (!http_error(res)) {
    return(TRUE)
  }
  status <- httr::status_code(res)
  body <- content(res, as = "text", encoding = "UTF-8")
  details <- c(
    x = "{httr::http_status(res)$message}.",
    i = if (nzchar(body)) "Codecov replied:"
  )
  if (status == 429L || status >= 500L) {
    covr_warn(
      c(what, details),
      output = body,
      status = status,
      class = "covr_codecov_warning"
    )
    return(FALSE)
  }
  covr_abort(
    c(what, details),
    output = body,
    status = status,
    class = "covr_codecov_error"
  )
}

# Returns the first of the environment variables that is set and not empty
env_var <- function(...) {
  for (name in c(...)) {
    value <- Sys.getenv(name)
    if (nzchar(value)) {
      return(value)
    }
  }
  NULL
}

codecov_pr <- function(pr) {
  pr <- as.character(pr)
  if (length(pr) == 1L && !is.na(pr) && nzchar(pr) && pr != "false") pr
}

git_remote_url <- function(dir = ".") {
  url <- tryCatch(
    withr::with_dir(
      dir,
      system_output("git", c("remote", "get-url", "origin"), quiet = TRUE)
    ),
    error = function(e) character()
  )
  if (length(url)) trim(url[[1]])
}

git_files <- function(dir = ".") {
  tryCatch(
    withr::with_dir(
      dir,
      system_output(
        "git",
        c("-c", "core.quotepath=off", "ls-files"),
        quiet = TRUE
      )
    ),
    error = function(e) character()
  )
}

# Parses the `https://`, `ssh://` and `git@host:` forms of a git remote url
parse_git_remote <- function(url) {
  if (is.null(url)) {
    return(NULL)
  }
  parts <- regmatches(
    url,
    regexec(
      "^[a-zA-Z+]+://(?:[^@/]+@)?([^/:@]+)(?::[0-9]+)?/(.+)$",
      url,
      perl = TRUE
    )
  )[[1]]
  if (!length(parts)) {
    parts <- regmatches(
      url,
      regexec("^(?:[^@/]+@)?([^/:@]+):(.+)$", url, perl = TRUE)
    )[[1]]
  }
  if (!length(parts)) {
    return(NULL)
  }
  slug <- sub("[.]git$", "", sub("/+$", "", parts[[3]]))
  if (!grepl("^[^/ ]+(/[^/ ]+)+$", slug)) {
    return(NULL)
  }
  list(slug = slug, git_service = git_service_from_host(parts[[2]]))
}

git_service_from_host <- function(host) {
  host <- tolower(host)
  if (host == "github.com") {
    "github"
  } else if (host == "gitlab.com") {
    "gitlab"
  } else if (host == "bitbucket.org") {
    "bitbucket"
  } else if (grepl("github", host, fixed = TRUE)) {
    "github_enterprise"
  } else if (grepl("gitlab", host, fixed = TRUE)) {
    "gitlab_enterprise"
  } else if (grepl("bitbucket", host, fixed = TRUE)) {
    "bitbucket_server"
  }
}

# Looks up what the CI service knows about the build. Anything it doesn't
# provide (`NULL`) is looked up from the local git repository in `codecov()`.
codecov_ci_info <- function() {
  # -------
  # Jenkins
  # -------
  if (Sys.getenv("JENKINS_URL") != "") {
    # https://wiki.jenkins-ci.org/display/JENKINS/Building+a+software+project
    list(
      ci_service = "jenkins",
      branch = env_var("GIT_BRANCH"),
      commit = env_var("GIT_COMMIT"),
      job_code = env_var("BUILD_NUMBER"),
      ci_url = env_var("BUILD_URL")
    )
    # ---------
    # Travis CI
    # ---------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("TRAVIS") == "true") {
    # https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables
    list(
      ci_service = "travis",
      branch = env_var("TRAVIS_BRANCH"),
      pr = env_var("TRAVIS_PULL_REQUEST"),
      job_code = env_var("TRAVIS_JOB_ID"),
      slug = env_var("TRAVIS_REPO_SLUG"),
      commit = env_var("TRAVIS_COMMIT"),
      ci_url = env_var("TRAVIS_JOB_WEB_URL")
    )
    # --------
    # Codeship
    # --------
  } else if (
    Sys.getenv("CI") == "true" && Sys.getenv("CI_NAME") == "codeship"
  ) {
    # https://www.codeship.io/documentation/continuous-integration/set-environment-variables/
    list(
      ci_service = "codeship",
      branch = env_var("CI_BRANCH"),
      job_code = env_var("CI_BUILD_NUMBER"),
      ci_url = env_var("CI_BUILD_URL"),
      commit = env_var("CI_COMMIT_ID")
    )
    # ---------
    # Circle CI
    # ---------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("CIRCLECI") == "true") {
    # https://circleci.com/docs/environment-variables
    owner <- env_var("CIRCLE_PROJECT_USERNAME")
    repo <- env_var("CIRCLE_PROJECT_REPONAME")
    list(
      ci_service = "circleci",
      branch = env_var("CIRCLE_BRANCH"),
      job_code = env_var("CIRCLE_BUILD_NUM"),
      ci_url = env_var("CIRCLE_BUILD_URL"),
      slug = if (!is.null(owner) && !is.null(repo)) paste0(owner, "/", repo),
      pr = env_var("CIRCLE_PR_NUMBER"),
      commit = env_var("CIRCLE_SHA1")
    )
    # ---------
    # Semaphore
    # ---------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("SEMAPHORE") == "true") {
    # https://semaphoreapp.com/docs/available-environment-variables.html
    list(
      ci_service = "semaphore",
      branch = env_var("BRANCH_NAME"),
      job_code = env_var("SEMAPHORE_BUILD_NUMBER"),
      slug = env_var("SEMAPHORE_REPO_SLUG"),
      commit = env_var("REVISION")
    )
    # --------
    # drone.io
    # --------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("DRONE") == "true") {
    # http://docs.drone.io/env.html
    list(
      ci_service = "drone.io",
      branch = env_var("DRONE_BRANCH"),
      job_code = env_var("DRONE_BUILD_NUMBER"),
      ci_url = env_var("DRONE_BUILD_URL"),
      pr = env_var("DRONE_PULL_REQUEST"),
      commit = env_var("DRONE_COMMIT")
    )
    # --------
    # AppVeyor
    # --------
  } else if (Sys.getenv("CI") == "True" && Sys.getenv("APPVEYOR") == "True") {
    # http://www.appveyor.com/docs/environment-variables
    list(
      ci_service = "appveyor",
      branch = env_var("APPVEYOR_REPO_BRANCH"),
      job_code = paste(
        Sys.getenv("APPVEYOR_ACCOUNT_NAME"),
        Sys.getenv("APPVEYOR_PROJECT_SLUG"),
        Sys.getenv("APPVEYOR_BUILD_VERSION"),
        sep = "/"
      ),
      pr = env_var("APPVEYOR_PULL_REQUEST_NUMBER"),
      slug = env_var("APPVEYOR_REPO_NAME"),
      git_service = switch(
        tolower(Sys.getenv("APPVEYOR_REPO_PROVIDER")),
        github = "github",
        gitlab = "gitlab",
        bitbucket = "bitbucket"
      ),
      commit = env_var("APPVEYOR_REPO_COMMIT")
    )
    # -------
    # Wercker
    # -------
  } else if (
    Sys.getenv("CI") == "true" && Sys.getenv("WERCKER_GIT_BRANCH") != ""
  ) {
    # http://devcenter.wercker.com/articles/steps/variables.html
    owner <- env_var("WERCKER_GIT_OWNER")
    repo <- env_var("WERCKER_GIT_REPOSITORY")
    list(
      ci_service = "wercker",
      branch = env_var("WERCKER_GIT_BRANCH"),
      job_code = env_var("WERCKER_MAIN_PIPELINE_STARTED"),
      slug = if (!is.null(owner) && !is.null(repo)) paste0(owner, "/", repo),
      commit = env_var("WERCKER_GIT_COMMIT")
    )
    # ---------
    # GitLab-CI
    # ---------
  } else if (
    Sys.getenv("CI") == "true" &&
      (Sys.getenv("CI_SERVER_NAME") == "GitLab CI" ||
        Sys.getenv("GITLAB_CI") == "true")
  ) {
    # http://docs.gitlab.com/ce/ci/variables/README.html
    host <- env_var("CI_SERVER_HOST") %||% "gitlab.com"
    list(
      ci_service = "gitlab",
      git_service = if (host == "gitlab.com") "gitlab" else "gitlab_enterprise",
      branch = env_var("CI_BUILD_REF_NAME", "CI_COMMIT_REF_NAME"),
      job_code = env_var("CI_BUILD_ID", "CI_JOB_ID"),
      ci_url = env_var("CI_JOB_URL"),
      pr = env_var("CI_MERGE_REQUEST_IID"),
      slug = env_var("CI_PROJECT_PATH") %||%
        parse_git_remote(env_var("CI_BUILD_REPO"))$slug,
      commit = env_var("CI_BUILD_REF", "CI_COMMIT_SHA")
    )
    # ---------
    # GitHub Actions
    # ---------
  } else if (nzchar(Sys.getenv("GITHUB_ACTION"))) {
    # Adapted from
    # https://github.com/codecov/codecov-bash/blob/3316b21c8fe0ca7ada543fb8473ac616822ce27a/codecov#L763-L783
    slug <- env_var("GITHUB_REPOSITORY")
    server_url <- env_var("GITHUB_SERVER_URL") %||% "https://github.com"
    run_id <- env_var("GITHUB_RUN_ID")
    github_ref <- Sys.getenv("GITHUB_REF")
    head_ref <- env_var("GITHUB_HEAD_REF")

    info <- list(
      ci_service = "github-actions",
      git_service = if (grepl("^https?://github[.]com$", server_url)) {
        "github"
      } else {
        "github_enterprise"
      },
      job_code = run_id,
      ci_url = if (!is.null(slug) && !is.null(run_id)) {
        paste0(server_url, "/", slug, "/actions/runs/", run_id)
      },
      slug = slug,
      branch = head_ref %||% sub("^refs/heads/", "", github_ref),
      commit = env_var("GITHUB_SHA")
    )
    if (!is.null(head_ref)) {
      # The pull request event has the pull request, and its head commit, which
      # GITHUB_SHA, the merge commit, is not
      event <- github_event()$pull_request
      info$pr <- event$number %||%
        regmatches(
          github_ref,
          regexpr("(?<=^refs/pull/)[0-9]+", github_ref, perl = TRUE)
        )
      info$commit <- event$head$sha %||% info$commit
      # Codecov only accepts a tokenless upload from an unprotected branch,
      # which has an owner prefix, like the `owner:branch` label GitHub gives
      # the head of a pull request from a fork
      head_repo <- event$head$repo$full_name
      if (!is.null(head_repo) && !identical(head_repo, slug)) {
        info$fork_branch <- event$head$label %||%
          paste0(sub("/.*", "", head_repo), ":", head_ref)
      }
    }
    info
    # ---------
    # Google Cloud Build
    # ---------
  } else if (nzchar(Sys.getenv("GCB_PROJECT_ID"))) {
    # https://cloud.google.com/build/docs/configuring-builds/substitute-variable-values
    list(
      ci_service = "google_cloud_build",
      branch = env_var("GCB_BRANCH_NAME"),
      job_code = env_var("GCB_BUILD_ID"),
      ci_url = sprintf(
        "https://console.cloud.google.com/cloud-build/builds/%s?project=%s",
        Sys.getenv("GCB_BUILD_ID"),
        Sys.getenv("GCB_PROJECT_ID")
      ),
      name = env_var("GCB_TAG_NAME"),
      pr = env_var("GCB_PR_NUMBER"),
      commit = env_var("GCB_COMMIT_SHA")
    )
    # ---------
    # Local GIT
    # ---------
  } else {
    list()
  }
}

github_event <- function() {
  path <- Sys.getenv("GITHUB_EVENT_PATH")
  if (!file.exists(path)) {
    return(NULL)
  }
  tryCatch(
    jsonlite::fromJSON(path, simplifyVector = FALSE),
    error = function(e) NULL
  )
}


curl_http_1_1 <- function() {
  symbols <- curl::curl_symbols()
  symbols$value[symbols$name == "CURL_HTTP_VERSION_1_1"]
}

extract_from_yaml <- function(path) {
  if (is.null(path)) {
    return("")
  }

  path_to_yaml <- file.path(path, "codecov.yml")
  if (file.exists(path_to_yaml)) {
    yaml::read_yaml(path_to_yaml)[["codecov"]][["token"]] %||% ""
  } else {
    ""
  }
}

to_codecov <- function(x) {
  coverages <- lapply(per_line(x), function(xx) {
    xx$coverage <- c(NA, xx$coverage)
    xx
  })

  if (!is.null(attr(x, "branches"))) {
    return(to_codecov_branches(coverages, tally_coverage(x, by = "branch")))
  }

  res <- Map(
    function(coverage, name) {
      list(
        "name" = jsonlite::unbox(name),
        "coverage" = coverage$coverage
      )
    },
    coverages,
    names(coverages),
    USE.NAMES = FALSE
  )

  jsonlite::toJSON(
    na = "null",
    list("files" = res, "uploader" = jsonlite::unbox("R"))
  )
}

# Codecov's R format only takes line hits, so with branch coverage the report
# uses Codecov's generic JSON format
# (<https://docs.codecov.com/docs/codecov-custom-coverage-format>), in which
# lines with branches have the number of branches taken and the number of
# branches, e.g. `"1/2"`. It has no `uploader` field, which would make Codecov
# process it as an R report.
to_codecov_branches <- function(coverages, branches) {
  totals <- line_branch_totals(branches)
  files <- Map(
    function(coverage, name) {
      values <- lapply(coverage$coverage, jsonlite::unbox)
      file_totals <- totals[totals$filename == name, , drop = FALSE]
      # The first element is line 0
      idx <- file_totals$line + 1L
      keep <- idx <= length(values) & !is.na(coverage$coverage[idx])
      values[idx[keep]] <- lapply(
        paste0(file_totals$taken[keep], "/", file_totals$total[keep]),
        jsonlite::unbox
      )
      values
    },
    coverages,
    names(coverages)
  )
  jsonlite::toJSON(na = "null", list("coverage" = files))
}
