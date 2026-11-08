#' Provide percent coverage of package
#'
#' Calculate the total percent coverage from a coverage result object.
#' @param x the coverage object returned from [package_coverage()]
#' @param ... additional arguments passed to [tally_coverage()]
#' @return The total percentage as a `numeric(1)`.
#' @export
percent_coverage <- function(x, ...) {
  res <- tally_coverage(x, ...)
  if (!is.null(res$line)) {
    res <- collapse_lines(res)
  }

  (sum(res$value > 0) / length(res$value)) * 100
}

#' Tally coverage by line, expression or function
#'
#' @inheritParams percent_coverage
#' @param by whether to tally coverage by line, expression or function
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
#' @examples
#' cov <- code_coverage(
#'   "f <- function(x) {\n  if (x) 'yes' else 'no'\n}\ng <- function() 1",
#'   "f(TRUE)"
#' )
#' tally_coverage(cov)
#' tally_coverage(cov, by = "expression")
#' tally_coverage(cov, by = "function")
#' @export
tally_coverage <- function(x, by = c("line", "expression", "function")) {
  # Rarely something goes wrong with the source references and we get all NAs
  # for them, so we omit them here
  df <- as.data.frame(x)

  all_na_rows <- rowSums(is.na(df)) == ncol(df)
  df <- df[!all_na_rows, ]

  if (NROW(df) == 0) {
    return(df)
  }

  by <- match.arg(by)

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
innermost_lines <- function(df) {
  rows <- rep(seq_len(NROW(df)), df$last_line - df$first_line + 1L)
  res <- df[rows, c("filename", "functions", "value")]
  res$line <- unlist(Map(seq, df$first_line, df$last_line))
  res$row <- rows
  rownames(res) <- NULL

  pairs <- merge(
    res[c("filename", "line", "row")],
    res[c("filename", "line", "row")],
    by = c("filename", "line")
  )
  outer <- pairs[which(contains(df, pairs$row.x, pairs$row.y)), ]
  keep <- !paste(res$row, res$line) %in% paste(outer$row.x, outer$line)

  res[keep, c("filename", "functions", "line", "value")]
}

# Whether expression `i` of `df` contains a different expression `j`.
contains <- function(df, i, j) {
  starts_before <- df$first_line[i] < df$first_line[j] |
    (df$first_line[i] == df$first_line[j] &
      df$first_byte[i] <= df$first_byte[j])
  ends_after <- df$last_line[i] > df$last_line[j] |
    (df$last_line[i] == df$last_line[j] & df$last_byte[i] >= df$last_byte[j])
  same <- df$first_line[i] == df$first_line[j] &
    df$first_byte[i] == df$first_byte[j] &
    df$last_line[i] == df$last_line[j] &
    df$last_byte[i] == df$last_byte[j]

  starts_before & ends_after & !same
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
  keep <- setdiff.data.frame(
    res,
    lines,
    by.x = c("filename", "line"),
    by.y = c("ind", "values")
  )
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
      rstudioapi::hasFun("sourceMarkers")
  ) {
    markers <- markers(coverage_data)
    rstudioapi::callFun(
      "sourceMarkers",
      name = "covr",
      markers = markers,
      basePath = attr(x, "package")$path,
      autoSelect = "first"
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
  percents <- tapply(counted$value, counted[[group]], FUN = function(x) {
    (sum(x > 0) / length(x)) * 100
  })

  overall_percentage <- percent_coverage(df, by = by)

  msg <- cli::format_message(paste0(
    cli::style_bold(
      "{attr(x, 'package')$package} {to_title(type)} Coverage: "
    ),
    format_percentage(overall_percentage)
  ))
  message(msg)
  by_coverage <- percents[order(percents, names(percents))]

  for (i in seq_len(min(n, length(by_coverage)))) {
    msg <- cli::format_message(
      paste0(
        cli::style_bold(names(by_coverage)[i], ": "),
        format_percentage(by_coverage[i])
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

format_percentage <- function(x) {
  color <- if (x >= 90) {
    cli::col_green
  } else if (x >= 75) {
    cli::col_yellow
  } else {
    cli::col_red
  }

  color(sprintf("%02.2f%%", x))
}

markers <- function(x, ...) UseMethod("markers")

#' @export
markers.coverages <- function(x, ...) {
  mrks <- unlist(lapply(unname(x), markers), recursive = FALSE)

  mrks <- mrks[order(
    vcapply(mrks, `[[`, "file"),
    viapply(mrks, `[[`, "line"),
    vcapply(mrks, `[[`, "message")
  )]

  # request source markers
  rstudioapi::callFun(
    "sourceMarkers",
    name = "covr",
    markers = mrks,
    basePath = NULL,
    autoSelect = "first"
  )
  invisible()
}
#' @export
markers.coverage <- function(x, ...) {
  # generate the markers
  markers <- lapply(unname(x), function(xx) {
    filename <- get_source_filename(xx$srcref, full.names = TRUE)

    list(
      type = "warning",
      file = filename,
      line = xx$srcref[1],
      column = xx$srcref[2],
      message = sprintf("No %s Coverage!", to_title(attr(x, "type")))
    )
  })
}

#' @export
markers.data.frame <- function(x, ..., type = "test") {
  # nolint
  # generate the markers
  markers <- Map(
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
