# Coverage of the test files, with `package_coverage(include_tests = TRUE)`.
#
# The code of the test files isn't in the package namespace, so unlike the
# package code it can't be instrumented when the package is loaded. Instead the
# installed copy of each test file is replaced with a stub that calls
# `run_traced_file()`, which runs an instrumented version of the code saved by
# `trace_test_files()`. The counts are saved to a trace file when the process
# exits, independently of the package, so test files that don't load it are
# still counted.
#
# The main process instruments the original files as well, to get traces with
# zero counts for all their code, including files and lines that never run. The
# counts from the trace files are added to these by key, which is made of the
# path of the file relative to the package and the position of the code, so it
# doesn't depend on where the files are and can't match a key of package code.

.test_counters <- new.env(parent = emptyenv())

# All the R files in `tests/`, except those in `.covrignore`, e.g. data files
# or fixtures that the tests read rather than run.
test_file_paths <- function(path) {
  paths <- file.path(
    "tests",
    list.files(file.path(path, "tests"), "\\.[rR]$", recursive = TRUE)
  )
  ignored <- withr::with_dir(
    path,
    normalize_path(as.character(parse_covr_ignore()))
  )
  paths[!normalize_path(file.path(path, paths)) %in% ignored]
}

# Instrument the test files of `pkg` installed in `lib`, replacing each with a
# stub that runs the instrumented code. Returns the traces of all the code in
# the test files, with zero counts.
trace_test_files <- function(pkg, lib) {
  paths <- test_file_paths(pkg$path)
  installed <- file.path(lib, pkg$package, paths)
  keep <- file.exists(installed)
  paths <- paths[keep]
  installed <- installed[keep]

  code_dir <- file.path(lib, "covr_test_files")
  dir.create(code_dir, showWarnings = FALSE)
  trace_dir <- paste0(
    "Sys.getenv(\"COVERAGE_DIR\", ",
    encodeString(lib, quote = "\""),
    ")"
  )

  traces <- list()
  for (i in seq_along(paths)) {
    source_file <- file.path(pkg$path, paths[[i]])
    lines <- readLines(source_file, warn = FALSE, encoding = "UTF-8")
    traces <- c(
      traces,
      instrument_test_file(lines, source_file, paths[[i]])$traces
    )

    # The srcrefs of the code that runs refer to the installed copy of the
    # file, as when the tests are run uninstrumented, e.g. so `record_tests`
    # finds the test code by its location in the temporary library.
    code <- instrument_test_file(lines, installed[[i]], paths[[i]])$exprs
    code_file <- file.path(code_dir, paste0(i, ".rds"))
    saveRDS(code, code_file)

    # Top level values of the scripts in `tests/` are printed, as in
    # `R CMD BATCH`.
    is_script <- dirname(paths[[i]]) == "tests"
    writeLines(
      paste0(
        "covr:::run_traced_file(",
        encodeString(code_file, quote = "\""),
        ", ",
        trace_dir,
        if (is_script) ", print = TRUE",
        ")"
      ),
      installed[[i]]
    )
  }
  traces
}

# Parse and instrument the code of a test file. `filename` is used for the
# srcrefs of the code, `path` for the keys of its traces. Returns a list with
# the instrumented code (an expression vector) and its traces.
instrument_test_file <- function(lines, filename, path) {
  srcfile <- srcfilecopy(filename, lines, isFile = TRUE)
  exprs <- parse(text = lines, keep.source = TRUE, srcfile = srcfile)

  tracer <- new_test_file_tracer(path)
  traced <- Map(
    function(expr, ref) {
      trace_calls(
        expr,
        test_code_name(expr),
        parent_ref = ref,
        test_file = tracer
      )
    },
    exprs,
    attr(exprs, "srcref")
  )
  traced <- as.expression(traced)
  attributes(traced) <- attributes(exprs)

  list(exprs = traced, traces = tracer$traces)
}

new_test_file_tracer <- function(path) {
  tracer <- new.env(parent = emptyenv())
  tracer$path <- path
  tracer$traces <- list()
  tracer
}

# Like `new_counter()` for the code of a test file.
test_file_counter <- function(tracer, src_ref, parent_functions) {
  key <- paste(collapse = ":", c(tracer$path, src_ref))
  tracer$traces[[key]] <- list(
    value = 0,
    srcref = src_ref,
    functions = parent_functions
  )
  key
}

# The "function" of a top level expression of a test file: the name of the
# function it defines, or "(top level)" for other code.
test_code_name <- function(x) {
  if (
    is.call(x) &&
      call_name(x) %in% c("<-", "=") &&
      is.call(x[[3]]) &&
      identical(x[[3]][[1]], as.name("function"))
  ) {
    # `trace_calls()` adds the name of the function
    return(character())
  }
  "(top level)"
}

# The arguments of these functions are code used as data, so they are not
# instrumented. Instrumenting the code of `testthat::expect_snapshot()` would
# change it in the snapshot, which would then fail.
quoting_functions <- c(
  "quote",
  "bquote",
  "expression",
  "alist",
  "substitute",
  "expect_snapshot"
)

is_quoting_call <- function(x) {
  call_name(x) %in% quoting_functions
}

# The name of the function called by `x`, without a `pkg::` prefix, or "" if
# it's not called by name.
call_name <- function(x) {
  fun <- x[[1]]
  if (
    is.call(fun) &&
      length(fun) == 3 &&
      (identical(fun[[1]], as.name("::")) ||
        identical(fun[[1]], as.name(":::")))
  ) {
    fun <- fun[[3]]
  }
  if (is.name(fun)) as.character(fun) else ""
}

# Increment the count of a trace in a test file.
count_test_file <- function(key) {
  .test_counters[[key]]$value <- (.test_counters[[key]]$value %||% 0) + 1L
}

# Called by the stubs that replace the installed test files (see
# `trace_test_files()`) to run the instrumented code in `file`, in the
# environment the stub runs in. The counts are saved to `directory` when the
# process exits.
run_traced_file <- function(
  file,
  directory,
  print = FALSE,
  env = parent.frame()
) {
  if (!isTRUE(the$test_trace_registered)) {
    reg.finalizer(
      .test_counters,
      function(e) save_trace(directory, e),
      onexit = TRUE
    )
    the$test_trace_registered <- TRUE
  }

  exprs <- readRDS(file)
  refs <- attr(exprs, "srcref")
  for (i in seq_along(exprs)) {
    # Evaluated as an expression vector with its srcref, so calls in it have
    # their srcrefs, as when the file is sourced.
    expr <- exprs[i]
    attr(expr, "srcref") <- refs[i]
    res <- withVisible(eval(expr, env))
    if (print && res$visible) {
      print(res$value)
    }
  }
  invisible()
}
