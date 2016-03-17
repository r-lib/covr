ops <- options("crayon.enabled" = FALSE)
library(testthat)
library("covr")

Sys.setenv("R_TESTS" = "")
test_check("covr")
options(ops)
