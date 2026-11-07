# Build key for the current test

If the current test has a srcref, a unique character key is built from
its srcref. Otherwise, an empty string is returned.

## Usage

``` r
current_test_key()
```

## Value

A unique character string if the test call has a srcref, or an empty
string otherwise.
