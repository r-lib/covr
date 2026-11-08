# Calculate test coverage for sets of files

The files in `source_files` are first sourced into a new environment to
define functions to be checked. Then they are instrumented to track
coverage and the files in `test_files` are sourced.

## Usage

``` r
file_coverage(
  source_files,
  test_files,
  line_exclusions = NULL,
  function_exclusions = NULL,
  parent_env = parent.frame()
)
```

## Arguments

- source_files:

  Character vector of source files with function definitions to measure
  coverage

- test_files:

  Character vector of test files with code to test the functions

- line_exclusions:

  a named list of files with the lines to exclude from each file.

- function_exclusions:

  a vector of regular expressions matching function names to exclude.
  Example `print\\\.` to match print methods.

- parent_env:

  The parent environment to use when sourcing the files.

## Value

A [coverage](https://covr.r-lib.org/dev/reference/coverage.md) object.

## Parallel code

Code run in processes forked by
[`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html),
[`parallel::mcparallel()`](https://rdrr.io/r/parallel/mcparallel.html)
and related functions (not available on Windows) is included in the
coverage. While the code runs, `parallel:::mcfork` and
`parallel:::mcexit` are patched so that the forked processes save their
counts when they exit. To turn this off, set the environment variable
`COVR_FIX_PARALLEL_MCEXIT` or the option `covr.fix_parallel_mcexit` to
`FALSE`.

## testthat tests

The test files are run with
[`sys.source()`](https://rdrr.io/r/base/sys.source.html), not with
testthat's test runner, so features that need the runner don't work. In
particular,
[`testthat::expect_snapshot()`](https://testthat.r-lib.org/reference/expect_snapshot.html)
is skipped ("Can't compare snapshot to reference when testing
interactively"), and testthat uses its 2nd edition unless the tests call
`testthat::local_edition(3)`.

To use these features, source the files yourself and run the tests with
[`testthat::test_file()`](https://testthat.r-lib.org/reference/test_file.html)
inside
[`with_coverage()`](https://covr.r-lib.org/dev/reference/with_coverage.md):

    env <- new.env()
    sys.source("R/my_functions.R", envir = env, keep.source = TRUE)
    cov <- with_coverage(
      testthat::test_file("tests/test-my_functions.R", env = env),
      env = env
    )

Snapshots are then saved in a `_snaps` directory next to the test file.
`expect_snapshot()` also needs the 3rd edition, and is skipped unless
the `NOT_CRAN` environment variable is `"true"`.

## Examples

``` r
# For the purpose of this example, save code containing code and tests to files
cat("add <- function(x, y) { x + y }", file="add.R")
cat("add(1, 2) == 3", file="add_test.R")

# Use file_coverage() to calculate test coverage
file_coverage(source_files = "add.R", test_files = "add_test.R")
#> Coverage: 100.00%
#> add.R: 100.00%

# cleanup
file.remove(c("add.R", "add_test.R"))
#> [1] TRUE TRUE
```
