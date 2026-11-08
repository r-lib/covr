#' Create an LCOV tracefile
#'
#' Write coverage in the LCOV tracefile format described in
#' [geninfo(1)](https://manpages.debian.org/unstable/lcov/geninfo.1.en.html),
#' which is read by `genhtml`, Codecov, Coveralls, SonarQube and editor
#' plugins such as Coverage Gutters.
#'
#' Each source file gets a record with its functions (`FN`, `FNDA`, `FNF`,
#' `FNH`) and lines (`DA`, `LF`, `LH`). Line counts are those of
#' [tally_coverage()] with `by = "line"`, combined so that each source line
#' has a single `DA` record: when several functions share a line, the line's
#' count is the smallest of theirs, so a line only counts as covered if all its
#' code was run, as in [report()], [percent_coverage()] and [codecov()]. A
#' function's count is the largest count of any of its expressions.
#'
#' Branches are only recorded if they were measured with
#' `options(covr.branch_coverage = TRUE)` (see [covr.branch_coverage]). Each
#' branch gets a `BRDA` record on the line where its `if` or `switch()`
#' starts, numbered from zero within each `if` or `switch()`. Its count is `-`
#' if the `if` or `switch()` never ran. `BRF` and `BRH` give the number of
#' branches and the number of branches taken.
#'
#' Source file paths (`SF`) are written as covr reports them, for a package
#' relative to the package root, so tools such as `genhtml` should be run from
#' that directory.
#'
#' @param cov the coverage object returned from [package_coverage()]
#' @param filename the name of the LCOV file
#' @return The lines of the LCOV file, invisibly.
#' @examples
#' cov <- code_coverage(
#'   "f <- function(x) {\n  y <- x + 1\n  y * 2\n}\ng <- function() 1",
#'   "f(1)"
#' )
#' tmp <- tempfile(fileext = ".info")
#' to_lcov(cov, tmp)
#' cat(readLines(tmp), sep = "\n")
#' @export
to_lcov <- function(cov, filename = "lcov.info") {
  lines <- collapse_lines(tally_coverage(cov, by = "line"))
  funs <- tally_coverage(cov, by = "function")
  branches <- if (!is.null(attr(cov, "branches"))) {
    tally_coverage(cov, by = "branch")
  }

  files <- sort(unique(as.character(c(
    lines$filename,
    funs$filename,
    branches$filename
  ))))

  out <- unlist(lapply(files, function(f) {
    file_lines <- lines[lines$filename == f, , drop = FALSE]
    file_funs <- funs[funs$filename == f, , drop = FALSE]
    c(
      "TN:",
      paste0("SF:", f),
      lcov_records("FN", file_funs$first_line, file_funs$functions),
      lcov_records("FNDA", file_funs$value, file_funs$functions),
      paste0("FNF:", NROW(file_funs)),
      paste0("FNH:", sum(file_funs$value > 0)),
      if (!is.null(branches)) {
        lcov_branches(branches[branches$filename == f, , drop = FALSE])
      },
      lcov_records("DA", file_lines$line, lcov_count(file_lines$value)),
      paste0("LF:", NROW(file_lines)),
      paste0("LH:", sum(file_lines$value > 0)),
      "end_of_record"
    )
  }))
  out <- as.character(out)

  writeLines(out, filename)

  invisible(out)
}

# One `KEY:count,value` line for each element; `count` is a double, so avoid
# scientific notation such as 1e+05.
lcov_records <- function(key, count, value) {
  if (length(count) == 0) {
    return(character())
  }
  paste0(key, ":", lcov_count(count), ",", value)
}

lcov_count <- function(x) {
  sprintf("%.0f", x)
}

# The `BRDA`, `BRF` and `BRH` records of the branches of one file, from
# `tally_coverage(by = "branch")`, which sorts them by line and column. Within
# each line, `block` numbers its `if` and `switch()` calls from zero in the
# order they start.
lcov_branches <- function(df) {
  decision <- match(
    paste(df$line, df$column),
    unique(paste(df$line, df$column))
  )
  block <- decision - decision[match(df$line, df$line)]
  ran <- tapply(df$value, decision, sum)[decision] > 0
  taken <- ifelse(ran, lcov_count(df$value), "-")
  c(
    if (NROW(df)) {
      paste0("BRDA:", df$line, ",", block, ",", df$branch - 1L, ",", taken)
    },
    paste0("BRF:", NROW(df)),
    paste0("BRH:", sum(df$value > 0))
  )
}
