full_exclusions <- function(coverage, exclusions) {
  res <- as.data.frame(coverage)

  filenames <- unique(res$filename)

  if (!is.null(attr(coverage, "path"))) {
    filenames <- file.path(attr(coverage, "path"), filenames)
  }

  source_exclusions <- lapply(filenames, parse_exclusions)

  merge_exclusion(source_exclusions, exclusions)
}

parse_exclusions <- function(file, exclude_pattern = rex::rex("#", any_spaces, "EXCLUDE COVERAGE"),
                                   exclude_start = rex::rex("#", any_spaces, "EXCLUDE COVERAGE START"),
                                   exclude_end = rex::rex("#", any_spaces, "EXCLUDE COVERAGE END")) {
  lines <- readLines(file)

  exclusions <- numeric(0)

  starts <- which(rex::re_matches(lines, exclude_start))
  ends <- which(rex::re_matches(lines, exclude_end))

  if (length(starts) > 0) {
    if (length(starts) != length(ends)) {
      stop(file, " has ", length(starts), " starts but only ", length(ends), " ends!")
    }

    for(i in seq_along(starts)) {
      exclusions <- c(exclusions, seq(starts[i], ends[i]))
    }
  }

  exclusions <- c(exclusions, which(rex::re_matches(lines, exclude_pattern)))

  sort(unique(exclusions))
}

merge_exclusions <- function(x, y) {
  nms <- union(names(x), names(y))
  res <- lapply(union(names(x), names(y)), function(name) union(x[[name]], y[[name]]))
  names(res) <- nms
  res
}
