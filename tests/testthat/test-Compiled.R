context("Compiled")
test_that("Compiled code coverage is reported including code in headers", {
  skip_on_cran()
  cov <- as.data.frame(package_coverage("TestCompiled", relative_path = TRUE))

  simple_cc <- cov[cov$filename == "src/simple.cc", ]
  expect_equal(simple_cc[simple_cc$first_line == "10", "value"], 4)

  expect_equal(simple_cc[simple_cc$first_line == "16", "value"], 3)

  expect_equal(simple_cc[simple_cc$first_line == "19", "value"], 0)

  expect_equal(simple_cc[simple_cc$first_line == "21", "value"], 1)

  expect_equal(simple_cc[simple_cc$first_line == "23", "value"], 4)

  # This header contains a C++ template, which requires you to run gcov for
  # each object file separately and merge the results together.
  simple_h <- cov[cov$filename == "src/simple-header.h", ]
  expect_equal(simple_h[simple_h$first_line == "12", "value"], 4)

  expect_equal(simple_h[simple_h$first_line == "18", "value"], 3)

  expect_equal(simple_h[simple_h$first_line == "21", "value"], 0)

  expect_equal(simple_h[simple_h$first_line == "23", "value"], 1)

  expect_equal(simple_h[simple_h$first_line == "25", "value"], 4)

  expect_true(all(unique(cov$filename) %in% c("R/TestCompiled.R", "src/simple-header.h", "src/simple.cc", "src/simple4.cc")))
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
