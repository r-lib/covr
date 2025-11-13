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
  exclusions,
  pre_clean = TRUE
)
```

## Arguments

- path:

  file path to the package.

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
  for debugging errors.

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
  help debug test failures.

- ...:

  Additional arguments passed to
  [`tools::testInstalledPackage()`](https://rdrr.io/r/tools/testInstalledPackage.html).

- exclusions:

  ‘Deprecated’, please use ‘line_exclusions’ instead.

- pre_clean:

  whether to delete all objects present in the src directory before
  recompiling

## Details

This function uses
[`tools::testInstalledPackage()`](https://rdrr.io/r/tools/testInstalledPackage.html)
to run the code, if you would like to test your package in another way
you can set `type = "none"` and pass the code to run as a character
vector to the `code` parameter.

Parallelized code using parallel's `mcparallel()` needs to use a patched
`parallel:::mcexit`. This is done automatically if the package depends
on parallel, but can also be explicitly set using the environment
variable `COVR_FIX_PARALLEL_MCEXIT` or the global option
`covr.fix_parallel_mcexit`.

## See also

[`exclusions()`](https://covr.r-lib.org/dev/reference/exclusions.md) For
details on excluding parts of the package from the coverage
calculations.
