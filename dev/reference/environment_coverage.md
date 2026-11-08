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

## See also

[`with_coverage()`](https://covr.r-lib.org/dev/reference/with_coverage.md)
