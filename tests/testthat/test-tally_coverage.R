test_that("tally_coverage includes compiled code", {
  skip_on_cran()

  cov <- package_coverage(test_path("TestCompiled"))
  tall <- tally_coverage(cov)

  expect_named(tall, c("filename", "functions", "line", "value"))

  expect_equal(
    unique(tall$filename),
    c("R/TestCompiled.R", "src/simple-header.h", "src/simple.cc", "src/simple4.cc"))
})
