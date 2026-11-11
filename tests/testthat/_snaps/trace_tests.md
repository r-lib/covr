# tally_tests() errors without recorded tests

    Code
      tally_tests(cov)
    Condition
      Error:
      ! `x` has no recorded tests.
      i Compute coverage with `options(covr.record_tests = TRUE)`.

# covr.record_tests: safely handles extremely large calls

    Code
      withr::with_options(c(covr.record_tests = TRUE), {
        cov <- code_coverage(fcode, "do.call('f', as.list(rep_len(1L, 1e6)))")
      })
    Condition
      Warning:
      Truncated a large call captured in a test.
      i R can't read calls longer than 10,000 elements from trace files.

