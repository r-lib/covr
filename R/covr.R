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

  on.exit(reset(replacement), add = TRUE)

  replace(replacement)

  eval(code, enc)

  res <- as.list(.counters)
  clear_counters()

  for (i in seq_along(res)) {
    display_name(res[[i]]$srcref) <- generate_display_name(res[[i]], NULL)
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
                             flags = c(CPPFLAGS = "-O0 -fprofile-arcs -ftest-coverage",
                               FFLAGS = "-O0 -fprofile-arcs -ftest-coverage",
                               FCFLAGS = "-O0 -fprofile-arcs -ftest-coverage",
                               LDFLAGS = "--coverage")) {

  pkg <- as_package(path)

  if (missing(type)) {
    type <- "test"
  }

  type <- match_arg(type, several.ok = TRUE)

  tmp_lib <- tempfile("R_LIBS")
  dir.create(tmp_lib)

  coverage <- list()

  if (is_windows()) {

    # workaround for https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16384
    # LDFLAGS is ignored on Windows and we don't want to override PKG_LIBS if
    # it is set, so use SHLIB_LIBADD
    flags[["SHLIB_LIBADD"]] <- "--coverage"
  }

  withr::with_makevars(flags,
    # install the package in a temporary directory
    install.packages(repos = NULL, lib = tmp_lib, pkg$path, INSTALL_opts = c("--example", "--install-tests"), quiet = quiet)
    )
  # add hooks to the package startup
  add_hooks(pkg$package, tmp_lib)

  withr::with_envvar(c(R_LIBS_USER = env_path(tmp_lib, Sys.getenv("R_LIBS_USER"))), {
    withr::with_libpaths(tmp_lib, action = "prefix", {
                           tools::testInstalledPackage(pkg$package, outDir = tmp_lib, types = type, lib.loc = tmp_lib)
    })})
}

add_hooks <- function(pkg_name, lib) {
  load_script <- file.path(lib, pkg_name, "R", pkg_name)
  lines <- readLines(file.path(lib, pkg_name, "R", pkg_name))
  lines <- append(lines, c("setHook(packageEvent(pkg, \"onLoad\"), function(...) covr:::trace_environment(ns))",
                           paste0("reg.finalizer(ns, function(...) { str(\"HI!\");covr:::save_trace(\"", lib, "\") }, onexit = TRUE)")),
                  length(lines) - 1L)
  writeLines(text = lines, con = load_script)
}
