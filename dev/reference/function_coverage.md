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

## Examples

``` r
add <- function(x, y) { x + y }
function_coverage(fun = add, code = NULL) # 0% coverage
function_coverage(fun = add, code = add(1, 2) == 3) # 100% coverage
```
