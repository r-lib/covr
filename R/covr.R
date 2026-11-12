#' covr: Test coverage for packages
#'
#' covr tracks and reports code coverage for your package and (optionally)
#' upload the results to a coverage service like 'Codecov' <https://about.codecov.io> or
#' 'Coveralls' <https://coveralls.io>. Code coverage is a measure of the amount of
#' code being exercised by a set of tests. It is an indirect measure of test
#' quality and completeness. This package is compatible with any testing
#' methodology or framework and tracks coverage of both R code and compiled
#' C, C++, Fortran and Rust code.
#'
#' A coverage report can be used to inspect coverage for each line in your
#' package. Using `report()` requires the additional dependency `htmltools`.
#'
#' ```r
#' # If run with no arguments `report()` implicitly calls `package_coverage()`
#' report()
#' ```
#'
#' @section Package options:
#'
#' `covr` uses the following [options()] to configure behaviour:
#'
#' \itemize{
#'   \item `covr.branch_coverage`: If `TRUE` (default `FALSE`), also record
#'     which branches of each `if` and `switch()` in R code were taken. This
#'     is experimental. It must be set before the code is instrumented, e.g.
#'     before calling `package_coverage()`. For more details, see
#'     `?covr.branch_coverage`.
#'
#'   \item `covr.covrignore`: A filename to use as an ignore file,
#'     listing glob-style wildcarded paths of files to ignore for coverage
#'     calculations. Defaults to the value of the environment variable
#'     `COVR_COVRIGNORE`, or `".covrignore"` if neither the option nor the
#'     environment variable is set.
#'
#'   \item `covr.exclude_end`: Used along with `covr.exclude_start`, an optional
#'     regular expression which ends a line-exclusion region. For more
#'     details, see `?exclusions`.
#'
#'   \item `covr.exclude_pattern`: An optional line-exclusion pattern. Lines
#'     which match the pattern will be excluded from coverage. For more details,
#'     see `?exclusions`.
#'
#'   \item `covr.exclude_start`: Used along with `covr.exclude_end`, an optional
#'     regular expression which starts a line-exclusion region. For more
#'     details, see `?exclusions`.
#'
#'   \item `covr.filter_non_package`: If `TRUE` (the default behavior), coverage
#'     of files outside the target package are filtered from coverage output.
#'
#'   \item `covr.failure_lines`: The number of trailing lines of test output
#'     shown in the message and `print()` method of a `covr_error` when tests,
#'     vignettes, examples or `code` fail (default `50`). The full output is
#'     always available in the condition's `$output` field.
#'
#'   \item `covr.allow_failures`: If `TRUE` (default `FALSE`), failures or
#'     errors when running the tests, vignettes, examples or `code` of
#'     `package_coverage()` are reported as warnings and coverage is still
#'     returned, the default of its `allow_failures` argument.
#'
#'   \item `covr.annotate_max_lines`: The maximum number of source lines shown
#'     by [annotate_coverage()] (default `200`), the default of its `max_lines`
#'     argument. `Inf` shows everything.
#'
#'   \item `covr.print_max_ranges`: The maximum number of missed ranges, and of
#'     missed branches, listed per file or function by `print(x, missing =
#'     TRUE)` (default `10`). More are summarised as `... (<k> more)`. `Inf`
#'     lists them all.
#'
#'   \item `covr.fix_parallel_mcexit`: Whether to include code run in processes
#'     forked by \pkg{parallel}'s `mclapply()`, `mcparallel()` and related
#'     functions, by patching `parallel:::mcexit`. By default
#'     `package_coverage()` does this if the package uses \pkg{parallel}, and
#'     the functions that measure coverage in the current session, such as
#'     `file_coverage()`, always do. Can also be set with the environment
#'     variable `COVR_FIX_PARALLEL_MCEXIT`. Not supported on Windows.
#'
#'   \item `covr.flags`: A named character vector of the compiler and linker
#'     settings (the values of a `Makevars` file, e.g. `CFLAGS`) that are added
#'     when `package_coverage()` installs a package, or `file_coverage()`
#'     builds one, for coverage of compiled code. The default, set when covr
#'     is loaded, compiles C, C++ and Fortran code without optimization and
#'     with `--coverage` (`"-O0 --coverage"`) and links it to gcov (`FLIBS` is
#'     `"-lgcov"`, `LDFLAGS` or on Windows `SHLIB_LIBADD` is `"--coverage"`).
#'
#'   \item `covr.gcov`: Path to the gcov executable. Defaults to the gcov found
#'     on your `PATH`, or `NA` if there is none. If the appropriate gcov version
#'     is not on your path you can use this option to set the appropriate
#'     location. If set to `""` it will turn off coverage of C, C++ and Fortran
#'     code, but not of Rust code, which is controlled by `covr.llvm_cov`. If
#'     `NA`, covr throws an error if any compiled coverage files (`.gcno`)
#'     exist.
#'
#'   \item `covr.gcov_additional_paths`: A character vector of directories,
#'     in addition to the package itself, whose compiled source files (C, C++,
#'     Fortran or Rust) are accepted in the coverage, e.g. the code of another
#'     package or library that is compiled into the package from outside of its
#'     `src/` directory. Files elsewhere are left out. Default `NULL`.
#'
#'   \item `covr.gcov_args`: A character vector of additional command line
#'     arguments passed to gcov. Default `NULL`.
#'
#'   \item `covr.gcov_partial`: How to count compiled code lines that gcov
#'     reports as only partially executed (e.g. `if (x) f();` when `f()` never
#'     runs). `"covered"` (the default) counts them as covered, `"uncovered"`
#'     counts them as not covered, for requiring every part of a line to run.
#'     This works with both gcc's gcov and llvm-cov (the gcov on macOS).
#'     llvm-cov can't tell apart code that only runs when a C++ exception is
#'     thrown, so lines that create objects with destructors may also count as
#'     partially executed.
#'
#'   \item `covr.llvm_cov`: Path to the `llvm-cov` used to read the coverage
#'     of Rust code. Defaults to the one of the Rust toolchain, installed with
#'     `rustup component add llvm-tools`, or for Rust installed without rustup
#'     (e.g. with `apt-get install cargo rustc`), to the one on the `PATH` with
#'     the same LLVM version as rustc, e.g. `llvm-cov-18`. If set to `""` the
#'     Rust code isn't instrumented, which turns off its coverage. This is
#'     independent of `covr.gcov`, which only controls C, C++ and Fortran code.
#'
#'   \item `covr.llvm_profdata`: Path to the `llvm-profdata` used to merge the
#'     coverage counts of Rust code. Found like `covr.llvm_cov`.
#'
#'   \item `covr.report_colors`: A named character vector with the colors of
#'     covered and missed lines in [report()] and [file_report()], and of the
#'     coverage percentages printed in the console, e.g.
#'     `c(covered = "#0072B2", missed = "#D55E00")`. [colorblind_palette] has
#'     colors that are easier to tell apart than the default green and red
#'     with color vision deficiency. Either element can be left out to keep
#'     its default.
#'     An optional `partial` element sets the color of partial coverage (at
#'     least 75% but less than 90%), which otherwise follows `covered`, or is
#'     yellow in the console if `covered` isn't set either, and of lines with
#'     a branch that wasn't taken in reports with branch coverage, which are
#'     otherwise yellow. Transparency is ignored. In terminals with only 8
#'     colors, the console uses the closest of those colors.
#'
#'   \item `covr.rstudio_source_markers`: A logical value. If `TRUE` (the
#'     default behavior), source markers are displayed within the RStudio IDE
#'     when using `zero_coverage`.
#'
#'   \item `covr.record_tests`: If `TRUE` (default `FALSE`), record a listing
#'     of top level test expressions and associate tests with `covr` traces
#'     evaluated during the test's execution. For more details, see
#'     `?covr.record_tests`.
#'
#'   \item `covr.full_traversal`: If `TRUE` (default `FALSE`), also trace
#'     functions nested inside lists and environments, such as
#'     `fns <- list(a = function(x) x)` or functions defined inside `local()`.
#'     This walks every object in the package, so it is off by default. For
#'     `package_coverage()` it can also be enabled for a package by adding
#'     `Config/covr/full_traversal: true` to its DESCRIPTION; the option takes
#'     precedence when set.
#'
#'   \item `covr.install_instrument`: If `FALSE` (default `TRUE`),
#'     `package_coverage()` installs a package as usual and instruments it each
#'     time a process loads it, rather than once after installing it. Can also
#'     be set with the environment variable `COVR_INSTALL_INSTRUMENT`.
#' }
#'
#' Some options can also be set with an environment variable. They are read in
#' this order: the option, then the environment variable (ignored if it is
#' empty), then the default. So an option set in R always takes precedence over
#' the environment variable, e.g. `COVR_FIX_PARALLEL_MCEXIT=false` has no
#' effect if `options(covr.fix_parallel_mcexit = TRUE)` is set. Logical
#' settings are `TRUE` or `FALSE`, or for the environment variable (and
#' options set to a string), one of `true`, `t`, `yes` or `1`, and `false`,
#' `f`, `no` or `0`, in any case. Other values are ignored with a warning.
#'
#' @import methods
#' @importFrom stats aggregate ave na.omit na.pass setNames
#' @importFrom utils capture.output getParseData getSrcDirectory
#' @importFrom utils getSrcFilename getSrcref head relist str tail
#' @useDynLib covr, .registration = TRUE
"_PACKAGE"

#' Determine if code is being run in covr
#'
#' covr functions set the environment variable `R_COVR` to `"true"` while they
#' are running. `in_covr()` returns `TRUE` if the environment variable is
#' exactly `"true"` and `FALSE` otherwise, e.g. to skip tests that don't work
#' while measuring coverage.
#' @returns A single `TRUE` or `FALSE`.
#' @export
#' @examplesIf requireNamespace("testthat", quietly = TRUE)
#' testthat::skip_if(in_covr())
in_covr <- function() {
  identical(Sys.getenv("R_COVR"), "true")
}
