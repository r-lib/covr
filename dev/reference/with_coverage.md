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

## Compiled code

[`environment_coverage()`](https://covr.r-lib.org/dev/reference/environment_coverage.md)
and `with_coverage()` include the compiled code in the coverage of the
namespace of a package loaded with
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
