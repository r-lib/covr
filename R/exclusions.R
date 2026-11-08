#' Exclusions
#'
#' covr supports a couple of different ways of excluding some or all of a file.
#'
#' @section Line Exclusions:
#'
#' The `line_exclusions` argument to `package_coverage()` can be used
#' to exclude some or all of a file.  This argument takes a list of filenames
#' or named ranges to exclude.
#'
#' @section Function Exclusions:
#'
#' Alternatively `function_exclusions` can be used to exclude R functions
#' based on regular expression(s). For example `print\\\.*` can be used to
#' exclude all the print methods defined in a package from coverage.
#'
#' @section Exclusion Comments:
#'
#' In addition you can exclude lines from the coverage by putting special comments
#' in your source code. This can be done per line or by specifying a range.
#' The patterns used can be specified by the `exclude_pattern`, `exclude_start`,
#' `exclude_end` arguments to `package_coverage()` or by setting the global
#' options `covr.exclude_pattern`, `covr.exclude_start`, `covr.exclude_end`.

#' @examples
#' \dontrun{
#' # exclude whole file of R/test.R
#' package_coverage(exclusions = "R/test.R")
#'
#' # exclude lines 1 to 10 and 15 from R/test.R
#' package_coverage(line_exclusions = list("R/test.R" = c(1:10, 15)))
#'
#' # exclude lines 1 to 10 from R/test.R, all of R/test2.R
#' package_coverage(line_exclusions = list("R/test.R" = 1:10, "R/test2.R"))
#'
#' # exclude all print and format methods from the package.
#' package_coverage(function_exclusions = c("print\\.", "format\\."))
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

exclude <- function(
  coverage,
  line_exclusions = NULL,
  function_exclusions = NULL,
  exclude_pattern = getOption("covr.exclude_pattern"),
  exclude_start = getOption("covr.exclude_start"),
  exclude_end = getOption("covr.exclude_end"),
  path = NULL
) {
  sources <- traced_files(coverage)

  source_exclusions <- Map(
    function(x, file) {
      parse_exclusions(
        x$file_lines,
        exclude_pattern,
        exclude_start,
        exclude_end,
        file = file
      )
    },
    sources,
    names(sources)
  )

  excl <- normalize_exclusions(c(source_exclusions, line_exclusions), path)

  df <- as.data.frame(coverage, sort = FALSE)

  to_exclude <- rep(FALSE, length(coverage))

  if (!is.null(function_exclusions)) {
    to_exclude <- Reduce(
      `|`,
      init = to_exclude,
      Map(
        rex::re_matches,
        function_exclusions,
        MoreArgs = list(data = df$functions)
      )
    )
    to_exclude[is.na(to_exclude)] <- FALSE
  }

  df$full_name <- vcapply(coverage, function(x) {
    normalize_path(get_source_filename(x$srcref, full.names = TRUE))
  })

  to_exclude <- to_exclude |
    vlapply(seq_len(NROW(df)), function(i) {
      file <- df[i, "full_name"]
      which_exclusion <- match(file, names(excl))

      !is.na(which_exclusion) &&
        (identical(excl[[which_exclusion]], Inf) ||
          (!is.na(df[i, "first_line"]) &&
            !is.na(df[i, "last_line"]) &&
            all(
              seq(df[i, "first_line"], df[i, "last_line"]) %in% excl[[file]]
            )))
    })

  if (any(to_exclude)) {
    coverage <- coverage[!to_exclude]
  }

  # Expressions spanning several lines are only dropped if all of their lines
  # are excluded, so record the excluded lines to leave them out of line
  # coverage, e.g. the `# nocov` lines of a function defined in a function.
  attr(coverage, "excluded_lines") <- excluded_lines(df[!to_exclude, ], excl)

  coverage
}

excluded_lines <- function(df, excl) {
  files <- unique(df[c("filename", "full_name")])
  lines <- lapply(files$full_name, function(file) {
    lines <- excl[[file]]
    if (identical(lines, Inf)) NULL else lines
  })
  compact(setNames(lines, files$filename))
}

parse_exclusions <- function(
  lines,
  exclude_pattern = getOption("covr.exclude"),
  exclude_start = getOption("covr.exclude_start"),
  exclude_end = getOption("covr.exclude_end"),
  file = NULL
) {
  exclusions <- numeric(0)

  starts <- which(rex::re_matches(lines, exclude_start))
  ends <- which(rex::re_matches(lines, exclude_end))

  if (length(starts) > 0) {
    if (length(starts) != length(ends)) {
      describe <- function(x, what) {
        if (length(x) == 0) {
          return(paste0("0 ", what, "s"))
        }
        cli::pluralize(paste0("{length(x)} ", what, "{?s} (line{?s} {x})"))
      }
      found <- paste(describe(starts, "start"), "and", describe(ends, "end"))
      covr_abort(c(
        "Each exclusion range start must have a matching range end.",
        x = if (is.null(file)) {
          "Found {found}."
        } else {
          "{.file {file}} has {found}."
        }
      ))
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

  full_files <- vlapply(excl, function(x1) length(x1) == 1 && x1 == Inf)
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
      bad <- vlapply(seq_along(x), function(i) {
        unnamed[i] & (!is.character(x[[i]]) | length(x[[i]]) != 1)
      })

      if (any(bad)) {
        # Character, so cli pluralizes by the number of elements
        bad <- as.character(which(bad))
        covr_abort(c(
          "Each unnamed element of {.arg line_exclusions} must be a single file path.",
          x = "Element{?s} {bad} {?isn't/aren't}."
        ))
      }
      names(x)[unnamed] <- x[unnamed]
      x[unnamed] <- Inf
    }
  }

  if (!is.null(path)) {
    relative <- !is_absolute_path(names(x))
    names(x)[relative] <- file.path(path, names(x)[relative])
  }
  names(x) <- normalize_path(names(x))

  remove_line_duplicates(
    remove_file_duplicates(
      compact(x)
    )
  )
}

remove_file_duplicates <- function(x) {
  unique_names <- unique(names(x))

  ## check for duplicate files
  if (length(unique_names) < length(names(x))) {
    x <- lapply(unique_names, function(name) {
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

parse_covr_ignore <- function(
  file = getOption(
    "covr.covrignore",
    Sys.getenv("COVR_COVRIGNORE", ".covrignore")
  )
) {
  if (!file.exists(file)) {
    return(NULL)
  }
  lines <- readLines(file)
  paths <- Sys.glob(lines, dirmark = TRUE)
  files <- unlist(
    lapply(paths, function(x) {
      if (dir.exists(x)) {
        list.files(
          recursive = TRUE,
          all.files = TRUE,
          path = x,
          full.names = TRUE
        )
      } else {
        x
      }
    })
  )
}
