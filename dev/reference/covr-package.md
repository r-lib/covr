# covr: Test coverage for packages

covr tracks and reports code coverage for your package and (optionally)
upload the results to a coverage service like 'Codecov'
<https://about.codecov.io> or 'Coveralls' <https://coveralls.io>. Code
coverage is a measure of the amount of code being exercised by a set of
tests. It is an indirect measure of test quality and completeness. This
package is compatible with any testing methodology or framework and
tracks coverage of both R code and compiled C, C++, Fortran and Rust
code.

## Details

A coverage report can be used to inspect coverage for each line in your
package. Using
[`report()`](https://covr.r-lib.org/dev/reference/report.md) requires
the additional dependency `htmltools`.

    # If run with no arguments `report()` implicitly calls `package_coverage()`
    report()

## Package options

`covr` uses the following
[`options()`](https://rdrr.io/r/base/options.html) to configure
behaviour:

- `covr.branch_coverage`: If `TRUE` (default `FALSE`), also record which
  branches of each `if` and
  [`switch()`](https://rdrr.io/r/base/switch.html) in R code were taken.
  This is experimental. It must be set before the code is instrumented,
  e.g. before calling
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md).
  For more details, see
  [`?covr.branch_coverage`](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md).

- `covr.covrignore`: A filename to use as an ignore file, listing
  glob-style wildcarded paths of files to ignore for coverage
  calculations. Defaults to the value of the environment variable
  `COVR_COVRIGNORE`, or `".covrignore"` if neither the option nor the
  environment variable is set.

- `covr.exclude_end`: Used along with `covr.exclude_start`, an optional
  regular expression which ends a line-exclusion region. For more
  details, see
  [`?exclusions`](https://covr.r-lib.org/dev/reference/exclusions.md).

- `covr.exclude_pattern`: An optional line-exclusion pattern. Lines
  which match the pattern will be excluded from coverage. For more
  details, see
  [`?exclusions`](https://covr.r-lib.org/dev/reference/exclusions.md).

- `covr.exclude_start`: Used along with `covr.exclude_end`, an optional
  regular expression which starts a line-exclusion region. For more
  details, see
  [`?exclusions`](https://covr.r-lib.org/dev/reference/exclusions.md).

- `covr.filter_non_package`: If `TRUE` (the default behavior), coverage
  of files outside the target package are filtered from coverage output.

- `covr.failure_lines`: The number of trailing lines of test output
  shown in the message and
  [`print()`](https://rdrr.io/r/base/print.html) method of a
  `covr_error` when tests, vignettes, examples or `code` fail (default
  `50`). The full output is always available in the condition's
  `$output` field.

- `covr.allow_failures`: If `TRUE` (default `FALSE`), failures or errors
  when running the tests, vignettes, examples or `code` of
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  are reported as warnings and coverage is still returned, the default
  of its `allow_failures` argument.

- `covr.annotate_max_lines`: The maximum number of source lines shown by
  [`annotate_coverage()`](https://covr.r-lib.org/dev/reference/annotate_coverage.md)
  (default `200`), the default of its `max_lines` argument. `Inf` shows
  everything.

- `covr.print_max_ranges`: The maximum number of missed ranges, and of
  missed branches, listed per file or function by
  `print(x, missing = TRUE)` (default `10`). More are summarised as
  `... (<k> more)`. `Inf` lists them all.

- `covr.fix_parallel_mcexit`: Whether to include code run in processes
  forked by parallel's `mclapply()`, `mcparallel()` and related
  functions, by patching `parallel:::mcexit`. By default
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  does this if the package uses parallel, and the functions that measure
  coverage in the current session, such as
  [`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md),
  always do. Can also be set with the environment variable
  `COVR_FIX_PARALLEL_MCEXIT`. Not supported on Windows.

- `covr.flags`: A named character vector of the compiler and linker
  settings (the values of a `Makevars` file, e.g. `CFLAGS`) that are
  added when
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  installs a package, or
  [`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md)
  builds one, for coverage of compiled code. The default, set when covr
  is loaded, compiles C, C++ and Fortran code without optimization and
  with `--coverage` (`"-O0 --coverage"`) and links it to gcov (`FLIBS`
  is `"-lgcov"`, `LDFLAGS` or on Windows `SHLIB_LIBADD` is
  `"--coverage"`).

- `covr.gcov`: Path to the gcov executable. Defaults to the gcov found
  on your `PATH`, or `NA` if there is none. If the appropriate gcov
  version is not on your path you can use this option to set the
  appropriate location. If set to `""` it will turn off coverage of C,
  C++ and Fortran code, but not of Rust code, which is controlled by
  `covr.llvm_cov`. If `NA`, covr throws an error if any compiled
  coverage files (`.gcno`) exist.

- `covr.gcov_additional_paths`: A character vector of directories, in
  addition to the package itself, whose compiled source files (C, C++,
  Fortran or Rust) are accepted in the coverage, e.g. the code of
  another package or library that is compiled into the package from
  outside of its `src/` directory. Files elsewhere are left out. Default
  `NULL`.

- `covr.gcov_args`: A character vector of additional command line
  arguments passed to gcov. Default `NULL`.

- `covr.gcov_partial`: How to count compiled code lines that gcov
  reports as only partially executed (e.g. `if (x) f();` when `f()`
  never runs). `"covered"` (the default) counts them as covered,
  `"uncovered"` counts them as not covered, for requiring every part of
  a line to run. This works with both gcc's gcov and llvm-cov (the gcov
  on macOS). llvm-cov can't tell apart code that only runs when a C++
  exception is thrown, so lines that create objects with destructors may
  also count as partially executed.

- `covr.llvm_cov`: Path to the `llvm-cov` used to read the coverage of
  Rust code. Defaults to the one of the Rust toolchain, installed with
  `rustup component add llvm-tools`, or for Rust installed without
  rustup (e.g. with `apt-get install cargo rustc`), to the one on the
  `PATH` with the same LLVM version as rustc, e.g. `llvm-cov-18`. If set
  to `""` the Rust code isn't instrumented, which turns off its
  coverage. This is independent of `covr.gcov`, which only controls C,
  C++ and Fortran code.

- `covr.llvm_profdata`: Path to the `llvm-profdata` used to merge the
  coverage counts of Rust code. Found like `covr.llvm_cov`.

- `covr.report_colors`: A named character vector with the colors of
  covered and missed lines in
  [`report()`](https://covr.r-lib.org/dev/reference/report.md) and
  [`file_report()`](https://covr.r-lib.org/dev/reference/file_report.md),
  and of the coverage percentages printed in the console, e.g.
  `c(covered = "#0072B2", missed = "#D55E00")`.
  [colorblind_palette](https://covr.r-lib.org/dev/reference/colorblind_palette.md)
  has colors that are easier to tell apart than the default green and
  red with color vision deficiency. Either element can be left out to
  keep its default. An optional `partial` element sets the color of
  partial coverage (at least 75% but less than 90%), which otherwise
  follows `covered`, or is yellow in the console if `covered` isn't set
  either, and of lines with a branch that wasn't taken in reports with
  branch coverage, which are otherwise yellow. Transparency is ignored.
  In terminals with only 8 colors, the console uses the closest of those
  colors.

- `covr.rstudio_source_markers`: A logical value. If `TRUE` (the default
  behavior), source markers are displayed within the RStudio IDE when
  using `zero_coverage`.

- `covr.record_tests`: If `TRUE` (default `FALSE`), record a listing of
  top level test expressions and associate tests with `covr` traces
  evaluated during the test's execution. For more details, see
  [`?covr.record_tests`](https://covr.r-lib.org/dev/reference/covr.record_tests.md).

- `covr.full_traversal`: If `TRUE` (default `FALSE`), also trace
  functions nested inside lists and environments, such as
  `fns <- list(a = function(x) x)` or functions defined inside
  [`local()`](https://rdrr.io/r/base/eval.html). This walks every object
  in the package, so it is off by default. For
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  it can also be enabled for a package by adding
  `Config/covr/full_traversal: true` to its DESCRIPTION; the option
  takes precedence when set.

- `covr.install_instrument`: If `FALSE` (default `TRUE`),
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  installs a package as usual and instruments it each time a process
  loads it, rather than once after installing it. Can also be set with
  the environment variable `COVR_INSTALL_INSTRUMENT`.

Some options can also be set with an environment variable. They are read
in this order: the option, then the environment variable (ignored if it
is empty), then the default. So an option set in R always takes
precedence over the environment variable, e.g.
`COVR_FIX_PARALLEL_MCEXIT=false` has no effect if
`options(covr.fix_parallel_mcexit = TRUE)` is set. Logical settings are
`TRUE` or `FALSE`, or for the environment variable (and options set to a
string), one of `true`, `t`, `yes` or `1`, and `false`, `f`, `no` or
`0`, in any case. Other values are ignored with a warning.

## See also

Useful links:

- <https://covr.r-lib.org>

- <https://github.com/r-lib/covr>

- Report bugs at <https://github.com/r-lib/covr/issues>

## Author

**Maintainer**: Jim Hester <james.f.hester@gmail.com>

Authors:

- Jim Hester <james.f.hester@gmail.com>

Other contributors:

- Willem Ligtenberg \[contributor\]

- Kirill Müller \[contributor\]

- Henrik Bengtsson \[contributor\]

- Steve Peak \[contributor\]

- Kirill Sevastyanenko \[contributor\]

- Jon Clayden \[contributor\]

- Robert Flight \[contributor\]

- Eric Brown \[contributor\]

- Brodie Gaslam \[contributor\]

- Will Beasley \[contributor\]

- Robert Krzyzanowski \[contributor\]

- Markus Wamser \[contributor\]

- Karl Forner \[contributor\]

- Gergely Daróczi \[contributor\]

- Jouni Helske \[contributor\]

- Kun Ren \[contributor\]

- Jeroen Ooms \[contributor\]

- Ken Williams \[contributor\]

- Chris Campbell \[contributor\]

- David Hugh-Jones \[contributor\]

- Qin Wang \[contributor\]

- Doug Kelkhoff \[contributor\]

- Ivan Sagalaev (highlight.js library) \[contributor, copyright holder\]
