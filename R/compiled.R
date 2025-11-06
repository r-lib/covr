# this does not handle LCOV_EXCL_START ect.
parse_gcov <- function(file, package_path = "") {
  if (!file.exists(file)) {
    return(NULL)
  }

  lines <- readLines(file)
  source_file <- rex::re_matches(lines[1], rex::rex("Source:", capture(name = "source", anything)))$source

  # retrieve full path to the source files
  source_file <- normalize_path(source_file)

  # If the source file does not start with the package path or does not exist ignore it.
  if (!file.exists(source_file) || !grepl(rex::rex(start, rex::regex(paste0(rex::escape(package_path), collapse = "|"))), source_file)) {
    return(NULL)
  }

  re <- rex::rex(any_spaces,
    capture(name = "coverage", some_of(digit, "-", "#", "=")),
    ":", any_spaces,
    capture(name = "line", digits),
    ":"
  )

  matches <- rex::re_matches(lines, re)

  # Exclude lines with no match to the pattern
  lines <- lines[!is.na(matches$coverage)]
  matches <- na.omit(matches)

  # gcov lines which have no coverage
  matches$coverage[matches$coverage == "#####"] <- 0 # nolint

  # gcov lines which have parse error, so make untracked
  matches$coverage[matches$coverage == "====="] <- "-"

  coverage_lines <- matches$line != "0" & matches$coverage != "-"
  matches <- matches[coverage_lines, ]

  values <- as.numeric(matches$coverage)

  if (any(is.na(values))) {
    stop("values could not be coerced to numeric ", matches$coverage)
  }

  # There are no functions for gcov, so we set everything to NA
  functions <- rep(NA_character_, length(values))

  line_coverages(source_file, matches, values, functions)
}

# for mocking
readLines <- NULL
file.exists <- NULL

clean_gcov <- function(path) {
  src_dir <- file.path(path, "src")

  gcov_files <- list.files(src_dir,
                    pattern = rex::rex(or(".gcda", ".gcno", ".gcov"), end),
                    full.names = TRUE,
                    recursive = TRUE)

  unlink(gcov_files)
}

run_gcov <- function(path, quiet = TRUE, clean = TRUE,
                      gcov_path = getOption("covr.gcov", ""),
                      gcov_args = getOption("covr.gcov_args", NULL)) {
  src_path <- normalize_path(file.path(path, "src"))
  if (!file.exists(src_path)) {
     return()
  }

  withr::local_dir(src_path)

  gcov_inputs <- list.files(".", pattern = rex::rex(".gcno", end), recursive = TRUE, full.names = TRUE)

  if (!nzchar(gcov_path)) {
    if (length(gcov_inputs)) stop('gcov not found')
    return()
  }

  run_gcov_one <- function(src) {
    system_check(gcov_path,
      args = c(gcov_args, src, "-p", "-o", dirname(src)),
      quiet = quiet, echo = !quiet)
    gcov_outputs <- list.files(".", pattern = rex::rex(".gcov", end), recursive = TRUE, full.names = TRUE)

    if (!quiet) {
      message("gcov output for ", src, ":")
      message(paste(gcov_outputs, collapse = "\n"))
    }

    if (clean) {
      on.exit(unlink(gcov_outputs))
    } else {
      gcov_output_base <- file.path("..", "covr", src)
      gcov_output_targets <- sub(".", gcov_output_base, gcov_outputs)

      if (!quiet) {
        message("gcov output targets for ", src, ":")
        message(paste(gcov_output_targets, collapse = "\n"))
      }

      lapply(
        unique(dirname(gcov_output_targets)),
        function(.x) dir.create(.x, recursive = TRUE, showWarnings = FALSE)
      )

      on.exit({
	if (!quiet) {
	  message("Moving gcov outputs to covr directory.\n")
	}
        file.rename(gcov_outputs, gcov_output_targets)
      })
    }

    unlist(lapply(gcov_outputs, parse_gcov, package_path = c(path, getOption("covr.gcov_additional_paths", NULL))), recursive = FALSE)
  }

  res <- compact(unlist(lapply(gcov_inputs, run_gcov_one), recursive = FALSE))

  if (!length(res) && length(gcov_inputs))
    warning('parsed gcov output was empty')

  res
}

line_coverages <- function(source_file, matches, values, functions) {

  # create srcfile reference from the source file
  src_file <- srcfilecopy(source_file, readLines(source_file))

  line_lengths <- vapply(src_file$lines[as.numeric(matches$line)], nchar, numeric(1))

  res <- Map(function(line, length, value, func) {
    src_ref <- srcref(src_file, c(line, 1, line, length))
    res <- list(srcref = src_ref, value = value, functions = func)
    class(res) <- "line_coverage"
    res
  },
  matches$line, line_lengths, values, functions)

  if (!length(res)) {
    return(NULL)
  }

  names(res) <- lapply(res, function(x) key(x$srcref))

  class(res) <- "line_coverages"
  res
}
