# Exclusions

covr supports a couple of different ways of excluding some or all of a
file.

## Line Exclusions

The `line_exclusions` argument to
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
can be used to exclude some or all of a file. This argument takes a list
of filenames or named ranges to exclude.

## Function Exclusions

Alternatively `function_exclusions` can be used to exclude R functions
based on regular expression(s). For example `print\\\.*` can be used to
exclude all the print methods defined in a package from coverage.

## Exclusion Comments

In addition you can exclude lines from the coverage by putting special
comments in your source code. This can be done per line or by specifying
a range. The patterns used can be specified by the `exclude_pattern`,
`exclude_start`, `exclude_end` arguments to
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
or by setting the global options `covr.exclude_pattern`,
`covr.exclude_start`, `covr.exclude_end`.

## Examples

``` r
if (FALSE) { # \dontrun{
# exclude whole file of R/test.R
package_coverage(exclusions = "R/test.R")

# exclude lines 1 to 10 and 15 from R/test.R
package_coverage(line_exclusions = list("R/test.R" = c(1:10, 15)))

# exclude lines 1 to 10 from R/test.R, all of R/test2.R
package_coverage(line_exclusions = list("R/test.R" = 1:10, "R/test2.R"))

# exclude all print and format methods from the package.
package_coverage(function_exclusions = c("print\\.", "format\\."))

# single line exclusions
f1 <- function(x) {
  x + 1 # nocov
}

# ranged exclusions
f2 <- function(x) { # nocov start
  x + 2
} # nocov end
} # }
```
