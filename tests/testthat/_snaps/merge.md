# coverage of a file whose name starts with `tests` is not read as recorded tests

    Code
      tally_tests(cov)
    Condition
      Error:
      ! `x` has no recorded tests.
      i Compute coverage with `options(covr.record_tests = TRUE)`.

# warn_unsaved_traces() counts each process once

    Code
      warn_unsaved_traces(dir, "loaded a package", "Let them exit.")
    Condition
      Warning:
      Can't find coverage from 2 R processes that loaded a package.
      i Coverage is lost if a process is killed or outlives the tests.
      i Let them exit.

