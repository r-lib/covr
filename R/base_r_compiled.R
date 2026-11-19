# Coverage of the C, C++ and Fortran code of base R itself (#782).
#
# R is built out of tree with `--coverage`, so every object in the build
# directory has a `.gcno` file with the layout of its code, and writes a
# `.gcda` file of execution counts when a process using it exits (e.g. while
# running `make check`). Unlike an R package, the sources are not in the build
# tree: the compiler records the source file names in the `.gcno` files, and
# they point to the source directory.

#' Coverage of the compiled code of R
#'
#' Computes the coverage of the C, C++ and Fortran code of R itself, from the
#' counts that gcov records while R runs, e.g. under `make check`. This is for
#' measuring R, not packages: use [package_coverage()] for those.
#'
#' @section Requirements:
#' * R must be built from source, out of tree, with `--coverage` in the
#'   compiler flags, e.g.
#'   `CFLAGS="-O0 --coverage" FFLAGS="-O0 --coverage" LDFLAGS=--coverage`.
#'   Every object in `build_dir` then has a `.gcno` file with its layout, and
#'   processes of that R write `.gcda` files of counts when they exit.
#' * `gcov` must be available, see `covr.gcov` in [covr-package].
#' * Processes forked by `parallel::mclapply()` leave with `_exit()` and don't
#'   write their gcov counts, unless R code was instrumented by
#'   [instrument_base_r()] on a build with `--coverage`.
#' * This is only supported on Unix-alikes.
#'
#' @section Example workflow:
#' ```r
#' # Build R with coverage flags in `build_dir` from the sources in
#' # `source_dir`, and run its checks: `make check`
#' cov <- base_r_compiled_coverage("build", "R-devel", cores = 4)
#' report(cov)
#' ```
#'
#' @details
#' All objects with a `.gcno` file are measured, also if no process ran them
#' and no `.gcda` file was written, so their lines count as not covered. gcov
#' is run in a temporary directory, in batches of `batch_size` objects that
#' may run in `cores` parallel processes, so neither the build nor the source
#' tree get any files. Headers outside of `source_dir`, and generated files
#' in the build tree, are dropped.
#'
#' @param build_dir The directory R was configured and built in, after the
#'   counts were collected.
#' @param source_dir The directory with the R sources it was built from.
#' @param exclude Directories relative to `source_dir` whose files are left
#'   out of the coverage.
#' @param cores The number of parallel processes to run gcov in. Forking is
#'   not available on Windows.
#' @param batch_size The number of objects gcov is run on at a time.
#' @param quiet Whether to hide the progress messages.
#' @param gcov_path The path of the gcov executable.
#' @param gcov_args Extra arguments for gcov.
#' @return A coverage object of the lines of the files in `source_dir`, with
#'   absolute file names.
#' @family base R coverage
#' @export
base_r_compiled_coverage <- function(
  build_dir,
  source_dir,
  exclude = "tests",
  cores = 1L,
  batch_size = 50L,
  quiet = TRUE,
  gcov_path = resolve_gcov(),
  gcov_args = getOption("covr.gcov_args", NULL)
) {
  build_dir <- normalize_path(build_dir)
  source_dir <- sub("/+$", "", normalize_path(source_dir))
  if (!dir.exists(build_dir)) {
    covr_abort("Can't find the build directory {.path {build_dir}}.")
  }
  if (!dir.exists(source_dir)) {
    covr_abort("Can't find the source directory {.path {source_dir}}.")
  }
  if (is.na(gcov_path) || !nzchar(gcov_path)) {
    covr_abort(c(
      "Can't find gcov.",
      i = "Set its path with {.code options(covr.gcov = )}."
    ))
  }

  timings <- list()
  start <- proc.time()[["elapsed"]]
  step <- function(name) {
    now <- proc.time()[["elapsed"]]
    timings[[name]] <<- now - start
    start <<- now
  }

  # Every object with a `.gcno` file is measured, also if no process ever ran
  # it and wrote a `.gcda` file: gcov reports its code as not executed, and
  # leaving it out would make the coverage higher than it is.
  objects <- list.files(
    build_dir,
    pattern = "[.]gcno$",
    recursive = TRUE,
    full.names = TRUE
  )
  counts <- list.files(
    build_dir,
    pattern = "[.]gcda$",
    recursive = TRUE
  )
  step("find")
  if (!length(objects)) {
    covr_abort("Can't find any {.file .gcno} files in {.path {build_dir}}.")
  }
  if (!length(counts)) {
    covr_abort(c(
      "Can't find any {.file .gcda} files in {.path {build_dir}}.",
      i = "Run the code to measure with the build first."
    ))
  }

  keep_dirs <- file.path(source_dir, exclude)
  keep <- function(file) {
    startsWith(file, paste0(source_dir, "/")) &
      !path_in_roots(file, keep_dirs)
  }

  # Objects in one directory go together; a batch is a chunk of them.
  objects <- objects[order(dirname(objects), objects)]
  batches <- split(objects, ceiling(seq_along(objects) / batch_size))

  format <- if (gcov_json_supported(gcov_path, gcov_args)) "json" else "text"
  run_batch <- function(files) {
    base_r_gcov_batch(
      files,
      format = format,
      source_dir = source_dir,
      keep = keep,
      gcov_path = gcov_path,
      gcov_args = gcov_args
    )
  }
  lines <- if (cores > 1L && length(batches) > 1L) {
    rlang::check_installed("parallel")
    parallel::mclapply(
      batches,
      run_batch,
      mc.cores = cores,
      mc.preschedule = FALSE
    )
  } else {
    lapply(batches, run_batch)
  }
  failed <- vlapply(lines, inherits, "try-error")
  if (any(failed)) {
    covr_abort(c(
      "Can't run gcov on {sum(failed)} batch{?es} of objects.",
      x = as.character(lines[failed][[1]])
    ))
  }
  step("gcov")

  lines <- sum_gcov_lines(do.call(rbind, lines))
  step("sum")

  files <- split(lines, factor(lines$file, unique(lines$file)))
  res <- lapply(files, function(x) {
    res <- line_coverages(
      x$file[[1]],
      list(line = x$line),
      x$count,
      rep(NA_character_, nrow(x))
    )
    # R has many files with the same name in different directories, e.g.
    # `init.c`, so the traces are named by the whole path of the file, not just
    # its name, or they would be merged by `c()`.
    suffix <- sub("^.*?((?::[0-9]+){8})$", "\\1", names(res), perl = TRUE)
    names(res) <- paste0(x$file[[1]], suffix)
    res
  })
  res <- unlist(unname(res), recursive = FALSE)
  step("srcrefs")

  coverage <- as_coverage(
    res,
    package = list(package = "R", path = source_dir),
    root = source_dir
  )
  step("coverage")

  attr(coverage, "timings") <- unlist(timings)
  if (!quiet) {
    message(
      length(objects),
      " objects in ",
      length(batches),
      " batches; seconds: ",
      paste(names(timings), round(unlist(timings), 1), collapse = ", ")
    )
  }
  coverage
}

# Runs gcov on the objects with the `.gcno` files `files`, in a temporary
# directory, and returns the lines of the source files for which `keep()`
# is true as a data frame with the columns `file`, `line` and `count`.
base_r_gcov_batch <- function(
  files,
  format,
  source_dir,
  keep,
  gcov_path,
  gcov_args
) {
  try(
    {
      work <- tempfile("covr-gcov-")
      dir.create(work)
      on.exit(unlink(work, recursive = TRUE, expand = FALSE), add = TRUE)
      withr::local_dir(work)

      # `-p` puts the directory of the source file in the name of the report,
      # as sources in different directories can have the same name.
      args <- if (format == "json") "--json-format" else "-a"
      gcov_run(gcov_path, c(gcov_args, args, "-p", files))

      reports <- list.files(
        work,
        pattern = if (format == "json") "[.]gcov[.]json[.]gz$" else "[.]gcov$",
        full.names = TRUE
      )
      lines <- if (format == "json") {
        lapply(reports, read_gcov_json_lines, keep = keep)
      } else {
        unblock <- gcov_unexecuted_block(gcov_path, gcov_args)
        lapply(
          reports,
          read_gcov_text_lines,
          source_dir = source_dir,
          unblock = unblock
        )
      }
      sum_gcov_lines(do.call(rbind, lines))
    },
    silent = TRUE
  )
}

# The lines of a report of `gcov --json-format` as a data frame with the
# columns `file`, `line` and `count`, like `parse_gcov_json()` does for the
# files in `keep()`, without creating the source references. Lines that
# only partially ran count as covered, unless `covr.gcov_partial` says
# otherwise.
read_gcov_json_lines <- function(file, keep) {
  json <- jsonlite::fromJSON(gzfile(file), simplifyVector = TRUE)
  cwd <- json$current_working_directory %||% "."
  partial_as_uncovered <- gcov_partial_as_uncovered()

  files <- json$files
  if (!NROW(files)) {
    return(NULL)
  }

  names <- files$file
  absolute <- is_absolute_path(names)
  names[!absolute] <- file.path(cwd, names[!absolute])
  names <- normalize_path(names)
  wanted <- which(keep(names))

  res <- lapply(wanted, function(i) {
    lines <- files$lines[[i]]
    if (!NROW(lines)) {
      return(NULL)
    }
    count <- as.numeric(lines$count)
    if (partial_as_uncovered) {
      # Only the parts of a line that ran are counted by gcov, so a line with
      # a block that never ran is uncovered.
      count[lines$unexecuted_block %in% TRUE] <- 0
    }
    data.frame(
      file = names[[i]],
      line = as.integer(lines$line_number),
      count = count,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, res)
}

# The lines of a report of `gcov -a` (see `read_gcov_json_lines()`).
read_gcov_text_lines <- function(file, source_dir, unblock) {
  lines <- parse_gcov(
    file,
    package_path = source_dir,
    unexecuted_block = unblock
  )
  if (is.null(lines)) {
    return(NULL)
  }
  data.frame(
    file = vcapply(lines, function(x) {
      get_source_filename(x$srcref, full.names = TRUE)
    }),
    line = viapply(lines, function(x) as.integer(x$srcref[[1]])),
    count = vdapply(lines, function(x) x$value),
    stringsAsFactors = FALSE
  )
}

# Adds the counts of the same line of the same file, e.g. of a header
# included in several objects, or of a function that gcov lists several times.
sum_gcov_lines <- function(x) {
  if (!NROW(x)) {
    return(NULL)
  }
  key <- paste(x$file, x$line, sep = ":")
  counts <- rowsum(x$count, key, reorder = FALSE)
  first <- !duplicated(key)
  res <- x[first, c("file", "line"), drop = FALSE]
  res$count <- as.numeric(counts[key[first], 1])
  res <- res[order(res$file, res$line), , drop = FALSE]
  rownames(res) <- NULL
  res
}

# The coverage of each directory with source files, e.g. `src/main`, as a data
# frame with the columns `directory`, `lines`, `covered` and `percent`, and
# the total.
base_r_compiled_summary <- function(coverage) {
  lines <- collapse_lines(tally_coverage(coverage))
  directory <- dirname(to_relative_path(lines$filename, attr(coverage, "root")))
  res <- data.frame(
    directory = c(sort(unique(directory)), "total"),
    stringsAsFactors = FALSE
  )
  in_directory <- function(x) {
    if (x == "total") rep(TRUE, length(directory)) else directory == x
  }
  res$lines <- vapply(
    res$directory,
    function(x) sum(in_directory(x)),
    numeric(1)
  )
  res$covered <- vapply(
    res$directory,
    function(x) sum(lines$value[in_directory(x)] > 0),
    numeric(1)
  )
  res$percent <- res$covered / res$lines * 100
  res
}
