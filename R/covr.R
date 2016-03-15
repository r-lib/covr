#' @import methods
#' @importFrom stats aggregate na.omit na.pass setNames
#' @importFrom utils capture.output getSrcFilename relist str
NULL

rex::register_shortcuts("covr")

the <- new.env(parent = emptyenv())

the$replacements <- list()

trace_environment <- function(env) {
  clear_counters()

  the$replacements <- c(replacements_S4(env), compact(lapply(ls(env, all.names = TRUE), replacement, env = env)))
  lapply(the$replacements, replace)
}

reset_traces <- function() {
  lapply(the$replacements, reset)
}

save_trace <- function(directory) {
  tmp_file <- tempfile("covr_trace_", tmpdir = directory)
  saveRDS(.counters, file = tmp_file)
}

#' Calculate test coverage for specific function.
#'
#' @param fun name of the function.
#' @param env environment the function is defined in.
#' @param ... expressions to run.
#' @param enc the enclosing environment which to run the expressions.
#' @export
function_coverage <- function(fun, code, env = NULL, enc = parent.frame()) {
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
#' @param flags Compilation flags used in compiling and liking compiled code.
#' @seealso exclusions
#' @export
package_coverage <- function(path = ".",
                             code,
                             type = c("tests", "vignettes", "examples"),
                             relative_path = TRUE,
                             quiet = TRUE,
                             clean = TRUE,
                             exclusions = NULL,
                             exclude_pattern = getOption("covr.exclude_pattern"),
                             exclude_start = getOption("covr.exclude_start"),
                             exclude_end = getOption("covr.exclude_end"),
                             use_subprocess = TRUE,
                             use_try = TRUE,
                             flags = getOption("covr.flags"),
                             ...) {

  pkg <- as_package(path)

  if (missing(type)) {
    type <- "tests"
  }

  type <- match_arg(type, several.ok = TRUE)

  tmp_lib <- tempfile("R_LIBS")
  dir.create(tmp_lib)

  if (is_windows()) {

    # workaround for https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16384
    # LDFLAGS is ignored on Windows and we don't want to override PKG_LIBS if
    # it is set, so use SHLIB_LIBADD
    flags[["SHLIB_LIBADD"]] <- "--coverage"
  }

  if (isTRUE(clean)) {
    on.exit({
      clean_objects(pkg$path)
      clean_gcov(pkg$path)
    })
  }

  withr::with_makevars(flags,
    # install the package in a temporary directory
    tryCatch({
      install.packages(repos = NULL, lib = tmp_lib, pkg$path, INSTALL_opts = c("--example", "--install-tests"), quiet = quiet, ...)
    }, warning = function(e) stop(e)))

  # add hooks to the package startup
  add_hooks(pkg$package, tmp_lib)

  withr::with_envvar(c(R_LIBS_USER = env_path(tmp_lib, Sys.getenv("R_LIBS_USER"))), {
    withr::with_libpaths(tmp_lib, action = "prefix", {
      if ("vignettes" %in% type) {
        type <- type[type != "vignettes"]
        run_vignettes(pkg, tmp_lib)
      }
      if (length(type)) {
        tools::testInstalledPackage(pkg$package, outDir = tmp_lib, types = type, lib.loc = tmp_lib)
      }
    })})

  trace_files <- list.files(path = tmp_lib, pattern = "^covr_trace_", full.names = TRUE)
  structure(class = "coverage", merge_coverage(lapply(trace_files, function(x) as.list(readRDS(x)))))
}

# merge multiple coverage outputs together Assumes the order of coverage lines
# is the same in each object, this should always be the case if the objects are
# from the same initial library.
merge_coverage <- function(...) {
  objs <- as.list(...)
  if (length(objs) == 0) {
    return(objs)
  }

  x <- objs[[1]]
  others <- objs[-1]
  stopifnot(all(lengths(others) == length(x)))

  for (y in others) {
    for (i in seq_along(x)) {
      x[[i]]$value <- x[[i]]$value + y[[i]]$value
    }
  }
  x
}

# Run vignettes for a package. This is done in a new process as otherwise the
# finalizer is not run to dump the results.
# @param pkg Package object (from as_package) to run
# @param lib the library path to look in
run_vignettes <- function(pkg, lib) {
  outfile <- file.path(lib, paste0(pkg$package, "-Vignette.Rout"))
  failfile <- paste(outfile, "fail", sep = "." )
  cat("message(gettextf(\"Running vignettes for package %s\", sQuote('", pkg$package, "')),
      domain = NA)
  tools::buildVignettes(dir = '", pkg$path, "')", file = outfile, sep = "")
  cmd <- paste(shQuote(file.path(R.home("bin"), "R")),
               "CMD BATCH --vanilla --no-timing",
               shQuote(outfile), shQuote(failfile))
  if (.Platform$OS.type == "windows") Sys.setenv(R_LIBS="")
  else cmd <- paste("R_LIBS=", cmd)
  system(cmd)
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
