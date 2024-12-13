test_that("mcparallel without the fix", {
  skip_on_os("windows")

  cov <- withr::with_options(list(covr.fix_parallel_mcexit = FALSE),
    package_coverage("TestParallel", type = "test"))
  # only the non parallel code is covered
  expect_equal(floor(percent_coverage(cov)), 33)
})



test_that("mcparallel with the fix", {
  skip_on_os("windows")

  # using auto detection
  cov <- package_coverage(test_path("TestParallel"), type = "test")
  # only the non parallel code is covered
  expect_equal(percent_coverage(cov), 100)
})



test_that("uses_parallel", {
  pkg <- covr:::as_package("TestParallel")
  expect_true(covr:::uses_parallel(pkg))

  pkg <- covr:::as_package("TestSummary")
  expect_false(covr:::uses_parallel(pkg))
})



test_that("should_enable_parallel_mcexit_fix", {
  skip_on_os("windows")
  on.exit({
      Sys.unsetenv('COVR_FIX_PARALLEL_MCEXIT')
      options(covr.fix_parallel_mcexit = NULL)
    }, add = TRUE
  )

  grid <- expand.grid(
    var = c(NA, TRUE, FALSE),
    option = c(NA, TRUE, FALSE),
    pkg = c("TestParallel", "TestSummary"), stringsAsFactors = FALSE)

  grid$res <- with(grid, ifelse(!is.na(var),
      var,
      ifelse(!is.na(option), option, pkg == "TestParallel")
   ))

  .test_config <- function(var, option, pkgname) {
    if (is.na(var))
      Sys.unsetenv('COVR_FIX_PARALLEL_MCEXIT')
    else
      Sys.setenv(COVR_FIX_PARALLEL_MCEXIT = var)


    if (is.na(option))
      options(covr.fix_parallel_mcexit = NULL)
    else
      options(covr.fix_parallel_mcexit = option)

    pkg <- covr:::as_package(pkgname)
    covr:::should_enable_parallel_mcexit_fix(pkg)
  }

  res <- with(grid, vapply(1:nrow(grid),
      function(i) .test_config(var[i], option[i], pkg[i]), TRUE))

  expect_identical(res, grid$res)

})
