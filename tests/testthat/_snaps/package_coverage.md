# package_coverage returns an error if the path does not exist

    Code
      package_coverage("blah")
    Condition
      Error:
      ! `path` must be an existing directory.
      x 'blah' doesn't exist.

# package_coverage returns an error if the type is incorrect

    Code
      package_coverage("TestPrint", type = "blah")
    Condition
      Error:
      ! `type` must be one of "tests", "vignettes", "examples", "all", "none".
      x "blah" isn't.

---

    Code
      package_coverage("TestPrint", type = c("blah", "test"))
    Condition
      Error:
      ! `type` must be one of "tests", "vignettes", "examples", "all", "none".
      x "blah" isn't.

# package_coverage requires 'all' and 'none' to be the only type

    Code
      package_coverage("TestPrint", type = c("all", "tests"))
    Condition
      Error:
      ! `type` can't combine "all" with other types.
    Code
      package_coverage("TestPrint", type = c("none", "tests"))
    Condition
      Error:
      ! `type` can't combine "none" with other types.

# package_coverage shows messages and warnings unless quiet

    Code
      . <- package_coverage(test_path("TestS4"), type = "none", quiet = FALSE)
    Message
      a message
    Condition
      Warning in `run_commands()`:
      a warning

# package_coverage needs tests and srcrefs of installed packages

    Code
      package_coverage(pkg, install_path = install_path)
    Condition
      Error:
      ! Can't find tests in the installed package TestSummary.
      i Install it with `R CMD INSTALL --install-tests`.

---

    Code
      package_coverage(pkg, install_path = install_path)
    Condition
      Error:
      ! Can't find source references in the installed package TestSummary.
      i Install it with `R CMD INSTALL --with-keep.source`.

# package_coverage warns about processes that did not save a trace

    Code
      cov <- package_coverage(test_path("TestSummary"), type = "none", code = code)
    Condition
      Warning:
      Can't find coverage from 1 R process that loaded TestSummary.
      i Coverage is lost if a process is killed or outlives the tests.
      i Did a test leave a Shiny app, callr session, or future worker running?

# package_coverage() requires a single string as relative_path

    Code
      package_coverage(test_path("TestS4"), relative_path = c("a", "b"))
    Condition
      Error:
      ! `relative_path` must be `TRUE`, `FALSE`, or a single string.
      x It is a character vector of length 2.

