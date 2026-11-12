# Calculate test coverage for a specific function.

Calculate test coverage for a specific function.

## Usage

``` r
function_coverage(fun, code = NULL, env = NULL, enc = parent.frame())
```

## Arguments

- fun:

  name of the function.

- code:

  expressions to run.

- env:

  environment the function is defined in.

- enc:

  the enclosing environment which to run the expressions.

## Value

A [coverage](https://covr.r-lib.org/dev/reference/coverage.md) object.

## Parallel code

Code run in processes forked by
[`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html),
[`parallel::mcparallel()`](https://rdrr.io/r/parallel/mcparallel.html)
and related functions (not available on Windows) is included in the
coverage. While the code runs, `parallel:::mcfork` and
`parallel:::mcexit` are patched so that the forked processes save their
counts when they exit. To turn this off, set the option
`covr.fix_parallel_mcexit` or the environment variable
`COVR_FIX_PARALLEL_MCEXIT` to `FALSE`.

## Examples

``` r
add <- function(x, y) { x + y }
function_coverage(fun = add, code = NULL) # 0% coverage
function_coverage(fun = add, code = add(1, 2) == 3) # 100% coverage
```
