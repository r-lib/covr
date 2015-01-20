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
#' @export
package_coverage <- function(path = ".", ..., relative_path = TRUE) {

  if (!file.exists(path)) {
    return(NULL)
  }

  set_makevars(
    c(CFLAGS = "-g -O0 -fprofile-arcs -ftest-coverage",
      CXXFLAGS = "-g -O0 -fprofile-arcs -ftest-coverage",
      FFLAGS = "-g -O0 -fprofile-arcs -ftest-coverage",
      LDFLAGS = "--coverage")
    )
  on.exit(reset_makevars(), add = TRUE)

  old_envs <- set_envvar(c(PKG_LIBS = "--coverage"), "prefix")
  on.exit(set_envvar(old_envs), add = TRUE)

  dots <- dots(...)

  sources <- sources(path)

  # if there are compiled components to a package we have to run in a subprocess
  if (length(sources) > 0) {
    subprocess(
      ns_env <- devtools::load_all(path, export_all = FALSE, quiet = FALSE, recompile = TRUE)$env,
      env <- new.env(parent = ns_env),
      testing_dir <- test_directory(path),
      args <-
        c(dots,
          if (file.exists(testing_dir)) {
            bquote(try(testthat::source_dir(path = .(testing_dir), env = .(env))))
          }),
        enc <- environment(),
        coverage <- environment_coverage_(ns_env, args, enc),
        rm(ns_env, env, enc, args)
        )

    coverage <- c(coverage, run_gcov(path, sources))

    devtools::clean_dll(path)
    clear_gcov(path)
  } else {
    ns_env <- devtools::load_all(path, export_all = FALSE, quiet = FALSE, recompile = TRUE)$env
    env <- new.env(parent = ns_env)
    testing_dir <- test_directory(path)
    args <-
      c(dots,
        if (file.exists(testing_dir)) {
          bquote(try(testthat::source_dir(path = .(testing_dir), env = .(env))))
        })
      enc <- environment()
      coverage <- environment_coverage_(ns_env, args, enc)
  }

  if (relative_path) {
    names(coverage) <- rex::re_substitutes(names(coverage), rex::rex(normalizePath(path), "/"), "")
  }
  class(coverage) <- "coverage"

  coverage
}
