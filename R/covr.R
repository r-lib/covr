#' @import methods
NULL

rex::register_shortcuts("covr")
#' calculate the coverage on an environment after evaluating some expressions.
#'
#' This function uses non_standard evaluation so is best used in interactive
#' sessions.
#' @param env the environment to take function definitions from
#' @param ... one or more expressions to be evaluated.
#' @param enc The enclosing environment from which the expressions should be
#' evaluated
#' @export
environment_coverage <- function(env, ..., enc = parent.frame()) {
  exprs <- dots(...)
  environment_coverage_(env, exprs, enc = enc)
}

#' calculate the coverage on an environment after evaluating some expressions.
#'
#' This function does not use non_standard evaluation so is more appropriate
#' for use in other functions.
#' @inheritParams environment_coverage
#' @param exprs a list of parsed expressions to be evaluated.
#' @export
environment_coverage_ <- function(env, exprs, enc = parent.frame()) {
  clear_counters()

  replacements <-
    c(replacements_S4(env),
      Filter(Negate(is.null), lapply(ls(env, all.names = TRUE), replacement, env = env))
    )

  on.exit(lapply(replacements, reset), add = TRUE)

  lapply(replacements, replace)

  for (expr in exprs) {
    eval(expr, enc)
  }

  res <- as.list(.counters)
  clear_counters()

  class(res) <- "coverage"

  res
}

#' Calculate test coverage for specific function.
#'
#' @param fun name of the function.
#' @param env environment the function is defined in.
#' @param ... expressions to run.
#' @param enc the enclosing environment which to run the expressions.
#' @export
function_coverage <- function(fun, ..., env = NULL, enc = parent.frame()) {

  exprs <- dots(...)

  clear_counters()

  replacement <- if (!is.null(env)) {
    replacement(fun, env)
  } else {
    replacement(fun)
  }

  on.exit(reset(replacement), add = TRUE)

  replace(replacement)

  for (expr in exprs) {
    eval(expr, enc)
  }

  res <- as.list(.counters)
  clear_counters()

  class(res) <- "coverage"

  res
}

#' Calculate test coverage for a package
#'
#' @param path file path to the package
#' @param ... expressions to run
#' @param relative_path whether to output the paths as relative or absolute
#' paths.
#' @param quiet whether to load and compile the package quietly
#' @param exclusions a named list of files with the lines to exclude from each file.
#' @param exclude_pattern a search pattern to look for in the source to exclude a particular line.
#' @param exclude_start a search pattern to look for in the source to start an exclude block.
#' @param exclude_end a search pattern to look for in the source to stop an exclude block.
#' @export
package_coverage <- function(path = ".",
                             ...,
                             relative_path = TRUE,
                             quiet = TRUE,
                             exclusions = NULL,
                             exclude_pattern = rex::rex("#", any_spaces, "EXCLUDE COVERAGE"),
                             exclude_start = rex::rex("#", any_spaces, "EXCLUDE COVERAGE START"),
                             exclude_end = rex::rex("#", any_spaces, "EXCLUDE COVERAGE END")
                             ) {

  pkg <- devtools::as.package(path)

  if (!file.exists(path)) {
    stop(sQuote(path), " does not exist!", call. = FALSE)
  }

  set_makevars(
    c(CFLAGS = "-g -O0 -fprofile-arcs -ftest-coverage",
      CXXFLAGS = "-g -O0 -fprofile-arcs -ftest-coverage",
      FFLAGS = "-g -O0 -fprofile-arcs -ftest-coverage",
      FCFLAGS = "-g -O0 -fprofile-arcs -ftest-coverage",
      LDFLAGS = "--coverage")
    )e
  on.exit(reset_makevars(), add = TRUE)

  old_envs <- set_envvar(c(PKG_LIBS = "--coverage"), "prefix")
  on.exit(set_envvar(old_envs), add = TRUE)

  dots <- dots(...)

  sources <- sources(path)

  tmp_lib <- tempdir()

  # if there are compiled components to a package we have to run in a subprocess
  if (length(sources) > 0) {
    subprocess(
      clean_output = FALSE,
      quiet = FALSE,
      coverage <- run_tests(pkg, tmp_lib, dots)
    )

    coverage <- c(coverage, run_gcov(path, sources))

    devtools::clean_dll(path)
    clear_gcov(path)
  } else {
    coverage <- run_tests(pkg, tmp_lib)
  }

  if (relative_path) {
    names(coverage) <- rex::re_substitutes(names(coverage),
                                           rex::rex(normalizePath(path), "/"),
                                           "")
    attr(coverage, "path") <- path
  }

  class(coverage) <- "coverage"

  exclude(coverage,
    exclusions = exclusions,
    exclude_pattern = exclude_pattern,
    exclude_start = exclude_start,
    exclude_end = exclude_end
  )
}

run_tests <- function(pkg, tmp_lib, dots) {
  devtools::RCMD("INSTALL",
                 options = c(shQuote(pkg$path),
                             "--no-docs",
                             "--no-multiarch",
                             "--no-demo",
                             "--preclean",
                             "--with-keep.source",
                             "--no-byte-compile",
                             "--no-test-load",
                             "-l",
                             shQuote(tmp_lib)))

  devtools::with_lib(tmp_lib,
                     library(pkg$package,
                             character.only = TRUE))

  ns_env <- asNamespace(pkg$package)
  env <- new.env(parent = ns_env) # nolint
  testing_dir <- test_directory(pkg$path)
  args <-
    c(dots,
      if (file.exists(testing_dir)) {
        bquote(try(testthat::source_dir(path = .(testing_dir), env = .(env))))
      })
  enc <- environment()
  environment_coverage_(ns_env, args, enc)
}
