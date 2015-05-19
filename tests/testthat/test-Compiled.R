context("Compiled")
test_that("Compiled code coverage is reported", {
  skip_on_cran()
  cov <- as.data.frame(package_coverage("TestCompiled", relative_path = TRUE))

  expect_equal(cov[cov$first_line == "9", "value"], 4)

  expect_equal(cov[cov$first_line == "15", "value"], 3)

  expect_equal(cov[cov$first_line == "18", "value"], 0)

  expect_equal(cov[cov$first_line == "20", "value"], 1)

  expect_equal(cov[cov$first_line == "22", "value"], 4)
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
