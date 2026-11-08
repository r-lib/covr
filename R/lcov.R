#' Create an LCOV tracefile
#'
#' Write coverage in the LCOV tracefile format described in
#' [geninfo(1)](https://manpages.debian.org/unstable/lcov/geninfo.1.en.html),
#' which is read by `genhtml`, Codecov, Coveralls, SonarQube and editor
#' plugins such as Coverage Gutters.
#'
#' Each source file gets a record with its functions (`FN`, `FNDA`, `FNF`,
#' `FNH`) and lines (`DA`, `LF`, `LH`). Line counts are those of
#' [tally_coverage()] with `by = "line"`, and a function's count is the
#' largest count of any of its expressions. Branch coverage is not recorded.
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
  lines <- tally_coverage(cov, by = "line")
  funs <- tally_coverage(cov, by = "function")

  files <- sort(unique(as.character(c(lines$filename, funs$filename))))

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
