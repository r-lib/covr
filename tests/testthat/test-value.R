test_that("value() returns the execution count of each expression", {
  cov <- code_coverage(
    "f <- function(x) {\n  if (x) 1 else 2\n}",
    "f(TRUE); f(TRUE)"
  )

  expect_equal(
    value(cov),
    setNames(as.data.frame(cov, sort = FALSE)$value, names(cov))
  )
  expect_equal(sort(unname(value(cov))), c(0, 2, 2))
})
