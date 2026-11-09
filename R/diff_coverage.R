#' Coverage of changed lines
#'
#' Reports the coverage of the lines changed relative to a base branch. Lines
#' are changed if they were added or modified between the merge base of `base`
#' and `HEAD` and the working tree, so uncommitted edits and untracked files
#' count. Only changed lines that contain code are reported.
#'
#' @param x a covr coverage object, from [package_coverage()], of a package
#'   in a git repository.
#' @param base the branch, tag or commit to compare against.
#' @return A data frame with columns `filename` (relative to the package),
#'   `line` and `value` (the number of times the line was run) with one row
#'   for each changed code line, of class `covr_diff_coverage`. Its
#'   `non_code_lines` attribute has the blank, comment and punctuation-only
#'   lines of each file, used when printing to join missed lines into ranges.
#'   If branch coverage was measured (see [covr.branch_coverage]), its
#'   `branches` attribute has the branches on the changed lines, as rows of
#'   `tally_coverage(by = "branch")`; it is empty otherwise. Printing also
#'   shows the changed branches that were not taken, if their `if` or
#'   `switch()` was evaluated.
#' @examples
#' \dontrun{
#' cov <- package_coverage()
#' diff_coverage(cov, base = "main")
#' }
#' @export
diff_coverage <- function(x, base = "main") {
  pkg_path <- attr(x, "package")$path
  if (is.null(pkg_path)) {
    diff_error("`x` must be coverage of a package, from `package_coverage()`.")
  }

  changed <- git_changed_lines(pkg_path, base)

  lines <- collapse_lines(tally_coverage(x))
  lines$filename <- as.character(lines$filename)
  keep <- vapply(
    seq_len(nrow(lines)),
    function(i) lines$line[[i]] %in% changed[[lines$filename[[i]]]],
    logical(1)
  )
  res <- lines[keep, c("filename", "line", "value"), drop = FALSE]
  rownames(res) <- NULL

  branches <- tally_coverage(x, by = "branch")
  branches$filename <- as.character(branches$filename)
  keep <- vapply(
    seq_len(nrow(branches)),
    function(i) branches$line[[i]] %in% changed[[branches$filename[[i]]]],
    logical(1)
  )
  branches <- branches[keep, , drop = FALSE]
  rownames(branches) <- NULL

  class(res) <- c("covr_diff_coverage", "data.frame")
  attr(res, "non_code_lines") <- non_code_lines(x)
  attr(res, "branches") <- branches
  res
}

#' @export
print.covr_diff_coverage <- function(x, ...) {
  branches <- attr(x, "branches")
  if (!nrow(x)) {
    cat("No changed code lines.\n")
    return(invisible(x))
  }

  covered <- sum(x$value > 0)
  cat(
    sprintf(
      "Changed lines: %d code lines, %d covered (%s%%)\n",
      nrow(x),
      covered,
      format(round(covered / nrow(x) * 100, 2), nsmall = 2)
    )
  )
  if (nrow(branches)) {
    taken <- sum(branches$value > 0)
    cat(
      sprintf(
        "Changed branches: %d, %d taken (%s%%)\n",
        nrow(branches),
        taken,
        format(round(taken / nrow(branches) * 100, 2), nsmall = 2)
      )
    )
  }

  non_code <- attr(x, "non_code_lines")
  missed_branches <- evaluated_missed_branches(branches)
  files <- unique(c(
    x$filename[x$value == 0],
    as.character(missed_branches$filename)
  ))
  for (file in files) {
    rows <- x[x$filename == file, , drop = FALSE]
    missed <- rows$line[rows$value == 0]
    file_branches <- missed_branches[missed_branches$filename == file, ]
    out <- character()
    if (length(missed)) {
      out <- sprintf(
        "%s: %d missed  %s",
        file,
        length(missed),
        missed_ranges(missed, non_code[[file]], print_max_ranges())
      )
    }
    if (nrow(file_branches)) {
      out <- paste0(
        if (length(out)) out else paste0(file, ":"),
        "  missed branches ",
        format_branches(file_branches, print_max_ranges())
      )
    }
    cat(out, "\n", sep = "")
  }
  invisible(x)
}

diff_error <- function(message, call = NULL) {
  stop(structure(
    class = c("covr_diff_error", "error", "condition"),
    list(message = message, call = call)
  ))
}

git <- function(args, path) {
  out <- tryCatch(
    suppressWarnings(
      withr::with_dir(
        path,
        system2("git", args, stdout = TRUE, stderr = TRUE)
      )
    ),
    error = function(e) {
      diff_error(paste0("Failed to run git: ", conditionMessage(e)))
    }
  )
  status <- attr(out, "status")
  if (!is.null(status) && status != 0L) {
    diff_error(
      paste0(
        "`git ",
        paste(args, collapse = " "),
        "` failed:\n",
        paste(out, collapse = "\n")
      )
    )
  }
  out
}

# Returns a list of changed line numbers named by package-relative filename.
git_changed_lines <- function(path, base) {
  prefix <- git(c("rev-parse", "--show-prefix"), path)
  if (!length(prefix)) {
    prefix <- ""
  }
  merge_base <- git(c("merge-base", base, "HEAD"), path)[[1]]
  # Fixed prefixes, quoting and no external diff tool, whatever the user's git
  # config, so that the output can be parsed.
  diff <- git(
    c(
      "-c",
      "core.quotePath=false",
      "diff",
      "-U0",
      "--no-color",
      "--no-ext-diff",
      "--src-prefix=a/",
      "--dst-prefix=b/",
      merge_base
    ),
    path
  )
  untracked <- git(
    c(
      "-c",
      "core.quotePath=false",
      "ls-files",
      "--others",
      "--exclude-standard",
      "--full-name"
    ),
    path
  )

  res <- parse_diff_lines(diff)
  for (file in untracked) {
    n <- length(readLines(file.path(git_root(path), file), warn = FALSE))
    res[[file]] <- seq_len(n)
  }

  names(res) <- vapply(
    names(res),
    function(f) {
      if (nzchar(prefix) && startsWith(f, prefix)) {
        substring(f, nchar(prefix) + 1L)
      } else {
        f
      }
    },
    character(1)
  )
  res
}

git_root <- function(path) {
  git(c("rev-parse", "--show-toplevel"), path)[[1]]
}

# Parses the output of `git diff -U0` into added/changed line numbers, a list
# named by the (repository relative) new filename.
parse_diff_lines <- function(diff) {
  res <- list()
  file <- NULL
  for (line in diff) {
    if (startsWith(line, "+++ ")) {
      file <- if (identical(line, "+++ /dev/null")) {
        NULL
      } else {
        sub("^\\+\\+\\+ b/", "", line)
      }
    } else if (!is.null(file) && startsWith(line, "@@ ")) {
      m <- regmatches(
        line,
        regexec("\\+(\\d+)(?:,(\\d+))? @@", line, perl = TRUE)
      )[[1]]
      start <- as.integer(m[[2]])
      count <- if (nzchar(m[[3]])) as.integer(m[[3]]) else 1L
      if (count > 0L) {
        res[[file]] <- c(res[[file]], seq(start, length.out = count))
      }
    }
  }
  res
}
