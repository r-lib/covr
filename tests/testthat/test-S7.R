test_that("S7 coverage is reported", {
  cov <- as.data.frame(package_coverage("TestS7"))
 
  expect_equal(cov$value, c(1, 1, 1, 1, 3, 0, 3, 0, 3, 1, 1))
})
