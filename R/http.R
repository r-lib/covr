# httr2 and curl are called with `pkg::fun()` rather than imported, so that they
# are only loaded when used. Importing them makes them and their dependencies
# load time dependencies of covr, which causes a cyclic namespace dependency
# when running coverage on them (#623). All HTTP requests of covr go through
# `http_request()`, which tests mock.

# Sends a request and returns the response as a list with the `status` code,
# its `reason` phrase and the `body` as a string. HTTP errors are returned, not
# thrown, so the caller decides what they mean. Requests that fail with a
# transient status (429 or 5xx) are retried, up to three attempts in all.
#
# `body` is a string or raw vector to send as is. `files` is a named character
# vector of paths of files to send as a multipart form, under the names. The
# default of `NULL` for `body` sends a request without a body.
http_request <- function(
  method,
  url,
  body = NULL,
  headers = character(),
  files = character()
) {
  req <- httr2::request(url)
  if (length(headers)) {
    req <- do.call(
      httr2::req_headers,
      c(list(req), as.list(headers), list(.redact = "Authorization"))
    )
  }
  if (!is.null(body)) {
    req <- httr2::req_body_raw(req, body)
  }
  if (length(files)) {
    req <- do.call(
      httr2::req_body_multipart,
      c(list(req), lapply(files, curl::form_file))
    )
  }
  req <- httr2::req_method(req, method)
  # Codecov has trouble with large uploads over HTTP/2 (ggplot2#3862), so use
  # HTTP/1.1, which is 2 for CURL_HTTP_VERSION_1_1.
  req <- httr2::req_options(req, http_version = 2L)
  req <- httr2::req_retry(
    req,
    max_tries = 3,
    retry_on_failure = TRUE,
    is_transient = http_is_transient,
    backoff = http_backoff
  )
  req <- httr2::req_error(req, is_error = function(resp) FALSE)

  resp <- httr2::req_perform(req)
  list(
    status = httr2::resp_status(resp),
    reason = httr2::resp_status_desc(resp),
    body = if (httr2::resp_has_body(resp)) {
      httr2::resp_body_string(resp, encoding = "UTF-8")
    } else {
      ""
    }
  )
}

http_is_transient <- function(resp) {
  status <- httr2::resp_status(resp)
  status == 429L || status >= 500L
}

# Seconds to wait before the next attempt: 1, 2, 4, ...
http_backoff <- function(attempt) {
  pmin(2^(attempt - 1), 60)
}

# "HTTP 404 Not Found" for a response of `http_request()`
http_status_message <- function(res) {
  trimws(paste("HTTP", res$status, res$reason))
}
