# Returns TRUE if we've moved on from test reflected in .current_test

Quickly dismiss the need to update the current test if we can. To test
if we're still in the last test, check if the same srcref (or call, if
source is not kept) exists at the last recorded calling frame prior to
entering a covr trace. If this has changed, do a more comprehensive test
to see if any of the test call stack has changed, in which case we are
onto a new test.

## Usage

``` r
is_current_test_finished()
```
