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

test_that("switch", {
  f <-
'f <- function(x) {
  switch(x,
    a = 1,
    b = 2,
    c = d <- 1
  )
}'

  expect_equal(length(zero_coverage(code_coverage(f, "f(\"a\"); f(\"b\")"))$line),
    1)
  expect_equal(length(zero_coverage(code_coverage(f, "f(\"a\"); f(\"c\")"))$line),
    1)
  expect_equal(diff(zero_coverage(code_coverage(f, "f(\"a\"); f(\"d\")"))$line),
    1)
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

  expect_equal(length(zero_coverage(code_coverage(f, "f(\"a\"); f(\"b\"); f(\"c\")"))$line),
    1)

  expect_equal(length(zero_coverage(code_coverage(f, "f(\"a\"); f(\"c\")"))$line),
    2)
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
