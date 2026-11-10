# restore_counters() errors if `.onLoad()` defined a `.Call` that masks the saved counters

    Code
      restore_counters(ns, file)
    Condition
      Error:
      ! Can't measure the coverage of pkg, as its `.onLoad()` defines a `.Call` function.
      i The counters that covr added when the package was installed call `.Call`, so they would call this function instead of the base one.
      i Define `.Call` in the package's R code instead, or set `options(covr.install_instrument = FALSE)`.

