# it throws an error if start and end are unpaired

    Code
      do.call(parse_exclusions, c(list(t1), exclude_ops))
    Condition
      Error:
      ! 1 range start (line 1) but only 0 range ends for exclusion from code coverage!

---

    Code
      do.call(parse_exclusions, c(list(t1), exclude_ops, file = "R/foo.R"))
    Condition
      Error:
      ! R/foo.R has 1 range start (line 1) but only 0 range ends for exclusion from code coverage!

---

    Code
      do.call(parse_exclusions, c(list(t2), exclude_ops, file = "R/foo.R"))
    Condition
      Error:
      ! R/foo.R has 1 range start (line 1) but 2 range ends (lines 2, 3) for exclusion from code coverage!

# unpaired start and end errors give the file name

    Code
      file_coverage(f, character())
    Condition
      Error:
      ! <file> has 2 range starts (lines 1, 3) but only 0 range ends for exclusion from code coverage!

