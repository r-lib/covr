repair_parse_data <- function(env) {
  srcref <- lapply(as.list(env), attr, "srcref")
  srcfile <- lapply(srcref, attr, "srcfile")
  parse_data <- compact(lapply(srcfile, "[[", "parseData"))
  if (length(parse_data) == 0L) {
    warning("Parse data not found, coverage may be inaccurate. Try declaring a function in the last file of your R package.",
            call. = FALSE)
    return()
  }

  if (!all_identical(parse_data)) {
    warning("Ambiguous parse data, coverage may be inaccurate.",
            call. = FALSE)
  }

  original <- compact(lapply(srcfile, "[[", "original"))
  if (!all_identical(parse_data)) {
    warning("Ambiguous original file, coverage may be inaccurate.",
            call. = FALSE)
  }

  original[[1]]$parseData <- parse_data[[1L]]
}

get_parse_data <- function(x) {
  if (inherits(x, "srcref"))
    get_parse_data(attr(x, "srcfile"))
  else if (exists("original", x))
    get_parse_data(x$original)
  else
    getParseData(x, includeText = FALSE)
}
