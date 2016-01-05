context("Compiled")
test_that("Compiled code coverage is reported including code in headers", {
  skip_on_cran()
  cov <- as.data.frame(package_coverage("TestCompiled", relative_path = TRUE))

  simple_c <- cov[cov$filename == "src/simple.c", ]
  expect_equal(simple_c[simple_c$first_line == "10", "value"], 4)

  expect_equal(simple_c[simple_c$first_line == "16", "value"], 3)

  expect_equal(simple_c[simple_c$first_line == "19", "value"], 0)

  expect_equal(simple_c[simple_c$first_line == "21", "value"], 1)

  expect_equal(simple_c[simple_c$first_line == "23", "value"], 4)

  expect_true(all(unique(cov$filename) %in% c("R/TestCompiled.R", "src/simple-header.h", "src/simple.c")))
})

test_that("Source code subdirectories are found", {
  skip_on_cran()
  cov <- as.data.frame(package_coverage("TestCompiledSubdir", relative_path = TRUE))

  expect_equal(cov[cov$first_line == "9", "value"], 4)

  expect_equal(cov[cov$first_line == "15", "value"], 3)

  expect_equal(cov[cov$first_line == "18", "value"], 0)

  expect_equal(cov[cov$first_line == "20", "value"], 1)

  expect_equal(cov[cov$first_line == "22", "value"], 4)
})
