# Print a coverage object

Print a coverage object

## Usage

``` r
# S3 method for class 'coverage'
print(x, group = c("filename", "functions"), by = "line", n = Inf, ...)
```

## Arguments

- x:

  the coverage object to be printed

- group:

  whether to group coverage by filename or function

- by:

  whether to count coverage by line, expression or function

- n:

  the maximum number of files or functions to print. They are sorted
  from least to most covered, so the least covered are shown first.

- ...:

  additional arguments ignored

## Value

The coverage object (invisibly).

## Examples

``` r
cov <- code_coverage(
  "f <- function(x) x + 1; g <- function(x) x - 1; h <- function(x) 0",
  "f(1)"
)
print(cov, group = "functions", n = 2)
#> Coverage: 33.33%
#> g: 0.00%
#> h: 0.00%
#> ... and 1 more function; use `print(x, n = Inf)` to show all
```
