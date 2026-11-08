# Calculate test coverage for a Shiny app

Measures the coverage of the functions of a Shiny app that is not part
of a package, while `code` runs its tests, by default with
[`shinytest2::test_app()`](https://rstudio.github.io/shinytest2/reference/test_app.html).
This includes the code run by the app in the R processes that shinytest2
starts to run it. For apps in a package, use
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
instead.

## Usage

``` r
shiny_app_coverage(
  app_dir = ".",
  code = shinytest2::test_app(app_dir),
  line_exclusions = NULL,
  function_exclusions = NULL
)
```

## Arguments

- app_dir:

  The directory of the Shiny app.

- code:

  The code to run the app's tests, evaluated in the calling environment.

- line_exclusions:

  a named list of files with the lines to exclude from each file.

- function_exclusions:

  a vector of regular expressions matching function names to exclude.
  Example `print\\\.` to match print methods.

## Value

A [coverage](https://covr.r-lib.org/dev/reference/coverage.md) object.

## Details

The functions defined by the app's files (`app.R`, `ui.R`, `server.R`,
`global.R` and the files in `R/`) are instrumented when Shiny loads
them, in this R process and in the R processes started while `code`
runs. This includes a server function that isn't assigned to a name,
such as the one in `server.R` or one defined inline, e.g.
`shinyApp(ui, function(input, output) ...)`. Code outside functions,
such as building the UI, is not counted, as in
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md).

This works by adding covr to the default packages of R processes started
while `code` runs (the `R_DEFAULT_PACKAGES` environment variable), and
relies on internal hooks of Shiny which may change in future versions.

An app process saves its coverage when it exits normally, so stop it
gracefully, e.g. with `$stop()` on a shinytest2 `AppDriver`, which waits
longer for the app to exit when run by covr. If an app process is killed
or is still running when `code` finishes, its coverage is lost and
`shiny_app_coverage()` warns (with class `covr_unsaved_trace`).

`AppDriver$new()` skips tests on CRAN unless the `NOT_CRAN` environment
variable is `"true"`.

## See also

[`vignette("shiny", package = "covr")`](https://covr.r-lib.org/dev/articles/shiny.md)

## Examples

``` r
if (FALSE) { # \dontrun{
Sys.setenv(NOT_CRAN = "true")
shiny_app_coverage("path/to/app")
} # }
```
