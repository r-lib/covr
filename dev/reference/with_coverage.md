# Calculate coverage of arbitrary code run against an environment

`with_coverage()` instruments the functions in `env`, evaluates `code`,
and returns the coverage that `code` produced. Unlike
[`environment_coverage()`](https://covr.r-lib.org/dev/reference/environment_coverage.md),
which [`sys.source()`](https://rdrr.io/r/base/sys.source.html)s a set of
files, `code` can be any expression. This makes it possible to measure
coverage while running tests with a test runner such as
[`testthat::test_file()`](https://testthat.r-lib.org/reference/test_file.html),
without having to recreate the runner's infrastructure (reporters,
snapshot handling, test environment, ...).

## Usage

``` r
with_coverage(
  code,
  env = parent.frame(),
  line_exclusions = NULL,
  function_exclusions = NULL
)
```

## Arguments

- code:

  The code to evaluate while measuring coverage. It is evaluated lazily,
  in the calling environment, after `env` has been instrumented.

- env:

  The environment to be instrumented, e.g. a package namespace.

- line_exclusions:

  a named list of files with the lines to exclude from each file.

- function_exclusions:

  a vector of regular expressions matching function names to exclude.
  Example `print\\\.` to match print methods.

## Value

A `coverage` object.

## Details

Functions are instrumented in place, so every existing reference to
them, including ones captured by an environment created by `code` (e.g.
the child environment of the namespace that
[`testthat::test_file()`](https://testthat.r-lib.org/reference/test_file.html)
evaluates tests in), runs the instrumented version. The only requirement
is that `code` must not re-create the functions in `env`, e.g. when
using
[`testthat::test_file()`](https://testthat.r-lib.org/reference/test_file.html)
with `package` set the package must not be reloaded (use
`load_package = "none"`), as reloading would replace the instrumented
functions with fresh, uninstrumented ones.

The instrumentation is removed and the counters are cleared when
`with_coverage()` exits, even if `code` fails.

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

[`environment_coverage()`](https://covr.r-lib.org/dev/reference/environment_coverage.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# With a package loaded by pkgload::load_all()
ns <- asNamespace("mypkg")
with_coverage(
  testthat::test_file(
    "tests/testthat/test-foo.R",
    package = "mypkg",
    load_package = "none"
  ),
  env = ns
)
} # }
```
