# Retrieve the index for the test in `.counters$tests`

If the test was encountered before, the index will be the index of the
test in the logged tests list. Otherwise, the index will be the next
index beyond the length of the tests list.

## Usage

``` r
current_test_index()
```

## Value

An integer index for the test call
