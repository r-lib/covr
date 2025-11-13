# Record Test Traces During Coverage Execution

By setting `options(covr.record_tests = TRUE)`, the result of covr
coverage collection functions will include additional data pertaining to
the tests which are executed and an index of which tests, at what stack
depth, trigger the execution of each trace.

## Details

This functionality requires that the package code and tests are
installed and sourced with the source. For more details, refer to R
options, `keep.source`, `keep.source.pkgs` and `keep.parse.data.pkgs`.

## Additional fields

Within the `covr` result, you can explore this information in two
places:

- `attr(,"tests")`: A list of call stacks, which results in target code
  execution.

- `$<srcref>$tests`: For each srcref count in the coverage object, a
  `$tests` field is now included which contains a matrix with three
  columns, "test", "call", "depth" and "i" which specify the test number
  (corresponding to the index of the test in `attr(,"tests")`, the
  number of times the test expression was evaluated to produce the trace
  hit, the stack depth into the target code where the trace was
  executed, and the order of execution for each test.

## Test traces

The content of test traces are dependent on the unit testing framework
that is used by the target package. The behavior is contingent on the
available information in the sources kept for the testing files.

Test traces are extracted by the following criteria:

1.  If any `srcref` files are are provided by a file within
    [covr](https://covr.r-lib.org/dev/reference/covr-package.md)'s
    temporary library, all calls from those files are kept as a test
    trace. This will collect traces from tests run with common testing
    frameworks such as `testthat` and `RUnit`.

2.  Otherwise, as a conservative fallback in situations where no source
    references are found, or when none are from within the temporary
    directory, the entire call stack is collected.

These calls are subsequently subset for only those up until the call to
[covr](https://covr.r-lib.org/dev/reference/covr-package.md)'s internal
`count` function, and will always include the last call in the call
stack prior to a call to `count`.

## Examples

``` r
fcode <- '
f <- function(x) {
  if (x)
    f(!x)
  else
    FALSE
}'

options(covr.record_tests = TRUE)
cov <- code_coverage(fcode, "f(TRUE)")

# extract executed test code for the first test
tail(attr(cov, "tests")[[1L]], 1L)
#> [[1]]
#> f(TRUE)
#> 
# [[1]]
# f(TRUE)

# extract test itemization per trace
cov[[3]][c("srcref", "tests")]
#> $srcref
#> FALSE
#> 
#> $tests
#>      test call depth i
#> [1,]    1    1     2 4
#> 
# $srcref
# f(!x)
#
# $tests
#      test call depth i
# [1,]    1    1     2 4

# reconstruct the code path of a test by ordering test traces by [,"i"]
lapply(cov, `[[`, "tests")
#> $`source.R1ca835bcd2a7:3:7:3:7:7:7:3:3`
#>      test call depth i
#> [1,]    1    1     1 1
#> [2,]    1    1     2 3
#> 
#> $`source.R1ca835bcd2a7:4:5:4:9:5:9:4:4`
#>      test call depth i
#> [1,]    1    1     1 2
#> 
#> $`source.R1ca835bcd2a7:6:5:6:9:5:9:6:6`
#>      test call depth i
#> [1,]    1    1     2 4
#> 
# $`source.Ref2326138c55:4:6:4:10:6:10:4:4`
#      test call depth i
# [1,]    1    1     1 2
#
# $`source.Ref2326138c55:3:8:3:8:8:8:3:3`
#      test call depth i
# [1,]    1    1     1 1
# [2,]    1    1     2 3
#
# $`source.Ref2326138c55:6:6:6:10:6:10:6:6`
#      test call depth i
# [1,]    1    1     2 4
```
