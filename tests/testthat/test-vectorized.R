s1 = tempfile()
t1 = tempfile()
writeLines(con = s1,
'scalar_func <- function(x,y) {
  z <- x + y
}

vector_func <- Vectorize(scalar_func,vectorize.args=c("x","y"),SIMPLIFY=TRUE)')

writeLines(con = t1,
"vector_func(1:10, 2)")

on.exit(unlink(c(s1, t1)))

test_that("it works on Vectorized functions", {
  cov <- file_coverage(s1, t1)
  cov_d <- as.data.frame(cov)

  expect_equal(cov_d$functions, "vector_func")
  expect_equal(cov_d$value, 10)
})
