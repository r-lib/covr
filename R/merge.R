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

# Merge multiple coverage objects together. Traces are matched by name; the
# counts of shared traces are summed and traces missing from earlier objects
# are appended.
merge_coverage <- function(x) {
  UseMethod("merge_coverage")
}

#' @export
merge_coverage.character <- function(x) {
  # Each trace is added to the result as it is read, rather than reading them
  # all first, as tests can start hundreds of processes that load the package
  # (#744). The counts of the traces that only have counts (see
  # `process_trace()`) are summed by the file of the counters they belong to,
  # which is read once at the end.
  merged <- NULL
  counts <- list()
  for (file in x) {
    trace <- read_trace(file)
    if (inherits(trace, "covr_counts")) {
      counters_file <- trace$counters_file
      counts[[counters_file]] <- add_counts(
        counts[[counters_file]],
        trace$counts
      )
      trace <- if (length(trace$counters) > 0) trace$counters
    }
    if (is.null(trace)) {
      next
    }
    merged <- if (is.null(merged)) {
      merge_coverage(list(trace))
    } else {
      merge_coverage_pair(merged, trace)
    }
  }
  for (counters_file in names(counts)) {
    counters <- read_trace(counters_file)
    if (!is.null(counters)) {
      counters <- add_counter_values(counters, counts[[counters_file]])
      merged <- merge_coverage(compact(list(counters, merged)))
    }
  }
  merged
}

# Add the named numeric `counts` to `into`, a named numeric too.
add_counts <- function(into, counts) {
  if (is.null(into)) {
    return(counts)
  }
  idx <- match(names(counts), names(into))
  shared <- !is.na(idx)
  into[idx[shared]] <- into[idx[shared]] + counts[shared]
  c(into, counts[!shared])
}

# Add the named numeric `counts` to the values of the `counters` of the same
# name.
add_counter_values <- function(counters, counts) {
  idx <- match(names(counts), names(counters))
  for (i in which(!is.na(idx))) {
    j <- idx[[i]]
    counters[[j]]$value <- counters[[j]]$value + counts[[i]]
  }
  counters
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
  if (inherits(trace, "covr_counts")) {
    return(trace)
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

  # `[[` rather than `$` for the elements that are not traces, which would
  # partially match the key of a trace in a file whose name starts with "tests"
  # or "branches"
  tests <- from[["tests"]]
  if (!is.null(into[["branches"]]) || !is.null(from[["branches"]])) {
    into[["branches"]] <- merge_branches(
      into[["branches"]],
      from[["branches"]]
    )
  }
  from <- from[setdiff(names(from), c("tests", "branches"))]
  idx <- match(names(from), names(into))
  shared <- which(!is.na(idx))

  if (!is.null(tests)) {
    into_tests <- into[["tests"]]
    test_idx <- match(names(tests), Filter(nchar, names(into_tests)))
    new_test_idx <- if (!length(test_idx)) {
      seq_along(tests)
    } else {
      which(is.na(test_idx))
    }
    test_idx[new_test_idx] <- length(into_tests) + seq_along(new_test_idx)

    into[["tests"]] <- append(into_tests, tests[new_test_idx])
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
