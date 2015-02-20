exclude <- function(coverage, exclusions = NULL, ...) {
  df <- as.data.frame(coverage)

  filenames <- unique(df$filename)

  full_filenames <-
    if (!is.null(attr(coverage, "path"))) {
      file.path(attr(coverage, "path"), filenames)
    } else {
      filenames
    }

  source_exclusions <- lapply(full_filenames, parse_exclusions, ...)
  names(source_exclusions) <- filenames

  excl <- merge_exclusions(source_exclusions, exclusions)

  to_exclude <- vapply(seq_len(NROW(df)),
    function(i) {
      file <- df[i, "filename"]
      file %in% names(excl) &&
      all(seq(df[i, "first_line"], df[i, "last_line"]) %in% excl[[file]])
    },
    logical(1)
  )

  if (any(to_exclude) == TRUE) {
    coverage <- coverage[-as.numeric(sort(rownames(df)[to_exclude]))]
  }

  coverage
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
