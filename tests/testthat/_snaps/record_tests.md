# tally_tests() errors without recorded tests

    Code
      tally_tests(cov_tests_not_recorded)
    Condition
      Error:
      ! `x` has no recorded tests.
      i Compute coverage with `options(covr.record_tests = TRUE)`.

