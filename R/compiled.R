# this does not handle LCOV_EXCL_START ect.
parse_gcov <- function(file, path) {
  if (!file.exists(file)) {
    return(NULL)
  }

  lines <- readLines(file)
  source_file <- remove_extension(file)

  src_file <- srcfilecopy(source_file, readLines(source_file))

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
  src_path <- file.path(normalizePath(path), "src")

  old_dir <- getwd()
  on.exit(setwd(old_dir))
  setwd(src_path)

  res <- unlist(recursive = FALSE,
    Filter(Negate(is.null),
    lapply(sources,
    function(src) {
      gcda <- paste0(remove_extension(src), ".gcda")
      gcno <- paste0(remove_extension(src), ".gcno")
      if (file.exists(gcno) && file.exists(gcda)) {
        devtools::in_dir(dirname(src),
          devtools:::system_check("gcov", args = src, ignore.stdout = TRUE, quiet = quiet))
        gcov_file <- paste0(src, ".gcov")
        if (file.exists(gcov_file)) {
          parse_gcov(gcov_file)
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
