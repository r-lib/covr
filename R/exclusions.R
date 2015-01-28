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

  # Drop non-excludes
  stopifnot(!any(duplicated(names(excl)))) ## Sanity check
  excl <- excl[sapply(excl, FUN=length) > 0L]

  str(list(df=df$filename, cov=names(coverage)))
  stopifnot(all(df$filename, names(coverage)))

  to_exclude <- vapply(seq_len(NROW(df)),
    function(i) {
      file <- df[i,"filename"]
      res <- file %in% names(excl) &&
      all(seq(df[i,"first_line"], df[i, "last_line"]) %in% excl[[file]])

      if (file == "R/abort.R") {
        stopifnot(file %in% names(excl))
        seq <- seq(df[i,"first_line"], df[i, "last_line"])
        drop <- all(seq %in% excl[[file]])
        str(list(df[i,], seq=seq, excl=excl[[file]], drop=drop, res=res))
        stopifnot(identical(res, drop))
      }

      res;
  }, logical(1))

  if (any(to_exclude)) {
      ok <- (df$filename == "R/abort.R")
      print(df[ok & !to_exclude,])
      stopifnot(length(coverage) == length(to_exclude))
      print(grep("R/abort.R", names(coverage), value=TRUE))
      print(length(coverage))
      print(sum(to_exclude))
      print(names(coverage)[to_exclude])
      coverage <- coverage[!to_exclude]
      print(grep("R/abort.R", names(coverage), value=TRUE))
      print(length(coverage))
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
