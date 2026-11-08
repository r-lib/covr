# covr_error print shows the last n lines

    Code
      print(err, n = 3)
    Output
      <covr_error> Failure in `x.Rout.fail`
      (showing last 3 of 11 lines; use `print(x, n = Inf)` or `x$output` for all)
      line 8
      line 9
      line 10
    Code
      print(err, n = Inf)
    Output
      <covr_error> Failure in `x.Rout.fail`
      >
      line 1
      line 2
      line 3
      line 4
      line 5
      line 6
      line 7
      line 8
      line 9
      line 10

# package_coverage warns about processes that did not save a trace

    Code
      cov <- package_coverage(test_path("TestSummary"), type = "none", code = code)
    Condition
      Warning:
      1 R process loaded TestSummary but did not save its coverage, so it is missing from the results.
      Coverage is saved when R exits normally; it is lost if a process is killed (e.g. with SIGKILL or SIGTERM) or is still running when the tests finish.
      Stop background processes started by the tests, such as Shiny apps, callr sessions or future workers, gracefully and wait for them to exit.

