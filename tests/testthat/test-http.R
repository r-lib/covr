test_that("http_request() sends a request and returns the response", {
  sent <- NULL
  httr2::local_mocked_responses(function(req) {
    sent <<- req
    httr2::response(201L, body = charToRaw("hello"))
  })

  res <- http_request(
    "PUT",
    "https://example.com/upload",
    body = charToRaw("data"),
    headers = c("Content-Type" = "text/plain", "Authorization" = "token abc")
  )
  expect_equal(res, list(status = 201L, reason = "Created", body = "hello"))

  expect_equal(sent$method, "PUT")
  expect_equal(sent$url, "https://example.com/upload")
  expect_equal(sent$body$data, charToRaw("data"))
  headers <- httr2::req_dry_run(
    sent,
    redact_headers = FALSE,
    quiet = TRUE
  )$headers
  expect_equal(headers$`content-type`, "text/plain")
  expect_equal(headers$authorization, "token abc")
  # The token is redacted
  redacted <- httr2::req_dry_run(sent, quiet = TRUE)$headers
  expect_equal(redacted$`content-type`, "text/plain")
  expect_false(identical(redacted$authorization, "token abc"))
  # HTTP/1.1
  expect_equal(sent$options$http_version, 2L)
})

test_that("http_request() returns HTTP errors", {
  httr2::local_mocked_responses(function(req) {
    httr2::response(404L)
  })
  res <- http_request("POST", "https://example.com", body = "{}")
  expect_equal(res, list(status = 404L, reason = "Not Found", body = ""))
  expect_equal(http_status_message(res), "HTTP 404 Not Found")
})

test_that("http_request() sends files as a multipart form", {
  file <- withr::local_tempfile(lines = "hello")
  sent <- NULL
  httr2::local_mocked_responses(function(req) {
    sent <<- req
    httr2::response(200L, body = charToRaw("{}"))
  })

  http_request("POST", "https://example.com", files = c(json_file = file))
  expect_equal(sent$method, "POST")
  expect_equal(sent$body$type, "multipart")
  expect_s3_class(sent$body$data$json_file, "form_file")
  expect_equal(
    normalizePath(unclass(sent$body$data$json_file)$path),
    normalizePath(file)
  )
})

test_that("http_is_transient() retries rate limiting and server errors", {
  transient <- vapply(
    c(200L, 400L, 403L, 404L, 429L, 500L, 503L),
    function(status) http_is_transient(httr2::response(status)),
    logical(1)
  )
  expect_equal(transient, c(FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE))
})

test_that("http_backoff() doubles the wait up to a minute", {
  expect_equal(http_backoff(1:8), c(1, 2, 4, 8, 16, 32, 60, 60))
})
