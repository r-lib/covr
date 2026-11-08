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
#'   \item `covr.failure_lines`: The number of trailing lines of test output
#'     shown in the message and `print()` method of a `covr_error` when tests,
#'     vignettes, examples or `code` fail (default `50`). The full output is
#'     always available in the condition's `$output` field.
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
#'   \item `covr.gcov_partial`: How to count compiled code lines that gcov
#'     reports as only partially executed (e.g. `if (x) f();` when `f()` never
#'     runs). `"covered"` (the default) counts them as covered, `"uncovered"`
#'     counts them as not covered, for requiring every part of a line to run.
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
#'   \item `covr.full_traversal`: If `TRUE` (default `FALSE`), also trace
#'     functions nested inside lists and environments, such as
#'     `fns <- list(a = function(x) x)` or functions defined inside `local()`.
#'     This walks every object in the package, so it is off by default. For
#'     `package_coverage()` it can also be enabled for a package by adding
#'     `Config/covr/full_traversal: true` to its DESCRIPTION; the option takes
#'     precedence when set.
#'
#'   \item `covr.showCfunctions`:
#' }
#'
#'
"_PACKAGE"

#' @import methods
#' @importFrom stats aggregate na.omit na.pass setNames
#' @importFrom utils capture.output getSrcFilename relist str head
NULL

# httr is called through these wrappers rather than imported, so that it is
# only loaded when used. Importing it makes httr and its dependencies load
# time dependencies of covr, which causes a cyclic namespace dependency when
# running coverage on them (#623). The wrappers also allow mocking in tests.
content <- function(...) {
  httr::content(...)
}

RETRY <- function(...) {
  httr::RETRY(...)
}

upload_file <- function(...) {
  httr::upload_file(...)
}

the <- new.env(parent = emptyenv())

the$replacements <- list()

trace_environment <- function(env) {
  clear_counters()

  replacements <- compact(c(
    replacements_S4(env),
    replacements_RC(env),
    replacements_R6(env),
    replacements_S7(env),
    replacements_box(env),
    lapply(ls(env, all.names = TRUE), replacement, env = env)
  ))
  if (isTRUE(getOption("covr.full_traversal", FALSE))) {
    replacements <- c(replacements, replacements_nested(env, replacements))
  }
  the$replacements <- replacements

  lapply(the$replacements, replace)
}

reset_traces <- function() {
  lapply(the$replacements, reset)
}

# Trace files are written under a temporary name and renamed into place, so
# `merge_coverage()` never sees a partially written `covr_trace_*` file. The
# temporary prefix intentionally does not match `^covr_trace_`: leftovers from
# a process killed mid-write are simply ignored.
#
# If serializing the counters fails (e.g. with ALTREP vectors, #509) an error
# marker is written instead, so the main process can report the failed save.
save_trace <- function(directory) {
  final_file <- temp_file("covr_trace_", tmpdir = directory)
  tmp_file <- temp_file(".covr_tmp_", tmpdir = directory)
  on.exit(unlink(tmp_file), add = TRUE)

  tryCatch(
    save_rds(.counters, tmp_file),
    error = function(e) {
      marker <- structure(
        list(message = conditionMessage(e), pid = Sys.getpid()),
        class = "covr_trace_error"
      )
      save_rds(marker, tmp_file)
    }
  )
  if (!file.rename(tmp_file, final_file)) {
    stop("Could not write trace file: ", final_file, call. = FALSE)
  }
  invisible(final_file)
}

save_rds <- function(object, file) {
  saveRDS(object, file = file)
}

#' Convert a counters object to a coverage object
#'
#' @param counters An environment of covr trace results to convert to a coverage
#'   object. If `counters` is not provided, the `covr` namespace value
#'   `.counters` is used.
#' @param ... Additional attributes to include with the coverage object.
#'
as_coverage <- function(counters = NULL, ...) {
  if (missing(counters)) {
    counters <- .counters
  }

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
    if (!is.environment(counters[[i]]$tests)) {
      next
    }
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
#' @return A [coverage] object.
#' @examples
#' add <- function(x, y) { x + y }
#' function_coverage(fun = add, code = NULL) # 0% coverage
#' function_coverage(fun = add, code = add(1, 2) == 3) # 100% coverage
#' @export
function_coverage <- function(
  fun,
  code = NULL,
  env = NULL,
  enc = parent.frame()
) {
  if (is.function(fun)) {
    env <- environment(fun)

    # get name of function, stripping preceding blah:: if needed
    fun <- rex::re_substitutes(
      deparse(substitute(fun)),
      rex::regex(".*:::?"),
      ""
    )
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

  withr::with_envvar(c("R_COVR" = "true"), eval(code, enc))

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
#' @return A [coverage] object.
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
  parent_env = parent.frame()
) {
  env <- new.env(parent = parent_env)

  withr::with_options(c("keep.parse.data.pkgs" = TRUE), {
    lapply(source_files, sys.source, keep.source = TRUE, envir = env)
  })

  trace_environment(env)
  on.exit({
    reset_traces()
    clear_counters()
  })

  withr::with_envvar(
    c("R_COVR" = "true"),
    lapply(test_files, sys.source, keep.source = TRUE, envir = env)
  )

  coverage <- as_coverage(.counters)

  exclude(
    coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = NULL
  )
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
#' @return A [coverage] object.
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
  ...
) {
  src <- tempfile("source.R")
  test <- tempfile("test.R")
  on.exit(file.remove(src, test))
  cat(source_code, file = src)
  cat(test_code, file = test)
  file_coverage(
    src,
    test,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    ...
  )
}

#' Calculate coverage of an environment
#'
#' The functions in `env` are instrumented, then the files in `test_files` are
#' run with [sys.source()] in a child environment of `env`, from the current
#' working directory. Nothing else is set up, so testthat tests that rely on
#' its test runner, e.g. for setup files, snapshots, or the test directory as
#' the working directory (which [testthat::test_path()] uses to find fixtures
#' while testing), should instead be run with [testthat::test_file()] inside
#' [with_coverage()].
#'
#' @param env The environment to be instrumented.
#' @inheritParams file_coverage
#' @return A [coverage] object.
#' @seealso [with_coverage()]
#' @export
environment_coverage <- function(
  env = parent.frame(),
  test_files,
  line_exclusions = NULL,
  function_exclusions = NULL
) {
  exec_env <- new.env(parent = env)

  trace_environment(env)
  on.exit({
    reset_traces()
    clear_counters()
  })

  withr::with_envvar(
    c("R_COVR" = "true"),
    lapply(test_files, sys.source, keep.source = TRUE, envir = exec_env)
  )

  coverage <- as_coverage(.counters)

  exclude(
    coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = NULL
  )
}

#' Calculate coverage of arbitrary code run against an environment
#'
#' `with_coverage()` instruments the functions in `env`, evaluates `code`, and
#' returns the coverage that `code` produced. Unlike [environment_coverage()],
#' which `sys.source()`s a set of files, `code` can be any expression. This
#' makes it possible to measure coverage while running tests with a test runner
#' such as [testthat::test_file()], without having to recreate the runner's
#' infrastructure (reporters, snapshot handling, test environment, ...).
#'
#' Functions are instrumented in place, so every existing reference to them,
#' including ones captured by an environment created by `code` (e.g. the child
#' environment of the namespace that [testthat::test_file()] evaluates tests
#' in), runs the instrumented version. The only requirement is that `code` must
#' not re-create the functions in `env`, e.g. when using
#' [testthat::test_file()] with `package` set the package must not be reloaded
#' (use `load_package = "none"`), as reloading would replace the instrumented
#' functions with fresh, uninstrumented ones.
#'
#' The instrumentation is removed and the counters are cleared when
#' `with_coverage()` exits, even if `code` fails.
#'
#' @param code The code to evaluate while measuring coverage. It is evaluated
#'   lazily, in the calling environment, after `env` has been instrumented.
#' @param env The environment to be instrumented, e.g. a package namespace.
#' @inheritParams file_coverage
#' @return A `coverage` object.
#' @seealso [environment_coverage()]
#' @examples
#' \dontrun{
#' # With a package loaded by pkgload::load_all()
#' ns <- asNamespace("mypkg")
#' with_coverage(
#'   testthat::test_file(
#'     "tests/testthat/test-foo.R",
#'     package = "mypkg",
#'     load_package = "none"
#'   ),
#'   env = ns
#' )
#' }
#' @export
with_coverage <- function(
  code,
  env = parent.frame(),
  line_exclusions = NULL,
  function_exclusions = NULL
) {
  force(env)

  trace_environment(env)
  on.exit({
    reset_traces()
    clear_counters()
  })

  withr::with_envvar(c("R_COVR" = "true"), code)

  coverage <- as_coverage(.counters)

  exclude(
    coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = NULL
  )
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
#' useful for debugging errors. If coverage fails, `install_path` is kept even
#' when `clean = TRUE`, so the test output can be inspected.
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
#'   FALSE`) to help debug test failures. It is not removed if coverage fails.
#' @param allow_failures If `TRUE`, failures or errors when running tests,
#'   vignettes, examples or `code` are reported as warnings (with class
#'   `covr_warning`) and coverage is still returned. Coverage may be incomplete
#'   in this case, as code which would have run after the failure is not
#'   tracked. The default, `FALSE`, throws an error (with class `covr_error`)
#'   on the first failure. The default can be changed with the
#'   `covr.allow_failures` option, e.g. `options(covr.allow_failures = TRUE)`.
#' @return A [coverage] object. If `combine_types = FALSE` and more than one
#'   `type` is run, a list of class `coverages` with one coverage object for
#'   each type, named by type.
#' @seealso [exclusions()] For details on excluding parts of the
#' package from the coverage calculations.
#' @export
package_coverage <- function(
  path = ".",
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
  exclusions,
  pre_clean = TRUE,
  allow_failures = getOption("covr.allow_failures", FALSE)
) {
  if (!missing(exclusions)) {
    warning(
      "`exclusions` is deprecated and will be removed in an upcoming release. Please use `line_exclusions` instead.",
      call. = FALSE,
      domain = NA
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

  # check for compiler
  if (!uses_icc()) {
    flags <- getOption("covr.flags")
  } else if (length(getOption("covr.icov")) > 0L) {
    flags <- getOption("covr.icov_flags")
    # clean up old icov files
    unlink(file.path(pkg$path, "src", "*.dyn"))
    unlink(file.path(pkg$path, "src", "pgopti.*"))
  } else {
    stop("icc is not available")
  }

  if (isTRUE(clean)) {
    # The install directory is only removed on success, so the test output
    # files referenced in failure messages remain available for debugging.
    succeeded <- FALSE
    on.exit(
      {
        clean_objects(pkg$path)
        clean_gcov(pkg$path)
        clean_parse_data()
        if (succeeded) {
          unlink(install_path, recursive = TRUE)
        }
      },
      add = TRUE
    )
  }

  # clean any dlls prior to trying to install
  if (isTRUE(pre_clean)) {
    clean_objects(pkg$path)
  }

  # install the package in a temporary directory
  withr::with_envvar(
    list(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep)),
    withr::with_makevars(flags, assignment = "+=", {
      args <- c(
        "--vanilla",
        "CMD",
        "INSTALL",
        "-l",
        shQuote(install_path),
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
      res <- system2(
        path,
        args,
        stdout = if (quiet) NULL else "",
        stderr = if (quiet) NULL else ""
      )
    })
  )

  if (res != 0) {
    stop("Package installation did not succeed.")
  }

  # add hooks to the package startup
  add_hooks(
    pkg$package,
    install_path,
    fix_mcexit = should_enable_parallel_mcexit_fix(pkg),
    full_traversal = getOption(
      "covr.full_traversal",
      # DESCRIPTION field names are lowercased by `read_description()`
      isTRUE(as.logical(pkg[[tolower("Config/covr/full_traversal")]]))
    )
  )

  libs <- env_path(install_path, .libPaths())

  # Failures collected when `allow_failures` is TRUE, signaled as warnings
  # after the tests have run.
  failures <- list()

  # We need to set the libpaths in the current R session for examples with
  # install or runtime Sexpr blocks, which may implicitly load the package in
  # the current R session.
  withr::with_libpaths(install_path, action = "prefix", {
    withr::with_envvar(
      c(
        R_DEFAULT_PACKAGES = "datasets,utils,grDevices,graphics,stats,methods",
        R_LIBS = libs,
        R_LIBS_USER = libs,
        R_LIBS_SITE = libs,
        R_COVR = "true",
        R_TESTS = file.path(R.home("share"), "R", "tests-startup.R")
      ),
      {
        withCallingHandlers(
          {
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
                result <- tools::testInstalledPackage(
                  pkg$package,
                  outDir = out_dir,
                  types = "examples",
                  lib.loc = install_path,
                  ...
                )
                if (result != 0L) {
                  show_failures(out_dir)
                }
              })
            }
            if ("tests" %in% type) {
              result <- tools::testInstalledPackage(
                pkg$package,
                outDir = out_dir,
                types = "tests",
                lib.loc = install_path,
                ...
              )
              if (result != 0L) {
                show_failures(out_dir)
              }
            }

            # We always run the commands file (even if empty) to load the package and
            # initialize all the counters to 0.
            run_commands(pkg, install_path, code)
          },
          message = function(e) {
            if (quiet) invokeRestart("muffleMessage") else e
          },
          warning = function(e) {
            if (quiet) invokeRestart("muffleWarning") else e
          },
          covr_error = function(e) {
            if (isTRUE(allow_failures)) {
              failures[[length(failures) + 1L]] <<- e
              invokeRestart("covr_continue")
            }
          }
        )
      }
    )
  })

  # read tracing files
  trace_files <- list.files(
    path = install_path,
    pattern = "^covr_trace_[^/]+$",
    full.names = TRUE
  )
  coverage <- withCallingHandlers(
    merge_coverage(trace_files),
    covr_error = function(e) {
      if (isTRUE(allow_failures)) {
        failures[[length(failures) + 1L]] <<- e
        invokeRestart("covr_continue")
      }
    }
  )

  for (failure in failures) {
    warning(structure(
      list(
        message = conditionMessage(failure),
        call = NULL,
        file = failure$file,
        output = failure$output
      ),
      class = c("covr_warning", "warning", "condition")
    ))
  }

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

  coverage <- exclude(
    coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = root
  )

  succeeded <- TRUE
  coverage
}

#' Convert a coverage dataset to a list
#'
#' @param x a coverage dataset, defaults to running `package_coverage()`.
#' @return A list containing coverage result for each individual file and the whole package
#' @export
coverage_to_list <- function(x = package_coverage()) {
  covr_df <- tally_coverage(x)
  file_result <- tapply(covr_df$value, covr_df$filename, FUN = function(x) {
    round(sum(x > 0) / length(x) * 100, digits = 2)
  })
  total_result <- round(
    sum(covr_df$value > 0) / nrow(covr_df) * 100,
    digits = 2
  )
  return(list(filecoverage = file_result, totalcoverage = total_result))
}

#' Convert a coverage dataset to a markdown table
#'
#' Creates a markdown table with the total coverage and the coverage of each
#' file, suitable for a GitHub Actions job summary or a pull request comment.
#' If `base` is given, the table also includes the coverage of `base` and the
#' change from it.
#'
#' @param x a coverage dataset, defaults to running `package_coverage()`.
#' @param base an optional coverage dataset to compare against, e.g. the
#'   coverage of the main branch.
#' @return A character vector of markdown lines, with class `"covr_markdown"`.
#' @examples
#' \dontrun{
#' # In a GitHub Actions step
#' md <- coverage_to_markdown(package_coverage())
#' cat(md, file = Sys.getenv("GITHUB_STEP_SUMMARY"), sep = "\n", append = TRUE)
#' }
#' @export
coverage_to_markdown <- function(x = package_coverage(), base = NULL) {
  head <- coverage_to_list(x)
  files <- names(head$filecoverage)
  head_pct <- c(head$totalcoverage, unname(head$filecoverage))
  rows <- c("Total", markdown_escape(files))
  fmt <- function(p) ifelse(is.na(p), "", sprintf("%.2f%%", p))

  if (is.null(base)) {
    lines <- c(
      "| File | Coverage |",
      "| :--- | ---: |",
      paste0("| ", rows, " | ", fmt(head_pct), " |")
    )
  } else {
    base <- coverage_to_list(base)
    base_pct <- c(
      base$totalcoverage,
      unname(base$filecoverage[match(files, names(base$filecoverage))])
    )
    diff <- head_pct - base_pct
    diff_str <- ifelse(
      is.na(diff),
      "",
      sprintf("%+.2f%%", diff)
    )
    lines <- c(
      "| File | Coverage | Base | Change |",
      "| :--- | ---: | ---: | ---: |",
      paste0(
        "| ",
        rows,
        " | ",
        fmt(head_pct),
        " | ",
        fmt(base_pct),
        " | ",
        diff_str,
        " |"
      )
    )
  }
  structure(lines, class = "covr_markdown")
}

# Escape text for use in a GitHub markdown table cell
markdown_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  gsub("|", "\\|", x, fixed = TRUE)
}

#' @export
print.covr_markdown <- function(x, ...) {
  writeLines(unclass(x))
  invisible(x)
}

show_failures <- function(dir) {
  fail_files <- list.files(
    dir,
    pattern = "fail$",
    recursive = TRUE,
    full.names = TRUE
  )
  for (file in fail_files) {
    withRestarts(stop(covr_error(file)), covr_continue = function() NULL)
  }
}

# Number of trailing output lines shown by default in the message and print()
failure_lines <- function() {
  getOption("covr.failure_lines", 50L)
}

covr_error <- function(file) {
  lines <- readLines(file, warn = FALSE)

  # Skip header lines (until first >)
  prompt <- grep("^>", lines)
  if (length(prompt) > 0L) {
    lines <- lines[seq(prompt[[1L]], length(lines))]
  }

  structure(
    list(
      message = failure_message(file, lines),
      call = NULL,
      file = file,
      output = lines
    ),
    class = c("covr_error", "error", "condition")
  )
}

# R only shows options("warning.length") characters of an error message, so
# keep the message within that (and at most `failure_lines()` lines) and show
# as many lines from the end as fit.
failure_message <- function(file, lines) {
  header <- paste0(
    "Failure in `",
    file,
    "` (full output is in that file and in the `$output` of this condition)\n"
  )
  # 9 is the length of `Error: ` + newline + NUL maybe?
  budget <- getOption("warning.length") - 9 - nchar(header, "chars")
  if (length(lines) == 0L || budget <= 0L) {
    return(header)
  }
  n <- failure_lines()
  if (length(lines) > n) {
    lines <- lines[seq.int(length(lines) - n + 1L, length(lines))]
  }
  # characters in the last k lines, joined by newlines
  size <- rev(cumsum(rev(nchar(lines, "chars") + 1L))) - 1L
  keep <- which(size <= budget)
  if (length(keep) > 0L) {
    lines <- lines[keep[[1L]]:length(lines)]
  } else {
    last <- lines[[length(lines)]]
    lines <- substring(last, nchar(last, "chars") - budget + 1L)
  }
  paste0(header, paste(lines, collapse = "\n"))
}

#' @export
format.covr_error <- function(x, n = failure_lines(), ...) {
  out <- x$output
  total <- length(out)
  if (total > n) {
    out <- out[seq.int(total - n + 1L, total)]
  }
  header <- paste0("<covr_error> Failure in `", x$file, "`")
  if (total > length(out)) {
    header <- paste0(
      header,
      "\n(showing last ",
      length(out),
      " of ",
      total,
      " lines; use `print(x, n = Inf)` or `x$output` for all)"
    )
  }
  paste(c(header, out), collapse = "\n")
}

#' @export
print.covr_error <- function(x, n = failure_lines(), ...) {
  cat(format(x, n = n), "\n", sep = "")
  invisible(x)
}

# Merge multiple coverage objects together. Traces are matched by name; the
# counts of shared traces are summed and traces missing from earlier objects
# are appended.
merge_coverage <- function(x) {
  UseMethod("merge_coverage")
}

#' @export
merge_coverage.character <- function(x) {
  coverage_objs <- lapply(x, read_trace)
  merge_coverage(Filter(Negate(is.null), coverage_objs))
}

# Read one trace file. Returns NULL (after signaling a `covr_error` that can be
# skipped with the `covr_continue` restart) if the file is corrupt or holds an
# error marker written by `save_trace()`.
read_trace <- function(file) {
  fail <- function(reason) {
    cnd <- structure(
      list(
        message = sprintf(
          "Failed to read coverage trace file '%s': %s\nCoverage will be incomplete.",
          file,
          reason
        ),
        call = NULL
      ),
      class = c("covr_error", "error", "condition")
    )
    withRestarts(stop(cnd), covr_continue = function() NULL)
  }

  trace <- tryCatch(
    suppressWarnings(readRDS(file)),
    error = function(e) e
  )
  if (inherits(trace, "error")) {
    return(fail(conditionMessage(trace)))
  }
  if (inherits(trace, "covr_trace_error")) {
    return(fail(sprintf(
      "the subprocess (pid %s) could not save its trace: %s",
      trace$pid,
      trace$message
    )))
  }
  as.list(trace)
}

#' @export
merge_coverage.list <- function(x) {
  if (length(x) == 0) {
    return()
  }

  clean_coverage_tests(x[[1L]])
  Reduce(merge_coverage_pair, x)
}

# Test tallies are held in environments and modified in-place during merging.
merge_coverage_pair <- function(into, from) {
  clean_coverage_tests(from)

  tests <- from$tests
  from <- from[setdiff(names(from), "tests")]
  idx <- match(names(from), names(into))
  shared <- which(!is.na(idx))

  if (!is.null(tests)) {
    test_idx <- match(names(tests), Filter(nchar, names(into$tests)))
    new_test_idx <- if (!length(test_idx)) {
      seq_along(tests)
    } else {
      which(is.na(test_idx))
    }
    test_idx[new_test_idx] <- length(into$tests) + seq_along(new_test_idx)

    into$tests <- append(into$tests, tests[new_test_idx])
    from <- lapply(from, renumber_trace_tests, test_idx)
    into[idx[shared]] <- Map(merge_trace_tests, into[idx[shared]], from[shared])
  }

  # Integer indexing avoids repeated name lookups in the loop.
  for (i in shared) {
    j <- idx[[i]]
    into[[j]]$value <- into[[j]]$value + from[[i]]$value
  }

  added <- is.na(idx)
  into[names(from)[added]] <- from[added]
  into
}

merge_trace_tests <- function(into, from) {
  if (!is.null(from$tests$tally)) {
    into$tests$tally <- rbind(into$tests$tally, from$tests$tally)
  }
  into
}

renumber_trace_tests <- function(trace, test_idx) {
  if (!is.null(trace$tests$tally)) {
    trace$tests$tally[, 1L] <- test_idx[trace$tests$tally[, 1L]]
  }
  trace
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
  if (is.na(Position(counter_has_tests_tally, obj))) {
    return()
  }

  for (i in seq_along(obj)) {
    val <- obj[[i]]$value
    if (length(val) == 0 || is.na(val)) {
      next
    }
    n <- nrow(obj[[i]]$tests$tally)
    if (length(n) == 0 || is.na(n) || n < val) {
      next
    }
    obj[[i]]$tests$tally <- obj[[i]]$tests$tally[seq_len(val), , drop = FALSE]
  }
}

parse_type <- function(type) {
  type <- match_arg(
    type,
    choices = c("tests", "vignettes", "examples", "all", "none"),
    several.ok = TRUE
  )
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
  failfile <- paste(outfile, "fail", sep = ".")
  cat(
    "tools::buildVignettes(dir = '",
    pkg$path,
    "')\n",
    file = outfile,
    sep = ""
  )
  cmd <- paste(
    shQuote(file.path(R.home("bin"), "R")),
    "CMD BATCH --vanilla --no-timing",
    shQuote(outfile),
    shQuote(failfile)
  )
  res <- system(cmd)
  if (res != 0) {
    show_failures(dirname(failfile))
  } else {
    file.rename(failfile, outfile)
  }
}

run_commands <- function(pkg, lib, commands) {
  outfile <- file.path(lib, paste0(pkg$package, "-commands.Rout"))
  failfile <- paste(outfile, "fail", sep = ".")
  writeLines(
    c(
      paste0("library('", pkg$package, "')"),
      commands
    ),
    con = outfile
  )
  cmd <- paste(
    shQuote(file.path(R.home("bin"), "R")),
    "CMD BATCH --vanilla --no-timing",
    shQuote(outfile),
    shQuote(failfile)
  )
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
add_hooks <- function(
  pkg_name,
  lib,
  fix_mcexit = FALSE,
  record_tests = isTRUE(getOption("covr.record_tests", FALSE)),
  full_traversal = FALSE
) {
  trace_dir <- paste0("Sys.getenv(\"COVERAGE_DIR\", \"", lib, "\")")

  load_script <- file.path(lib, pkg_name, "R", pkg_name)
  lines <- readLines(load_script)
  lines <- append(
    lines,
    c(
      paste0(
        "setHook(packageEvent(pkg, \"onLoad\"), function(...) options(covr.record_tests = ",
        record_tests,
        "))"
      ),
      paste0(
        "setHook(packageEvent(pkg, \"onLoad\"), function(...) options(covr.full_traversal = ",
        isTRUE(full_traversal),
        "))"
      ),
      "setHook(packageEvent(pkg, \"onLoad\"), function(...) covr:::trace_environment(ns))",
      paste0(
        "reg.finalizer(ns, function(...) { covr:::save_trace(",
        trace_dir,
        ") }, onexit = TRUE)"
      )
    ),
    length(lines) - 1L
  )

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
