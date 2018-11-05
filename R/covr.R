#' covr: Test coverage for packages
#'
#' covr tracks and reports code coverage for your package and (optionally)
#' upload the results to a coverage service like 'Codecov' <http://codecov.io> or
#' 'Coveralls' <http://coveralls.io>. Code coverage is a measure of the amount of
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
"_PACKAGE"

#' @import methods
#' @importFrom stats aggregate na.omit na.pass setNames
#' @importFrom utils capture.output getSrcFilename relist str head
NULL

rex::register_shortcuts("covr")

the <- new.env(parent = emptyenv())

the$replacements <- list()

trace_environment <- function(env) {
  clear_counters()

  the$replacements <- compact(c(
      replacements_S4(env),
      replacements_RC(env),
      replacements_R6(env),
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

#' Calculate test coverage for a specific function.
#'
#' @param fun name of the function.
#' @param code expressions to run.
#' @param env environment the function is defined in.
#' @param enc the enclosing environment which to run the expressions.
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
  eval(code, enc)
  structure(as.list(.counters), class = "coverage")
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

  lapply(test_files,
    sys.source, keep.source = TRUE, envir = env)

  coverage <- structure(as.list(.counters), class = "coverage")

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

  lapply(test_files,
    sys.source, keep.source = TRUE, envir = exec_env)

  coverage <- structure(as.list(.counters), class = "coverage")

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
#' be use a patched `parallel:::mcexit`. This is done automatically if the
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
#' paths.
#' @param quiet whether to load and compile the package quietly, useful for
#' debugging errors.
#' @param clean whether to clean temporary output files after running, mainly
#' useful for debugging errors.
#' @param line_exclusions a named list of files with the lines to exclude from
#' each file.
#' @param function_exclusions a vector of regular expressions matching function
#' names to exclude. Example `print\\\.` to match print methods.
#' @param code A character vector of additional test code to run.
#' @param batch whether to execute commands using \code{R CMD BATCH}, defaults to
#' \code{TRUE}.
#' @param ... Additional arguments passed to [tools::testInstalledPackage()].
#' @param exclusions \sQuote{Deprecated}, please use \sQuote{line_exclusions} instead.
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
                             batch = TRUE,
                             ...,
                             exclusions) {

  if (!missing(exclusions)) {
    warning(paste0("`exclusions` is deprecated and will be removed in an upcoming
      release. ", "Please use `line_exclusions` instead."), call. = FALSE,
      domain = NA)
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

  tmp_lib <- temp_file("R_LIBS")
  dir.create(tmp_lib)

  flags <- getOption("covr.flags")

  # check for compiler
  if (!uses_icc()) {
    flags <- getOption("covr.flags")
  }
  else {
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
      unlink(tmp_lib, recursive = TRUE)
    }, add = TRUE)
  }

  # clean any dlls prior to trying to install
  clean_objects(pkg$path)

  # install the package in a temporary directory
  withr::with_makevars(flags, assignment = "+=",
    utils::install.packages(repos = NULL,
                            lib = tmp_lib,
                            pkg$path,
                            type = "source",
                            INSTALL_opts = c("--example",
                                             "--install-tests",
                                             "--with-keep.source",
                                             "--with-keep.parse.data",
                                             "--no-multiarch"),
                            quiet = quiet))

  # add hooks to the package startup
  add_hooks(pkg$package, tmp_lib,
    fix_mcexit = should_enable_parallel_mcexit_fix(pkg))

  libs <- env_path(tmp_lib, .libPaths())

  withr::with_envvar(
    c(R_DEFAULT_PACKAGES = "datasets,utils,grDevices,graphics,stats,methods",
      R_LIBS = libs,
      R_LIBS_USER = libs,
      R_LIBS_SITE = libs,
      R_COVR = "true"), {


    withCallingHandlers({
      if ("vignettes" %in% type) {
        type <- type[type != "vignettes"]
        run_vignettes(pkg, tmp_lib)
      }

      out_dir <- file.path(tmp_lib, pkg$package)
      if ("examples" %in% type) {
        type <- type[type != "examples"]
        # testInstalledPackage explicitly sets R_LIBS="" on windows, and does
        # not restore it after, so we need to reset it ourselves.
        withr::with_envvar(c(R_LIBS = Sys.getenv("R_LIBS")), {
          result <- tools::testInstalledPackage(pkg$package, outDir = out_dir, types = "examples", lib.loc = tmp_lib, ...)
          if (result != 0L) {
            show_failures(out_dir)
          }
        })
      }
      if ("tests" %in% type) {
        result <- tools::testInstalledPackage(pkg$package, outDir = out_dir, types = "tests", lib.loc = tmp_lib, ...)
        if (result != 0L) {
          show_failures(out_dir)
        }
      }

      # We always run the commands file (even if empty) to load the package and
      # initialize all the counters to 0.
      run_commands(pkg, tmp_lib, code, batch)
    },
    message = function(e) if (quiet) invokeRestart("muffleMessage") else e,
    warning = function(e) if (quiet) invokeRestart("muffleWarning") else e)
    })

  # read tracing files
  trace_files <- list.files(path = tmp_lib, pattern = "^covr_trace_[^/]+$", full.names = TRUE)
  coverage <- merge_coverage(trace_files)
  if (!uses_icc()) {
    res <- run_gcov(pkg$path, quiet = quiet)
  } else {
    res <- run_icov(pkg$path, quiet = quiet)
  }

  coverage <- structure(c(coverage, res),
      class = "coverage",
      package = pkg,
      relative = relative_path)

  if (!clean) {
    attr(coverage, "library") <- tmp_lib
  }

  coverage <- filter_non_package_files(coverage)

  # Exclude both RcppExports to avoid redundant coverage information
  line_exclusions <- c("src/RcppExports.cpp", "R/RcppExports.R", line_exclusions, parse_covr_ignore())

  exclude(coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = if (isTRUE(relative_path)) pkg$path else NULL)
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
merge_coverage <- function(files) {
  nfiles <- length(files)
  if (nfiles == 0) {
    return()
  }

  x <- readRDS(files[1])
  x <- as.list(x)
  if (nfiles == 1) {
    return(x)
  }

  names <- names(x)
  for (i in 2:nfiles) {
    y <- readRDS(files[i])
    for (name in intersect(names, names(y))) {
      x[[name]]$value <- x[[name]]$value + y[[name]]$value
    }
    for (name in setdiff(names(y), names)) {
      x[[name]] <- y[[name]]
    }
    names <- union(names, names(y))
    y <- NULL
  }

  x
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

run_commands <- function(pkg, lib, commands, batch) {
  outfile <- file.path(lib, paste0(pkg$package, "-commands.Rout"))
  failfile <- paste(outfile, "fail", sep = "." )
  cat(
    "library('", pkg$package, "')\n",
    commands, "\n", file = outfile, sep = "")
  if (batch) {
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
  else {
    cmd <- paste(shQuote(file.path(R.home("bin"), "RScript")), shQuote(outfile))
    res <- system(cmd)
    if (res != 0L) stop("Failed running code coverage.")
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
add_hooks <- function(pkg_name, lib, fix_mcexit = FALSE) {
  trace_dir <- paste0("Sys.getenv(\"COVERAGE_DIR\", \"", lib, "\")")

  load_script <- file.path(lib, pkg_name, "R", pkg_name)
  lines <- readLines(file.path(lib, pkg_name, "R", pkg_name))
  lines <- append(lines,
    c("setHook(packageEvent(pkg, \"onLoad\"), function(...) covr:::trace_environment(ns))",
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
