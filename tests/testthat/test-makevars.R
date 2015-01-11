context("makevars")
test_that("makevars correctly matches only exact variable name", {
  f1 <- "makevars.tmp"
  writeLines(c("FCFLAGS=1"), con = f1)
  with_mock(
    `base::file.path` = function(...) "makevars.tmp",
    `base::dir.create` = function(...) invisible(),
    `base::writeLines` = function(con, lines) print(lines),

    expect_output(set_makevars(c(CFLAGS="test")), "FCFLAGS=1"),
    expect_output(set_makevars(c(CFLAGS="test")), "CFLAGS=test")
  )
  unlink("makevars.tmp")
})
test_that("makevars correctly ignores commented lines", {
  f1 <- "makevars.tmp"
  writeLines(c("# CFLAGS=1"), con = f1)
  with_mock(
    `base::file.path` = function(...) "makevars.tmp",
    `base::dir.create` = function(...) invisible(),
    `base::writeLines` = function(con, lines) print(lines),

    expect_output(set_makevars(c(CFLAGS="test")), "# CFLAGS=1"),
    expect_output(set_makevars(c(CFLAGS="test")), "CFLAGS=test")
  )
  unlink("makevars.tmp")
})
