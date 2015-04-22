# this does not handle LCOV_EXCL_START ect.
parse_gcov <- function(file, source_file) {
  if (!file.exists(file)) {
    return(NULL)
  }

  lines <- readLines(file)

  re <- rex::rex(spaces,
    capture(name = "coverage", some_of(digit, "-", "#")),
    ":", spaces,
    capture(name = "line", digits),
    ":"
  )

  matches <- rex::re_matches(lines, re)
  matches$coverage[matches$coverage == "#####"] <- 0
  coverage_lines <- matches$line > 0 & matches$coverage != "-"
  matches <- matches[coverage_lines, ]

  values <- as.numeric(matches$coverage)

  # create srcfile reference from the source file
  src_file <- srcfilecopy(source_file, readLines(source_file))

  line_lengths <- vapply(src_file$lines[as.numeric(matches$line)], nchar, numeric(1))

  if (any(is.na(values))) {
    stop("values could not be coerced to numeric ", matches$coverage)
  }

  res <- Map(function(line, length, value) {
    src_ref <- srcref(src_file, c(line, 1, line, length))
    res <- list(srcref = src_ref, value = value)
    class(res) <- "line_coverage"
    res
  },
  matches$line, line_lengths, values)

  if (!length(res)) {
    return(NULL)
  }

  names(res) <- lapply(res, function(x) key(x$srcref))

  class(res) <- "line_coverages"
  res
}

clear_gcov <- function(path) {
  src_dir <- file.path(path, "src")

  gcov_files <- dir(src_dir,
                    pattern = rex::rex(or(".gcda", ".gcno", ".gcov"), end),
                    full.names = TRUE,
                    recursive = TRUE)

  unlink(gcov_files)
}

run_gcov <- function(path, sources, quiet = TRUE) {

  sources <- normalizePath(sources)
  src_path <- file.path(path, "src")

  res <- unlist(recursive = FALSE,
    Filter(Negate(is.null),
    lapply(sources,
    function(src) {
      gcda <- paste0(remove_extension(src), ".gcda")
      gcno <- paste0(remove_extension(src), ".gcno")
      if (file.exists(gcno) && file.exists(gcda)) {
        robustr::in_dir(src_path,
          robustr::system_check("gcov", args = src, ignore.stdout = TRUE, quiet = quiet)
        )
        # the gcov files are in the src_path with the basename of the file
        gcov_file <- file.path(src_path, paste0(basename(src), ".gcov"))
        if (file.exists(gcov_file)) {
          parse_gcov(gcov_file, src)
        }
      }
    })))

  class(res) <- "coverage"
  res
}

remove_extension <- function(x) {
  rex::re_substitutes(x, rex::rex(".", except_any_of("."), end), "")
}

sources <- function(pkg = ".") {
  pkg <- devtools::as.package(pkg)
  srcdir <- file.path(pkg$path, "src")
  dir(srcdir, rex::rex(".",
                       list("c", except_any_of(".")) %or% list("f", except_any_of(".")), end),
      recursive = TRUE,
      full.names = TRUE)
}
