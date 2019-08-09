ops <- options("crayon.enabled" = FALSE, warn = 1)
library(testthat)
library("covr")

# Skip tests on Solaris as gcc is not in the PATH and I do not have an easy way
# to mimic the CRAN build environment
if (!tolower(Sys.info()[["sysname"]]) == "sunos") {
  Sys.setenv("R_TESTS" = "")
  if (requireNamespace("xml2")) {
    test_check("covr", reporter = MultiReporter$new(reporters = list(JunitReporter$new(file = "test-results.xml"), CheckReporter$new())))
  } else {
    test_check("covr")
  }
}

options(ops)
