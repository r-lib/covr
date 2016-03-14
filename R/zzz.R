.onLoad <- function(libname, pkgname) { # nolint
  op <- options()
  op_covr <- list(
    covr.gcov = "gcov",
    covr.gcov_args = NULL,
    covr.exclude_pattern = rex::rex("#", any_spaces, "nocov"),
    covr.exclude_start = rex::rex("#", any_spaces, "nocov", any_spaces, "start"),
    covr.exclude_end = rex::rex("#", any_spaces, "nocov", any_spaces, "end"),
    covr.flags = c(CPPFLAGS = "-O0 -fprofile-arcs -ftest-coverage",
                   FFLAGS = "-O0 -fprofile-arcs -ftest-coverage",
                   FCFLAGS = "-O0 -fprofile-arcs -ftest-coverage",
                   LDFLAGS = "--coverage")
  )
  toset <- !(names(op_covr) %in% names(op))
  if (any(toset)) options(op_covr[toset])

  invisible()
}
