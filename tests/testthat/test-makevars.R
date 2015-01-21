context("makevars")
test_that("makevars correctly matches only exact variable name", {
  f1 <- "Makevars"
  writeLines(c("FCFLAGS=1"), con = f1)

  set_makevars(c(CFLAGS="test"), f1)
  expect_equal(c("FCFLAGS=1", "CFLAGS=test"), readLines(f1))
  expect_true(file.exists(backup_name(f1)))

  reset_makevars(f1)
  expect_false(file.exists(backup_name(f1)))
  expect_equal("FCFLAGS=1", readLines(f1))

  unlink(f1)
})

test_that("makevars correctly ignores commented lines", {
  f1 <- "Makevars"
  writeLines(c("# CFLAGS=1"), con = f1)
  set_makevars(c(CFLAGS="test"), f1)
  expect_equal(c("# CFLAGS=1", "CFLAGS=test"), readLines(f1))
  expect_true(file.exists(backup_name(f1)))

  reset_makevars(f1)
  expect_false(file.exists(backup_name(f1)))
  expect_equal("# CFLAGS=1", readLines(f1))

  unlink(f1)
})

test_that("makevars does nothing if the file will not change", {
  f1 <- "Makevars"
  writeLines(c("CFLAGS=1"), con = f1)
  set_makevars(c(CFLAGS="1"), f1)

  expect_equal(c("CFLAGS=1"), readLines(f1))
  expect_false(file.exists(backup_name(f1)))

  unlink(f1)
})

test_that("makevars errors if more than one match is found", {
  f1 <- "Makevars"
  writeLines(c("CFLAGS=1", "CFLAGS=2"), con = f1)
  expect_error(set_makevars(c(CFLAGS="1"), f1), "Multiple results")

  unlink(f1)
})
test_that("makevars handles the case without a Makevars file", {

  f1 <- "Makevars"
  set_makevars(c(CFLAGS="1"), f1)
  expect_equal(c("CFLAGS=1"), readLines(f1))

  reset_makevars(f1)
  expect_false(file.exists(f1))
})
