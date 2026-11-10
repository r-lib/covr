#' covr: Test coverage for packages
#'
#' covr tracks and reports code coverage for your package and (optionally)
#' upload the results to a coverage service like 'Codecov' <https://about.codecov.io> or
#' 'Coveralls' <https://coveralls.io>. Code coverage is a measure of the amount of
#' code being exercised by a set of tests. It is an indirect measure of test
#' quality and completeness. This package is compatible with any testing
#' methodology or framework and tracks coverage of both R code and compiled
#' C, C++, Fortran and Rust code.
#'
#' A coverage report can be used to inspect coverage for each line in your
#' package. Using `report()` requires the additional dependency `htmltools`.
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
#'   \item `covr.branch_coverage`: If `TRUE` (default `FALSE`), also record
#'     which branches of each `if` and `switch()` in R code were taken. This
#'     is experimental. It must be set before the code is instrumented, e.g.
#'     before calling `package_coverage()`. For more details, see
#'     `?covr.branch_coverage`.
#'
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
#'   \item `covr.fix_parallel_mcexit`: Whether to include code run in processes
#'     forked by \pkg{parallel}'s `mclapply()`, `mcparallel()` and related
#'     functions, by patching `parallel:::mcexit`. By default
#'     `package_coverage()` does this if the package uses \pkg{parallel}, and
#'     the functions that measure coverage in the current session, such as
#'     `file_coverage()`, always do. The environment variable
#'     `COVR_FIX_PARALLEL_MCEXIT` takes precedence over this option. Not
#'     supported on Windows.
#'
#'   \item `covr.flags`:
#'
#'   \item `covr.gcov`: Path to the gcov executable. Defaults to the gcov found
#'     on your `PATH`, or `NA` if there is none. If the appropriate gcov version
#'     is not on your path you can use this option to set the appropriate
#'     location. If set to `""` it will turn off coverage of compiled code. If
#'     `NA`, covr throws an error if any compiled coverage files (`.gcno`)
#'     exist.
#'
#'   \item `covr.gcov_additional_paths`:
#'
#'   \item `covr.gcov_args`:
#'
#'   \item `covr.gcov_partial`: How to count compiled code lines that gcov
#'     reports as only partially executed (e.g. `if (x) f();` when `f()` never
#'     runs). `"covered"` (the default) counts them as covered, `"uncovered"`
#'     counts them as not covered, for requiring every part of a line to run.
#'     This works with both gcc's gcov and llvm-cov (the gcov on macOS).
#'     llvm-cov can't tell apart code that only runs when a C++ exception is
#'     thrown, so lines that create objects with destructors may also count as
#'     partially executed.
#'
#'   \item `covr.llvm_cov`: Path to the `llvm-cov` used to read the coverage
#'     of Rust code. Defaults to the one of the Rust toolchain, installed with
#'     `rustup component add llvm-tools`, or for Rust installed without rustup
#'     (e.g. with `apt-get install cargo rustc`), to the one on the `PATH` with
#'     the same LLVM version as rustc, e.g. `llvm-cov-18`. If set to `""` the
#'     Rust code isn't instrumented, which turns off its coverage.
#'
#'   \item `covr.llvm_profdata`: Path to the `llvm-profdata` used to merge the
#'     coverage counts of Rust code. Found like `covr.llvm_cov`.
#'
#'   \item `covr.report_colors`: A named character vector with the colors of
#'     covered and missed lines in [report()] and [file_report()], and of the
#'     coverage percentages printed in the console, e.g.
#'     `c(covered = "#0072B2", missed = "#E69F00")` for blue and orange, which
#'     are easier to tell apart than the default green and red with color
#'     vision deficiency. Either element can be left out to keep its default.
#'     An optional `partial` element sets the color of partial coverage (at
#'     least 75% but less than 90%), which otherwise follows `covered`, or is
#'     yellow in the console if `covered` isn't set either. Transparency is
#'     ignored. In terminals with only 8 colors, the console uses the closest
#'     of those colors.
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
#'   \item `covr.install_instrument`: If `FALSE` (default `TRUE`, or the value
#'     of the environment variable `COVR_INSTALL_INSTRUMENT`),
#'     `package_coverage()` installs a package as usual and instruments it each
#'     time a process loads it, rather than once after installing it.
#'
#'   \item `covr.install_compile`: If `FALSE` (default `TRUE`, or the value of
#'     the environment variable `COVR_INSTALL_COMPILE`), `package_coverage()`
#'     doesn't byte-compile the instrumented functions of a package after
#'     installing it, so each process that runs them compiles them with the
#'     JIT instead.
#'
#'   \item `covr.showCfunctions`:
#' }
#'
#'
"_PACKAGE"

#' @import methods
#' @importFrom stats aggregate ave na.omit na.pass setNames
#' @importFrom utils capture.output getSrcFilename relist str head
NULL

# httr is called through these wrappers rather than imported, so that it is
# only loaded when used. Importing it makes httr and its dependencies load
# time dependencies of covr, which causes a cyclic namespace dependency when
# running coverage on them (#623). The wrappers also allow mocking in tests.
content <- function(...) {
  httr::content(...)
}

http_error <- function(...) {
  httr::http_error(...)
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
  # Tracing an environment that is already traced, e.g. when
  # `pkgload::load_all()` re-fires the onLoad hook, keeps the counts and only
  # instruments the functions that are not instrumented yet, such as functions
  # added or replaced since (#641).
  if (!identical(the$traced_env, env)) {
    clear_counters()
    the$replacements <- list()
  }

  replacements <- compact(c(
    replacements_S4(env),
    replacements_RC(env),
    replacements_R6(env),
    replacements_S7(env),
    replacements_box(env),
    lapply(inactive_names(env), replacement, env = env)
  ))
  if (isTRUE(getOption("covr.full_traversal", FALSE))) {
    replacements <- c(replacements, replacements_nested(env, replacements))
  }
  # Keep the earlier replacements, which hold the originals of the functions
  # traced before.
  the$replacements <- c(the$replacements, replacements)
  the$traced_env <- env

  invisible(lapply(replacements, replace))
}

# The function that the counters added by `trace_calls()` call: the `.Call`
# symbol, or `base::.Call` if a `.Call` function found from `env` would be
# called in place of the primitive, e.g. one that a package defines to wrap
# the calls to its compiled code, as parzer does. `replacement()` checks this
# once for each traced function, from its enclosing environment, which is
# cheaper than looking up `base::.Call` in every count.
dot_call <- function(env) {
  fun <- get0(".Call", envir = env, mode = "function")
  if (is.null(fun) || identical(fun, base::.Call)) {
    as.symbol(".Call")
  } else {
    quote(base::.Call)
  }
}

reset_traces <- function() {
  the$traced_env <- NULL
  # Undo in reverse order, so a function replaced more than once ends up with
  # the original from its first replacement.
  lapply(rev(the$replacements), reset)
}

# Trace files are written under a temporary name and renamed into place, so
# `merge_coverage()` never sees a partially written `covr_trace_*` file. The
# temporary prefix intentionally does not match `^covr_trace_`: leftovers from
# a process killed mid-write are simply ignored.
#
# If serializing the counters fails (e.g. with ALTREP vectors, #509), or the
# process can't count the code it runs (`the$trace_error`, see
# `check_saved_dot_call()`), an error marker is written instead, so the main
# process can report it.
save_trace <- function(directory) {
  final_file <- temp_file("covr_trace_", tmpdir = directory)
  tmp_file <- temp_file(".covr_tmp_", tmpdir = directory)
  on.exit(unlink(tmp_file), add = TRUE)

  sync_counts()
  tryCatch(
    {
      if (!is.null(the$trace_error)) {
        stop(the$trace_error, call. = FALSE)
      }
      save_rds(portable_srcfiles(.counters), tmp_file)
    },
    error = function(e) {
      marker <- structure(
        list(message = conditionMessage(e), pid = Sys.getpid()),
        class = "covr_trace_error"
      )
      save_rds(marker, tmp_file)
    }
  )
  if (!file.rename(tmp_file, final_file)) {
    covr_abort("Can't write trace file {.path {final_file}}.")
  }
  invisible(final_file)
}

save_rds <- function(object, file) {
  saveRDS(object, file = file)
}

# Returns a copy of `x` in which the srcfiles are replaced by `copy_srcfile()`.
#
# The srcfiles of an installed package are restored from its lazy-load
# database, with promises to load their `lines` and `parseData`. These are
# evaluated in an environment that references every environment restored from
# the database, such as environments in the package namespace and the closure
# environments of objects created when the package was built. Saving the
# promises would save the contents of all of these environments too, which can
# be large, and crashes R if they hold objects that were already finalized when
# the trace is saved on exit, e.g. data read with arrow (#602).
#
# The srcfiles are found by the reference hook of `serialize()`, so they are
# replaced wherever they are, e.g. in the calls of recorded tests.
portable_srcfiles <- function(x) {
  srcfiles <- list()
  serialized <- serialize(x, NULL, refhook = function(env) {
    if (inherits(env, "srcfile")) {
      id <- address(env)
      srcfiles[[id]] <<- env
      id
    }
  })
  copies <- new.env(parent = emptyenv())
  unserialize(serialized, refhook = function(id) {
    copy_srcfile(srcfiles[[id]], copies)
  })
}

# A copy of `srcfile` that only holds what is needed to report coverage: its
# atomic values, such as its file name and lines, and copies of the srcfiles it
# references, such as the `original` of a `srcfilealias`. Its parse data and
# anything packages added to it are left out, e.g. this.path adds an
# environment with a promise referencing the srcfile. Only R's promise to
# load `lines` is forced; other promises and active bindings could run
# arbitrary code while R exits.
#
# `copies` holds the copies made so far by the address of their srcfile, so
# the srcfiles of the files of a package share the copy of the srcfile they are
# an alias of, which holds the lines of all the files. A copy is added before
# its bindings are copied, so srcfiles that reference each other don't recurse
# forever.
copy_srcfile <- function(srcfile, copies) {
  id <- address(srcfile)
  if (!is.null(copies[[id]])) {
    return(copies[[id]])
  }
  copy <- new.env(parent = emptyenv())
  class(copy) <- class(srcfile)
  copies[[id]] <- copy
  for (name in setdiff(ls(srcfile, all.names = TRUE), "parseData")) {
    if (
      bindingIsActive(name, srcfile) ||
        (name != "lines" && is_unforced_promise(srcfile, name))
    ) {
      next
    }
    value <- get(name, envir = srcfile, inherits = FALSE)
    if (is.environment(value) && inherits(value, "srcfile")) {
      assign(name, copy_srcfile(value, copies), envir = copy)
    } else if (
      is.null(value) ||
        is.atomic(value) &&
          all(vapply(attributes(value), is.atomic, logical(1)))
    ) {
      assign(name, value, envir = copy)
    }
  }
  copy
}

# Called from the loader script of the instrumented package (see `add_hooks()`)
# while its namespace is loaded. The finalizer saves the trace when the
# namespace is garbage collected or R exits normally. Until then a
# `covr_pending_<pid>_*` marker exists in `directory`, so `package_coverage()`
# can report processes that loaded the package but never saved their trace,
# e.g. because they were killed (#438). Markers are owned by the process whose
# pid is in their name; forked children inherit the finalizer but not the
# parent's markers, so `save_trace_and_clear()` leaves those alone.
#
# `directory` (from `COVERAGE_DIR`) is fixed when the package loads, so the
# marker and the trace end up in the same place. A marker that can't be created
# is not worth a warning during package load; the trace save fails later too.
register_trace <- function(ns, directory) {
  pid <- Sys.getpid()
  pending <- temp_file(paste0("covr_pending_", pid, "_"), tmpdir = directory)
  suppressWarnings(file.create(pending))
  reg.finalizer(
    ns,
    function(...) save_trace_and_clear(directory),
    onexit = TRUE
  )
  invisible(pending)
}

# Also used by the patched `parallel:::mcexit()` (see `fix_mcexit()`), as forked
# workers exit without running finalizers. A worker that loads the package after
# forking creates its own marker, which is removed here.
save_trace_and_clear <- function(directory) {
  res <- save_trace(directory)
  unlink(list.files(
    directory,
    pattern = pending_pattern(Sys.getpid()),
    full.names = TRUE
  ))
  invisible(res)
}

pending_pattern <- function(pid) {
  paste0("^covr_pending_", pid, "_")
}

# The markers of processes that loaded the package but did not save their
# trace. Markers of this process are ignored; it can load the instrumented
# package (e.g. for a `\Sexpr` in an example) but only saves its trace on exit.
unsaved_traces <- function(directory) {
  markers <- list.files(directory, pattern = "^covr_pending_")
  markers[!grepl(pending_pattern(Sys.getpid()), markers)]
}

#' Convert a counters object to a coverage object
#'
#' @param counters An environment of covr trace results to convert to a coverage
#'   object.
#' @param ... Additional attributes to include with the coverage object.
#'
as_coverage <- function(counters, ...) {
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
  # `[[` rather than `$`, which would partially match the key of a trace in a
  # file whose name starts with "branches"
  branches <- as_branch_list(counters[["branches"]])
  counters$branches <- NULL

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
  structure(
    counters,
    tests = tests,
    branches = branches,
    class = "coverage"
  )
}

# Merge the traces saved in `directory` by other processes, into `counters` if
# given.
merge_traces <- function(directory, counters = NULL) {
  trace_files <- list.files(
    directory,
    pattern = "^covr_trace_",
    full.names = TRUE
  )
  traces <- merge_coverage(trace_files)
  if (is.null(counters)) {
    traces
  } else if (is.null(traces)) {
    counters
  } else {
    merge_coverage(list(counters, traces))
  }
}

# Warn, with class `covr_unsaved_trace`, about the processes in `directory`
# that did not save their trace. `subject` says what they did.
warn_unsaved_traces <- function(directory, subject, hint) {
  n <- length(unsaved_traces(directory))
  if (n > 0) {
    covr_warn(
      c(
        "Can't find coverage from {n} R process{?es} that {subject}.",
        i = "Coverage is lost if a process is killed or outlives the tests.",
        i = hint
      ),
      class = "covr_unsaved_trace"
    )
  }
}

# Evaluate `code` and return the coverage it produced from the current traces.
# Unless disabled (see should_enable_parallel_mcexit_fix()), this includes code
# run in processes forked by parallel's mclapply(), mcparallel() etc.
collect_coverage <- function(code) {
  if (!should_enable_parallel_mcexit_fix()) {
    withr::with_envvar(c("R_COVR" = "true"), code)
    sync_counts()
    return(as_coverage(.counters))
  }

  trace_dir <- tempfile("covr_traces_")
  dir.create(trace_dir)
  restore_forks <- trace_forks(trace_dir)
  on.exit({
    restore_forks()
    unlink(trace_dir, recursive = TRUE)
  })

  withr::with_envvar(c("R_COVR" = "true"), code)

  sync_counts()
  counters <- as.list(.counters)
  as_coverage(merge_traces(trace_dir, counters))
}

#' Calculate test coverage for a specific function.
#'
#' @param fun name of the function.
#' @param code expressions to run.
#' @param env environment the function is defined in.
#' @param enc the enclosing environment which to run the expressions.
#' @inheritSection file_coverage Parallel code
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

  collect_coverage(eval(code, enc))
}

#' Calculate test coverage for sets of files
#'
#' The files in `source_files` are first sourced into a new environment
#' to define functions to be checked. Then they are instrumented to track
#' coverage and the files in `test_files` are run with `runner`.
#' @param source_files Character vector of source files with function
#'   definitions to measure coverage. Can also include compiled files from a
#'   package's `src/` directory; see the compiled code section.
#' @param test_files Character vector of test files with code to test the
#'   functions
#' @param parent_env The parent environment to use when sourcing the files.
#'   If `source_files` includes compiled files, the default is the namespace
#'   of their package.
#' @param runner A function used to run each test file, called as
#'   `runner(file, env = env)`, where `env` is the environment the
#'   `source_files` were sourced into. The default sources the file into `env`
#'   with [sys.source()]. Use `runner = testthat::test_file` to run testthat
#'   tests with testthat's test runner; see the testthat tests section.
#' @inheritParams package_coverage
#' @section Parallel code:
#' Code run in processes forked by [parallel::mclapply()],
#' `parallel::mcparallel()` and related functions (not available on Windows)
#' is included in the coverage. While the code runs, `parallel:::mcfork` and
#' `parallel:::mcexit` are patched so that the forked processes save their
#' counts when they exit. To turn this off, set the environment variable
#' `COVR_FIX_PARALLEL_MCEXIT` or the option `covr.fix_parallel_mcexit` to
#' `FALSE`.
#' @section testthat tests:
#' By default the test files are run with [sys.source()], not with testthat's
#' test runner, so features that need the runner don't work. In particular,
#' `testthat::expect_snapshot()` is skipped ("Can't compare snapshot to
#' reference when testing interactively").
#'
#' To use these features, run the test files with [testthat::test_file()]:
#'
#' ```r
#' file_coverage(
#'   "R/my_functions.R",
#'   "tests/test-my_functions.R",
#'   runner = testthat::test_file
#' )
#' ```
#'
#' The tests then run in a child of the environment the source files were
#' sourced into, and snapshots are saved in a `_snaps` directory next to the
#' test file. `expect_snapshot()` also needs testthat's 3rd edition (e.g.
#' `testthat::local_edition(3)` in the tests), and is skipped unless the
#' `NOT_CRAN` environment variable is `"true"`.
#'
#' For more control, source the files yourself and use [with_coverage()].
#' @section Files from a package:
#' To make the package's other functions available, load the package (e.g.
#' with `pkgload::load_all()`) and use `parent_env = asNamespace("pkg")`.
#' Calls from other package files use the namespace's untraced functions, so
#' don't count. `devtools::test_coverage_active_file()` measures the coverage
#' of one file of a package without this limitation.
#' @section Compiled code:
#' [environment_coverage()] and [with_coverage()] include the compiled code in
#' the coverage of the namespace of a package loaded with `pkgload::load_all()`
#' (e.g. by `devtools::load_all()`), so `devtools::test_coverage_active_file()`
#' also works for files in `src/`. With compiled files in `source_files`,
#' `file_coverage()` loads their package with `pkgload::load_all()` and reports
#' the coverage of those files, without needing devtools:
#'
#' ```r
#' file_coverage("src/foo.c", "tests/testthat/test-foo.R")
#' ```
#'
#' The compiled code is measured with gcov in the current session, which is
#' much faster than [package_coverage()]. An instrumented copy of the package
#' is built in the session's temporary directory, leaving the package's own
#' build untouched, and later runs only recompile the files that changed.
#' While the code runs, the namespace's native routines use the instrumented
#' DLL instead of the package's own. Routines that were looked up some other
#' way, e.g. stored by `.onLoad()` or found by other packages with
#' `R_GetCCallable()`, keep using the package's DLL, so their code isn't
#' counted. Set `options(covr.gcov = "")` to leave out compiled code.
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
  parent_env = parent.frame(),
  runner = source_test_file
) {
  compiled <- is_compiled_file(source_files)
  if (any(compiled)) {
    ns <- load_compiled_package(source_files[compiled])
    if (missing(parent_env)) {
      parent_env <- ns
    }
  }

  env <- new.env(parent = parent_env)

  withr::with_options(c("keep.parse.data.pkgs" = TRUE), {
    lapply(
      source_files[!compiled],
      sys.source,
      keep.source = TRUE,
      envir = env
    )
  })

  if (any(compiled)) {
    state <- start_compiled_coverage(ns, required = TRUE)
    on.exit(stop_compiled_coverage(state), add = TRUE)
  }

  trace_environment(env)
  on.exit(
    {
      reset_traces()
      clear_counters()
    },
    add = TRUE
  )

  coverage <- collect_coverage(
    lapply(test_files, runner, env = env)
  )

  if (any(compiled)) {
    coverage <- add_compiled_coverage(coverage, state)
    # Only keep the compiled files asked for
    is_compiled <- vlapply(coverage, inherits, "line_coverage")
    filenames <- vcapply(coverage, function(x) {
      get_source_filename(x$srcref, full.names = TRUE, normalize = TRUE)
    })
    coverage <- coverage[
      !is_compiled | filenames %in% normalize_path(source_files[compiled])
    ]
  }

  exclude(
    coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = NULL
  )
}

source_test_file <- function(file, env) {
  sys.source(file, envir = env, keep.source = TRUE)
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
#' @inheritSection file_coverage Parallel code
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
#' @inheritSection file_coverage Parallel code
#' @inheritSection file_coverage Compiled code
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

  with_coverage(
    lapply(test_files, sys.source, keep.source = TRUE, envir = exec_env),
    env = env,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions
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
#' @inheritSection file_coverage Parallel code
#' @inheritSection file_coverage Compiled code
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

  compiled <- start_compiled_coverage(env)
  on.exit(stop_compiled_coverage(compiled), add = TRUE)

  trace_environment(env)
  on.exit(
    {
      reset_traces()
      clear_counters()
    },
    add = TRUE
  )

  coverage <- collect_coverage(code)
  coverage <- add_compiled_coverage(coverage, compiled)

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
#' Coverage is also recorded in other R processes that load the package, such
#' as \pkg{callr} sessions, \pkg{future} or \pkg{parallel} cluster workers, or
#' Shiny apps run by \pkg{shinytest2}. Each process saves its coverage when it
#' exits normally, so the coverage is lost if a process is killed (e.g. with
#' `SIGKILL` or `SIGTERM`) or is still running when the tests finish, and
#' `package_coverage()` warns (with class `covr_unsaved_trace`). Stop these
#' processes gracefully and wait for them to exit, e.g. call `$stop()` on a
#' \pkg{shinytest2} `AppDriver`, which waits longer for the app to exit when
#' run by covr. See `vignette("shiny", package = "covr")` for measuring the
#' coverage of Shiny apps.
#'
#' `path` can also be an installed package, e.g.
#' `system.file(package = "pkg")`, to compute coverage without the package
#' source. The package must have been installed with its tests and source
#' references, e.g. with
#' `remotes::install_github("user/pkg", INSTALL_opts = c("--install-tests",
#' "--with-keep.source"))`. File names are those of the source it was
#' installed from, and compiled code isn't covered.
#'
#' The coverage of Rust code, built by cargo into a static library that is
#' linked into the package, is measured with LLVM's source-based coverage.
#' This needs the llvm tools of the Rust toolchain
#' (`rustup component add llvm-tools`), or for Rust installed by a Linux
#' distribution, those of the LLVM version rustc uses (e.g.
#' `apt-get install llvm-18`); without them `package_coverage()`
#' warns and reports no coverage for the Rust code. covr instruments the
#' crates of the package's cargo workspace by having cargo run rustc through a
#' wrapper (with `RUSTC_WORKSPACE_WRAPPER`) that adds `-C instrument-coverage`,
#' so it works however the package sets `RUSTFLAGS`, and dependencies are
#' built as usual. Vendored crates, including the C code they compile, and
#' code generated in cargo's `target` directory aren't included. The code that
#' macros such as `#[extendr]` and `#[savvy]` generate is counted on the
#' macro's line, so the line isn't covered if parts of the generated code
#' never run, e.g. the handling of arguments that can't be converted. The
#' coverage of Rust code isn't measured on Windows, as rustup's Rust for the
#' `x86_64-pc-windows-gnu` target that Rtools uses has no profiler runtime.
#'
#' #ifdef unix
#' Parallelized code using \pkg{parallel}'s [mcparallel()] needs to
#' use a patched `parallel:::mcexit`. This is done automatically if the
#' package depends on \pkg{parallel}, but can also be explicitly set using the
#' environment variable `COVR_FIX_PARALLEL_MCEXIT` or the global option
#' `covr.fix_parallel_mcexit`.
#' #endif
#'
#' @param path file path to the package, or to an installed package.
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
#' useful for debugging errors. If coverage fails, or failures are reported as
#' warnings with `allow_failures = TRUE`, `install_path` is kept even when
#' `clean = TRUE`, so the test output can be inspected.
#' @param line_exclusions a named list of files with the lines to exclude from
#' each file.
#' @param function_exclusions a vector of regular expressions matching function
#' names to exclude. Example `print\\\.` to match print methods.
#' @param code A character vector of additional test code to run.
#' @param show_code_output If `TRUE`, the output of `code` is shown on the
#'   console while it runs, e.g. to follow it in the logs of a CI job. The
#'   default, `FALSE`, only saves it to a file in `install_path`, which is shown
#'   if `code` fails.
#' @param ... Additional arguments passed to [tools::testInstalledPackage()].
#'   Use `outDir` to save the output of the tests and examples to a directory
#'   which is kept after coverage finishes; by default it is written to
#'   `install_path`.
#' @param pre_clean Deprecated and ignored. Objects present in the src directory
#'   are always deleted before recompiling.
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
  pre_clean,
  allow_failures = getOption("covr.allow_failures", FALSE),
  show_code_output = FALSE
) {
  if (!missing(pre_clean)) {
    covr_warn(c(
      "{.arg pre_clean} is deprecated and ignored.",
      i = "Objects in {.file src} are always removed before installing."
    ))
  }

  pkg <- as_package(path)
  installed <- is_installed_package(pkg$path)

  if (missing(type)) {
    type <- "tests"
  }

  type <- parse_type(type)

  if (
    installed &&
      "tests" %in% type &&
      !dir.exists(file.path(pkg$path, "tests"))
  ) {
    covr_abort(c(
      "Can't find tests in the installed package {.pkg {pkg$package}}.",
      i = "Install it with {.code R CMD INSTALL --install-tests}."
    ))
  }

  run_separately <- !isTRUE(combine_types) && length(type) > 1
  if (run_separately) {
    # store the args that were called, evaluated in the caller's frame so
    # `Recall()` doesn't look up local variables in this one
    called_args <- lapply(as.list(match.call())[-1], eval, parent.frame())

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

  if (isTRUE(clean)) {
    # The install directory is only removed on success, so the test output
    # files referenced in failure messages remain available for debugging.
    succeeded <- FALSE
    on.exit(
      {
        if (!installed) {
          clean_objects(pkg$path)
          clean_gcov(pkg$path)
        }
        clean_parse_data()
        if (succeeded) {
          unlink(install_path, recursive = TRUE)
        }
      },
      add = TRUE
    )
  }

  # clean any dlls prior to trying to install
  if (!installed) {
    clean_objects(pkg$path)
  }

  # Measure the coverage of Rust code, if the package has any
  manifests <- if (!installed) rust_manifests(pkg$path)
  rust <- if (length(manifests)) {
    rust_coverage_setup(pkg$path, install_path)
  }

  full_traversal <- getOption(
    "covr.full_traversal",
    # DESCRIPTION field names are lowercased by `read_description()`
    isTRUE(as.logical(pkg[[tolower("Config/covr/full_traversal")]]))
  )
  counters_file <- NULL
  if (installed) {
    # `R CMD INSTALL` fails to reinstall an installed package on Windows, and
    # only copies it elsewhere, so copy it directly (#638).
    copy_installed_package(pkg, install_path)
  } else {
    # The package is instrumented and byte-compiled once after it is
    # installed, so there is no point byte-compiling the original code.
    instrument <- isTRUE(install_instrument())
    install_package(
      pkg,
      install_path,
      add_rust_flags(flags, rust),
      quiet,
      env = rust$build_env,
      byte_compile = !instrument
    )
    if (instrument) {
      counters_file <- instrument_package(
        pkg,
        install_path,
        full_traversal = full_traversal
      )
    }
    if (!is.null(rust)) {
      rust <- rust_check_build(rust)
    }
  }

  # add hooks to the package startup
  add_hooks(
    pkg$package,
    install_path,
    fix_mcexit = should_enable_parallel_mcexit_fix(pkg),
    full_traversal = full_traversal,
    counters_file = counters_file
  )

  libs <- env_path(install_path, .libPaths())
  # The processes only get the site libraries of this session, not all of
  # `libs`: renv removes the site libraries from the library paths when it
  # activates its sandbox, e.g. when the package imports renv (or vetiver,
  # which embeds it) in an renv project, which would also remove covr and the
  # package (#560).
  site_libs <- r_libs_site()

  # Failures collected when `allow_failures` is TRUE, signaled as warnings
  # after the tests have run.
  failures <- list()

  # Load sys (used to show the output of `code`) before the instrumented
  # package's library is put first in the library paths, so measuring the
  # coverage of sys itself doesn't load the instrumented copy in this process.
  if (isTRUE(show_code_output)) {
    loadNamespace("sys")
  }

  # We need to set the libpaths in the current R session for examples with
  # install or runtime Sexpr blocks, which may implicitly load the package in
  # the current R session.
  withr::with_libpaths(install_path, action = "prefix", {
    withr::with_envvar(
      c(
        R_DEFAULT_PACKAGES = "datasets,utils,grDevices,graphics,stats,methods",
        R_LIBS = libs,
        R_LIBS_USER = libs,
        R_LIBS_SITE = site_libs,
        R_COVR = "true",
        R_TESTS = file.path(R.home("share"), "R", "tests-startup.R"),
        rust$env
      ),
      {
        withCallingHandlers(
          {
            if ("vignettes" %in% type) {
              type <- type[type != "vignettes"]
              run_vignettes(pkg, install_path)
            }

            test_installed <- function(
              types,
              outDir = file.path(install_path, pkg$package),
              ...
            ) {
              dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
              outDir <- normalize_path(outDir)
              result <- tools::testInstalledPackage(
                pkg$package,
                outDir = outDir,
                types = types,
                lib.loc = install_path,
                ...
              )
              if (result != 0L) {
                show_failures(outDir)
              }
            }
            if ("examples" %in% type) {
              type <- type[type != "examples"]
              # testInstalledPackage explicitly sets R_LIBS="" on windows, and does
              # not restore it after, so we need to reset it ourselves.
              withr::with_envvar(c(R_LIBS = Sys.getenv("R_LIBS")), {
                test_installed("examples", ...)
              })
            }
            if ("tests" %in% type) {
              test_installed("tests", ...)
            }

            # We always run the commands file (even if empty) to load the package and
            # initialize all the counters to 0.
            run_commands(
              pkg,
              install_path,
              code,
              show_output = show_code_output
            )
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
  coverage <- withCallingHandlers(
    merge_traces(install_path),
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

  warn_unsaved_traces(
    install_path,
    cli::format_inline("loaded {.pkg {pkg$package}}"),
    "Did a test leave a Shiny app, callr session, or future worker running?"
  )

  if (installed) {
    # `R CMD INSTALL` copies an installed package rather than building it, so
    # its R code is only available from the srcrefs kept when it was
    # installed, whose file names are in the source it was installed from.
    # Its compiled code isn't instrumented (#638).
    pkg$path <- installed_source_path(coverage)
    if (is.null(pkg$path)) {
      covr_abort(c(
        "Can't find source references in the installed package {.pkg {pkg$package}}.",
        i = "Install it with {.code R CMD INSTALL --with-keep.source}."
      ))
    }
    if (isTRUE(relative_path)) {
      root <- pkg$path
    }
    res <- NULL
  } else {
    res <- run_gcov(pkg$path, quiet = quiet, clean = clean)
  }

  if (!is.null(rust)) {
    res <- c(
      res,
      run_llvm_cov(rust, pkg$path, install_path, pkg$package, quiet = quiet)
    )
  }
  if (length(manifests)) {
    res <- drop_rust_dependencies(
      res,
      roots = c(pkg$path, getOption("covr.gcov_additional_paths", NULL))
    )
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

  # Exclude generated files from Rcpp and cpp11 to avoid redundant coverage
  # information, and the files in `.covrignore`. Rcpp replaces dots in the
  # package name with underscores in the interfaces header. These paths are in
  # the package, so they are resolved against its root rather than the root
  # used for the output paths, which is `NULL` with `relative_path = FALSE`.
  generated_files <- file.path(
    pkg$path,
    c(
      "src/RcppExports.cpp",
      "R/RcppExports.R",
      file.path(
        "inst",
        "include",
        paste0(gsub(".", "_", pkg$package, fixed = TRUE), "_RcppExports.h")
      ),
      "src/cpp11.cpp",
      "R/cpp11.R"
    )
  )
  line_exclusions <- c(
    generated_files,
    line_exclusions,
    if (!installed) {
      withr::with_dir(
        pkg$path,
        normalize_path(as.character(parse_covr_ignore()))
      )
    }
  )

  coverage <- exclude(
    coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = root
  )

  # Keep the install directory if any failures were reported as warnings, as
  # their messages refer to output files in it.
  succeeded <- length(failures) == 0L
  coverage
}

#' Convert a coverage dataset to a list
#'
#' @param x a coverage dataset, defaults to running `package_coverage()`.
#' @return A list containing coverage result for each individual file and the whole package
#' @export
coverage_to_list <- function(x = package_coverage()) {
  covr_df <- collapse_lines(tally_coverage(x))
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
    cli::format_error(c(
      "Code run to compute coverage failed.",
      i = "Its full output is in {.file {file}} and in the {.code $output} of this condition."
    )),
    "\n"
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
    withRestarts(
      covr_abort(
        c(
          "Can't read coverage trace file {.file {file}}.",
          x = "{reason}",
          i = "Coverage will be incomplete."
        ),
        class = "covr_error"
      ),
      covr_continue = function() NULL
    )
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
  # `[[` as in `as_coverage_with_tests()`
  if (!is.null(into[["branches"]]) || !is.null(from[["branches"]])) {
    into$branches <- merge_branches(into[["branches"]], from[["branches"]])
  }
  from <- from[setdiff(names(from), c("tests", "branches"))]
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
  obj$branches <- NULL
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
  # Each type must match a choice, unlike `match.arg(several.ok = TRUE)`,
  # which only fails if none of them do.
  type <- vapply(
    type,
    match.arg,
    character(1),
    choices = c("tests", "vignettes", "examples", "all", "none"),
    USE.NAMES = FALSE
  )
  if (identical(type, "all")) {
    type <- c("tests", "vignettes", "examples")
  }

  if (length(type) > 1L) {
    if ("all" %in% type) {
      covr_abort('{.arg type} can\'t combine "all" with other types.')
    }

    if ("none" %in% type) {
      covr_abort('{.arg type} can\'t combine "none" with other types.')
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

# The value of R_LIBS_SITE that gives R processes the site libraries `site`.
# An empty R_LIBS_SITE is the default site library, so no site libraries (as in
# renv projects) is "NULL".
r_libs_site <- function(site = .Library.site) {
  site_libs <- env_path(site)
  if (!nzchar(site_libs)) {
    site_libs <- "NULL"
  }
  site_libs
}

r_binary <- function() {
  name <- "R"
  if (is_windows()) {
    name <- "R.exe" # nocov
  }
  file.path(R.home("bin"), name)
}

# Install the package source with the options covr needs. With `quiet`, the
# output is captured to give the reason if the installation fails.
install_package <- function(
  pkg,
  install_path,
  flags,
  quiet,
  env = NULL,
  byte_compile = TRUE
) {
  output <- withr::with_envvar(
    c(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), env),
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
        if (!byte_compile) "--no-byte-compile",
        shQuote(pkg$path)
      )

      path <- r_binary()
      if (quiet) {
        suppressWarnings(system2(path, args, stdout = TRUE, stderr = TRUE))
      } else {
        structure(
          character(),
          status = system2(path, args, stdout = "", stderr = "")
        )
      }
    })
  )

  status <- attr(output, "status") %||% 0L
  if (status != 0) {
    covr_abort(
      "Can't install {.pkg {pkg$package}}.",
      output = utils::tail(output, failure_lines())
    )
  }
}

# Copy an installed package to `install_path`, giving the warnings of
# `file.copy()` as the reason if the copy fails.
copy_installed_package <- function(pkg, install_path) {
  reasons <- character()
  copied <- withCallingHandlers(
    file.copy(pkg$path, install_path, recursive = TRUE),
    warning = function(w) {
      reasons <<- c(reasons, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (
    !isTRUE(copied) ||
      !file.exists(file.path(install_path, pkg$package, "DESCRIPTION"))
  ) {
    covr_abort(
      "Can't copy the installed package {.pkg {pkg$package}} to {.path {install_path}}.",
      output = if (length(reasons) > 0) reasons else "`file.copy()` failed."
    )
  }
}

run_commands <- function(pkg, lib, commands, show_output = FALSE) {
  outfile <- file.path(lib, paste0(pkg$package, "-commands.Rout"))
  failfile <- paste(outfile, "fail", sep = ".")
  writeLines(
    c(
      paste0("library('", pkg$package, "')"),
      commands
    ),
    con = outfile
  )
  if (isTRUE(show_output)) {
    res <- run_r_live(outfile, failfile)
  } else {
    cmd <- paste(
      shQuote(file.path(R.home("bin"), "R")),
      "CMD BATCH --vanilla --no-timing",
      shQuote(outfile),
      shQuote(failfile)
    )
    res <- system(cmd)
  }
  if (res != 0L) {
    show_failures(dirname(failfile))
  } else {
    file.rename(failfile, outfile)
  }
}

# Run the R script `infile` like `R CMD BATCH` does, but also show its stdout
# and stderr on the console (on stdout and stderr respectively) as it runs.
# Both are saved to `outfile`, in the order they are read. Returns the exit
# status.
run_r_live <- function(infile, outfile) {
  out <- file(outfile, "wb")
  on.exit(close(out))
  show <- function(con) {
    function(x) {
      cat(rawToChar(x), file = con)
      writeBin(x, out)
    }
  }
  tryCatch(
    sys::exec_wait(
      r_binary(),
      c("--vanilla", "--quiet", "-f", infile),
      std_out = show(stdout()),
      std_err = show(stderr())
    ),
    # sys signals an error if the process is killed, e.g. by a segfault; report
    # it as a failure, as `R CMD BATCH` does.
    error = function(e) {
      show(stderr())(charToRaw(paste0(conditionMessage(e), "\n")))
      1L
    }
  )
}

# Add hooks to the installed package
# Installed packages have lazy loading code to setup the lazy load database at
# pkg_name/R/pkg_name. This function adds a user level onLoad Hook to the
# package which calls `covr::trace_environment`, so the package environment is
# traced when the package is loaded.
# It also registers a finalizer (with `register_trace()`) that saves the
# tracing information when the namespace is garbage collected or the process
# exits normally. A process that is killed does not save its trace, which
# `package_coverage()` reports. Like the tracing, this runs in an onLoad hook:
# calling covr from the load script itself loads covr while the package is
# still being lazy-loaded, which made tracing ~4x slower when covr measures its
# own coverage (covr is then loaded from an instrumented copy).
# @param pkg_name name of the package to add hooks to
# @param lib the library path to look in
# @param fix_mcexit whether to add the fix for mcparallel:::mcexit
# @param counters_file the file with the counters of a package that was
#   instrumented by `instrument_package()`, which are restored when the package
#   is loaded instead of tracing its namespace.
add_hooks <- function(
  pkg_name,
  lib,
  fix_mcexit = FALSE,
  record_tests = isTRUE(getOption("covr.record_tests", FALSE)),
  full_traversal = FALSE,
  branch_coverage = isTRUE(getOption("covr.branch_coverage", FALSE)),
  counters_file = NULL
) {
  trace_dir <- paste0("Sys.getenv(\"COVERAGE_DIR\", \"", lib, "\")")

  load_script <- file.path(lib, pkg_name, "R", pkg_name)
  lines <- readLines(load_script)
  if (!is.null(counters_file)) {
    # Load the instrumented code that `instrument_package()` saved
    db_line <- grep(
      'dbbase <- file.path(info$libname, pkg, "R", pkg)',
      lines,
      fixed = TRUE
    )
    if (length(db_line) != 1L) {
      covr_abort(
        "Can't find where the loader script of {.pkg {pkg_name}} reads the package."
      )
    }
    lines[db_line] <- sub(
      '"R", pkg)',
      '"R", paste0(pkg, ".covr"))',
      lines[db_line],
      fixed = TRUE
    )
  }
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
      paste0(
        "setHook(packageEvent(pkg, \"onLoad\"), function(...) options(covr.branch_coverage = ",
        isTRUE(branch_coverage),
        "))"
      ),
      if (is.null(counters_file)) {
        "setHook(packageEvent(pkg, \"onLoad\"), function(...) covr:::trace_environment(ns))"
      } else {
        paste0(
          "setHook(packageEvent(pkg, \"onLoad\"), function(...) covr:::restore_counters(ns, file.path(info$libname, pkg, \"R\", \"",
          basename(counters_file),
          "\")))"
        )
      },
      paste0(
        "setHook(packageEvent(pkg, \"onLoad\"), function(...) covr:::register_trace(ns, ",
        trace_dir,
        "))"
      )
    ),
    length(lines) - 1L
  )

  if (fix_mcexit) {
    lines <- append(lines, sprintf("covr:::fix_mcexit('%s')", trace_dir))
  }

  writeLines(text = lines, con = load_script)
}

#' Combine coverage objects
#'
#' Combine the coverage of several runs, e.g. of tests in different
#' directories, into a single coverage object. The counts of traces present in
#' more than one object are added, and traces only in some of the objects are
#' appended. Tests recorded with `options(covr.record_tests = TRUE)` are
#' combined as well.
#'
#' The result keeps the attributes of the first object, such as the package
#' and root used for relative paths, except that the lines excluded from line
#' coverage are the union of the excluded lines of all objects. As with
#' `package_coverage(type = c("tests", "examples"))`, the result only has a
#' `type` if all objects have the same `type`.
#'
#' As with any S3 method for [c()], this method is only used when the first
#' argument is a coverage object.
#'
#' @param ... Coverage objects, e.g. from [package_coverage()] or
#'   [file_coverage()]. They must all be for the same package, or all have no
#'   package, like the results of [file_coverage()] and [code_coverage()].
#'   `NULL` arguments are dropped.
#' @return A coverage object.
#' @export
#' @examples
#' source_file <- tempfile(fileext = ".R")
#' writeLines(
#'   c(
#'     "add <- function(x, y) {",
#'     "  x + y",
#'     "}",
#'     "subtract <- function(x, y) {",
#'     "  x - y",
#'     "}"
#'   ),
#'   source_file
#' )
#' add_test <- tempfile(fileext = ".R")
#' writeLines("add(1, 2)", add_test)
#' subtract_test <- tempfile(fileext = ".R")
#' writeLines("subtract(2, 1)", subtract_test)
#'
#' add_cov <- file_coverage(source_file, add_test)
#' subtract_cov <- file_coverage(source_file, subtract_test)
#' percent_coverage(add_cov)
#' percent_coverage(c(add_cov, subtract_cov))
c.coverage <- function(...) {
  covs <- Filter(Negate(is.null), list(...))
  if (!all(vlapply(covs, inherits, "coverage"))) {
    covr_abort(
      "All arguments to {.fn c} must be coverage objects.",
      class = "covr_combine_error"
    )
  }
  packages <- unique(vcapply(covs, function(x) {
    attr(x, "package")$package %||% NA_character_
  }))
  if (length(packages) > 1L) {
    covr_abort(
      c(
        "Can't combine coverage of different packages.",
        x = "Packages: {.pkg {packages}}."
      ),
      class = "covr_combine_error"
    )
  }

  merged <- merge_coverage(lapply(covs, coverage_to_counters))

  tests <- merged$tests
  merged$tests <- NULL
  branches <- as_branch_list(merged[["branches"]])
  merged$branches <- NULL
  merged <- lapply(merged, function(trace) {
    if (!is.null(trace$tests)) {
      trace$tests <- trace$tests$tally
    }
    trace
  })

  attrs <- attributes(covs[[1L]])
  attrs$names <- names(merged)
  attrs$tests <- tests
  attrs$branches <- branches
  attrs$excluded_lines <- union_excluded_lines(
    lapply(covs, attr, "excluded_lines")
  )
  types <- unique(lapply(covs, attr, "type"))
  if (length(types) > 1L) {
    attrs$type <- NULL
  }
  attributes(merged) <- attrs
  merged
}

# Convert a coverage object back to the list of traces used by
# `merge_coverage()`, with the recorded tests in a `tests` element.
coverage_to_counters <- function(x) {
  counters <- lapply(unclass(x), function(trace) {
    if (!is.null(trace$tests)) {
      trace$tests <- list(tally = trace$tests)
    }
    trace
  })
  counters$tests <- attr(x, "tests")
  counters$branches <- attr(x, "branches")
  counters
}

union_excluded_lines <- function(excluded) {
  excluded <- unlist(excluded, recursive = FALSE)
  if (length(excluded) == 0L) {
    return(NULL)
  }
  lapply(split(excluded, names(excluded)), function(lines) {
    sort(unique(unlist(lines)))
  })
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
