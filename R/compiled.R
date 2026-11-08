# Parses the JSON intermediate format written by `gcov --json-format`
# (gcc >= 9). Each file describes one object file, and lists the lines of
# every source file and header compiled into it.
parse_gcov_json <- function(file, package_path = "") {
  if (!file.exists(file)) {
    return(NULL)
  }

  # fromJSON() opens and closes the connection
  json <- jsonlite::fromJSON(gzfile(file), simplifyVector = FALSE)

  # Source file names are relative to the directory the code was compiled in
  cwd <- json$current_working_directory %||% "."

  res <- lapply(json$files, function(x) {
    source_file <- x$file
    if (!is_absolute_path(source_file)) {
      source_file <- file.path(cwd, source_file)
    }
    source_file <- normalize_path(source_file)

    if (!length(x$lines) || !in_package_path(source_file, package_path)) {
      return(NULL)
    }

    line <- viapply(x$lines, function(l) as.integer(l$line_number))
    count <- vdapply(x$lines, function(l) as.numeric(l$count))
    unexecuted <- vlapply(x$lines, function(l) isTRUE(l$unexecuted_block))

    # Functions gcov groups together, such as the instantiations of a
    # template, list their lines separately, so add them up like the text
    # output does.
    values <- tapply(count, line, sum)
    partial <- tapply(unexecuted, line, any) & values > 0

    # gcov's `unexecuted_block` marks lines with blocks that never ran, e.g.
    # `if (x) f();` when `f()` never runs (#604).
    if (gcov_partial_as_uncovered()) {
      values[partial] <- 0
    }

    lines <- as.integer(names(values))
    values <- as.numeric(values)

    # There are no functions for gcov, so we set everything to NA
    functions <- rep(NA_character_, length(values))

    line_coverages(source_file, list(line = lines), values, functions)
  })

  unlist(res, recursive = FALSE)
}

# Is the source file in the package, or one of the
# `covr.gcov_additional_paths`?
in_package_path <- function(source_file, package_path) {
  file.exists(source_file) &&
    grepl(
      rex::rex(
        start,
        rex::regex(paste0(rex::escape(package_path), collapse = "|"))
      ),
      source_file
    )
}

# Partially executed lines count as covered by default, or as uncovered with
# `options(covr.gcov_partial = "uncovered")`.
gcov_partial_as_uncovered <- function() {
  partial_as <- match.arg(
    getOption("covr.gcov_partial", "covered"),
    c("covered", "uncovered")
  )
  partial_as == "uncovered"
}

# Parses the text output of `gcov -a`, for gcov implementations without
# `--json-format` (llvm-cov and gcc < 9).
# this does not handle LCOV_EXCL_START ect.
parse_gcov <- function(file, package_path = "", unexecuted_block = "%%%%%") {
  if (!file.exists(file)) {
    return(NULL)
  }

  lines <- readLines(file)
  source_file <- rex::re_matches(
    lines[1],
    rex::rex("Source:", capture(name = "source", anything))
  )$source

  # retrieve full path to the source files
  source_file <- normalize_path(source_file)

  # If the source file does not start with the package path or does not exist ignore it.
  if (!in_package_path(source_file, package_path)) {
    return(NULL)
  }

  # gcc >= 8 follows the lines of functions it groups together, such as the
  # instantiations of a template, with the lines of each function again,
  # between `------------------` separators. Only keep the combined lines, so
  # they are not counted twice. These are already marked with `*` if partially
  # executed.
  lines <- lines[!in_gcov_function_section(lines)]

  # With `gcov -a` each line is followed by the counts of its basic blocks,
  # e.g. `$$$$$:    4-block  1` for a block that never ran.
  blocks <- rex::re_matches(
    lines,
    rex::rex(
      start,
      any_spaces,
      capture(name = "coverage", except_some_of(space, ":")),
      ":",
      any_spaces,
      capture(name = "line", digits),
      "-block"
    )
  )
  unexecuted_lines <- blocks$line[
    !is.na(blocks$coverage) & blocks$coverage == unexecuted_block
  ]

  re <- rex::rex(
    any_spaces,
    capture(name = "coverage", some_of(digit, "-", "#", "=", "*")),
    ":",
    any_spaces,
    capture(name = "line", digits),
    ":"
  )

  matches <- rex::re_matches(lines, re)

  # Exclude lines with no match to the pattern
  lines <- lines[!is.na(matches$coverage)]
  matches <- na.omit(matches)

  # gcov lines which have no coverage; `=====` marks lines only reached by
  # exceptions, e.g. a `catch` block that never ran
  matches$coverage[matches$coverage %in% c("#####", "=====")] <- 0 # nolint

  # A line is only partially executed if some of its blocks never ran (e.g.
  # `if (x) f();` when `f()` never runs). gcc >= 8 marks these lines with a
  # trailing `*` (e.g. `3*`), but llvm-cov and older gcc do not, so we also
  # look for unexecuted blocks in the `gcov -a` output (#610).
  starred <- endsWith(matches$coverage, "*")
  matches$coverage[starred] <- sub(
    "*",
    "",
    matches$coverage[starred],
    fixed = TRUE
  )
  partial <- starred |
    (matches$line %in% unexecuted_lines & matches$coverage != "-")
  if (gcov_partial_as_uncovered()) {
    matches$coverage[partial] <- "0"
  }

  coverage_lines <- matches$line != "0" & matches$coverage != "-"
  matches <- matches[coverage_lines, ]

  values <- as.numeric(matches$coverage)

  if (any(is.na(values))) {
    bad <- unique(matches$coverage[is.na(values)])
    covr_abort(c(
      "Can't parse gcov line counts.",
      x = "Unexpected count{?s}: {.val {bad}}."
    ))
  }

  # There are no functions for gcov, so we set everything to NA
  functions <- rep(NA_character_, length(values))

  line_coverages(source_file, matches, values, functions)
}

# Is each line of gcov's text output in one of the sections listing the lines
# of a single function of a group? A separator followed by the function's name
# starts a section, and the separator after the last section is followed by a
# source line.
in_gcov_function_section <- function(lines) {
  separators <- which(lines == "------------------")
  if (!length(separators)) {
    return(rep(FALSE, length(lines)))
  }
  opens <- !grepl("^ *[^ ]+: *[0-9]+[:-]", lines[separators + 1])
  section <- findInterval(seq_along(lines), separators)
  section > 0 & opens[pmax(section, 1)]
}

# for mocking
readLines <- NULL
file.exists <- NULL
system2 <- NULL

clean_gcov <- function(path) {
  src_dir <- file.path(path, "src")

  gcov_files <- list.files(
    src_dir,
    pattern = rex::rex(or(".gcda", ".gcno", ".gcov", ".gcov.json.gz"), end),
    full.names = TRUE,
    recursive = TRUE
  )

  unlink(gcov_files)
}

# The marker `gcov -a` uses for a basic block that never ran on a normal
# (non-exception) path. gcc >= 8 uses `%%%%%`, and `$$$$$` for blocks only
# reached by exceptions; older gcc swaps the two. llvm-cov (the gcov on macOS)
# uses `$$$$$` for every unexecuted block.
gcov_unexecuted_block <- function(gcov_path, gcov_args = NULL) {
  version <- tryCatch(
    system_output(gcov_path, c(gcov_args, "--version"), quiet = TRUE),
    error = function(e) character()
  )
  version <- c(version, "")[[1]]
  if (grepl("LLVM", version, fixed = TRUE)) {
    return("$$$$$")
  }
  major <- rex::re_matches(
    version,
    rex::rex(
      space,
      capture(name = "major", digits),
      ".",
      digits,
      any_non_spaces,
      end
    )
  )$major
  if (!is.na(major) && as.integer(major) < 8) "$$$$$" else "%%%%%"
}

# gcc >= 9 can write structured JSON instead of the text output, which
# llvm-cov (the gcov on macOS) and older gcc can't (#609).
gcov_json_supported <- function(gcov_path, gcov_args = NULL) {
  help <- tryCatch(
    system_output(gcov_path, c(gcov_args, "--help"), quiet = TRUE),
    error = function(e) character()
  )
  any(grepl("--json-format", help, fixed = TRUE))
}

find_gcov <- function() {
  path <- unname(Sys.which("gcov"))
  if (!nzchar(path)) {
    return(NA_character_)
  }
  path
}

# Run gcov, capturing its output so that failures report gcov's diagnostics.
# gcov exits with status 0 for objects with no functions; a nonzero status
# always means a real problem, e.g. a .gcno version mismatch (status 3) when
# the package was compiled with a different gcc than the gcov used (#537).
gcov_run <- function(gcov_path, args, quiet = TRUE) {
  if (!quiet) {
    message(wrap_command(paste(
      c(shQuote(gcov_path), shQuote(args)),
      collapse = " "
    )))
  }
  output <- suppressWarnings(
    system2(gcov_path, shQuote(args), stdout = TRUE, stderr = TRUE)
  )
  status <- attr(output, "status")
  if (!quiet && length(output)) {
    message(paste(output, collapse = "\n"))
  }
  if (!is.null(status) && status != 0) {
    covr_abort(
      c(
        "Can't run gcov.",
        x = "Exit status {status}.",
        i = if (length(output)) "gcov output:"
      ),
      output = output
    )
  }
  invisible(output)
}

run_gcov <- function(
  path,
  quiet = TRUE,
  clean = TRUE,
  gcov_path = getOption("covr.gcov", find_gcov()),
  gcov_args = getOption("covr.gcov_args", NULL)
) {
  src_path <- normalize_path(file.path(path, "src"))
  if (!file.exists(src_path)) {
    return()
  }

  withr::local_dir(src_path)

  gcov_inputs <- list.files(
    ".",
    pattern = rex::rex(".gcno", end),
    recursive = TRUE,
    full.names = TRUE
  )

  if (is.na(gcov_path)) {
    if (length(gcov_inputs)) {
      covr_abort(c(
        "Can't find gcov.",
        i = "Set its path with {.code options(covr.gcov = )}."
      ))
    }
    return()
  }

  # `options(covr.gcov = "")` turns off coverage of compiled code
  if (!nzchar(gcov_path)) {
    return()
  }

  if (gcov_json_supported(gcov_path, gcov_args)) {
    format_args <- "--json-format"
    output_pattern <- rex::rex(".gcov.json.gz", end)
    parse_output <- parse_gcov_json
  } else {
    unexecuted_block <- gcov_unexecuted_block(gcov_path, gcov_args)
    format_args <- "-a"
    output_pattern <- rex::rex(".gcov", end)
    parse_output <- function(file, package_path) {
      parse_gcov(file, package_path, unexecuted_block = unexecuted_block)
    }
  }

  run_gcov_one <- function(src) {
    gcov_run(
      gcov_path,
      args = c(gcov_args, src, format_args, "-p", "-o", dirname(src)),
      quiet = quiet
    )
    gcov_outputs <- list.files(
      ".",
      pattern = output_pattern,
      recursive = TRUE,
      full.names = TRUE
    )

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

    unlist(
      lapply(
        gcov_outputs,
        parse_output,
        package_path = c(path, getOption("covr.gcov_additional_paths", NULL))
      ),
      recursive = FALSE
    )
  }

  res <- compact(unlist(lapply(gcov_inputs, run_gcov_one), recursive = FALSE))

  if (!length(res) && length(gcov_inputs)) {
    covr_warn("Can't find any coverage in the gcov output.")
  }

  res
}

line_coverages <- function(source_file, matches, values, functions) {
  # create srcfile reference from the source file
  src_file <- srcfilecopy(source_file, readLines(source_file))

  line_lengths <- vapply(
    src_file$lines[as.numeric(matches$line)],
    nchar,
    numeric(1)
  )

  res <- Map(
    function(line, length, value, func) {
      src_ref <- srcref(src_file, c(line, 1, line, length))
      res <- list(srcref = src_ref, value = value, functions = func)
      class(res) <- "line_coverage"
      res
    },
    matches$line,
    line_lengths,
    values,
    functions
  )

  if (!length(res)) {
    return(NULL)
  }

  names(res) <- lapply(res, function(x) key(x$srcref))

  class(res) <- "line_coverages"
  res
}
