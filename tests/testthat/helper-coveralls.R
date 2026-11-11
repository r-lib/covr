ci_vars <- c(
  codecov_ci_vars(),
  "CI_REMOTE" = NA,
  "COVERALLS_REPO_TOKEN" = NA,
  "COVERALLS_TOKEN" = NA,
  "GITHUB_REF_NAME" = NA
)

read_file <- function(file) paste(collapse = "\n", readLines(file))

coveralls_ok_response <- function() {
  fake_response(
    200L,
    '{"message":"Job #1.1","url":"https://coveralls.io/jobs/1"}'
  )
}

# Replaces the upload and git calls of `coveralls()`, and returns an
# environment that records the requests, with the content of the uploaded file
# (which `coveralls()` deletes).
local_coveralls_mocks <- function(
  response = coveralls_ok_response(),
  frame = parent.frame()
) {
  recorded <- new.env()
  recorded$requests <- list()
  local_mocked_bindings(
    http_request = function(
      method,
      url,
      body = NULL,
      headers = character(),
      files = character()
    ) {
      path <- files[["json_file"]]
      recorded$requests[[length(recorded$requests) + 1L]] <- list(
        method = method,
        url = url,
        path = path,
        json = readChar(path, file.size(path), useBytes = TRUE)
      )
      response
    },
    system_output = function(...) {
      paste0(c("a", "b", "c", "d", "e", "f"), collapse = "\n")
    },
    .env = frame
  )
  recorded
}

# The JSON that `coveralls()` last uploaded
coveralls_json <- function(recorded) {
  requests <- recorded$requests
  jsonlite::fromJSON(requests[[length(requests)]]$json)
}
