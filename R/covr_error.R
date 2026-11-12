show_failures <- function(dir) {
  fail_files <- list.files(
    dir,
    pattern = "fail$",
    recursive = TRUE,
    full.names = TRUE
  )
  for (file in fail_files) {
    withRestarts(stop(covr_error(file)), covr_continue = function() NULL)
  }
}

# Number of trailing output lines shown by default in the message and print()
failure_lines <- function() {
  getOption("covr.failure_lines", 50L)
}

covr_error <- function(file) {
  lines <- readLines(file, warn = FALSE)

  # Skip header lines (until first >)
  prompt <- grep("^>", lines)
  if (length(prompt) > 0L) {
    lines <- lines[seq(prompt[[1L]], length(lines))]
  }

  structure(
    list(
      message = failure_message(file, lines),
      call = NULL,
      file = file,
      output = lines
    ),
    class = c("covr_error", "error", "condition")
  )
}

# R only shows options("warning.length") characters of an error message, so
# keep the message within that (and at most `failure_lines()` lines) and show
# as many lines from the end as fit.
failure_message <- function(file, lines) {
  header <- paste0(
    cli::format_error(c(
      "Code run to compute coverage failed.",
      i = "Its full output is in {.file {file}} and in the {.code $output} of this condition."
    )),
    "\n"
  )
  # 9 is the length of `Error: ` + newline + NUL maybe?
  budget <- getOption("warning.length") - 9 - nchar(header, "chars")
  if (length(lines) == 0L || budget <= 0L) {
    return(header)
  }
  n <- failure_lines()
  if (length(lines) > n) {
    lines <- lines[seq.int(length(lines) - n + 1L, length(lines))]
  }
  # characters in the last k lines, joined by newlines
  size <- rev(cumsum(rev(nchar(lines, "chars") + 1L))) - 1L
  keep <- which(size <= budget)
  if (length(keep) > 0L) {
    lines <- lines[keep[[1L]]:length(lines)]
  } else {
    last <- lines[[length(lines)]]
    lines <- substring(last, nchar(last, "chars") - budget + 1L)
  }
  paste0(header, paste(lines, collapse = "\n"))
}

#' @export
format.covr_error <- function(x, n = failure_lines(), ...) {
  out <- x$output
  total <- length(out)
  if (total > n) {
    out <- out[seq.int(total - n + 1L, total)]
  }
  header <- paste0("<covr_error> Failure in `", x$file, "`")
  if (total > length(out)) {
    header <- paste0(
      header,
      "\n(showing last ",
      length(out),
      " of ",
      total,
      " lines; use `print(x, n = Inf)` or `x$output` for all)"
    )
  }
  paste(c(header, out), collapse = "\n")
}

#' @export
print.covr_error <- function(x, n = failure_lines(), ...) {
  cat(format(x, n = n), "\n", sep = "")
  invisible(x)
}
