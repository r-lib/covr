#' Convert a coverage object to a data frame
#'
#' @param x a coverage object, as returned by [package_coverage()].
#' @param row.names,optional ignored, for compatibility with
#'   [base::as.data.frame()].
#' @param sort if `TRUE` (the default), sum the counts of identical
#'   expressions and sort the rows by file and position. If `FALSE`, there is
#'   one row for each element of `x`, in the same order.
#' @param ... ignored.
#' @return A data frame with one row for each traced expression of R code and
#'   each line of compiled code, and the columns:
#'
#'   * `filename`: the source file, relative to the `root` attribute of `x`
#'     (the package directory, for [package_coverage()]) if there is one.
#'   * `functions`: the name of the function containing the expression, or
#'     `NA` for compiled code.
#'   * `first_line`, `last_line`: the lines the expression starts and ends on.
#'   * `first_byte`, `last_byte`: the bytes of those lines the expression
#'     starts and ends at.
#'   * `first_column`, `last_column`: the columns the expression starts and
#'     ends at. These differ from the bytes when the line contains multibyte
#'     characters.
#'   * `first_parsed`, `last_parsed`: the lines as seen by the parser. These
#'     differ from `first_line` and `last_line` when the source uses `#line`
#'     directives.
#'   * `value`: the number of times the expression was executed.
#'
#'   Use [tally_coverage()] for one row for each line instead.
#' @examples
#' cov <- code_coverage("add <- function(x, y) { x + y }", "add(1, 2)")
#' as.data.frame(cov)
#' @export
as.data.frame.coverage <- function(
  x,
  row.names = NULL,
  optional = FALSE,
  sort = TRUE,
  ...
) {
  column_names <- c(
    "filename",
    "functions",
    "first_line",
    "first_byte",
    "last_line",
    "last_byte",
    "first_column",
    "last_column",
    "first_parsed",
    "last_parsed",
    "value"
  )

  res <- setNames(
    c(
      list(character(0)),
      rep(list(numeric(0)), times = length(column_names) - 1)
    ),
    column_names
  )
  if (length(x)) {
    res$filename <- display_name(x)
    res$functions <- vcapply(x, function(xx) xx$functions[1])

    vals <- t(vapply(
      x,
      function(xx) c(xx$srcref, xx$value),
      numeric(9),
      USE.NAMES = FALSE
    ))
    for (i in seq_len(NCOL(vals))) {
      res[[i + 2]] <- vals[, i]
    }
  }

  df <- data.frame(res, stringsAsFactors = FALSE, check.names = FALSE)

  if (sort) {
    # if we are sorting we no longer need to preserve the order of the input and can merge values together
    df <- merge_values(df)

    df <- df[
      order(
        df$filename,
        df$first_line,
        df$first_byte,
        df$last_line,
        df$last_byte
      ),
    ]
  }

  rownames(df) <- NULL

  df
}

merge_values <- function(x, sentinel = "___NA___") {
  if (NROW(x) == 0) {
    return(x)
  }
  # We can't use aggregate directly, because it doesn't allow missing values in
  # grouping variables...
  x$functions[is.na(x$functions)] <- sentinel
  res <- aggregate(value ~ ., x, sum)
  res$functions[res$functions == sentinel] <- NA_character_
  res
}
