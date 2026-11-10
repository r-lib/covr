#' Provide percent coverage of package
#'
#' Calculate the total percent coverage from a coverage result object.
#' @param x the coverage object returned from [package_coverage()]
#' @param ... additional arguments passed to [tally_coverage()], such as `by
#'   = "branch"` for the percentage of branches taken (see
#'   [covr.branch_coverage]).
#' @return The total percentage as a `numeric(1)`.
#' @export
percent_coverage <- function(x, ...) {
  res <- tally_coverage(x, ...)
  if (!is.null(res$branch)) {
    return((sum(res$value > 0) / NROW(res)) * 100)
  }
  if (!is.null(res$line)) {
    res <- collapse_lines(res)
  }

  percent_covered(res$value)
}

percent_covered <- function(x) {
  sum(x > 0) / length(x) * 100
}

# The "high" (>= 90%), "mid" (>= 75%) or "low" level of a coverage percentage.
coverage_level <- function(percent) {
  if (percent >= 90) {
    "high"
  } else if (percent >= 75) {
    "mid"
  } else {
    "low"
  }
}

#' Tally coverage by line, expression, function or branch
#'
#' @inheritParams percent_coverage
#' @param by whether to tally coverage by line, expression, function or
#'   branch
#' @return A `data.frame`. With `by = "expression"` it is the same as
#'   [as.data.frame.coverage()]. With `by = "line"` it has one row for each
#'   function on each line of code (excluding blank lines, comments and lines
#'   with only punctuation such as `}`) and the columns `filename`,
#'   `functions`, `line` and `value`, where `value` is the smallest execution
#'   count of the expressions on that line, so a line only counts as covered
#'   if all its expressions were run. An expression spanning several lines,
#'   such as a loop, only counts for the lines that none of the expressions
#'   inside it are on. [percent_coverage()], [report()] and the other line
#'   based outputs count each line once, with the smallest count of its
#'   functions.
#'
#'   With `by = "function"` it has one row for each top level R function and
#'   the columns `filename`, `functions`, `first_line`, `last_line` and
#'   `value`, where `first_line` and `last_line` span the function's traced
#'   code and `value` is the largest execution count of its expressions, so a
#'   function counts as covered if any of its code was run. Compiled code has
#'   no function names, so it is left out.
#'
#'   With `by = "branch"` it has one row for each branch measured with
#'   `options(covr.branch_coverage = TRUE)` (see [covr.branch_coverage]), and
#'   the columns `filename`, `functions`, `line` and `column` (where the `if`
#'   or `switch()` starts), `branch` (the index of the branch in its `if` or
#'   `switch()`), `label` and `value`, the number of times the branch was
#'   taken. It has no rows if branch coverage wasn't measured.
#' @examples
#' cov <- code_coverage(
#'   "f <- function(x) {\n  if (x) 'yes' else 'no'\n}\ng <- function() 1",
#'   "f(TRUE)"
#' )
#' tally_coverage(cov)
#' tally_coverage(cov, by = "expression")
#' tally_coverage(cov, by = "function")
#' @export
tally_coverage <- function(
  x,
  by = c("line", "expression", "function", "branch")
) {
  by <- match.arg(by)
  if (by == "branch") {
    return(tally_branches(x))
  }

  # Rarely something goes wrong with the source references and we get all NAs
  # for them, so we omit them here
  df <- as.data.frame(x)

  all_na_rows <- rowSums(is.na(df)) == ncol(df)
  df <- df[!all_na_rows, ]

  if (NROW(df) == 0) {
    return(df)
  }

  switch(
    by,
    "line" = tally_lines(df, x),
    "expression" = df,
    "function" = tally_functions(df)
  )
}

# `x` is the object passed to tally_coverage(); if it is a coverage object its
# source files are used to drop lines that aren't code.
tally_lines <- function(df, x) {
  # if it already has a line column it has already been tallied.
  if (!is.null(df$line)) {
    return(df)
  }

  # Expressions without source references, such as code generated on load,
  # have no lines.
  df <- df[!is.na(df$first_line), , drop = FALSE]
  if (!NROW(df)) {
    return(data.frame(
      filename = character(),
      functions = character(),
      line = integer(),
      value = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  res <- innermost_lines(df)

  # The smallest count of each function on each line, sorted by file, line and
  # function, with compiled code (`NA` functions) last.
  file <- collation_rank(res$filename)
  functions <- collation_rank(res$functions)
  ord <- order(file, res$line, functions, !is.na(res$value), res$value)
  first <- run_starts(list(file[ord], res$line[ord], functions[ord]))
  res <- res[ord[first], c("filename", "functions", "line", "value")]
  res$functions <- as.character(res$functions)

  if (inherits(x, "coverage")) {
    res <- drop_lines(res, non_code_lines(x))
    res <- drop_lines(res, attr(x, "excluded_lines"))
  }
  rownames(res) <- NULL
  res
}

# The rank of each element of `x` in `sort(unique(x))`, so that ordering the
# ranks orders `x` as `order()` would, but can use the faster radix sort.
collation_rank <- function(x) {
  match(x, sort(unique(x)))
}

# Whether each element of the sorted `keys`, a list of vectors of the same
# length, starts a run of equal keys. `NA`s are equal to each other.
run_starts <- function(keys) {
  n <- length(keys[[1]])
  starts <- rep(TRUE, n)
  if (n < 2) {
    return(starts)
  }
  same <- rep(TRUE, n - 1)
  for (key in keys) {
    prev <- key[-n]
    cur <- key[-1]
    eq <- prev == cur
    na <- is.na(eq)
    eq[na] <- is.na(prev[na]) & is.na(cur[na])
    same <- same & eq
  }
  starts[-1] <- !same
  starts
}

# Expands each expression to the lines it spans, keeping on each line only the
# innermost expressions on it. An expression spanning several lines, such as a
# loop or a function defined inside another, would otherwise lower the counts
# of the expressions inside it, which can run more often, or, for a function
# created when the package was installed, run when the outer one never did.
#
# Source ranges of parsed code are nested or disjoint, so an expression isn't
# innermost on a line exactly when an expression directly inside it is on it.
innermost_lines <- function(df) {
  # Byte positions within each file, comparable across lines.
  width <- max(df$first_byte, df$last_byte) + 1
  start <- df$first_line * width + df$first_byte
  end <- df$last_line * width + df$last_byte

  # Expressions with the same range, such as identical code in two functions,
  # don't contain each other, so they share a node.
  file <- match(df$filename, unique(df$filename))
  ord <- order(file, start, end)
  new_node <- run_starts(list(file[ord], start[ord], end[ord]))
  id <- integer(length(ord))
  id[ord] <- cumsum(new_node)
  first <- ord[new_node]
  parent <- nesting_parents(file[first], start[first], end[first])

  # Lines of each node that a node directly inside it is on.
  child <- which(!is.na(parent))
  max_line <- max(df$last_line) + 1
  child_lines <- expand_range(
    df$first_line[first][child],
    df$last_line[first][child]
  )
  outer <- parent[child][child_lines$index] * max_line + child_lines$line

  rows <- expand_range(df$first_line, df$last_line)
  keep <- !(id[rows$index] * max_line + rows$line) %in% outer

  res <- df[rows$index[keep], c("filename", "functions", "value")]
  res$line <- rows$line[keep]
  rownames(res) <- NULL
  res
}

# The innermost range containing each range, or `NA`. Sorting by start, and the
# longest range first, puts each range after the ranges containing it, so a
# stack of the open ranges gives its parent in a single pass.
nesting_parents <- function(filename, start, end) {
  ord <- order(filename, start, -end)
  parent <- rep(NA_integer_, length(ord))
  stack <- integer(length(ord))
  top <- 0L
  for (i in ord) {
    while (
      top > 0L &&
        (filename[stack[top]] != filename[i] || end[stack[top]] < end[i])
    ) {
      top <- top - 1L
    }
    if (top > 0L) {
      parent[i] <- stack[top]
    }
    top <- top + 1L
    stack[top] <- i
  }
  parent
}

# Each line from `first` to `last` of each range, with the range's index.
expand_range <- function(first, last) {
  n <- last - first + 1L
  index <- rep(seq_along(first), n)
  list(index = index, line = first[index] + sequence(n) - 1L)
}

# The lines of each traced file that aren't code, named by filename: blank
# lines, comments and lines with only punctuation, such as `}` or `} else {`
# (#387).
non_code_lines <- function(x) {
  pattern <- "^[[:space:]]*(?:#.*)?$|^(?:[[:punct:][:space:]]|else)*$"
  compact(lapply(traced_files(x), function(file) {
    which(grepl(pattern, file$file_lines, perl = TRUE))
  }))
}

# tally_coverage(by = "line") has a row for each function on a line; this
# combines them into one row for each line with the smallest count, so a line
# only counts as covered if all its code was run.
collapse_lines <- function(lines) {
  if (!NROW(lines)) {
    return(data.frame(
      filename = character(),
      line = integer(),
      value = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  file <- collation_rank(lines$filename)
  ord <- order(file, lines$line, !is.na(lines$value), lines$value)
  first <- run_starts(list(file[ord], lines$line[ord]))
  res <- lines[ord[first], c("filename", "line", "value")]
  rownames(res) <- NULL
  res
}

# Drops the rows of `res` for the lines in `lines`, a list of line numbers named
# by filename.
drop_lines <- function(res, lines) {
  if (!length(lines) || !NROW(res)) {
    return(res)
  }

  files <- unique(names(lines))
  max_line <- max(res$line, unlist(lines)) + 1
  drop <- rep(match(names(lines), files), lengths(lines)) *
    max_line +
    unlist(lines, use.names = FALSE)
  keep <- !(match(res$filename, files) * max_line + res$line) %in% drop
  res[keep, , drop = FALSE]
}

# Accepts the output of tally_coverage() by expression, line or function.
tally_functions <- function(df) {
  df <- df[!is.na(df$functions), , drop = FALSE]
  first_line <- df$first_line %||% df$line
  last_line <- df$last_line %||% df$line

  groups <- split(
    seq_len(NROW(df)),
    paste(df$filename, df$functions, sep = "\r")
  )
  idx <- vapply(groups, `[[`, integer(1), 1L, USE.NAMES = FALSE)

  res <- data.frame(
    filename = as.character(df$filename[idx]),
    functions = as.character(df$functions[idx]),
    first_line = vapply(groups, function(i) min(first_line[i]), numeric(1)),
    last_line = vapply(groups, function(i) max(last_line[i]), numeric(1)),
    value = vapply(groups, function(i) max(df$value[i]), numeric(1)),
    stringsAsFactors = FALSE
  )
  res <- res[order(res$filename, res$first_line, res$functions), ]
  rownames(res) <- NULL
  res
}

#' Provide locations of zero coverage
#'
#' When examining the test coverage of a package, it is useful to know if there are
#' any locations where there is **0** test coverage.
#'
#' @param x a coverage object returned [package_coverage()]
#' @param ... additional arguments passed to
#' [tally_coverage()], such as `by = "function"` to list the functions that
#' were never run.
#' @return A `data.frame` with coverage data where the coverage is 0.
#' @details if used within RStudio this function outputs the results using the
#' Marker API.
#' @examples
#' cov <- code_coverage(
#'   "f <- function(x) {\n  if (x) 'yes' else 'no'\n}\ng <- function() 1",
#'   "f(TRUE)"
#' )
#' zero_coverage(cov)
#' zero_coverage(cov, by = "function")
#' @export
zero_coverage <- function(x, ...) {
  coverage_data <- tally_coverage(x, ...)
  coverage_data <- coverage_data[coverage_data$value == 0, , drop = FALSE]

  res <- coverage_data[
    # need to use %in% rather than explicit indexing because
    # tally_coverage returns a df without the columns if
    # by is equal to "line"
    colnames(coverage_data) %in%
      c(
        "filename",
        "functions",
        "line",
        "first_line",
        "last_line",
        "first_column",
        "last_column",
        "value"
      )
  ]

  if (
    getOption("covr.rstudio_source_markers", TRUE) &&
      rstudio_has_source_markers()
  ) {
    rstudio_source_markers(
      source_markers(coverage_data),
      attr(x, "package")$path
    )
    invisible(res)
  } else {
    res
  }
}

#' Print a coverage object
#'
#' @param x the coverage object to be printed
#' @param group whether to group coverage by filename or function
#' @param by whether to count coverage by line, expression or function
#' @param n the maximum number of files or functions to print. They are
#'   sorted from least to most covered, so the least covered are shown first.
#' @param missing whether to list the lines that were not run after each file
#'   or function that has any, as ranges such as `missed 41-48, 112`. Lines
#'   are joined into a range when only blank lines, comments and lines with
#'   only punctuation, such as closing braces, are between them. Code that was
#'   run, or that has no coverage data, such as the line a function is defined
#'   on, ends the range. Only used with `by = "line"`, and ignored otherwise.
#'
#'   If branch coverage was measured (see [covr.branch_coverage]), the missed
#'   branches of each file or function are also listed, as `missed branches 12
#'   FALSE, 30 b`: the line of the `if` or `switch()` and the label of the
#'   branch that was not taken. Only `if` and `switch()` calls that were
#'   evaluated are listed; the others are covered by the missed lines.
#'
#' @section Branches:
#' If branch coverage was measured (see [covr.branch_coverage]), the
#' percentage of branches taken is also shown after the overall coverage, e.g.
#' `Coverage: 87.40% (branches 72.00%)`.
#'
#' @param ... additional arguments ignored
#' @return The coverage object (invisibly).
#' @examples
#' cov <- code_coverage(
#'   "f <- function(x) x + 1; g <- function(x) x - 1; h <- function(x) 0",
#'   "f(1)"
#' )
#' print(cov, group = "functions", n = 2)
#'
#' cov <- code_coverage(
#'   "f <- function(x) {\n  if (x) {\n    1\n\n    # no\n    2\n  }\n}",
#'   "f(FALSE)"
#' )
#' print(cov, missing = TRUE)
#' @export
print.coverage <- function(
  x,
  group = c("filename", "functions"),
  by = "line",
  n = Inf,
  missing = FALSE,
  ...
) {
  if (length(x) == 0) {
    return()
  }
  group <- match.arg(group)

  type <- attr(x, "type")

  if (is.null(type) || type == "none") {
    type <- NULL
  }

  df <- tally_coverage(x, by = by)

  if (!NROW(df)) {
    return(invisible())
  }

  # Each line counts once for its file, but once for each function on it.
  counted <- if (group == "filename" && !is.null(df$line)) {
    collapse_lines(df)
  } else {
    df
  }
  percents <- tapply(counted$value, counted[[group]], FUN = percent_covered)

  overall_percentage <- percent_coverage(df, by = by)
  styles <- console_styles()

  branches <- tally_coverage(x, by = "branch")
  if (!NROW(branches)) {
    branches <- NULL
  }
  header <- paste0(
    cli::style_bold(
      "{attr(x, 'package')$package} {to_title(type)} Coverage: "
    ),
    format_percentage(overall_percentage, styles)
  )
  if (!is.null(branches)) {
    header <- paste0(
      header,
      " (branches ",
      format_percentage(percent_coverage(x, by = "branch"), styles),
      ")"
    )
  }
  msg <- cli::format_message(header)
  message(msg)
  by_coverage <- percents[order(percents, names(percents))]

  missed <- if (missing && identical(by, "line")) {
    missed_ranges_by(df, group, non_code_lines(x))
  }
  missed_branches <- if (missing && !is.null(branches)) {
    missed_branches_by(branches, group)
  }

  shown <- by_coverage[seq_len(min(n, length(by_coverage)))]
  msgs <- format_messages(
    paste0(
      cli::style_bold(names(shown), ": "),
      vcapply(shown, format_percentage, styles = styles)
    )
  )
  for (i in seq_along(shown)) {
    msg <- msgs[[i]]
    # Outside of format_message(), which would collapse the spaces.
    name <- names(shown)[i]
    if (name %in% names(missed)) {
      msg <- paste0(msg, "  missed ", missed[[name]])
    }
    if (name %in% names(missed_branches)) {
      msg <- paste0(msg, "  missed branches ", missed_branches[[name]])
    }
    message(msg)
  }
  if (length(by_coverage) > n) {
    rest <- length(by_coverage) - n
    noun <- if (group == "filename") "file" else "function"
    message(
      "... and ",
      rest,
      " more ",
      noun,
      if (rest != 1) "s",
      "; use `print(x, n = Inf)` to show all"
    )
  }
  invisible(x)
}

# `cli::format_message()` of each element of `lines`. Formatting them as one
# text with `\f` (a line break for cli) between them is much faster, but only
# possible when no line is wrapped, as otherwise the output can't be split back
# into the lines.
format_messages <- function(lines, .envir = parent.frame()) {
  if (!length(lines)) {
    return(character())
  }
  text <- paste(lines, collapse = "\f")
  res <- strsplit(cli::format_message(text, .envir = .envir), "\n")[[1]]
  if (length(res) != length(lines)) {
    res <- vapply(
      lines,
      cli::format_message,
      character(1),
      .envir = .envir,
      USE.NAMES = FALSE
    )
  }
  res
}

# The missed ranges of each file or function, a named character vector. `df` is
# the tally by line and `non_code` the non-code lines of each file, so a
# missed line is joined to the next only if everything between them is
# non-code.
missed_ranges_by <- function(df, group, non_code) {
  df <- df[!is.na(df$value) & df$value == 0, , drop = FALSE]
  df <- df[!is.na(df[[group]]), , drop = FALSE]
  df$filename <- as.character(df$filename)

  by_group <- split(df, df[[group]])
  vapply(
    by_group,
    function(rows) {
      by_file <- split(rows$line, rows$filename)
      pieces <- unlist(lapply(
        names(by_file),
        function(file) range_pieces(by_file[[file]], non_code[[file]])
      ))
      cap_items(pieces, print_max_ranges())
    },
    character(1)
  )
}

# The maximum number of missed ranges or branches listed per row by `print()`,
# from the option `covr.print_max_ranges` (default 10, `Inf` for no limit).
print_max_ranges <- function() {
  max <- getOption("covr.print_max_ranges", 10)
  if (!is.numeric(max) || length(max) != 1 || is.na(max) || max < 0) {
    stop(
      "`covr.print_max_ranges` must be a single non-negative number.",
      call. = FALSE
    )
  }
  max
}

# Joins `items` with commas, keeping at most `max` of them and ending with
# ", ... (<k> more)" if any were left out. The one rule for capping listed
# ranges and branches.
cap_items <- function(items, max = Inf) {
  if (length(items) > max) {
    more <- length(items) - max
    items <- c(items[seq_len(max)], sprintf("... (%d more)", more))
  }
  paste(items, collapse = ", ")
}

# The untaken branches in the branch tally `df` whose `if` or `switch()` was
# evaluated, i.e. where another branch of the same construct (filename, line,
# column) was taken. Unevaluated constructs are covered by the missed lines.
evaluated_missed_branches <- function(df) {
  key <- paste(df$filename, df$line, df$column)
  evaluated <- unique(key[!is.na(df$value) & df$value > 0])
  df[!is.na(df$value) & df$value == 0 & key %in% evaluated, , drop = FALSE]
}

# The missed branches of each file or function, a named character vector, from
# the branch tally `df`.
missed_branches_by <- function(df, group) {
  df <- evaluated_missed_branches(df)
  df <- df[!is.na(df[[group]]), , drop = FALSE]
  df$filename <- as.character(df$filename)
  vapply(
    split(df, df[[group]]),
    function(rows) cap_items(branch_pieces(rows), print_max_ranges()),
    character(1)
  )
}

# The missed branches in `df`, rows of the branch tally with a `value` of zero,
# as `<line> <label>` strings ordered by line, then branch, e.g.
# c("12 FALSE", "30 b").
branch_pieces <- function(df) {
  df <- df[order(df$line, df$branch), , drop = FALSE]
  paste(df$line, df$label)
}

# Formats the missed branches in `df` joined by commas, e.g. "12 FALSE, 30 b",
# with at most `max` of them (see `cap_items()`).
format_branches <- function(df, max = Inf) {
  cap_items(branch_pieces(df), max)
}

# The missed `lines` of a file as ranges, e.g. c("41-48", "112"). Two missed
# lines are in the same range only if every line between them is in `non_code`
# (blank lines, comments and punctuation); covered code, and code without
# coverage data, such as a function header, ends the range.
range_pieces <- function(lines, non_code = integer()) {
  lines <- sort(unique(as.integer(lines)))
  if (!length(lines)) {
    return(character())
  }

  joined <- vapply(
    seq_len(length(lines) - 1L),
    function(i) {
      between <- seq_len(lines[[i + 1L]] - lines[[i]] - 1L) + lines[[i]]
      all(between %in% non_code)
    },
    logical(1)
  )
  run <- cumsum(c(TRUE, !joined))
  starts <- tapply(lines, run, min)
  ends <- tapply(lines, run, max)
  as.character(ifelse(starts == ends, starts, paste0(starts, "-", ends)))
}

# Formats the missed `lines` of a file as ranges, e.g. "41-48, 112", with at
# most `max` of them (see `cap_items()`).
missed_ranges <- function(lines, non_code = integer(), max = Inf) {
  cap_items(range_pieces(lines, non_code), max)
}

#' @export
print.coverages <- function(x, ...) {
  for (i in seq_along(x)) {
    # Add a blank line between consecutive coverage items
    if (i != 1) {
      message()
    }
    print(x[[i]], ...)
  }
  invisible(x)
}

# The styles of the coverage percentages, following `covr.report_colors`.
# Colors that aren't set keep the default green (>= 90%), yellow (>= 75%;
# `partial`, or `covered` if only that is set) and red. An invalid option only
# warns, so it doesn't stop coverage objects from printing.
console_styles <- function() {
  colors <- tryCatch(report_colors(), error = function(e) {
    note <- cli::format_message(c(i = "Using the default colors."))
    warning(structure(
      list(message = paste0(conditionMessage(e), "\n", note), call = NULL),
      class = c("warning", "condition")
    ))
    NULL
  })
  custom <- if (is.null(colors)) character() else colnames(colors)
  custom <- intersect(custom, names(getOption("covr.report_colors")))
  style <- function(type, default) {
    if (type %in% custom) {
      cli::make_ansi_style(rgb_hex(colors[, type]))
    } else {
      default
    }
  }

  list(
    high = style("covered", cli::col_green),
    mid = style(
      if ("partial" %in% custom) "partial" else "covered",
      cli::col_yellow
    ),
    low = style("missed", cli::col_red)
  )
}

format_percentage <- function(x, styles = console_styles()) {
  styles[[coverage_level(x)]](sprintf("%02.2f%%", x))
}

rstudio_has_source_markers <- function() {
  is_installed("rstudioapi") &&
    rstudioapi::hasFun("sourceMarkers")
}

# nocov start
rstudio_source_markers <- function(markers, base_path) {
  rstudioapi::callFun(
    "sourceMarkers",
    name = "covr",
    markers = markers,
    basePath = base_path,
    autoSelect = "first"
  )
}
# nocov end

source_markers <- function(x, type = "test") {
  Map(
    function(filename, line, column) {
      list(
        type = "warning",
        file = filename,
        line = line,
        column = column %||% 1,
        message = sprintf("No %s Coverage!", to_title(type))
      )
    },
    x$filename,
    x$first_line %||% x$line,
    x$first_column %||% rep(list(NULL), NROW(x)),
    USE.NAMES = FALSE
  )
}
