# Retrieve the number of times the test call was called

A single test expression might be evaluated many times. Each time the
same expression is called, the call count is incremented.

## Usage

``` r
current_test_call_count()
```

## Value

An integer value representing the number of calls of the current call
into the package from the testing suite.
