#' @import methods
#' @importFrom stats aggregate na.omit na.pass setNames
#' @importFrom utils capture.output getSrcFilename relist str
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

#' Calculate test coverage for specific function.
#'
#' @param fun name of the function.
#' @param env environment the function is defined in.
#' @param code expressions to run.
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
#' The files in \code{source_files} are first sourced in to a new environment
#' to define functions to be checked. Then they are instrumented to track
#' coverage and the files in the \code{test_files} are sourced.
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

  lapply(source_files,
     sys.source, keep.source = TRUE, envir = env)

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

#' Calculate test coverage for a package
#'
#' @param path file path to the package
#' @param type run the package \sQuote{tests}, \sQuote{vignettes},
#' \sQuote{examples}, \sQuote{all}, or \sQuote{none}. The default is
#' \sQuote{tests}.
#' @param combine_types If \code{TRUE} (the default) the coverage for all types
#' is simply summed into one coverage object. If \code{FALSE} separate objects
#' are used for each type of coverage.
#' @param relative_path whether to output the paths as relative or absolute
#' paths.
#' @param quiet whether to load and compile the package quietly
#' @param clean whether to clean temporary output files after running.
#' @param line_exclusions a named list of files with the lines to exclude from
#' each file.
#' @param function_exclusions a vector of regular expressions matching function
#' names to exclude. Example \code{print\\.} to match print methods.
#' @param code Additional test code to run.
#' @param ... Additional arguments passed to \code{\link[tools]{testInstalledPackage}}
#' @param exclusions \sQuote{Deprecated}, please use \sQuote{line_exclusions} instead.
#' @seealso exclusions
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

  on.exit(clear_counters())

  tmp_lib <- temp_file("R_LIBS")
  dir.create(tmp_lib)

  flags <- getOption("covr.flags")

  if (isTRUE(clean)) {
    on.exit({
      clean_objects(pkg$path)
      clean_gcov(pkg$path)
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
                                             "--no-multiarch"),
                            quiet = quiet))

  # add hooks to the package startup
  add_hooks(pkg$package, tmp_lib)

  libs <- env_path(tmp_lib, .libPaths())

  withr::with_envvar(
    c(R_DEFAULT_PACKAGES = "datasets,utils,grDevices,graphics,stats,methods",
      R_LIBS = libs,
      R_LIBS_USER = libs,
      R_LIBS_SITE = libs), {


    withCallingHandlers({
      if ("vignettes" %in% type) {
        type <- type[type != "vignettes"]
        run_vignettes(pkg, tmp_lib)
      }

      if ("examples" %in% type) {
        type <- type[type != "examples"]
        # testInstalledPackage explicitly sets R_LIBS="" on windows, and does
        # not restore it after, so we need to reset it ourselves.
        withr::with_envvar(c(R_LIBS = Sys.getenv("R_LIBS")), {
          tools::testInstalledPackage(pkg$package, outDir = tmp_lib, types = "examples", lib.loc = tmp_lib, ...)
        })
      }
      if ("tests" %in% type) {
        tools::testInstalledPackage(pkg$package, outDir = tmp_lib, types = "tests", lib.loc = tmp_lib, ...)
      }

      run_commands(pkg, tmp_lib, code)
    },
    message = function(e) if (quiet) invokeRestart("muffleMessage") else e,
    warning = function(e) if (quiet) invokeRestart("muffleWarning") else e)
    })

  # read tracing files
  trace_files <- list.files(path = tmp_lib, pattern = "^covr_trace_[^/]+$", full.names = TRUE)
  coverage <- merge_coverage(lapply(trace_files, function(x) as.list(readRDS(x))))
  coverage <- structure(c(coverage, run_gcov(pkg$path, quiet = quiet)),
    class = "coverage",
    package = pkg,
    relative = relative_path)

  # Exclude both RcppExports to avoid reduntant coverage information
  line_exclusions <- c("src/RcppExports.cpp", "R/RcppExports.R", line_exclusions)

  exclude(coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = if (isTRUE(relative_path)) pkg$path else NULL)
}

# merge multiple coverage outputs together Assumes the order of coverage lines
# is the same in each object, this should always be the case if the objects are
# from the same initial library.
merge_coverage <- function(...) {
  objs <- as.list(...)
  if (length(objs) == 0) {
    return()
  }

  x <- objs[[1]]
  others <- objs[-1]

  if (getRversion() < "3.2.0") {
    lengths <- function(x, ...) vapply(x, length, integer(1L))
  }
  stopifnot(all(lengths(others) == length(x)))

  for (y in others) {
    for (i in seq_along(x)) {
      x[[i]]$value <- x[[i]]$value + y[[i]]$value
    }
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
    stop("Error running Vignettes:\n", paste(readLines(failfile), collapse = "\n"))
  } else {
    file.rename(failfile, outfile)
  }
}

run_commands <- function(pkg, lib, commands) {
  outfile <- file.path(lib, paste0(pkg$package, "-commands.Rout"))
  failfile <- paste(outfile, "fail", sep = "." )
  cat(
    "library('", pkg$package, "')\n",
    commands, "\n", file = outfile, sep = "")
  cmd <- paste(shQuote(file.path(R.home("bin"), "R")),
               "CMD BATCH --vanilla --no-timing",
               shQuote(outfile), shQuote(failfile))
  res <- system(cmd)
  if (res != 0) {
    stop("Error running commands:\n", paste(readLines(failfile), collapse = "\n"))
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
add_hooks <- function(pkg_name, lib) {
  load_script <- file.path(lib, pkg_name, "R", pkg_name)
  lines <- readLines(file.path(lib, pkg_name, "R", pkg_name))
  lines <- append(lines,
    c("setHook(packageEvent(pkg, \"onLoad\"), function(...) covr:::trace_environment(ns))",
      paste0("reg.finalizer(ns, function(...) { covr:::save_trace(\"", lib, "\") }, onexit = TRUE)")),
    length(lines) - 1L)
  writeLines(text = lines, con = load_script)
}
