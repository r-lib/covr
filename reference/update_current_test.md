# Update current test if unit test expression has progressed

Updating a test logs some metadata regarding the current call stack,
noteably trying to capture information about the call stack prior to the
covr::count call being traced.

## Usage

``` r
update_current_test()
```

## Details

There are a couple patterns of behavior, which try to accommodate a
variety of testing suites:

- `testthat`: During execution of `testthat`'s `test_*` functions, files
  are sourced and the working directory is temporarily changed to the
  package `/tests` directory. Knowing this, calls in the call stack
  which are relative to this directory are extracted and recorded.

- `RUnit`:

- `custom`: Any other custom test suites may not have source kept with
  their execution, in which case the entire test call stack is kept.

checks to see if the current call stack has the same `srcref` (or
expression, if no source is available) at the same frame prior to
entering into a package where `covr:::count` is called.
