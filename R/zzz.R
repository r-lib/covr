.onLoad <- function(libname, pkgname) { # nolint
  op <- options()
  op_covr <- list(
    covr.covrignore = Sys.getenv("COVR_COVRIGNORE", ".covrignore"),
    covr.gcov = Sys.which("gcov"),
    covr.gcov_args = NULL,
    covr.exclude_pattern = rex::rex("#", any_spaces, "nocov"),
    covr.exclude_start = rex::rex("#", any_spaces, "nocov", any_spaces, "start"),
    covr.exclude_end = rex::rex("#", any_spaces, "nocov", any_spaces, "end"),
    covr.flags = c(CFLAGS = "-O0 --coverage",
                 CXXFLAGS = "-O0 --coverage",
                 CXX1XFLAGS = "-O0 --coverage",
                 CXX11FLAGS = "-O0 --coverage",

                 FFLAGS = "-O0 --coverage",
                 FCFLAGS = "-O0 --coverage",

                 # LDFLAGS is ignored on windows and visa versa
                 LDFLAGS = if (!is_windows()) "--coverage" else NULL,
                 SHLIB_LIBADD = if (is_windows()) "--coverage" else NULL)
  )

# add icc code coverage settings
  icov_flag <- "-O0 -prof-gen=srcpos"
  op_covr <- c(op_covr, list(
    covr.icov = Sys.which("codecov"),
    covr.icov_args = NULL,
    covr.icov_prof = Sys.which("profmerge"),
    covr.icov_flags = c(CFLAGS = icov_flag,
                 CXXFLAGS = icov_flag,
                 CXX1XFLAGS = icov_flag,

                 FFLAGS = icov_flag,
                 FCFLAGS = icov_flag,

                 # LDFLAGS is ignored on windows and visa versa
                 LDFLAGS = icov_flag,
                 SHLIB_LIBADD = icov_flag)
  ))

  toset <- !(names(op_covr) %in% names(op))
  if (any(toset)) options(op_covr[toset])

  invisible()
}
