exclude <- function(coverage,
  exclusions = NULL, exclude_pattern = options("covr.exclude_pattern"),
  exclude_start = options("covr.exclude_start"),
  exclude_end = options("covr.exclude_end"),
  path = NULL) {

  sources <- traced_files(coverage)

  source_exclusions <- lapply(sources,
    function(x) {
      parse_exclusions(x$file_lines, exclude_pattern, exclude_start, exclude_end)
    })

  names(source_exclusions) <- lapply(sources, display_name)

  excl <- normalize_exclusions(c(source_exclusions, exclusions), path)

  df <- as.data.frame(coverage, sort = FALSE)

  df$full_name <- vapply(coverage,
    function(x) {
      normalizePath(getSrcFilename(x$srcref, full.names = TRUE), mustWork = FALSE)
    },
    character(1))

  to_exclude <- vapply(seq_len(NROW(df)),
    function(i) {
      file <- df[i, "full_name"]
      which_exclusion <- match(file, names(excl))

      !is.na(which_exclusion) &&
        (
          excl[[which_exclusion]] == Inf ||
          all(seq(df[i, "first_line"], df[i, "last_line"]) %in% excl[[file]])
        )
    },
    logical(1))

  if (any(to_exclude)) {
    coverage <- coverage[!to_exclude]
  }

  coverage
}

parse_exclusions <- function(lines,
                             exclude_pattern = getOption("covr.exclude"),
                             exclude_start = getOption("covr.exclude_start"),
                             exclude_end = getOption("covr.exclude_end")) {

  exclusions <- numeric(0)

  starts <- which(rex::re_matches(lines, exclude_start))
  ends <- which(rex::re_matches(lines, exclude_end))

  if (length(starts) > 0) {
    if (length(starts) != length(ends)) {
      stop(length(starts), " starts but only ", length(ends), " ends!")
    }

    for(i in seq_along(starts)) {
      exclusions <- c(exclusions, seq(starts[i], ends[i]))
    }
  }

  exclusions <- c(exclusions, which(rex::re_matches(lines, exclude_pattern)))

  sort(unique(exclusions))
}

file_exclusions <- function(x, path = NULL) {
  excl <- normalize_exclusions(x, path)

  full_files <- vapply(excl, function(x1) length(x1) == 1 && x1 == Inf, logical(1))
  if (any(full_files)) {
    names(excl)[full_files]
  } else {
    NULL
  }
}

normalize_exclusions <- function(x, path = NULL) {
  if (is.null(x) || length(x) <= 0) {
    return(list())
  }

  # no named parameters at all
  if (is.null(names(x))) {
    x <- structure(relist(rep(Inf, length(x)), x), names = x)
  } else {
    unnamed <- names(x) == ""
    if (any(unnamed)) {

      # must be character vectors of length 1
      bad <- vapply(seq_along(x),
        function(i) {
          unnamed[i] & (!is.character(x[[i]]) | length(x[[i]]) != 1)
        },
        logical(1))

      if (any(bad)) {
        stop("Full file exclusions must be character vectors of length 1. items: ",
             paste(collapse = ", ", which(bad)),
             " are not!",
             call. = FALSE)
      }
      names(x)[unnamed] <- x[unnamed]
      x[unnamed] <- Inf
    }
  }

  if (!is.null(path)) {
    names(x) <- file.path(path, names(x))
  }
  names(x) <- normalizePath(names(x), mustWork = FALSE)

  remove_line_duplicates(
    remove_file_duplicates(
      remove_empty(x)
    )
  )
}

remove_file_duplicates <- function(x) {
  unique_names <- unique(names(x))

  ## check for duplicate files
  if (length(unique_names) < length(names(x))) {
    x <- lapply(unique_names,
                function(name) {
                  vals <- unname(unlist(x[names(x) == name]))
                  if (any(vals == Inf)) {
                    Inf
                  } else {
                    vals
                  }
                })

    names(x) <- unique_names
  }

  x
}

remove_line_duplicates <- function(x) {
  x[] <- lapply(x, unique)

  x
}

remove_empty <- function(x) {
  x[vapply(x, length, numeric(1)) > 0]
}
