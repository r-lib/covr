#' Exclusions
#'
#' covr supports a couple of different ways of excluding some or all of a file.
#'
#' @section Exclusions Argument:
#'
#' The exclusions argument to \code{package_coverage()} can be used to exclude some or
#' all of a file.  This argument takes a list of filenames or named ranges to
#' exclude.
#'
#' @section Exclusion Comments:
#'
#' In addition you can exclude lines from the coverage by putting special comments
#' in your source code. This can be done per line or by specifying a range.
#' The patterns used can be specified by the \code{exclude_pattern}, \code{exclude_start},
#' \code{exclude_end} arguments to \code{package_coverage()} or by setting the global
#' options \code{covr.exclude_pattern}, \code{covr.exclude_start}, \code{covr.exclude_end}.

#' @examples
#' \dontrun{
#' # exclude whole file of R/test.R
#' package_coverage(exclusions = "R/test.R")
#'
#' # exclude lines 1 to 10 and 15 from R/test.R
#' package_coverage(exclusions = list("R/test.R" = c(1:10, 15)))
#'
#' # exclude lines 1 to 10 from R/test.R, all of R/test2.R
#' package_coverage(exclusions = list("R/test.R" = 1:10, "R/test2.R"))
#'
#' # single line exclusions
#' f1 <- function(x) {
#'   x + 1 # nocov
#' }
#'
#' # ranged exclusions
#' f2 <- function(x) { # nocov start
#'   x + 2
#' } # nocov end
#' }
#' @name exclusions
NULL

exclude <- function(coverage,
  line_exclusions = NULL,
  function_exclusions = NULL,
  exclude_pattern = getOption("covr.exclude_pattern"),
  exclude_start = getOption("covr.exclude_start"),
  exclude_end = getOption("covr.exclude_end"),
  path = NULL) {

  sources <- traced_files(coverage)

  source_exclusions <- lapply(sources,
    function(x) {
      parse_exclusions(x$file_lines, exclude_pattern, exclude_start, exclude_end)
    })

  excl <- normalize_exclusions(c(source_exclusions, line_exclusions), path)

  df <- as.data.frame(coverage, sort = FALSE)

  to_exclude <- rep(FALSE, length(coverage))

  if (!is.null(function_exclusions)) {
    to_exclude <- Reduce(`|`, init = to_exclude,
      Map(rex::re_matches, function_exclusions, MoreArgs = list(data = df$functions)))
  }

  df$full_name <- vapply(coverage,
    function(x) {
      normalize_path(getSrcFilename(x$srcref, full.names = TRUE))
    },
    character(1))

  to_exclude <- to_exclude | vapply(seq_len(NROW(df)),
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

    for (i in seq_along(starts)) {
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
  names(x) <- normalize_path(names(x))

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
