# Replaces the upload and git calls of `coveralls()`, which then returns the
# request it would have sent.
local_coveralls_mocks <- function(frame = parent.frame()) {
  local_mocked_bindings(
    RETRY = function(...) list(...),
    content = identity,
    upload_file = function(file) readChar(file, file.info(file)$size),
    system_output = function(...) {
      paste0(c("a", "b", "c", "d", "e", "f"), collapse = "\n")
    },
    .env = frame
  )
}

coveralls_json <- function(res) {
  jsonlite::fromJSON(res$body$json_file)
}
