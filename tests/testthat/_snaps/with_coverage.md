# with_coverage() restores functions and counters on error

    Code
      with_coverage({
        env$add(1, 2)
        stop("boom")
      }, env = env)
    Condition
      Error in `force()`:
      ! boom

# with_coverage() cleans up when tracing fails

    Code
      with_mocked_bindings(with_coverage(env$add(1, 2), env = env), replacement = function(
        ...) stop("boom"))
    Condition
      Error in `FUN()`:
      ! boom

# with_coverage() cleans up when a test file fails

    Code
      with_coverage(quiet_test_file("TestFailure", stop_on_failure = TRUE), env = ns)
    Condition
      Error:
      ! Test failures

# nested in-process coverage warns and restores the functions

    Code
      cov <- with_coverage({
        with_coverage(inner$g(1), env = inner)
        function_coverage("g", inner$g(1), env = inner)
      }, env = outer)
    Condition
      Warning:
      Coverage is already being measured by an enclosing call.
      i `with_coverage()`, `file_coverage()`, `function_coverage()` and the functions that call them can't be nested; the enclosing call's coverage is incomplete.

