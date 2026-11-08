# Calculate coverage of an environment

The functions in `env` are instrumented, then the files in `test_files`
are run with [`sys.source()`](https://rdrr.io/r/base/sys.source.html) in
a child environment of `env`, from the current working directory.
Nothing else is set up, so testthat tests that rely on its test runner,
e.g. for setup files, snapshots, or the test directory as the working
directory (which
[`testthat::test_path()`](https://testthat.r-lib.org/reference/test_path.html)
uses to find fixtures while testing), should instead be run with
[`testthat::test_file()`](https://testthat.r-lib.org/reference/test_file.html)
inside
[`with_coverage()`](https://covr.r-lib.org/dev/reference/with_coverage.md).

## Usage

``` r
environment_coverage(
  env = parent.frame(),
  test_files,
  line_exclusions = NULL,
  function_exclusions = NULL
)
```

## Arguments

- env:

  The environment to be instrumented.

- test_files:

  Character vector of test files with code to test the functions

- line_exclusions:

  a named list of files with the lines to exclude from each file.

- function_exclusions:

  a vector of regular expressions matching function names to exclude.
  Example `print\\\.` to match print methods.

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

## Compiled code

`environment_coverage()` and
[`with_coverage()`](https://covr.r-lib.org/dev/reference/with_coverage.md)
include the compiled code in the coverage of the namespace of a package
loaded with
[`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html)
(e.g. by `devtools::load_all()`), so
`devtools::test_coverage_active_file()` also works for files in `src/`.
With compiled files in `source_files`,
[`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md)
loads their package with
[`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html)
and reports the coverage of those files, without needing devtools:

    file_coverage("src/foo.c", "tests/testthat/test-foo.R")

The compiled code is measured with gcov in the current session, which is
much faster than
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md).
An instrumented copy of the package is built in the session's temporary
directory, leaving the package's own build untouched, and later runs
only recompile the files that changed. While the code runs, the
namespace's native routines use the instrumented DLL instead of the
package's own. Routines that were looked up some other way, e.g. stored
by `.onLoad()` or found by other packages with `R_GetCCallable()`, keep
using the package's DLL, so their code isn't counted. Set
`options(covr.gcov = "")` to leave out compiled code.

## See also

[`with_coverage()`](https://covr.r-lib.org/dev/reference/with_coverage.md)
