#' covr: Test coverage for packages
#'
#' covr tracks and reports code coverage for your package and (optionally)
#' upload the results to a coverage service like 'Codecov' <https://about.codecov.io> or
#' 'Coveralls' <https://coveralls.io>. Code coverage is a measure of the amount of
#' code being exercised by a set of tests. It is an indirect measure of test
#' quality and completeness. This package is compatible with any testing
#' methodology or framework and tracks coverage of both R code and compiled
#' C/C++/FORTRAN code.
#'
#' A coverage report can be used to inspect coverage for each line in your
#' package. Using `report()` requires the additional dependencies `DT` and `htmltools`.
#'
#' ```r
#' # If run with no arguments `report()` implicitly calls `package_coverage()`
#' report()
#' ```
#'
#' @section Package options:
#'
#' `covr` uses the following [options()] to configure behaviour:
#'
#' \itemize{
#'   \item `covr.covrignore`: A filename to use as an ignore file,
#'     listing glob-style wildcarded paths of files to ignore for coverage
#'     calculations. Defaults to the value of environment variable
#'     `COVR_COVRIGNORE`, or `".covrignore"`  if the neither the option nor the
#'     environment variable are set.
#'
#'   \item `covr.exclude_end`: Used along with `covr.exclude_start`, an optional
#'     regular expression which ends a line-exclusion region. For more
#'     details, see `?exclusions`.
#'
#'   \item `covr.exclude_pattern`: An optional line-exclusion pattern. Lines
#'     which match the pattern will be excluded from coverage. For more details,
#'     see `?exclusions`.
#'
#'   \item `covr.exclude_start`: Used along with `covr.exclude_end`, an optional
#'     regular expression which starts a line-exclusion region. For more
#'     details, see `?exclusions`.
#'
#'   \item `covr.filter_non_package`: If `TRUE` (the default behavior), coverage
#'     of files outside the target package are filtered from coverage output.
#'
#'   \item `covr.fix_parallel_mcexit`:
#'
#'   \item `covr.flags`:
#'
#'   \item `covr.gcov`: If the appropriate gcov version is not on your path you
#'     can use this option to set the appropriate location. If set to "" it will
#'     turn off coverage of compiled code.
#'
#'   \item `covr.gcov_additional_paths`:
#'
#'   \item `covr.gcov_args`:
#'
#'   \item `covr.icov`:
#'
#'   \item `covr.icov_args`:
#'
#'   \item `covr.icov_flags`:
#'
#'   \item `covr.icov_prof`:
#'
#'   \item `covr.rstudio_source_markers`: A logical value. If `TRUE` (the
#'     default behavior), source markers are displayed within the RStudio IDE
#'     when using `zero_coverage`.
#'
#'   \item `covr.record_tests`: If `TRUE` (default `NULL`), record a listing of
#'     top level test expressions and associate tests with `covr` traces
#'     evaluated during the test's execution. For more details, see
#'     `?covr.record_tests`.
#'
#'   \item `covr.showCfunctions`:
#' }
#'
#'
"_PACKAGE"

#' @import methods
#' @importFrom stats aggregate na.omit na.pass setNames
#' @importFrom utils capture.output getSrcFilename relist str head
#' @importFrom httr content RETRY upload_file
NULL

the <- new.env(parent = emptyenv())

the$replacements <- list()

trace_environment <- function(env) {
  clear_counters()

  the$replacements <- compact(c(
      replacements_S4(env),
      replacements_RC(env),
      replacements_R6(env),
      replacements_S7(env),
      replacements_box(env),
      lapply(ls(env, all.names = TRUE), replacement, env = env)))

  lapply(the$replacements, replace)
}

reset_traces <- function() {
  lapply(the$replacements, reset)
}

save_trace <- function(directory) {
  tmp_file <- temp_file("covr_trace_", tmpdir = directory)
  saveRDS(.counters, file = tmp_file)
}

#' Convert a counters object to a coverage object
#'
#' @param counters An environment of covr trace results to convert to a coverage
#'   object. If `counters` is not provided, the `covr` namespace value
#'   `.counters` is used.
#' @param ... Additional attributes to include with the coverage object.
#'
as_coverage <- function(counters = NULL, ...) {
  if (missing(counters))
    counters <- .counters

  counters <- as.list(counters)
  counters <- as_coverage_with_tests(counters)

  structure(counters, ..., class = "coverage")
}

#' Clean and restructure counter tests for a coverage object
#'
#' For tests produced with `options(covr.record_tests)`, prune any unused
#' records in the $tests$tally matrices of each trace and get rid of the
#' wrapping $tests environment (reassigning with value of $tests$tally)
#'
#' @inheritParams as_coverage
#'
as_coverage_with_tests <- function(counters) {
  clean_coverage_tests(counters)

  # unnest environment-wrapped $tests$tally as more accessible $tests
  for (i in seq_along(counters)) {
    if (!is.environment(counters[[i]]$tests)) next
    counters[[i]]$tests <- counters[[i]]$tests$tally
  }

  tests <- counters$tests
  counters$tests <- NULL
  structure(counters, tests = tests, class = "coverage")
}

#' Calculate test coverage for a specific function.
#'
#' @param fun name of the function.
#' @param code expressions to run.
#' @param env environment the function is defined in.
#' @param enc the enclosing environment which to run the expressions.
#' @examples
#' add <- function(x, y) { x + y }
#' function_coverage(fun = add, code = NULL) # 0% coverage
#' function_coverage(fun = add, code = add(1, 2) == 3) # 100% coverage
#' @export
function_coverage <- function(fun, code = NULL, env = NULL, enc = parent.frame()) {
  if (is.function(fun)) {
    env <- environment(fun)

    # get name of function, stripping preceding blah:: if needed
    fun <- rex::re_substitutes(deparse(substitute(fun)), rex::regex(".*:::?"), "")
  }

  clear_counters()

  replacement <- if (!is.null(env)) {
    replacement(fun, env)
  } else {
    replacement(fun)
  }

  on.exit({
    reset(replacement)
    clear_counters()
  })

  replace(replacement)

  withr::with_envvar(c("R_COVR" = "true"),
    eval(code, enc)
  )

  as_coverage(as.list(.counters))
}

#' Calculate test coverage for sets of files
#'
#' The files in `source_files` are first sourced into a new environment
#' to define functions to be checked. Then they are instrumented to track
#' coverage and the files in `test_files` are sourced.
#' @param source_files Character vector of source files with function
#'   definitions to measure coverage
#' @param test_files Character vector of test files with code to test the
#'   functions
#' @param parent_env The parent environment to use when sourcing the files.
#' @inheritParams package_coverage
#' @examples
#' # For the purpose of this example, save code containing code and tests to files
#' cat("add <- function(x, y) { x + y }", file="add.R")
#' cat("add(1, 2) == 3", file="add_test.R")
#'
#' # Use file_coverage() to calculate test coverage
#' file_coverage(source_files = "add.R", test_files = "add_test.R")
#'
#' # cleanup
#' file.remove(c("add.R", "add_test.R"))
#' @export
file_coverage <- function(
  source_files,
  test_files,
  line_exclusions = NULL,
  function_exclusions = NULL,
  parent_env = parent.frame()) {

  env <- new.env(parent = parent_env)

  withr::with_options(c("keep.parse.data.pkgs" = TRUE), {
    lapply(source_files,
      sys.source, keep.source = TRUE, envir = env)
  })

  trace_environment(env)
  on.exit({
    reset_traces()
    clear_counters()
  })

  withr::with_envvar(c("R_COVR" = "true"),
    lapply(test_files,
      sys.source, keep.source = TRUE, envir = env)
  )

  coverage <- as_coverage(.counters)

  exclude(coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = NULL)
}

#' Calculate coverage of code directly
#'
#' This function is useful for testing, and is a thin wrapper around
#' [file_coverage()] because parseData is not populated properly
#' unless the functions are defined in a file.
#' @param source_code A character vector of source code
#' @param test_code A character vector of test code
#' @inheritParams file_coverage
#' @param ... Additional arguments passed to [file_coverage()]
#' @examples
#' source <- "add <- function(x, y) { x + y }"
#' test <- "add(1, 2) == 3"
#' code_coverage(source, test)
#' @export
code_coverage <- function(
   source_code,
   test_code,
   line_exclusions = NULL,
   function_exclusions = NULL,
   ...) {
  src <- tempfile("source.R")
  test <- tempfile("test.R")
  on.exit(file.remove(src, test))
  cat(source_code, file = src)
  cat(test_code, file = test)
  file_coverage(src, test, line_exclusions = line_exclusions,
    function_exclusions = function_exclusions, ...)
}

#' Calculate coverage of an environment
#'
#' @param env The environment to be instrumented.
#' @inheritParams file_coverage
#' @export
environment_coverage <- function(
  env = parent.frame(),
  test_files,
  line_exclusions = NULL,
  function_exclusions = NULL) {

  exec_env <- new.env(parent = env)

  trace_environment(env)
  on.exit({
    reset_traces()
    clear_counters()
  })

  withr::with_envvar(c("R_COVR" = "true"),
    lapply(test_files,
      sys.source, keep.source = TRUE, envir = exec_env)
  )

  coverage <- as_coverage(.counters)

  exclude(coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = NULL)
}

#' Calculate test coverage for a package
#'
#' This function calculates the test coverage for a development package on the
#' `path`. By default it runs only the package tests, but it can also run
#' vignette and example code.
#'
#' @details
#' This function uses [tools::testInstalledPackage()] to run the
#' code, if you would like to test your package in another way you can set
#' `type = "none"` and pass the code to run as a character vector to the
#' `code` parameter.
#'
#' #ifdef unix
#' Parallelized code using \pkg{parallel}'s [mcparallel()] needs to
#' use a patched `parallel:::mcexit`. This is done automatically if the
#' package depends on \pkg{parallel}, but can also be explicitly set using the
#' environment variable `COVR_FIX_PARALLEL_MCEXIT` or the global option
#' `covr.fix_parallel_mcexit`.
#' #endif
#'
#' @param path file path to the package.
#' @param type run the package \sQuote{tests}, \sQuote{vignettes},
#' \sQuote{examples}, \sQuote{all}, or \sQuote{none}. The default is
#' \sQuote{tests}.
#' @param combine_types If `TRUE` (the default) the coverage for all types
#' is simply summed into one coverage object. If `FALSE` separate objects
#' are used for each type of coverage.
#' @param relative_path whether to output the paths as relative or absolute
#'   paths. If a string, it is interpreted as a root path and all paths will be
#'   relative to that root.
#' @param quiet whether to load and compile the package quietly, useful for
#' debugging errors.
#' @param clean whether to clean temporary output files after running, mainly
#' useful for debugging errors.
#' @param line_exclusions a named list of files with the lines to exclude from
#' each file.
#' @param function_exclusions a vector of regular expressions matching function
#' names to exclude. Example `print\\\.` to match print methods.
#' @param code A character vector of additional test code to run.
#' @param ... Additional arguments passed to [tools::testInstalledPackage()].
#' @param exclusions \sQuote{Deprecated}, please use \sQuote{line_exclusions} instead.
#' @param pre_clean whether to delete all objects present in the src directory before recompiling
#' @param install_path The path the instrumented package will be installed to
#'   and tests run in. By default it is a path in the R sessions temporary
#'   directory. It can sometimes be useful to set this (along with `clean =
#'   FALSE`) to help debug test failures.
#' @seealso [exclusions()] For details on excluding parts of the
#' package from the coverage calculations.
#' @export
package_coverage <- function(path = ".",
                             type = c("tests", "vignettes", "examples", "all", "none"),
                             combine_types = TRUE,
                             relative_path = TRUE,
                             quiet = TRUE,
                             clean = TRUE,
                             line_exclusions = NULL,
                             function_exclusions = NULL,
                             code = character(),
                             install_path = temp_file("R_LIBS"),
                             ...,
                             exclusions, pre_clean = TRUE) {

  if (!missing(exclusions)) {
    warning(
      "`exclusions` is deprecated and will be removed in an upcoming release. Please use `line_exclusions` instead.",
      call. = FALSE, domain = NA
    )
    line_exclusions <- exclusions
  }

  pkg <- as_package(path)

  if (missing(type)) {
    type <- "tests"
  }

  type <- parse_type(type)

  run_separately <- !isTRUE(combine_types) && length(type) > 1
  if (run_separately) {
    # store the args that were called
    called_args <- as.list(match.call())[-1]

    # remove the type
    called_args$type <- NULL
    res <- list()
    for (t in type) {
      res[[t]] <- do.call(Recall, c(called_args, type = t))
      attr(res[[t]], "type") <- t
    }

    attr(res, "package") <- pkg
    class(res) <- "coverages"
    return(res)
  }

  if (is.character(relative_path)) {
    stopifnot(length(relative_path) == 1)
    root <- normalize_path(relative_path)
  } else if (isTRUE(relative_path)) {
    root <- pkg$path
  } else {
    root <- NULL
  }

  # tools::testInstalledPackage requires normalized install_path (#517)
  install_path <- normalize_path(install_path)
  dir.create(install_path)

  flags <- getOption("covr.flags")

  # check for compiler
  if (!uses_icc()) {
    flags <- getOption("covr.flags")
  } else {
    if (length(getOption("covr.icov")) > 0L) {
      flags <- getOption("covr.icov_flags")
      # clean up old icov files
      unlink(file.path(pkg$path, "src","*.dyn"))
      unlink(file.path(pkg$path, "src","pgopti.*"))
    } else {
      stop("icc is not available")
    }
  }

  if (isTRUE(clean)) {
    on.exit({
      clean_objects(pkg$path)
      clean_gcov(pkg$path)
      clean_parse_data()
      unlink(install_path, recursive = TRUE)
    }, add = TRUE)
  }

  # clean any dlls prior to trying to install
  if (isTRUE(pre_clean)) clean_objects(pkg$path)

  # install the package in a temporary directory
  withr::with_envvar(
    list(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep)),
    withr::with_makevars(flags, assignment = "+=", {
      args <- c(
        "--vanilla", "CMD", "INSTALL",
        "-l", shQuote(install_path),
        "--example",
        "--install-tests",
        "--with-keep.source",
        "--with-keep.parse.data",
        "--no-staged-install",
        "--no-multiarch",
        shQuote(pkg$path)
      )

      name <- if (.Platform$OS.type == "windows") "R.exe" else "R"
      path <- file.path(R.home("bin"), name)
      system2(
        path,
        args,
        stdout = if (quiet) NULL else "",
        stderr = if (quiet) NULL else ""
      )
    })
  )

  # add hooks to the package startup
  add_hooks(pkg$package, install_path,
    fix_mcexit = should_enable_parallel_mcexit_fix(pkg))

  libs <- env_path(install_path, .libPaths())

  # We need to set the libpaths in the current R session for examples with
  # install or runtime Sexpr blocks, which may implicitly load the package in
  # the current R session.
  withr::with_libpaths(install_path, action = "prefix", {

  withr::with_envvar(
    c(R_DEFAULT_PACKAGES = "datasets,utils,grDevices,graphics,stats,methods",
      R_LIBS = libs,
      R_LIBS_USER = libs,
      R_LIBS_SITE = libs,
      R_COVR = "true",
      R_TESTS = file.path(R.home("share"), "R", "tests-startup.R")), {


    withCallingHandlers({
      if ("vignettes" %in% type) {
        type <- type[type != "vignettes"]
        run_vignettes(pkg, install_path)
      }

      out_dir <- file.path(install_path, pkg$package)
      if ("examples" %in% type) {
        type <- type[type != "examples"]
        # testInstalledPackage explicitly sets R_LIBS="" on windows, and does
        # not restore it after, so we need to reset it ourselves.
        withr::with_envvar(c(R_LIBS = Sys.getenv("R_LIBS")), {
          result <- tools::testInstalledPackage(pkg$package, outDir = out_dir, types = "examples", lib.loc = install_path, ...)
          if (result != 0L) {
            show_failures(out_dir)
          }
        })
      }
      if ("tests" %in% type) {
        result <- tools::testInstalledPackage(pkg$package, outDir = out_dir, types = "tests", lib.loc = install_path, ...)
        if (result != 0L) {
          show_failures(out_dir)
        }
      }

      # We always run the commands file (even if empty) to load the package and
      # initialize all the counters to 0.
      run_commands(pkg, install_path, code)
    },
    message = function(e) if (quiet) invokeRestart("muffleMessage") else e,
    warning = function(e) if (quiet) invokeRestart("muffleWarning") else e)
    })
    })

  # read tracing files
  trace_files <- list.files(path = install_path, pattern = "^covr_trace_[^/]+$", full.names = TRUE)
  coverage <- merge_coverage(trace_files)
  if (!uses_icc()) {
    res <- run_gcov(pkg$path, quiet = quiet, clean = clean)
  } else {
    res <- run_icov(pkg$path, quiet = quiet)
  }

  coverage <- as_coverage(
    c(coverage, res),
    package = pkg,
    root = root
  )

  if (!clean) {
    attr(coverage, "library") <- install_path
  }

  if (getOption("covr.filter_non_package", TRUE)) {
    coverage <- filter_non_package_files(coverage)
  }

  # Exclude generated files from Rcpp and cpp11 to avoid redundant coverage information
  line_exclusions <- c(
    "src/RcppExports.cpp",
    "R/RcppExports.R",
    "src/cpp11.cpp",
    "R/cpp11.R",
    line_exclusions,
    withr::with_dir(root, parse_covr_ignore())
  )

  exclude(coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = root)
}

#' Convert a coverage dataset to a list
#'
#' @param x a coverage dataset, defaults to running `package_coverage()`.
#' @return A list containing coverage result for each individual file and the whole package
#' @export
coverage_to_list <- function(x = package_coverage()){
  covr_df <- tally_coverage(x)
  file_result <- tapply(covr_df$value, covr_df$filename,
    FUN = function(x) round(sum(x > 0) / length(x) * 100, digits = 2))
  total_result <- round(sum(covr_df$value > 0) / nrow(covr_df) * 100, digits = 2)
  return(list(filecoverage = file_result, totalcoverage = total_result))
}

show_failures <- function(dir) {
  fail_files <- list.files(dir, pattern = "fail$", recursive = TRUE, full.names = TRUE)
  for (file in fail_files) {
    lines <- readLines(file)

    # Skip header lines (until first >)
    lines <- lines[seq(which.min(grepl("^>", lines)), length(lines))]


    # R will only show options("warning.length") number of characters in an
    # error, so show the last characters of that number
    error_header <- paste0("Failure in `", file, "`\n")

    # 9 is the length of `Error: ` + newline + NUL maybe?
    error_length <- getOption("warning.length") - 9
    error_body <- paste(lines, collapse = "\n")

    header_len <- nchar(error_header, "bytes")
    body_len <- nchar(error_body, "bytes")

    error_body <- substr(error_body, body_len - (error_length - header_len), body_len)

    cnd <- structure(list(message = paste0(error_header, error_body)), class = c("covr_error", "error", "condition"))
    stop(cnd)
  }
}

# merge multiple coverage files together. Assumes the order of coverage lines
# is the same in each object, this should always be the case if the objects are
# from the same initial library.
merge_coverage <- function(x) {
  UseMethod("merge_coverage")
}

#' @export
merge_coverage.character <- function(x) {
  coverage_objs <- lapply(x, function(f) {
    as.list(suppressWarnings(readRDS(f)))
  })
  merge_coverage(coverage_objs)
}

#' @export
merge_coverage.list <- function(x) {
  coverage_objs <- x
  if (length(coverage_objs) == 0) {
    return()
  }

  x <- coverage_objs[[1]]
  names <- names(x)
  clean_coverage_tests(x)  # x[[key]]$tests environments modified in-place

  for (y in tail(coverage_objs, -1L)) {

    # only affects coverage produced with options(covr.record_tests = TRUE)
    clean_coverage_tests(y)
    x <- merge_coverage_tests(from = y, into = x)

    for (name in intersect(names, names(y))) {
      if (name == "tests") next
      x[[name]]$value <- x[[name]]$value + y[[name]]$value
    }

    for (name in setdiff(names(y), names)) {
      x[[name]] <- y[[name]]
    }

    names <- union(names, names(y))
  }

  x
}

# Strip allocated, but unused test records from coverage test matrix
#
# The tally of tests that hit each trace is held in a pre-allocated matrix
# which may be padded with unused rows. Start by stripping unused rows:
#
# If tests were not recorded (that is, if `options(covr.record_tests)` was not
# `TRUE` when the coverage was calculated, this function will have no effect.
#
# @param obj A coverage counter environment, within which a $tests$tally matrix
#   may have been allocated, but not entirely populated.
#
clean_coverage_tests <- function(obj) {
  counter_has_tests_tally <- function(counter) !is.null(counter$tests)
  if (is.na(Position(counter_has_tests_tally, obj))) return()

  for (i in seq_along(obj)) {
    if (is.null(val <- obj[[i]]$value)) next
    if (is.null(n <- nrow(obj[[i]]$tests$tally)) || n < val) next
    obj[[i]]$tests$tally <- obj[[i]]$tests$tally[seq_len(val),,drop = FALSE]
  }
}

# Merge recorded tests from one coverage object into another. Because coverage
# objects are environments, these environments will be modified by-reference as
# a side-effect of calling this function.
#
# If tests were not recorded (that is, if `options(covr.record_tests)` was not
# `TRUE` when the coverage was calculated, this function will have no effect.
#
# @param from A coverage counter environment whose tests should be merged into
#   \code{into}
# @param into A coverage counter environment to add tests into
#
merge_coverage_tests <- function(from, into = NULL) {
  if (is.null(from$tests)) return(into)

  # TODO: The x[[name]]$tests$tally matrices are re-allocated with each rbind of
  # additional test hits as each object is merged. This could be avoided by
  # first calculating the total rows needed to store all the merged tests and
  # then allocating a matrix of the appropriate size from the start. In most
  # cases, this amounts to neglegable overhead but is an opportunity for
  # improvement.

  # align tests from coverage objects
  test_idx <- match(names(from$tests), Filter(nchar, names(into$tests)))
  new_test_idx <- if (!length(test_idx)) seq_along(from$tests) else which(is.na(test_idx))
  test_idx[new_test_idx] <- length(into$tests) + seq_along(new_test_idx)

  # append any tests that we haven't encountered in previous objects
  into$tests <- append(into$tests, from$tests[new_test_idx])
  from$tests <- NULL

  # modify trace test tallies
  for (name in intersect(names(into), names(from))) {
    if (name == "tests") next
    from[[name]]$tests$tally[, 1L] <- test_idx[from[[name]]$tests$tally[, 1L]]
    into[[name]]$tests$tally <- rbind(into[[name]]$tests$tally, from[[name]]$tests$tally)
  }

  into
}

parse_type <- function(type) {
  type <- match_arg(type, choices = c("tests", "vignettes", "examples", "all", "none"), several.ok = TRUE)
  if (type %==% "all") {
    type <- c("tests", "vignettes", "examples")
  }

  if (length(type) > 1L) {

    if ("all" %in% type) {
      stop(sQuote("all"), " must be the only type specified", call. = FALSE)
    }

    if ("none" %in% type) {
      stop(sQuote("none"), " must be the only type specified", call. = FALSE)
    }
  }
  type
}

# Run vignettes for a package. This is done in a new process as otherwise the
# finalizer is not called to dump the results. The namespace is first
# explicitly loaded to ensure output even if no vignettes exist.
# @param pkg Package object (from as_package) to run
# @param lib the library path to look in
run_vignettes <- function(pkg, lib) {
  outfile <- file.path(lib, paste0(pkg$package, "-Vignette.Rout"))
  failfile <- paste(outfile, "fail", sep = "." )
  cat("tools::buildVignettes(dir = '", pkg$path, "')\n", file = outfile, sep = "")
  cmd <- paste(shQuote(file.path(R.home("bin"), "R")),
               "CMD BATCH --vanilla --no-timing",
               shQuote(outfile), shQuote(failfile))
  res <- system(cmd)
  if (res != 0) {
    show_failures(dirname(failfile))
  } else {
    file.rename(failfile, outfile)
  }
}

run_commands <- function(pkg, lib, commands) {
  outfile <- file.path(lib, paste0(pkg$package, "-commands.Rout"))
  failfile <- paste(outfile, "fail", sep = "." )
  writeLines(c(
    paste0("library('", pkg$package, "')"),
    commands), con = outfile)
  cmd <- paste(shQuote(file.path(R.home("bin"), "R")),
               "CMD BATCH --vanilla --no-timing",
               shQuote(outfile), shQuote(failfile))
  res <- system(cmd)
  if (res != 0L) {
    show_failures(dirname(failfile))
  } else {
    file.rename(failfile, outfile)
  }
}

# Add hooks to the installed package
# Installed packages have lazy loading code to setup the lazy load database at
# pkg_name/R/pkg_name. This function adds a user level onLoad Hook to the
# package which calls `covr::trace_environment`, so the package environment is
# traced when the package is loaded.
# It also adds a finalizer that saves the tracing information to the package
# namespace environment which is run when the ns is garbage collected or the
# process ends. This ensures the tracing count information will be written
# regardless of how the process terminates.
# @param pkg_name name of the package to add hooks to
# @param lib the library path to look in
# @param fix_mcexit whether to add the fix for mcparallel:::mcexit
add_hooks <- function(pkg_name, lib, fix_mcexit = FALSE,
  record_tests = isTRUE(getOption("covr.record_tests", FALSE))) {

  trace_dir <- paste0("Sys.getenv(\"COVERAGE_DIR\", \"", lib, "\")")

  load_script <- file.path(lib, pkg_name, "R", pkg_name)
  lines <- readLines(file.path(lib, pkg_name, "R", pkg_name))
  lines <- append(lines,
    c(paste0("setHook(packageEvent(pkg, \"onLoad\"), function(...) options(covr.record_tests = ", record_tests, "))"),
      "setHook(packageEvent(pkg, \"onLoad\"), function(...) covr:::trace_environment(ns))",
      paste0("reg.finalizer(ns, function(...) { covr:::save_trace(", trace_dir, ") }, onexit = TRUE)")),
    length(lines) - 1L)

  if (fix_mcexit) {
    lines <- append(lines, sprintf("covr:::fix_mcexit('%s')", trace_dir))
  }

  writeLines(text = lines, con = load_script)
}

#' @export
`[.coverage` <- function(x, ...) {
  structure(NextMethod(), class = "coverage")
}

#' Determine if code is being run in covr
#'
#' covr functions set the environment variable `R_COVR` when they are running.
#' [in_covr()] returns `TRUE` if this environment variable is set and `FALSE`
#' otherwise.
#' @export
#' @examples
#' if (require(testthat)) {
#'   testthat::skip_if(in_covr())
#' }
in_covr <- function() {
  identical(Sys.getenv("R_COVR"), "true")
}
