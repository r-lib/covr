# Tally which tests ran each line

Builds a traceability matrix from coverage recorded with
`options(covr.record_tests = TRUE)`: which tests ran each line of code.
Use it to find the tests to rerun after changing some lines, or the
tests exercising a function.

## Usage

``` r
tally_tests(x)
```

## Arguments

- x:

  a coverage object computed with `options(covr.record_tests = TRUE)`.

## Value

A `data.frame` with one row for each line and each test that ran it, and
the columns:

- `filename`, `functions`, `line`: the line of code, as in
  [`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md).

- `test_file`, `test_line`: where the test call is. For
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md),
  test files are relative to the package directory, e.g.
  `tests/testthat/test-foo.R`. `NA` if the test has no source
  references.

- `test`: the description of the enclosing
  [`test_that()`](https://testthat.r-lib.org/reference/test_that.html)
  or [`it()`](https://testthat.r-lib.org/reference/describe.html) call,
  or `NA`.

- `value`: the number of times the test ran the line.

## Details

Lines are those of
[`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md)
with `by = "line"`, so blank lines, comments, lines with only
punctuation and excluded lines are left out. A test is a top level call
in a test file that ran package code, such as an expectation; see
[covr.record_tests](https://covr.r-lib.org/dev/reference/covr.record_tests.md).

## Examples

``` r
cov <- withr::with_options(
  list(covr.record_tests = TRUE),
  code_coverage(
    "f <- function(x) {\n  if (x) 'yes' else 'no'\n}",
    "f(TRUE)\nf(FALSE)"
  )
)
tests <- tally_tests(cov)
tests
#>                              filename functions line           test_file
#> 1 /tmp/Rtmps7M0bS/source.R1919d99619d         f    2 ./test.R1919bee22e3
#> 2 /tmp/Rtmps7M0bS/source.R1919d99619d         f    2 ./test.R1919bee22e3
#>   test_line test value
#> 1         1 <NA>     1
#> 2         2 <NA>     1

# The tests that ran lines 1 to 2
unique(tests[tests$line %in% 1:2, c("test_file", "test_line")])
#>             test_file test_line
#> 1 ./test.R1919bee22e3         1
#> 2 ./test.R1919bee22e3         2
```
