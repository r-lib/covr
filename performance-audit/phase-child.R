# Child process of bench-phases.R: loads the package from the first library
# in R_LIBS and runs its installed tests with testthat, timing each step.
#
# Usage: Rscript --vanilla phase-child.R <mode> <pkg> <out.rds> [<profile>]
#   mode: "plain" (uninstrumented install) or "instr" (installed by covr with
#         add_hooks(), so loading the namespace traces it)
#   profile: if given, Rprof() the load and the tests into this file instead of
#            timing them (the profiling run is not used for timings)

args <- commandArgs(trailingOnly = TRUE)
mode <- args[[1]]
pkg <- args[[2]]
out <- args[[3]]
profile <- if (length(args) >= 4) args[[4]] else NULL

vmhwm <- function() {
  x <- grep("^VmHWM", readLines("/proc/self/status"), value = TRUE)
  as.numeric(gsub("[^0-9]", "", x)) / 1024
}
now <- function() proc.time()[["elapsed"]]

# Run the tests that skip on CRAN too, as devtools::test() does.
Sys.setenv(NOT_CRAN = "true")
suppressPackageStartupMessages(library(testthat))
lib <- strsplit(Sys.getenv("R_LIBS"), ":", fixed = TRUE)[[1]][[1]]
test_path <- file.path(lib, pkg, "tests", "testthat")
mem_start <- vmhwm()

if (!is.null(profile)) {
  Rprof(profile, interval = 0.01, filter.callframes = TRUE)
}
t0 <- now()
suppressPackageStartupMessages(loadNamespace(pkg))
t1 <- now()
res <- suppressMessages(suppressWarnings(testthat::test_dir(
  test_path,
  package = pkg,
  load_package = "installed",
  reporter = "silent",
  stop_on_failure = FALSE,
  stop_on_warning = FALSE
)))
t2 <- now()
if (!is.null(profile)) {
  Rprof(NULL)
}

result <- list(
  mode = mode,
  pkg = pkg,
  load = t1 - t0,
  tests = t2 - t1,
  n_tests = nrow(as.data.frame(res)),
  mem_start_mb = mem_start,
  mem_after_tests_mb = vmhwm()
)

if (mode == "instr") {
  # covr versions that count in C keep pending counts there until synced.
  if (exists("sync_counts", envir = asNamespace("covr"), inherits = FALSE)) {
    covr:::sync_counts()
  }
  counters <- covr:::.counters
  keys <- setdiff(ls(counters, all.names = TRUE), "tests")
  values <- vapply(
    keys,
    function(k) as.numeric(counters[[k]]$value),
    numeric(1)
  )
  # The number of times an `if` ran, which is the number of extra calls branch
  # coverage would add: the count of the counter of each `if` condition,
  # found in the bodies of the traced functions, where a counted expression
  # `x` is `if (TRUE) { covr:::count(key); x }`.
  count_fun <- call(":::", as.symbol("covr"), as.symbol("count"))
  count_key <- function(e) {
    if (
      is.call(e) &&
        identical(e[[1]], as.name("if")) &&
        isTRUE(e[[2]]) &&
        is.call(e[[3]]) &&
        identical(e[[3]][[1]], as.name("{")) &&
        length(e[[3]]) >= 2 &&
        is.call(e[[3]][[2]]) &&
        identical(e[[3]][[2]][[1]], count_fun)
    ) {
      e[[3]][[2]][[2]]
    }
  }
  if_keys <- function(e) {
    if (!is.call(e)) {
      return(character())
    }
    key <- if (identical(e[[1]], as.name("if")) && !isTRUE(e[[2]])) {
      count_key(e[[2]])
    }
    c(key, unlist(lapply(as.list(e)[-1], if_keys)))
  }
  traced <- Filter(
    is.function,
    lapply(covr:::the$replacements, `[[`, "new_value")
  )
  if_conditions <- unique(unlist(lapply(traced, function(f) if_keys(body(f)))))
  names(values) <- keys
  is_if <- keys %in% if_conditions
  # The parent passes a directory that outlives this process.
  trace_dir <- Sys.getenv("TRACE_SAVE_DIR")
  t3 <- now()
  covr:::save_trace(trace_dir)
  t4 <- now()
  result$save <- t4 - t3
  result$trace_file <- list.files(trace_dir, full.names = TRUE)
  result$trace_bytes <- file.size(result$trace_file)
  result$n_traces <- length(keys)
  result$n_counts <- sum(values)
  result$n_if_counts <- sum(values[is_if])
  result$n_if_statements <- sum(is_if)
  # A check that the child loaded the covr under test.
  result$covr <- as.character(utils::packageVersion("covr"))
  result$mem_after_save_mb <- vmhwm()
  # The finalizer registered by the load hook saves the trace again at exit,
  # into COVERAGE_DIR, which the parent sets to a scratch directory.
}

saveRDS(result, out)
