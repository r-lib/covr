.onLoad <- function(libname, pkgname) {
  # nolint
  rex::register_shortcuts("covr")
  op <- options()
  op_covr <- list(
    covr.covrignore = Sys.getenv("COVR_COVRIGNORE", ".covrignore"),
    covr.gcov = find_gcov(),
    covr.gcov_args = NULL,
    covr.gcov_additional_paths = NULL,
    covr.exclude_pattern = rex::rex("#", any_spaces, "nocov"),
    covr.exclude_start = rex::rex(
      "#",
      any_spaces,
      "nocov",
      any_spaces,
      "start"
    ),
    covr.exclude_end = rex::rex("#", any_spaces, "nocov", any_spaces, "end"),
    covr.flags = c(
      CFLAGS = "-O0 --coverage",
      CXXFLAGS = "-O0 --coverage",
      CXX1XFLAGS = "-O0 --coverage",
      CXX11FLAGS = "-O0 --coverage",
      CXX14FLAGS = "-O0 --coverage",
      CXX17FLAGS = "-O0 --coverage",
      CXX20FLAGS = "-O0 --coverage",

      FFLAGS = "-O0 --coverage",
      FCFLAGS = "-O0 --coverage",
      FLIBS = "-lgcov",

      # LDFLAGS is ignored on windows and visa versa
      LDFLAGS = if (!is_windows()) "--coverage" else NULL,
      SHLIB_LIBADD = if (is_windows()) "--coverage" else NULL
    )
  )

  toset <- !(names(op_covr) %in% names(op))
  if (any(toset)) {
    options(op_covr[toset])
  }

  invisible()
}

.onAttach <- function(libname, pkgname) {
  # covr is attached as a default package by the R processes started by
  # `shiny_app_coverage()`, but not by the process that calls it.
  app_dir <- Sys.getenv("COVR_SHINY_APP")
  if (
    nzchar(app_dir) &&
      !identical(Sys.getenv("COVR_SHINY_PID"), as.character(Sys.getpid()))
  ) {
    start_shiny_app_tracing(
      app_dir,
      Sys.getenv("COVERAGE_DIR"),
      as.environment(paste0("package:", pkgname))
    )
  }
}
