s1 <- tempfile()
t1 <- tempfile()
writeLines(con = s1,
"a <- memoise::memoise(function(x) {
  x + 1
})")

writeLines(con = t1,
"
a(1)
a(1)
a(1)
a(1)
a(2)
a(3)")

on.exit(unlink(c(s1, t1)))

test_that("it works on Vectorized functions", {
  cov <- file_coverage(s1, t1)
  cov_d <- as.data.frame(cov)

  expect_equal(cov_d$functions, "a")
  expect_equal(cov_d$value, 3)
})
