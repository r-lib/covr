test_that("if", {
  f <-
    'f <- function(x) {
  if (FALSE)
    FALSE # never covered, used as anchor
  if (x)
    TRUE
  else
    FALSE
}'

  cov <- code_coverage(f, "f(TRUE)")
  expect_equal(zero_coverage(code_coverage(f, "f(TRUE)"))$line, c(3, 7))
  expect_equal(zero_coverage(code_coverage(f, "f(FALSE)"))$line, c(3, 5))
  expect_equal(zero_coverage(code_coverage(f, "f(TRUE);f(FALSE)"))$line, 3)
})
test_that("nested if else", {
  f <-
    'f <- function(x) {
  if (FALSE)
    FALSE # never covered, used as anchor
  else if (x)
    TRUE
  else
    FALSE
}'

  cov <- code_coverage(f, "f(TRUE)")
  expect_equal(zero_coverage(code_coverage(f, "f(TRUE)"))$line, c(3, 7))
  expect_equal(zero_coverage(code_coverage(f, "f(FALSE)"))$line, c(3, 5))
  expect_equal(zero_coverage(code_coverage(f, "f(TRUE);f(FALSE)"))$line, 3)
})

test_that("one-line if in the body of a function without braces (#279)", {
  f <- "f <- function(x) if (x) 1 else 2"

  for (code in c("f(TRUE)", "f(FALSE)")) {
    cov <- code_coverage(f, code)
    expect_equal(percent_coverage(cov, by = "line"), 0)
    expect_equal(percent_coverage(cov, by = "expression"), 75)
  }

  cov <- code_coverage(f, "f(TRUE); f(FALSE)")
  expect_equal(percent_coverage(cov, by = "line"), 100)
  expect_equal(percent_coverage(cov, by = "expression"), 100)
})

test_that("braceless function bodies are covered like braced ones (#279)", {
  braceless <- "f <- function(x) if (x)
  1 else
  2"
  braced <- "f <- function(x) { if (x)
  1 else
  2 }"

  for (code in c("f(TRUE)", "f(FALSE)", "f(TRUE); f(FALSE)")) {
    cov_braceless <- code_coverage(braceless, code)
    cov_braced <- code_coverage(braced, code)
    expect_equal(
      zero_coverage(cov_braceless)$line,
      zero_coverage(cov_braced)$line
    )
    expect_equal(percent_coverage(cov_braceless), percent_coverage(cov_braced))
  }
  expect_equal(zero_coverage(code_coverage(braceless, "f(TRUE)"))$line, 3)
  expect_equal(zero_coverage(code_coverage(braceless, "f(FALSE)"))$line, 2)
  expect_equal(percent_coverage(code_coverage(braceless, "f(TRUE)")), 200 / 3)
})

test_that("if nested in other calls (#279)", {
  f <- 'f <- function(x) {
  y <- if (x)
    "a"
  else
    "b"
  z <- list(if (x) "c" else "d", e = paste(if (x) "f" else "g"))
  lapply(1, function(i) if (x) i else -i)
  (if (x) "h" else "i") -> a
  paste(switch(as.character(x), "TRUE" = "j", "k"))
}'

  res <- as.data.frame(code_coverage(f, "f(FALSE)"))
  expect_equal(res$first_line[res$value == 0], c(3, 6, 6, 7, 8, 9))
  expect_equal(res$first_column[res$value == 0], c(5, 20, 51, 32, 11, 42))
})

test_that("switch", {
  f <-
    'f <- function(x) {
  switch(x,
    a = 1,
    b = 2,
    c = d <- 1
  )
}'

  expect_equal(
    length(zero_coverage(code_coverage(f, "f(\"a\"); f(\"b\")"))$line),
    1
  )
  expect_equal(
    length(zero_coverage(code_coverage(f, "f(\"a\"); f(\"c\")"))$line),
    1
  )
  expect_equal(
    diff(zero_coverage(code_coverage(f, "f(\"a\"); f(\"d\")"))$line),
    1
  )
})

test_that("switch with default value", {
  f <-
    'f <- function(x) {
  switch(x,
    a = 1,
    b = 2,
    c = d <- 1,
    NULL
  )
}'

  expect_equal(
    length(
      zero_coverage(code_coverage(f, "f(\"a\"); f(\"b\"); f(\"c\")"))$line
    ),
    1
  )

  expect_equal(
    length(zero_coverage(code_coverage(f, "f(\"a\"); f(\"c\")"))$line),
    2
  )
})

test_that("switch with drop through", {
  f <-
    'f <- function(x) {
  switch(x,
    a = ,
    b = 2,
    c = d <- 1,
    NULL
  )
}'

  res <- as.data.frame(code_coverage(f, 'f("a");f("b");f("c")'))
  expect_equal(res$first_line, c(2, 4, 5, 6))
  expect_equal(res$value, c(3, 2, 1, 0))
})

test_that("switch with trailing comma", {
  f <-
    'f <- function(x) {
  switch(x,
    a = 1,
    b = 2,
  )
}'

  expect_no_warning(
    res <- as.data.frame(code_coverage(f, 'f("a");f("a");f("b")'))
  )
  expect_equal(res$first_line, c(2, 3, 4))
  expect_equal(res$value, c(3, 2, 1))
})

test_that("switch with drop through and the base pipe (#630)", {
  skip_if(getRversion() < "4.1")
  f <-
    'f <- function(x) {
  x |>
    switch(
      a = ,
      b = 2,
      c = d <- 1,
      NULL
    )
}'

  res <- as.data.frame(code_coverage(f, 'f("a");f("b");f("c")'))
  expect_equal(res$first_line, c(2, 5, 6, 7))
  expect_equal(res$value, c(3, 2, 1, 0))
})

test_that("switch with ellipses", {
  f <-
    'f <- function(x, ...) {
  switch(typeof(x), ...)
}'

  res <- as.data.frame(code_coverage(f, "f(\"a\", character = TRUE)"))
  expect_equal(res$first_line, 2)
  expect_equal(res$value, 1)

  f <-
    'f <- function(x, ...) {
  switch(typeof(x),
    ...,
    character = TRUE)
}'

  res <- as.data.frame(code_coverage(f, "f(\"a\")"))
  expect_equal(res$first_line, c(2, 4))
  expect_equal(res$value, c(1, 1))
})
