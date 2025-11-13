# trace each call with a srcref attribute

This function calls itself recursively so it can properly traverse the
AST.

## Usage

``` r
trace_calls(x, parent_functions = NULL, parent_ref = NULL)
```

## Arguments

- x:

  the call

- parent_functions:

  the functions which this call is a child of.

- parent_ref:

  argument used to set the srcref of the current call during the
  recursion.

## Value

a modified expression with count calls inserted before each previous
call.

## See also

[http://adv-r.had.co.nz/Expressions.html](http://adv-r.had.co.nz/Expressions.md)
