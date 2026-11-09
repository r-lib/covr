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

# parse_gcov errors on coverage values it cannot parse

    Code
      suppressWarnings(parse_gcov("hi.c.gcov"))
    Condition
      Error:
      ! Can't parse gcov line counts.
      x Unexpected count: "###*#".

# gcov_run reports the command and output when not quiet

    Code
      gcov_run("gcov", c("a b.gcno", "-a"), quiet = FALSE)
    Message
      'gcov' 'a b.gcno' '-a' 
      line one

# run_gcov returns without error when gcov is unavailable and unused

    Code
      run_gcov(pkg, gcov_path = NA_character_)
    Condition
      Error:
      ! Can't find gcov.
      i Set its path with `options(covr.gcov = )`.

# run_gcov reports progress when not quiet

    Code
      cat(msgs(TRUE), sep = "")
    Output
      gcov output for ./f.gcno:
      ./f.c.gcov

---

    Code
      cat(gsub(pkg, "<pkg>", msgs(FALSE), fixed = TRUE), sep = "")
    Output
      gcov output for ./f.gcno:
      ./f.c.gcov
      gcov output targets for ./f.gcno:
      ../covr/./f.gcno/f.c.gcov
      Moving gcov outputs to covr directory.
      

