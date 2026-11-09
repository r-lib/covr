# Calculate test coverage for a package

This function calculates the test coverage for a development package on
the `path`. By default it runs only the package tests, but it can also
run vignette and example code.

## Usage

``` r
package_coverage(
  path = ".",
  type = c("tests", "vignettes", "examples", "all", "none"),
  combine_types = TRUE,
  relative_path = TRUE,
  quiet = TRUE,
  clean = TRUE,
  line_exclusions = NULL,
  function_exclusions = NULL,
  code = character(),
  install_path = temp_file("R_LIBS"),
  ...,
  pre_clean,
  allow_failures = getOption("covr.allow_failures", FALSE),
  show_code_output = FALSE
)
```

## Arguments

- path:

  file path to the package, or to an installed package.

- type:

  run the package ‘tests’, ‘vignettes’, ‘examples’, ‘all’, or ‘none’.
  The default is ‘tests’.

- combine_types:

  If `TRUE` (the default) the coverage for all types is simply summed
  into one coverage object. If `FALSE` separate objects are used for
  each type of coverage.

- relative_path:

  whether to output the paths as relative or absolute paths. If a
  string, it is interpreted as a root path and all paths will be
  relative to that root.

- quiet:

  whether to load and compile the package quietly, useful for debugging
  errors.

- clean:

  whether to clean temporary output files after running, mainly useful
  for debugging errors. If coverage fails, or failures are reported as
  warnings with `allow_failures = TRUE`, `install_path` is kept even
  when `clean = TRUE`, so the test output can be inspected.

- line_exclusions:

  a named list of files with the lines to exclude from each file.

- function_exclusions:

  a vector of regular expressions matching function names to exclude.
  Example `print\\\.` to match print methods.

- code:

  A character vector of additional test code to run.

- install_path:

  The path the instrumented package will be installed to and tests run
  in. By default it is a path in the R sessions temporary directory. It
  can sometimes be useful to set this (along with `clean = FALSE`) to
  help debug test failures. It is not removed if coverage fails.

- ...:

  Additional arguments passed to
  [`tools::testInstalledPackage()`](https://rdrr.io/r/tools/testInstalledPackage.html).
  Use `outDir` to save the output of the tests and examples to a
  directory which is kept after coverage finishes; by default it is
  written to `install_path`.

- pre_clean:

  Deprecated and ignored. Objects present in the src directory are
  always deleted before recompiling.

- allow_failures:

  If `TRUE`, failures or errors when running tests, vignettes, examples
  or `code` are reported as warnings (with class `covr_warning`) and
  coverage is still returned. Coverage may be incomplete in this case,
  as code which would have run after the failure is not tracked. The
  default, `FALSE`, throws an error (with class `covr_error`) on the
  first failure. The default can be changed with the
  `covr.allow_failures` option, e.g.
  `options(covr.allow_failures = TRUE)`.

- show_code_output:

  If `TRUE`, the output of `code` is shown on the console while it runs,
  e.g. to follow it in the logs of a CI job. The default, `FALSE`, only
  saves it to a file in `install_path`, which is shown if `code` fails.

## Value

A [coverage](https://covr.r-lib.org/dev/reference/coverage.md) object.
If `combine_types = FALSE` and more than one `type` is run, a list of
class `coverages` with one coverage object for each type, named by type.

## Details

This function uses
[`tools::testInstalledPackage()`](https://rdrr.io/r/tools/testInstalledPackage.html)
to run the code, if you would like to test your package in another way
you can set `type = "none"` and pass the code to run as a character
vector to the `code` parameter.

Coverage is also recorded in other R processes that load the package,
such as callr sessions, future or parallel cluster workers, or Shiny
apps run by shinytest2. Each process saves its coverage when it exits
normally, so the coverage is lost if a process is killed (e.g. with
`SIGKILL` or `SIGTERM`) or is still running when the tests finish, and
`package_coverage()` warns (with class `covr_unsaved_trace`). Stop these
processes gracefully and wait for them to exit, e.g. call `$stop()` on a
shinytest2 `AppDriver`, which waits longer for the app to exit when run
by covr. See
[`vignette("shiny", package = "covr")`](https://covr.r-lib.org/dev/articles/shiny.md)
for measuring the coverage of Shiny apps.

`path` can also be an installed package, e.g.
`system.file(package = "pkg")`, to compute coverage without the package
source. The package must have been installed with its tests and source
references, e.g. with
`remotes::install_github("user/pkg", INSTALL_opts = c("--install-tests", "--with-keep.source"))`.
File names are those of the source it was installed from, and compiled
code isn't covered.

The coverage of Rust code, built by cargo into a static library that is
linked into the package, is measured with LLVM's source-based coverage.
This needs the llvm tools of the Rust toolchain
(`rustup component add llvm-tools`), or for Rust installed by a Linux
distribution, those of the LLVM version rustc uses (e.g.
`apt-get install llvm-18`); without them `package_coverage()` warns and
reports no coverage for the Rust code. covr instruments the crates of
the package's cargo workspace by having cargo run rustc through a
wrapper (with `RUSTC_WORKSPACE_WRAPPER`) that adds
`-C instrument-coverage`, so it works however the package sets
`RUSTFLAGS`, and dependencies are built as usual. Vendored crates,
including the C code they compile, and code generated in cargo's
`target` directory aren't included. The code that macros such as
`#[extendr]` and `#[savvy]` generate is counted on the macro's line, so
the line isn't covered if parts of the generated code never run, e.g.
the handling of arguments that can't be converted. The coverage of Rust
code isn't measured on Windows, as rustup's Rust for the
`x86_64-pc-windows-gnu` target that Rtools uses has no profiler runtime.

Parallelized code using parallel's `mcparallel()` needs to use a patched
`parallel:::mcexit`. This is done automatically if the package depends
on parallel, but can also be explicitly set using the environment
variable `COVR_FIX_PARALLEL_MCEXIT` or the global option
`covr.fix_parallel_mcexit`.

## See also

[`exclusions()`](https://covr.r-lib.org/dev/reference/exclusions.md) For
details on excluding parts of the package from the coverage
calculations.
