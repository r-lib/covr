# instrument_base_r validates `exclusions`

    Code
      instrument_base_r(tempdir(), exclusions = c(stats = "pbinom"))
    Condition
      Error:
      ! `exclusions` must be a named list of function names, or `NULL`.

