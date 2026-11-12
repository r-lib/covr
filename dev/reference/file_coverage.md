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
  coverage. Can also include compiled files from a package's `src/`
  directory; see the compiled code section.

- test_files:

  Character vector of test files with code to test the functions

- line_exclusions:

  a named list of files with the lines to exclude from each file.

- function_exclusions:

  a vector of regular expressions matching function names to exclude.
  Example `print\\\.` to match print methods.

- parent_env:

  The parent environment to use when sourcing the files. If
  `source_files` includes compiled files, the default is the namespace
  of their package.

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
counts when they exit. To turn this off, set the option
`covr.fix_parallel_mcexit` or the environment variable
`COVR_FIX_PARALLEL_MCEXIT` to `FALSE`.

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

## Compiled code

[`environment_coverage()`](https://covr.r-lib.org/dev/reference/environment_coverage.md)
and
[`with_coverage()`](https://covr.r-lib.org/dev/reference/with_coverage.md)
include the compiled code in the coverage of the namespace of a package
loaded with
[`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html)
(e.g. by `devtools::load_all()`), so
`devtools::test_coverage_active_file()` also works for files in `src/`.
With compiled files in `source_files`, `file_coverage()` loads their
package with
[`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html)
and reports the coverage of those files, without needing devtools:

    file_coverage("src/foo.c", "tests/testthat/test-foo.R")
    file_coverage("src/rust/src/lib.rs", "tests/testthat/test-foo.R")

The compiled code is measured in the current session, which is much
faster than
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md):
C, C++, Fortran and Objective-C code with gcov, and Rust code (e.g. of
packages using extendr or savvy) with LLVM's source-based coverage,
which needs the llvm tools described in
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md).
An instrumented copy of the package is built in the session's temporary
directory, leaving the package's own build untouched, and later runs
only recompile the files that changed, with cargo's incremental build in
the copy's own `target` directory for Rust code. While the code runs,
the namespace's native routines use the instrumented DLL instead of the
package's own. Routines that were looked up some other way, e.g. stored
by `.onLoad()` or found by other packages with `R_GetCCallable()`, keep
using the package's DLL, so their code isn't counted. Set
`options(covr.gcov = "")` to leave out C, C++, Fortran and Objective-C
code, and `options(covr.llvm_cov = "")` to leave out Rust code.

## Examples

``` r
# Save code and tests to temporary files
source_file <- tempfile(fileext = ".R")
test_file <- tempfile(fileext = ".R")
cat("add <- function(x, y) { x + y }", file = source_file)
cat("add(1, 2) == 3", file = test_file)

# Use file_coverage() to calculate test coverage
file_coverage(source_files = source_file, test_files = test_file)
#> Coverage: 100.00%
#> /tmp/RtmpFF13RN/file185e20dd0689.R: 100.00%
```
