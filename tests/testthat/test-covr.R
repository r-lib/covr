context("environment_coverage")
test_that("environment_coverage calls environment_coverage_", {

  # this is pretty silly, make more useful later
  with_mock(environment_coverage_ = function(...) TRUE,
    expect_true(environment_coverage(NULL))
    )
})

context("package_coverage")
test_that("package_coverage returns NULL if the path does not exist", {
  expect_null(package_coverage("blah"))
})

context("function_coverage")
test_that("function_coverage", {
  expect_equal(as.numeric(function_coverage("dots")), 0)

  expect_equal(as.numeric(function_coverage("dots", dots(hi))), 1)

  expect_equal(as.numeric(function_coverage("dots", dots(hi), dots(hi2))), 2)

  cov <- function_coverage("dots", dots(hi), dots(hi2))

  as_df_cov <- function_coverage("as.data.frame.coverage", as.data.frame(cov))

  expect_equal(unname(unlist(as_df_cov)), c(1, 1, 1, 1, 1))
})
