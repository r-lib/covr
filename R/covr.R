#' @import methods
#' @importFrom stats aggregate na.omit na.pass setNames
#' @importFrom utils capture.output getSrcFilename relist str
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
  if (is.function(fun)) {
    env <- environment(fun)

    # get name of function, stripping preceding blah:: if needed
    fun <- rex::re_substitutes(deparse(substitute(fun)), rex::regex(".*:::?"), "")
  }

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

  for (i in seq_along(res)) {
    display_name(res[[i]]$srcref) <- generate_display_name(res[[i]], path = NULL)
    class(res[[i]]) <- "expression_coverage"
  }

  class(res) <- "coverage"

  res
}

#' Calculate test coverage for a package
#'
#' @param path file path to the package
#' @param ... extra expressions to run
#' @param type run the package \sQuote{test}, \sQuote{vignette},
#' \sQuote{example}, \sQuote{all}, or \sQuote{none}. The default is
#' \sQuote{test}.
#' @param relative_path whether to output the paths as relative or absolute
#' paths.
#' @param quiet whether to load and compile the package quietly
#' @param clean whether to clean temporary output files after running.
#' @param exclusions a named list of files with the lines to exclude from each file.
#' @param exclude_pattern a search pattern to look for in the source to exclude a particular line.
#' @param exclude_start a search pattern to look for in the source to start an exclude block.
#' @param exclude_end a search pattern to look for in the source to stop an exclude block.
#' @param use_subprocess whether to run the code in a separate subprocess.
#' Needed for compiled code and many packages using S4 classes.
#' @param use_try whether to wrap test evaluation in a \code{try} call; enabled by default
#' @seealso exclusions
#' @export
package_coverage <- function(path = ".",
                             ...,
                             type = c("test", "vignette", "example", "all", "none"),
                             relative_path = TRUE,
                             quiet = TRUE,
                             clean = TRUE,
                             exclusions = NULL,
                             exclude_pattern = getOption("covr.exclude_pattern"),
                             exclude_start = getOption("covr.exclude_start"),
                             exclude_end = getOption("covr.exclude_end"),
                             use_subprocess = TRUE,
                             use_try = TRUE
                             ) {

  pkg <- as_package(path)

  type <- match.arg(type)

  if (type == "all") {

    # store the args that were called
    called_args <- as.list(match.call())[-1]

    # remove the type
    called_args$type <- NULL
    res <- list(
                test = do.call(Recall, c(called_args, type = "test")),
                vignette = do.call(Recall, c(called_args, type = "vignette")),
                example = do.call(Recall, c(called_args, type = "example"))
                )

    attr(res, "package") <- pkg
    class(res) <- "coverages"
    return(res)
  }

  dots <- dots(...)

  sources <- sources(pkg$path)

  tmp_lib <- tempdir()

  coverage <- list()

  # if there are compiled components to a package we have to run in a subprocess
  if (length(sources)) {

    if (isTRUE(clean)) {
      on.exit({
        clean_objects(pkg$path)
        clear_gcov(pkg$path)
      })
    }
    flags <- c(CFLAGS = "-g -O0 -fprofile-arcs -ftest-coverage",
        CXXFLAGS = "-g -O0 -fprofile-arcs -ftest-coverage",
        CXX1XFLAGS = "-g -O0 -fprofile-arcs -ftest-coverage",
        FFLAGS = "-g -O0 -fprofile-arcs -ftest-coverage",
        FCFLAGS = "-g -O0 -fprofile-arcs -ftest-coverage",
        LDFLAGS = "--coverage")

    if (is_windows()) {

      # workaround for https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16384
      # LDFLAGS is ignored on Windows and we don't want to override PKG_LIBS if
      # it is set, so use SHLIB_LIBADD
      flags[["SHLIB_LIBADD"]] <- "--coverage"
    }

    withr::with_makevars(
      flags, {
        if (use_subprocess) {
          subprocess(
                     clean = clean,
                     quiet = quiet,
                     coverage <- run_tests(pkg, tmp_lib, dots, type, quiet, use_try = use_try)
                     )
        } else {
          coverage <- run_tests(pkg, tmp_lib, dots, type, quiet, use_try = use_try)
        }
      })

    coverage <- c(coverage, run_gcov(pkg$path, quiet = quiet))

  } else {
    if (use_subprocess) {
      subprocess(
                 clean = clean,
                 quiet = quiet,
                 coverage <- run_tests(pkg, tmp_lib, dots, type, quiet, use_try = use_try)
                 )
    } else {
      coverage <- run_tests(pkg, tmp_lib, dots, type, quiet, use_try = use_try)
    }
  }

  # set the display names for coverage
  for (i in seq_along(coverage)) {
    display_path <- if (isTRUE(relative_path)) pkg$path else NULL

    display_name(coverage[[i]]$srcref) <-
      generate_display_name(coverage[[i]], display_path)

    class(coverage[[i]]) <- "expression_coverage"
  }

  attr(coverage, "type") <- type
  attr(coverage, "package") <- pkg
  class(coverage) <- "coverage"

  # BasicClasses are functions from the method package
  coverage <- coverage[!rex::re_matches(display_name(coverage),
    rex::rex("R", one_of("/", "\\"), "BasicClasses.R"))]

  # perform exclusions
  exclude(coverage,
    exclusions = exclusions,
    exclude_pattern = exclude_pattern,
    exclude_start = exclude_start,
    exclude_end = exclude_end,
    path = if (isTRUE(relative_path)) pkg$path else NULL
  )
}

generate_display_name <- function(x, path = NULL) {
  file_path <- normalizePath(getSrcFilename(x$srcref, full.names = TRUE), mustWork = FALSE)
  if (!is.null(path)) {

    # we have to check the system explicitly because both file.path and
    # normalizePath strip the trailing path separator.
    if (is_windows()) {
      sep <- "\\"
    } else {
      sep <- "/"
    }

    package_path <- paste0(path, sep)

    file_path <- rex::re_substitutes(file_path, rex::rex(package_path), "")
  }
  file_path
}

run_tests <- function(pkg, tmp_lib, dots, type, quiet, use_try = TRUE) {
  testing_dir <- test_directory(pkg$path)

  # install the package in a temporary directory
  RCMD("INSTALL",
                 options = c(pkg$path,
                             "--no-docs",
                             "--no-multiarch",
                             "--preclean",
                             "--with-keep.source",
                             "--no-byte-compile",
                             "--no-test-load",
                             "--no-multiarch",
                             "-l",
                             tmp_lib),
                  quiet = quiet)

  if (isNamespaceLoaded(pkg$package)) {
    try_unload(pkg$package)
    on.exit(loadNamespace(pkg$package), add = TRUE)
  }
  withr::with_libpaths(tmp_lib, action = "prefix", {
    ns_env <- loadNamespace(pkg$package)
    env <- new.env(parent = ns_env) # nolint

    # directories for vignettes and examples
    vignette_dir <- file.path(pkg$path, "vignettes")
    example_dir <- file.path(pkg$path, "man")

    # get expressions to run
    exprs <-
      c(dots,
        quote("library(methods)"),
        if (type == "test" && file.exists(testing_dir)) {
          if (isTRUE(use_try)) {
            bquote(try(source_dir(path = .(testing_dir), env = .(env), quiet = .(quiet)), silent = .(quiet)))
          } else {
            bquote(source_dir(path = .(testing_dir), env = .(env), quiet = .(quiet)))
          }
        } else if (type == "vignette" && file.exists(vignette_dir)) {
          lapply(dir(vignette_dir, pattern = rex::rex(".", one_of("R", "r"), or("nw", "md")), full.names = TRUE),
            function(file) {
              out_file <- tempfile(fileext = ".R")
              knitr::knit(input = file, output = out_file, tangle = TRUE)
              bquote(source2(.(out_file), .(env), path = .(vignette_dir), quiet = .(quiet)))
            })
        } else if (type == "example" && file.exists(example_dir)) {
          ex_file <- process_examples(pkg, tmp_lib, quiet) # nolint
          bquote(source(.(ex_file)))
        })

    enc <- environment()

    # actually calculate the coverage
    cov <- environment_coverage_(ns_env, exprs, enc)

    # unload the package being tested
    try_unload(pkg$package)
    cov
  })
}

try_unload <- function(pkg) {
  tryCatch(unloadNamespace(pkg), error = function(e) warning(e$message))
}

process_examples <- function(pkg, lib = getwd(), quiet = TRUE) {

  ex_file <- ex_dot_r(pkg$package, file.path(lib, pkg$package), silent = quiet)

  # we need to move the file from the working directory into the tmp
  # dir, remove the last line (which quits) and remove the originaal
  # and *-cnt file
  tmp_ex_file <- file.path(lib, ex_file)
  lines <- readLines(ex_file)
  header_lines <- readLines(file.path(R.home("share"), "R", "examples-header.R"))

  # pdf output at lib
  header_lines <- rex::re_substitutes(header_lines,
    rex::rex("grDevices::pdf(paste(pkgname, \"-Ex.pdf\", sep=\"\")"),
    paste0("grDevices::pdf(\"", file.path(lib, pkg$package), "-Ex.pdf\""))

  # remove header source line
  lines <- lines[-2]

  # append header_lines after the first line
  lines <- append(lines, header_lines, after = 1)

  # remove last line "quit("no")"
  lines <- lines[-length(lines)]
  writeLines(lines, con = tmp_ex_file)

  if (file.exists(ex_file)) {
    file.remove(ex_file)
  }

  cnt_file <- paste0(ex_file, "-cnt")
  if (file.exists(cnt_file)) {
    file.remove(paste0(ex_file, "-cnt"))
  }

  tmp_ex_file
}
