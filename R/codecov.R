#' Run covr on a package and upload the result to codecov.io
#' @param path file path to the package
#' @param Codecov url (change for Enterprise)
#' @param ... additional arguments passed to \code{\link{package_coverage}}
#' @export
codecov <- function(path = ".", base_url = 'https://codecov.io', ...) {
  
  # -------
  # Jenkins
  # -------
  if (Sys.getenv('JENKINS_URL')) {
    # https://wiki.jenkins-ci.org/display/JENKINS/Building+a+software+project
    # path <- Sys.getenv("WORKSPACE")
    codecov_url <- paste(base_url, "/upload/v2?service=jenkins", 
                         "&branch=", Sys.getenv('GIT_BRANCH'), 
                         "&commit=", Sys.getenv('GIT_COMMIT'),
                         "&build=", Sys.getenv('BUILD_NUMBER'),
                         "&build_url=", Sys.getenv('BUILD_URL'), sep="")

  # ---------
  # Travis CI
  # ---------
  } else if (Sys.getenv('CI') == "true" && Sys.getenv('TRAVIS') == "true") {
    # http://docs.travis-ci.com/user/ci-environment/#Environment-variables
    # path <- Sys.getenv('TRAVIS_BUILD_DIR')
    codecov_url <- paste(base_url, "/upload/v2?service=travis-org",
                         "&branch=", Sys.getenv('TRAVIS_BRANCH'),
                         "&build=", Sys.getenv('TRAVIS_JOB_NUMBER'),
                         "&pull_request=", ifelse(Sys.getenv('TRAVIS_PULL_REQUEST')!='false', Sys.getenv('TRAVIS_PULL_REQUEST'), ''),
                         "&travis_job_id=", Sys.getenv('TRAVIS_JOB_ID'),
                         "&owner=", strsplit(Sys.getenv('TRAVIS_REPO_SLUG'), '/')[0],
                         "&repo=", strsplit(Sys.getenv('TRAVIS_REPO_SLUG'), '/')[1],
                         "&commit=", Sys.getenv('TRAVIS_COMMIT'), sep="")
  # --------
  # Codeship
  # --------
  } else if (Sys.getenv('CI') == "true" && Sys.getenv('CI_NAME') == 'codeship') {
    # https://www.codeship.io/documentation/continuous-integration/set-environment-variables/
    codecov_url <- paste(base_url, "/upload/v2?service=codeship",
                         "&branch=", Sys.getenv('CI_BRANCH'),
                         "&build=", Sys.getenv('CI_BUILD_NUMBER'),
                         "&build_url=", Sys.getenv('CI_BUILD_URL'),
                         "&commit=", Sys.getenv('CI_COMMIT_ID')), sep="")
  # ---------
  # Circle CI
  # ---------
  } else if (Sys.getenv('CI') == "true" && Sys.getenv('CIRCLECI') == 'true') {
    # https://circleci.com/docs/environment-variables
    codecov_url <- paste(base_url, "/upload/v2?service=circleci",
                         "&branch=", Sys.getenv('CIRCLE_BRANCH'),
                         "&build=", Sys.getenv('CIRCLE_BUILD_NUM'),
                         "&owner=", Sys.getenv('CIRCLE_PROJECT_USERNAME'),
                         "&repo=", Sys.getenv('CIRCLE_PROJECT_REPONAME'),
                         "&commit=", Sys.getenv('CIRCLE_SHA1')), sep="")
  
  # ---------
  # Semaphore
  # ---------
  } else if (Sys.getenv('CI') == "true" && Sys.getenv('SEMAPHORE') == "true") {
    # https://semaphoreapp.com/docs/available-environment-variables.html
    codecov_url <- paste(base_url, "/upload/v2?service=semaphore",
                         "&branch=", Sys.getenv('BRANCH_NAME'),
                         "&build=", Sys.getenv('SEMAPHORE_BUILD_NUMBER'),
                         "&owner=", strsplit(Sys.getenv('SEMAPHORE_REPO_SLUG'), '/')[0],
                         "&repo=", strsplit(Sys.getenv('SEMAPHORE_REPO_SLUG'), '/')[1],
                         "&commit=", Sys.getenv('REVISION')), sep="")
  # --------
  # drone.io
  # --------
  } else if (Sys.getenv('CI') == "true" && Sys.getenv('DRONE') == "true") {
    # http://docs.drone.io/env.html
    codecov_url <- paste(base_url, "/upload/v2?service=drone.io",
                         "&branch=", Sys.getenv('DRONE_BRANCH'),
                         "&build=", Sys.getenv('DRONE_BUILD_NUMBER'),
                         "&build_url=", Sys.getenv('DRONE_BUILD_URL'),
                         "&commit=", Sys.getenv('DRONE_COMMIT')), sep="")
  # --------
  # AppVeyor
  # --------
  } else if (Sys.getenv('CI') == "True" && Sys.getenv('APPVEYOR') == 'True') {
    # http://www.appveyor.com/docs/environment-variables
    codecov_url <- paste(base_url, "/upload/v2?service=AppVeyor",
                         "&branch=", Sys.getenv('APPVEYOR_REPO_BRANCH'),
                         "&build=", Sys.getenv('APPVEYOR_BUILD_NUMBER'),
                         "&owner=", strsplit(Sys.getenv('APPVEYOR_REPO_NAME'), '/')[0],
                         "&repo=", strsplit(Sys.getenv('APPVEYOR_REPO_NAME'), '/')[1],
                         "&commit=", Sys.getenv('APPVEYOR_REPO_COMMIT')), sep="")
  # -------
  # Wercker
  # -------
  } else if (Sys.getenv('CI') == "true" && Sys.getenv('WERCKER_GIT_BRANCH')) {
    # http://devcenter.wercker.com/articles/steps/variables.html
    codecov_url <- paste(base_url, "/upload/v2?service=werker",
                         "&branch=", Sys.getenv('WERCKER_GIT_BRANCH'),
                         "&build=", Sys.getenv('WERCKER_MAIN_PIPELINE_STARTED'),
                         "&owner=", Sys.getenv('WERCKER_GIT_OWNER'),
                         "&repo=", Sys.getenv('WERCKER_GIT_REPOSITORY'),
                         "&commit=", Sys.getenv('WERCKER_GIT_COMMIT')), sep="")

  # ---------
  # Local GIT
  # ---------
  } else {
    branch <- gsub("^\\s+|\\s+$", "", system("git rev-parse --abbrev-ref HEAD", intern = TRUE))
    codecov_url <- paste(base_url, "/upload/v2",
                         "&branch=", ifelse(branch=='HEAD', 'master', branch),
                         "&commit=", gsub("^\\s+|\\s+$", "", system('git rev-parse HEAD', intern = TRUE)), sep="")
  }

  if (Sys.getenv('CODECOV_TOKEN')) {
    codecov_url <- paste(codecov_url, "&token=", Sys.getenv('CODECOV_TOKEN'), sep="")
  }

  # add query args
  # Sys.getenv("TRAVIS_JOB_ID"), service = "travis"
  coverage <- to_codecov(package_coverage(path, relative_path = TRUE, ...))

  name <- tempfile()
  con <- file(name)
  writeChar(con = con, coverage, eos = NULL)
  close(con)
  on.exit(unlink(name))
  httr::content(httr::POST(codecov_url, body = list(json_file = httr::upload_file(name))))
}

to_codecov <- function(x) {
  coverages <- per_line(x)

  coverage_names <- names(coverages)

  if (!is.null(attr(x, "path"))) {
    coverage_names <- file.path(attr(x, "path"), coverage_names)
  }

  res <- mapply(
    function(name, source, coverage) {
      list("name" = jsonlite::unbox(name),
        "coverage" = coverage)
    },
    coverage_names,
    sources,
    coverages,
    SIMPLIFY = FALSE,
    USE.NAMES = FALSE)

  jsonlite::toJSON(na = "null", list("files" = res, "uploader" = "R"))
}

per_line <- function(x) {

  df <- as.data.frame(x)

  filenames <- unique(df$filename)

  if (!is.null(attr(x, "path"))) {
    filenames <- file.path(attr(x, "path"), filenames)
  }

  sources <- lapply(filenames, readLines)

  blank_lines <- lapply(sources, function(file) {
    which(rex::re_matches(file, rex::rex(start, any_spaces, maybe("#", anything), end)))
    })
  names(blank_lines) <- filenames

  file_lengths <- tapply(df$last_line, df$filename,

    function(x) {
      max(unlist(x))
    })

  res <- lapply(file_lengths,
    function(x) {
      rep(NA_real_, length.out = x)
    })

  # get the minimum coverage per line
  for (i in seq_len(NROW(df))) {
    for (line in seq(df[i, "first_line"], df[i, "last_line"])) {
      filename <- df[i, "filename"]
      value <- df[i, "value"]
      if (!line %in% blank_lines[[filename]]) {
        if (is.na(res[[filename]][line]) || value < res[[filename]][line]) {
          res[[filename]][line] <- value
        }
      }
    }
  }
  res
}
