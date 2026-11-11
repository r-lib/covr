# coverage of a file whose name starts with `tests` is not read as recorded tests

    Code
      tally_tests(cov)
    Condition
      Error:
      ! `x` has no recorded tests.
      i Compute coverage with `options(covr.record_tests = TRUE)`.

