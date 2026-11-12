# Convert a coverage dataset to a list

Convert a coverage dataset to a list

## Usage

``` r
coverage_to_list(x = package_coverage())
```

## Arguments

- x:

  a coverage dataset, defaults to running
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md).

## Value

A list with two components: `filecoverage`, a named numeric vector with
the percentage of lines covered in each file, and `totalcoverage`, the
percentage of lines covered in the whole package. Both are rounded to
two decimal places.
