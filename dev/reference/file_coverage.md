# Calculate test coverage for sets of files

The files in `source_files` are first sourced into a new environment to
define functions to be checked. Then they are instrumented to track
coverage and the files in `test_files` are run with `runner`.

## Usage

``` r
file_coverage(
  source_files,
  test_files,
  line_exclusions = NULL,
  function_exclusions = NULL,
  parent_env = parent.frame(),
  runner = source_test_file
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

- runner:

  A function used to run each test file, called as
  `runner(file, env = env)`, where `env` is the environment the
  `source_files` were sourced into. The default sources the file into
  `env` with [`sys.source()`](https://rdrr.io/r/base/sys.source.html).
  Use `runner = testthat::test_file` to run testthat tests with
  testthat's test runner; see the testthat tests section.

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

By default the test files are run with
[`sys.source()`](https://rdrr.io/r/base/sys.source.html), not with
testthat's test runner, so features that need the runner don't work. In
particular,
[`testthat::expect_snapshot()`](https://testthat.r-lib.org/reference/expect_snapshot.html)
is skipped ("Can't compare snapshot to reference when testing
interactively").

To use these features, run the test files with
[`testthat::test_file()`](https://testthat.r-lib.org/reference/test_file.html):

    file_coverage(
      "R/my_functions.R",
      "tests/test-my_functions.R",
      runner = testthat::test_file
    )

The tests then run in a child of the environment the source files were
sourced into, and snapshots are saved in a `_snaps` directory next to
the test file. `expect_snapshot()` also needs testthat's 3rd edition
(e.g. `testthat::local_edition(3)` in the tests), and is skipped unless
the `NOT_CRAN` environment variable is `"true"`.

For more control, source the files yourself and use
[`with_coverage()`](https://covr.r-lib.org/dev/reference/with_coverage.md).

## Files from a package

To make the package's other functions available, load the package (e.g.
with
[`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html))
and use `parent_env = asNamespace("pkg")`. Calls from other package
files use the namespace's untraced functions, so don't count.
`devtools::test_coverage_active_file()` measures the coverage of one
file of a package without this limitation.

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
