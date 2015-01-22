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

