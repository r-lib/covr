# gcov_run only fails when gcov does (#537)

    Code
      gcov_result(no_lines("./utils.gcno:cannot open notes file"), 1L)
    Condition
      Error:
      ! Can't run gcov.
      x Exit status 1.
      i gcov output:
      ./utils.gcno:cannot open notes file
      ./utils.gcda:cannot open data file, assuming not executed
      No executable lines
    Code
      gcov_result(no_lines("./utils.gcno:not a gcov notes file"), 2L)
    Condition
      Error:
      ! Can't run gcov.
      x Exit status 2.
      i gcov output:
      ./utils.gcno:not a gcov notes file
      ./utils.gcda:cannot open data file, assuming not executed
      No executable lines
    Code
      gcov_result(no_lines("./utils.gcno:version 'B33*', prefer 'B13*'",
        "./utils.gcno:no functions found"), 3L)
    Condition
      Error:
      ! Can't run gcov.
      x Exit status 3.
      i gcov output:
      ./utils.gcno:version 'B33*', prefer 'B13*'
      ./utils.gcno:no functions found
      ./utils.gcda:cannot open data file, assuming not executed
      No executable lines
    Code
      gcov_result(no_lines("./utils.gcno:corrupted",
        "./utils.gcno:no functions found"), 4L)
    Condition
      Error:
      ! Can't run gcov.
      x Exit status 4.
      i gcov output:
      ./utils.gcno:corrupted
      ./utils.gcno:no functions found
      ./utils.gcda:cannot open data file, assuming not executed
      No executable lines

