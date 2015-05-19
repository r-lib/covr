ops <- options("crayon.enabled" = FALSE)
library(testthat)
library("covr")

test_check("covr")
options(ops)
