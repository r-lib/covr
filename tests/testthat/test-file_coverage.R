s1 <- tempfile()
t1 <- tempfile()
writeLines(con = s1,
"a <- function(x) {
  x + 1
}

b <- function(x) {
  if (x > 1) TRUE
  else FALSE
}")

writeLines(con = t1,
"a(1)
a(2)
a(3)
b(0)
b(1)
b(2)")

on.exit(unlink(c(s1, t1)))

test_that("it works on single files", {
  cov <- file_coverage(s1, t1)
  cov_d <- as.data.frame(cov)

  expect_equal(cov_d$functions, c("a", "b", "b", "b"))
  expect_equal(cov_d$value, c(3, 3, 1, 2))
})
