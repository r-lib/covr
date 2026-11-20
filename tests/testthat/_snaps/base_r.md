# instrument_base_r validates `exclusions`

    Code
      instrument_base_r(tempdir(), exclusions = c(stats = "pbinom"))
    Condition
      Error:
      ! `exclusions` must be a named list of function names, or `NULL`.

# instrument_base_r needs base

    Code
      instrument_base_r(tempdir(), lib = lib, packages = "stats")
    Condition
      Error:
      ! `packages` must include base.

# uninstrument_base_r keeps what the instrumented packages need

    Code
      uninstrument_base_r(lib, packages = "base")
    Condition
      Error:
      ! Can't restore base while other packages are instrumented.
      i Restore stats too.

