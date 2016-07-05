.onLoad <- function(libname, pkgname) { # nolint
  op <- options()
  op_covr <- list(
    covr.gcov = Sys.which("gcov"),
    covr.gcov_args = NULL,
    covr.exclude_pattern = rex::rex("#", any_spaces, "nocov"),
    covr.exclude_start = rex::rex("#", any_spaces, "nocov", any_spaces, "start"),
    covr.exclude_end = rex::rex("#", any_spaces, "nocov", any_spaces, "end"),
    covr.flags = c(CFLAGS = "-O0 -coverage",
                 CXXFLAGS = "-O0 -coverage",
                 FFLAGS = "-O0 -coverage",
                 FCFLAGS = "-O0 -coverage",

                 # LDFLAGS is ignored on windows and visa versa
                 LDFLAGS = if (!is_windows()) "-coverage" else NULL,
                 SHLIB_LIBADD = if (is_windows()) "-coverage" else NULL)
  )
  toset <- !(names(op_covr) %in% names(op))
  if (any(toset)) options(op_covr[toset])

  invisible()
}
