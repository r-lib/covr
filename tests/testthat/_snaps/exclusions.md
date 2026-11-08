# it throws an error if start and end are unpaired

    Code
      do.call(parse_exclusions, c(list(t1), exclude_ops))
    Condition
      Error:
      ! Each exclusion range start must have a matching range end.
      x Found 1 start (line 1) and 0 ends.

---

    Code
      do.call(parse_exclusions, c(list(t1), exclude_ops, file = "R/foo.R"))
    Condition
      Error:
      ! Each exclusion range start must have a matching range end.
      x 'R/foo.R' has 1 start (line 1) and 0 ends.

---

    Code
      do.call(parse_exclusions, c(list(t2), exclude_ops, file = "R/foo.R"))
    Condition
      Error:
      ! Each exclusion range start must have a matching range end.
      x 'R/foo.R' has 1 start (line 1) and 2 ends (lines 2 and 3).

# unpaired start and end errors give the file name

    Code
      file_coverage(f, character())
    Condition
      Error:
      ! Each exclusion range start must have a matching range end.
      x '<file>' has 2 starts (lines 1 and 3) and 0 ends.

