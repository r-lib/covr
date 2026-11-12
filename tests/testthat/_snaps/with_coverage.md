# with_coverage() restores functions and counters on error

    Code
      with_coverage({
        env$add(1, 2)
        stop("boom")
      }, env = env)
    Condition
      Error in `force()`:
      ! boom

# with_coverage() cleans up when a test file fails

    Code
      with_coverage(quiet_test_file("TestFailure", stop_on_failure = TRUE), env = ns)
    Condition
      Error:
      ! Test failures

