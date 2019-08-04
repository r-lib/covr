test_that("tally_coverage includes compiled code", {
  cov <- package_coverage(test_path("TestCompiled"))
  tall <- tally_coverage(cov)

  expect_named(tall, c("filename", "functions", "line", "value"))

  expect_equal(
    unique(tall$filename),
    c("R/TestCompiled.R", "src/simple-header.h", "src/simple.c"))

  expect_equal(
    unname(as.list(tall[3, ])),
    list("src/simple-header.h", NA_character_, 9L, 4L)
  )

  expect_equal(
    unname(as.list(tall[15, ])),
    list("src/simple.c", NA_character_, 10L, 4L)
  )
})
