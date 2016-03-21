ops <- options("crayon.enabled" = FALSE, warn = 1)
library(testthat)
library("covr")

Sys.setenv("R_TESTS" = "")
test_check("covr")
options(ops)
