# Truncate call objects to limit the number of arguments

A helper to circumvent R errors when deserializing large call objects
from Rds. Trims the number of arguments in a call object, and replaces
the last argument with a `<truncated>` symbol.

## Usage

``` r
truncate_call(call_obj, limit = 10000)
```

## Arguments

- call_obj:

  A (possibly large) `call` object

- limit:

  A `call` length limit to impose

## Value

The `call_obj` with arguments trimmed
