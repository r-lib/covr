# The source file of each trace

`display_name()` returns the path of the source file of each trace of a
coverage object, relative to the package root, e.g. to keep the coverage
of some files with `x[display_name(x) %in% files]`.

## Usage

``` r
display_name(x)
```

## Arguments

- x:

  A [coverage](https://covr.r-lib.org/dev/reference/coverage.md) object.

## Value

A character vector with one path for each trace of `x`, or `NULL` if `x`
has no traces.

## Examples

``` r
cov <- code_coverage("f <- function(x) x + 1", "f(1)")
display_name(cov)
#> source.R19217c493bff:1:6:1:22:6:22:1:1 
#> "/tmp/RtmpKQz88e/source.R19217c493bff" 
```
