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
      Can't find coverage from 1 R process that loaded TestSummary.
      i Coverage is lost if a process is killed or outlives the tests.
      i Did a test leave a Shiny app, callr session, or future worker running?

