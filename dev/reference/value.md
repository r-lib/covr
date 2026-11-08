# Retrieve the execution counts from a coverage object

Retrieve the execution counts from a coverage object

## Usage

``` r
value(x, ...)
```

## Arguments

- x:

  a [coverage](https://covr.r-lib.org/dev/reference/coverage.md) object,
  or one of its elements.

- ...:

  additional arguments passed to methods.

## Value

For a coverage object, a named numeric vector with the number of times
each traced expression or line was executed, named like the elements of
`x` (see [coverage](https://covr.r-lib.org/dev/reference/coverage.md)).
For a single element, its count.

## Examples

``` r
cov <- code_coverage("add <- function(x, y) { x + y }", "add(1, 2)")
value(cov)
#> source.R19462233482e:1:25:1:29:25:29:1:1 
#>                                        1 
```
