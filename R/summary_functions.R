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

  # results with NA functions (such as from compiled code) are dropped
  # unless NA is a level.
  df$functions <- addNA(df$functions)
  res <- innermost_lines(df)

  res <- aggregate(
    value ~ filename + functions + line,
    data = res,
    FUN = min,
    na.action = na.pass
  )
  res$functions <- as.character(res$functions)

  if (inherits(x, "coverage")) {
    res <- drop_lines(res, non_code_lines(x))
    res <- drop_lines(res, attr(x, "excluded_lines"))
  }
  res[order(res$filename, res$line), ]
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
  node <- paste(df$filename, start, end, sep = "\r")
  nodes <- unique(node)
  id <- match(node, nodes)
  first <- match(seq_along(nodes), id)
  parent <- nesting_parents(df$filename[first], start[first], end[first])

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
  compact(lapply(traced_files(x), function(file) {
    which(
      rex::re_matches(
        file$file_lines,
        rex::rex(start, any_spaces, maybe("#", anything), end)
      ) |
        rex::re_matches(file$file_lines, "^(?:[[:punct:][:space:]]|else)*$")
    )
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
  res <- aggregate(
    value ~ filename + line,
    data = lines,
    FUN = min,
    na.action = na.pass
  )
  res[order(res$filename, res$line), ]
}

# Drops the rows of `res` for the lines in `lines`, a list of line numbers named
# by filename.
drop_lines <- function(res, lines) {
  if (!length(lines)) {
    return(res)
  }

  lines <- utils::stack(lines)
  keep <- !do.call(paste, c(res[c("filename", "line")], sep = "\30")) %in%
    do.call(paste, c(lines[c("ind", "values")], sep = "\30"))
  res[keep, ]
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
#' @param ... additional arguments ignored
#' @return The coverage object (invisibly).
#' @examples
#' cov <- code_coverage(
#'   "f <- function(x) x + 1; g <- function(x) x - 1; h <- function(x) 0",
#'   "f(1)"
#' )
#' print(cov, group = "functions", n = 2)
#' @export
print.coverage <- function(
  x,
  group = c("filename", "functions"),
  by = "line",
  n = Inf,
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

  msg <- cli::format_message(paste0(
    cli::style_bold(
      "{attr(x, 'package')$package} {to_title(type)} Coverage: "
    ),
    format_percentage(overall_percentage, styles)
  ))
  message(msg)
  by_coverage <- percents[order(percents, names(percents))]

  for (i in seq_len(min(n, length(by_coverage)))) {
    msg <- cli::format_message(
      paste0(
        cli::style_bold(names(by_coverage)[i], ": "),
        format_percentage(by_coverage[i], styles)
      )
    )
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
  requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::hasFun("sourceMarkers")
}

rstudio_source_markers <- function(markers, base_path) {
  rstudioapi::callFun(
    "sourceMarkers",
    name = "covr",
    markers = markers,
    basePath = base_path,
    autoSelect = "first"
  )
}

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
