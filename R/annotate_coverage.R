#' Annotate source code with line and branch coverage
#'
#' Produces plain text showing source lines together with their coverage
#' counts, in a form that is easy to read in a terminal or to paste into a
#' prompt. By default the missed lines are shown with `context` surrounding
#' lines.
#'
#' Each shown line has the line number, a count column and the source. Missed
#' lines are marked `!!0`, covered code lines show their hit count, and lines
#' without coverage data (blank lines, comments, ...) have an empty count.
#' Non-adjacent chunks are separated by `...`.
#'
#' If branch coverage was measured (see [covr.branch_coverage]), lines with a
#' branch that was not taken are also shown by default, followed by
#' `<- not taken:` and the labels of their missed branches. Only `if` and
#' `switch()` calls that were evaluated count; the others are covered by the
#' missed lines. Such a line keeps
#' its count if it was run.
#'
#' @param x A coverage object, e.g. from [package_coverage()] or
#'   [code_coverage()].
#' @param lines A data frame with `filename` and `line` columns identifying the
#'   lines to show, e.g. the result of [zero_coverage()] or the lines changed in
#'   a pull request. Other columns are ignored. The default is all missed code
#'   lines in `x`, and the lines with a missed branch if branch coverage was
#'   measured.
#' @param context Number of lines to show before and after each line in
#'   `lines`. Use `Inf` to show whole files.
#' @param files Optional character vector of file names (as they appear in the
#'   coverage, e.g. `"R/foo.R"`) to restrict the output to.
#' @param max_lines The maximum number of source lines to show, 200 by default
#'   (option `covr.annotate_max_lines`). Whole chunks of lines are added until
#'   the next one would go over the limit, but the first chunk is always shown.
#'   If anything is left out, the last line says how many of the missed or
#'   requested lines in how many files are not shown. Use `Inf` for no limit.
#' @return A character vector of class `covr_annotation`, with one element per
#'   output line. If there is nothing to show it is `"No missed lines."`.
#' @examples
#' source <- "
#' f <- function(x) {
#'   if (x) {
#'     'yes'
#'   } else {
#'     'no'
#'   }
#' }
#' "
#' cov <- code_coverage(source, "f(TRUE)")
#' annotate_coverage(cov)
#' annotate_coverage(cov, context = Inf)
#' @export
annotate_coverage <- function(
  x,
  lines = NULL,
  context = 2,
  files = NULL,
  max_lines = getOption("covr.annotate_max_lines", 200)
) {
  stopifnot(
    is.numeric(max_lines),
    length(max_lines) == 1,
    !is.na(max_lines)
  )
  stopifnot(is.numeric(context), length(context) == 1, !is.na(context))
  context <- max(context, 0)

  values <- collapse_lines(tally_coverage(x))
  missed_branches <- tally_coverage(x, by = "branch")
  missed_branches <- evaluated_missed_branches(missed_branches)
  if (is.null(lines)) {
    lines <- rbind(
      values[values$value == 0, c("filename", "line"), drop = FALSE],
      missed_branches[, c("filename", "line"), drop = FALSE]
    )
  }
  if (!is.null(files)) {
    lines <- lines[lines$filename %in% files, , drop = FALSE]
  }

  filenames <- unique(as.character(lines$filename))
  if (!length(filenames)) {
    return(structure("No missed lines.", class = "covr_annotation"))
  }

  sources <- traced_files(x)
  root <- attr(x, "package")$path

  chunks <- list()
  for (filename in filenames) {
    src <- sources[[filename]]$file_lines
    if (is.null(src) && !is.null(root)) {
      path <- file.path(root, filename)
      if (file.exists(path)) {
        src <- readLines(path, warn = FALSE)
      }
    }
    if (is.null(src)) {
      stop("Cannot find source for ", filename, call. = FALSE)
    }
    n <- length(src)

    targets <- sort(unique(lines$line[lines$filename == filename]))
    targets <- targets[targets >= 1 & targets <= n]
    if (!length(targets)) {
      next
    }

    if (is.finite(context)) {
      shown <- unique(unlist(lapply(targets, function(l) {
        seq.int(max(l - context, 1), min(l + context, n))
      })))
      shown <- sort(shown)
    } else {
      shown <- seq_len(n)
    }

    file_values <- values[values$filename == filename, , drop = FALSE]
    counts <- rep("", n)
    counts[file_values$line] <- ifelse(
      file_values$value == 0,
      "!!0",
      format(file_values$value, scientific = FALSE, trim = TRUE)
    )

    notes <- rep("", n)
    file_branches <- missed_branches[
      missed_branches$filename == filename & missed_branches$line <= n,
      ,
      drop = FALSE
    ]
    if (nrow(file_branches)) {
      labels <- tapply(
        as.character(file_branches$label),
        file_branches$line,
        paste,
        collapse = ", "
      )
      notes[as.integer(names(labels))] <- paste0("  <- not taken: ", labels)
    }

    num_width <- nchar(as.character(max(shown)))
    body <- paste0(
      formatC(shown, width = num_width),
      " | ",
      formatC(counts[shown], width = 4),
      " | ",
      src[shown],
      notes[shown]
    )
    gaps <- which(diff(shown) > 1)
    chunk_id <- cumsum(seq_along(shown) %in% (gaps + 1))
    chunks <- c(
      chunks,
      lapply(split(seq_along(shown), chunk_id), function(idx) {
        list(
          filename = filename,
          body = body[idx],
          targets = sum(targets %in% shown[idx])
        )
      })
    )
  }

  if (!length(chunks)) {
    return(structure("No missed lines.", class = "covr_annotation"))
  }

  # Keep whole chunks, in order, until the next would exceed `max_lines`; the
  # first is always kept.
  size <- vapply(chunks, function(chunk) length(chunk$body), integer(1))
  n_keep <- max(1L, sum(cumsum(size) <= max_lines))
  kept <- chunks[seq_len(n_keep)]
  dropped <- chunks[seq_len(length(chunks))[-seq_len(n_keep)]]

  out <- character()
  previous <- NULL
  for (chunk in kept) {
    if (!identical(chunk$filename, previous)) {
      out <- c(out, chunk$filename)
    } else {
      out <- c(out, "  ...")
    }
    out <- c(out, paste0("  ", chunk$body))
    previous <- chunk$filename
  }

  if (length(dropped)) {
    n_dropped <- sum(vapply(dropped, function(chunk) chunk$targets, numeric(1)))
    n_files <- length(unique(vapply(
      dropped,
      function(chunk) chunk$filename,
      character(1)
    )))
    out <- c(
      out,
      sprintf(
        paste0(
          "... %d more %s in %d %s not shown; narrow with `files` or ",
          "`lines`, or raise `max_lines`."
        ),
        n_dropped,
        if (n_dropped == 1) "line" else "lines",
        n_files,
        if (n_files == 1) "file" else "files"
      )
    )
  }
  structure(out, class = "covr_annotation")
}

#' @export
print.covr_annotation <- function(x, ...) {
  writeLines(unclass(x))
  invisible(x)
}
