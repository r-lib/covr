context("coveralls")
library(devtools)
read_file <- function(file) readChar(file, file.info(file)$size)
test_that("coveralls generates a properly formatted json file", {

  with_envvar(c("CI_NAME" = "FAKECI"),
    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr::upload_file` = function(file) readChar(file, file.info(file)$size),

      res <- coveralls("TestS4"),
      json <<- jsonlite::fromJSON(res[[5]]$body$json_file),

      expect_equal(nrow(json$source_files), 1),
      expect_equal(json$service_name, "fakeci"),
      expect_equal(json$source_files$name, "TestS4/R/TestS4.R"),
      expect_equal(json$source_files$source, read_file("TestS4/R/TestS4.R")),
      expect_equal(json$source_files$coverage[[1]],
        c(NA, NA, 5, 2, 5, 3, 5, NA, NA, NA, NA, NA, NA, NA, NA, NA,
          NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1))
    )
  )
})

test_that("coveralls can spawn a job using repo_token", {

  with_envvar(c("CI_NAME" = "DRONE"),
    with_mock(
      `httr:::perform` = function(...) list(...),
      `httr::content` = identity,
      `httr::upload_file` = function(file) readChar(file, file.info(file)$size),

      res <- coveralls("TestS4", repo_token="mytoken"),
      json <<- jsonlite::fromJSON(res[[5]]$body$json_file),

      expect_equal(is.null(json$git), FALSE),
      expect_equal(nrow(json$source_files), 1),
      expect_equal(json$service_name, NULL),
      expect_equal(json$repo_token, "mytoken"),
      expect_equal(json$source_files$name, "TestS4/R/TestS4.R"),
      expect_equal(json$source_files$source, read_file("TestS4/R/TestS4.R")),
      expect_equal(json$source_files$coverage[[1]],
        c(NA, NA, 5, 2, 5, 3, 5, NA, NA, NA, NA, NA, NA, NA, NA, NA,
          NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1))
    )
  )
})

test_that("generates correct payload for Drone and Jenkins", {

  with_envvar(c("CI_NAME" = "FAKECI", "CI_BRANCH" = "fakebranch", "CI_REMOTE" = "covr"),
    with_mock(
      `system` = function(...) paste0(c("a","b","c","d","e","f"), collapse="\n"),
      git <- jenkins_git_info(),

      expect_equal(git$head$id, jsonlite::unbox("a")),
      expect_equal(git$head$author_name, jsonlite::unbox("b")),
      expect_equal(git$head$author_email, jsonlite::unbox("c")),
      expect_equal(git$head$commiter_name, jsonlite::unbox("d")),
      expect_equal(git$head$commiter_email, jsonlite::unbox("e")),
      expect_equal(git$head$message, jsonlite::unbox("f")),
      expect_equal(git$branch, jsonlite::unbox("fakebranch")),
      expect_equal(git$remotes[[1]]$name, jsonlite::unbox("origin")),
      expect_equal(git$remotes[[1]]$url, jsonlite::unbox("covr"))

    )
  )
})
