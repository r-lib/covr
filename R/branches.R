#' Branch coverage
#'
#' By setting `options(covr.branch_coverage = TRUE)` before measuring
#' coverage, covr also records which branches of each `if` and `switch()` in R
#' code were taken. Line and expression coverage are the same as without it.
#' Branch coverage is experimental: what counts as a branch, and how branches
#' are stored and reported, may change.
#'
#' The option is read when the code is instrumented, so it has no cost when it
#' is not set. When it is set, every `if` and `switch()` that runs calls a
#' function of covr, which makes the code slower.
#'
#' @section Branches:
#'
#' * An `if` has two branches, `"TRUE"` and `"FALSE"`. The `"FALSE"` branch
#'   of an `if` without an `else` is taken when the condition is `FALSE`.
#'   Nothing is recorded if the condition is `NA` or otherwise signals an
#'   error.
#' * A `switch()` has a branch for each of its arms, labelled with the name of
#'   the arm. Arms that fall through to the next arm (`switch(x, a = , b = 1)`)
#'   share its branch, labelled `"a, b"`. An unnamed arm is labelled
#'   `"<default>"`, or with its position if all arms are unnamed. A `switch()`
#'   without a default arm has another branch, `"<no match>"`, taken when no
#'   arm matches, including a number that selects no arm. A `switch()` with
#'   arms in `...` has no branches.
#'
#' `&&`, `||` and loops have no branches, nor does compiled code. An `if` or
#' `switch()` in the default value of an argument only has branches if the
#' default is in braces, `function(x = { if (y) 1 else 2 })`, as for line
#' coverage.
#'
#' If the line where an `if` or `switch()` starts is excluded, e.g. with
#' `# nocov` (see [exclusions]), all its branches are excluded too.
#'
#' @section Results:
#'
#' The branches are in the `branches` attribute of the coverage object, a list
#' with an element for each `if` and `switch()`, named like the elements of
#' the coverage object (see [coverage]). Each is a list with the `srcref` of
#' the `if` or `switch()`, its `functions`, the `labels` of its branches, and
#' `value`, the number of times each branch was taken. Use
#' `tally_coverage(by = "branch")` for a data frame with one row for each
#' branch, and `percent_coverage(by = "branch")` for the percentage of
#' branches taken.
#'
#' [to_lcov()], [to_cobertura()], [codecov()] and [coveralls()] include the
#' branches. Codecov shows a line with branches that weren't all taken as
#' partly covered, and counts it as not covered in the coverage percentage, so
#' the percentage on Codecov is lower with branch coverage. [report()],
#' [file_report()] and [to_sonarqube()] don't include the branches yet.
#'
#' @examples
#' withr::with_options(list(covr.branch_coverage = TRUE), {
#'   cov <- code_coverage(
#'     "f <- function(x) {\n  if (x > 0) 'positive'\n  'done'\n}",
#'     "f(1)"
#'   )
#' })
#' tally_coverage(cov, by = "branch")
#' percent_coverage(cov, by = "branch")
#' @name covr.branch_coverage
NULL

# Branch coverage of R code (#279), enabled with
# `options(covr.branch_coverage = TRUE)` when the code is instrumented.
#
# Each decision (an `if` or `switch` call) has an entry in the environment
# `.counters$branches`, keyed like a counter by the srcref of the decision,
# holding its `srcref`, `functions`, the `labels` of its branches and their
# counts in `value`. The `branches` element of the counters is handled like
# their `tests` element: it is saved in trace files, merged by
# `merge_coverage()`, and becomes the `branches` attribute of the coverage
# object.

# Add branch counters to `traced`, the instrumented version of the decision
# `x` whose srcref is `src_ref`.
trace_branches <- function(traced, x, src_ref, parent_functions) {
  switch(
    as.character(x[[1L]]),
    "if" = trace_if(traced, src_ref, parent_functions),
    "switch" = trace_switch(traced, x, src_ref, parent_functions),
    traced
  )
}

# `if (cond)` becomes `if (covr:::branch(key, cond))`, which also counts the
# implicit `else` of an `if` without one.
trace_if <- function(traced, src_ref, parent_functions) {
  key <- new_branch(src_ref, parent_functions, c("TRUE", "FALSE"))
  traced[[2L]] <- as.call(list(covr_call("branch"), key, traced[[2L]]))
  traced
}

# Each arm of a `switch()` counts its branch before it is evaluated. Arms that
# fall through to the next arm (`a = , b = 2`) share its branch, as they can't
# be told apart without re-implementing the matching of `switch()`. A
# `switch()` without a default gets one, `covr:::branch_miss(key)`, which
# counts the "no match" branch and returns `invisible(NULL)` like a `switch()`
# without a match.
trace_switch <- function(traced, x, src_ref, parent_functions) {
  arms <- as.list(x)[-(1:2)]
  n <- length(arms)
  if (n == 0L) {
    return(traced)
  }
  # The arms in `...` are unknown, and a last arm without a body has no code
  # to count it.
  empty <- vlapply(arms, is_missing_arg)
  if (empty[[n]] || any(vlapply(arms, identical, as.symbol("...")))) {
    return(traced)
  }

  arm_names <- names(arms) %||% character(n)
  named <- nzchar(arm_names)
  arm_labels <- arm_names
  arm_labels[!named] <- if (any(named)) "<default>" else which(!named)

  # Each arm with a body ends a group of arms sharing a branch.
  group <- cumsum(c(1L, !empty[-n]))
  labels <- vcapply(split(arm_labels, group), paste, collapse = ", ")

  # Another unnamed arm would be a second default for a character `EXPR`, so
  # a default is only added if there is none, or if all arms are unnamed and
  # there are two or more of them, which a character `EXPR` can't select.
  add_default <- all(named) || (!any(named) && n >= 2L)
  if (add_default) {
    labels <- c(labels, "<no match>")
  }
  key <- new_branch(src_ref, parent_functions, unname(labels))

  for (i in which(!empty)) {
    traced[[i + 2L]] <- call(
      "if",
      TRUE,
      call(
        "{",
        as.call(list(covr_call("branch_arm"), key, group[[i]])),
        traced[[i + 2L]]
      )
    )
  }
  if (add_default) {
    # The added default only catches a numeric `EXPR` of `n + 1`, so
    # `branch_switch()` counts the other numbers that select no arm.
    traced[[2L]] <- as.call(list(
      covr_call("branch_switch"),
      key,
      traced[[2L]],
      n
    ))
    traced <- as.call(c(
      as.list(traced),
      list(as.call(list(covr_call("branch_miss"), key)))
    ))
  }
  traced
}

# Constructed by hand like in `trace_calls()`, to avoid a NOTE from R CMD
# check
covr_call <- function(name) {
  call(":::", as.symbol("covr"), as.symbol(name))
}

is_missing_arg <- function(x) {
  identical(x, quote(expr = ))
}

new_branch <- function(src_ref, parent_functions, labels) {
  key <- key(src_ref)
  if (is.null(.counters$branches)) {
    .counters$branches <- new.env(parent = emptyenv())
  }
  branches <- .counters$branches
  # Keep the counts of a decision that already exists, as in `new_counter()`.
  value <- branches[[key]]$value
  if (length(value) != length(labels)) {
    value <- numeric(length(labels))
  }
  branches[[key]] <- list(
    srcref = src_ref,
    functions = parent_functions,
    labels = labels,
    value = value
  )
  key
}

# Records which branch of an `if` is taken and returns `cond` unchanged, so
# `if` signals its own errors and warnings for conditions that are `NA`,
# have length zero or more than one, or can't be interpreted as logical.
# Nothing is recorded for these conditions, or if `cond` signals an error.
branch <- function(key, cond) {
  # Runs for every `if`, so the common case of `TRUE` or `FALSE` avoids
  # calling other closures, including `record_branch()`. Objects take the
  # slow path, as `length()` and `is.na()` would dispatch on their class,
  # which `if` doesn't.
  i <- if (
    is.logical(cond) && !is.object(cond) && length(cond) == 1L && !is.na(cond)
  ) {
    if (cond) 1L else 2L
  } else {
    branch_index(cond)
  }
  if (!is.na(i)) {
    branches <- .counters$branches
    entry <- branches[[key]]
    if (!is.null(entry)) {
      entry$value[[i]] <- entry$value[[i]] + 1
      branches[[key]] <- entry
    }
  }
  cond
}

# The branch `if` takes for a condition other than `TRUE` or `FALSE`, e.g. a
# number, a string such as `"true"` or a factor, or `NA` if it signals an
# error.
branch_index <- function(cond) {
  tryCatch(
    suppressWarnings(if (cond) 1L else 2L),
    error = function(e) NA_integer_
  )
}

branch_arm <- function(key, i) {
  record_branch(key, i)
}

branch_miss <- function(key) {
  record_branch(key, length(.counters$branches[[key]]$value))
  invisible(NULL)
}

# Counts the "no match" branch of a `switch()` with `n` arms and an added
# default for a non-character `EXPR` that selects no arm, e.g. `0` or `NA`,
# and returns `expr` unchanged. `switch()` itself finds whether it selects an
# arm, so `EXPR` is converted as `switch()` does it. An `EXPR` of `n + 1`
# selects the added default, which counts it. Only atomic vectors are
# checked, as other objects can't be inlined in the call.
branch_switch <- function(key, expr, n) {
  if (is.atomic(expr) && !is.character(expr)) {
    probe <- as.call(c(as.name("switch"), list(expr), rep(list(TRUE), n + 1L)))
    selected <- tryCatch(
      suppressWarnings(eval(probe, baseenv())),
      error = function(e) TRUE
    )
    if (is.null(selected)) {
      branch_miss(key)
    }
  }
  expr
}

record_branch <- function(key, i) {
  branches <- .counters$branches
  entry <- branches[[key]]
  if (!is.null(entry)) {
    entry$value[[i]] <- entry$value[[i]] + 1
    branches[[key]] <- entry
  }
  invisible()
}

zero_branches <- function() {
  branches <- .counters$branches
  if (is.null(branches)) {
    return()
  }
  for (key in ls(branches, all.names = TRUE)) {
    branches[[key]]$value[] <- 0
  }
}

# The decisions as a list sorted by key, or `NULL` if there are none.
as_branch_list <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  x <- as.list(x, all.names = TRUE)
  x[order(names(x))]
}

# Sum the counts of decisions in both `into` and `from`, and append the others.
merge_branches <- function(into, from) {
  into <- as_branch_list(into)
  from <- as_branch_list(from)
  if (is.null(into) || is.null(from)) {
    return(into %||% from)
  }
  idx <- match(names(from), names(into))
  for (i in which(!is.na(idx))) {
    j <- idx[[i]]
    if (length(into[[j]]$value) == length(from[[i]]$value)) {
      into[[j]]$value <- into[[j]]$value + from[[i]]$value
    }
  }
  added <- is.na(idx)
  as_branch_list(c(into, from[added]))
}

# The file names of the srcrefs of a list of traces or decisions.
srcref_filenames <- function(x) {
  vcapply(x, function(x) {
    get_source_filename(x$srcref, full.names = TRUE)
  })
}

# Keep the decisions in `branches` that contain one of the traces in
# `counters`, e.g. the trace of the condition of an `if`, so subsetting a
# coverage object (see `[.coverage`) subsets its branches too.
subset_branches <- function(branches, counters) {
  if (!length(branches) || !length(counters)) {
    return(branches[0])
  }
  position <- function(refs, line, byte) {
    vapply(refs, function(x) x$srcref[[line]] * 1e6 + x$srcref[[byte]], 0)
  }
  counter_files <- srcref_filenames(counters)
  counter_start <- position(counters, 1L, 2L)
  counter_end <- position(counters, 3L, 4L)
  files <- srcref_filenames(branches)
  start <- position(branches, 1L, 2L)
  end <- position(branches, 3L, 4L)
  keep <- vlapply(seq_along(branches), function(i) {
    any(
      counter_files == files[[i]] &
        counter_start >= start[[i]] &
        counter_end <= end[[i]],
      na.rm = TRUE
    )
  })
  branches[keep]
}

# Drop the decisions in `branches` whose first line is excluded in `excl`
# (from `normalize_exclusions()`), or whose function matches one of
# `function_exclusions`.
exclude_branches <- function(branches, excl, function_exclusions = NULL) {
  if (!length(branches)) {
    return(branches)
  }
  files <- normalize_path(srcref_filenames(branches))
  lines <- vapply(branches, function(x) x$srcref[[1L]], integer(1))
  excluded <- vlapply(seq_along(branches), function(i) {
    file_excl <- excl[[files[[i]]]]
    !is.null(file_excl) &&
      (identical(file_excl, Inf) || lines[[i]] %in% file_excl)
  })
  if (length(function_exclusions)) {
    functions <- vcapply(branches, function(x) x$functions[1L])
    for (pattern in function_exclusions) {
      matched <- rex::re_matches(functions, pattern)
      excluded <- excluded | (!is.na(matched) & matched)
    }
  }
  branches[!excluded]
}

# One row for each branch, see `tally_coverage()`.
tally_branches <- function(x) {
  branches <- attr(x, "branches")
  if (!length(branches)) {
    return(data.frame(
      filename = character(),
      functions = character(),
      line = integer(),
      column = integer(),
      branch = integer(),
      label = character(),
      value = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  n <- vapply(branches, function(x) length(x$value), integer(1))
  idx <- rep(seq_along(branches), n)
  filenames <- to_relative_path(srcref_filenames(branches), attr(x, "root"))
  df <- data.frame(
    filename = filenames[idx],
    functions = vcapply(branches, function(x) x$functions[1L])[idx],
    line = vapply(branches, function(x) x$srcref[[1L]], integer(1))[idx],
    column = vapply(branches, function(x) x$srcref[[5L]], integer(1))[idx],
    branch = sequence(n),
    label = unlist(lapply(branches, `[[`, "labels"), use.names = FALSE),
    value = unlist(lapply(branches, `[[`, "value"), use.names = FALSE),
    stringsAsFactors = FALSE
  )
  df <- df[order(df$filename, df$line, df$column, df$branch), ]
  rownames(df) <- NULL
  df
}

# The index of each `if` and `switch()` among those on its line, from zero in
# the order they start, for the branches `df` from `tally_branches()` (which
# sorts them by file, line and column). This is the "block" of LCOV and
# Coveralls.
branch_blocks <- function(df) {
  id <- paste(df$filename, df$line, df$column, sep = "\r")
  decision <- match(id, unique(id))
  line <- paste(df$filename, df$line, sep = "\r")
  decision - decision[match(line, line)]
}

# The number of branches taken and the total number of branches on each line
# with branches, from the branches `df` from `tally_branches()`.
line_branch_totals <- function(df) {
  if (!NROW(df)) {
    return(data.frame(
      filename = character(),
      line = integer(),
      taken = integer(),
      total = integer(),
      stringsAsFactors = FALSE
    ))
  }
  taken <- aggregate(
    cbind(taken = value > 0, total = 1L) ~ filename + line,
    data = df,
    FUN = sum
  )
  taken[order(taken$filename, taken$line), ]
}
