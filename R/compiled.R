# this does not handle LCOV_EXCL_START ect.
parse_gcov <- function(file) {
  if (!file.exists(file)) {
    return()
  }

  lines <- readLines(file)
  re <- rex::rex(spaces,
    capture(name = "coverage", some_of(digit, "-", "#")),
    ":", spaces,
    capture(name = "line", digits),
    ":"
  )

  res <- rex::re_matches(lines, re)
  res$coverage[res$coverage == "#####"] <- 0
  res <- res[res$line > 0 & res$coverage != "-", ]

  if (NROW(res) > 0) {
    values <- as.numeric(res$coverage)
    names(values) <- paste(sep = ":",
      remove_extension(file),
      res$line,
      NA,
      res$line,
      NA,
      NA,
      NA,
      NA,
      NA)
  } else {
    return()
  }

  class(values) <- "coverage"
  values
}

clear_gcov <- function(path) {
  src_dir <- file.path(path, "src")

  gcov_files <- dir(src_dir,
                    pattern = rex::rex(or(".gcda", ".gcno", ".gcov"), end),
                    full.names = TRUE,
                    recursive = TRUE)

  unlink(gcov_files)
}

run_gcov <- function(path, sources) {
  src_path <- file.path(normalizePath(path), "src")

  old_dir <- getwd()
  on.exit(setwd(old_dir))
  setwd(src_path)

  srcs <- rex::re_substitutes(sources, rex::rex(src_path, one_of("/", "\\")), "")

  res <- unlist(Filter(Negate(is.null),
    lapply(srcs,
    function(src) {
      gcda <- paste0(remove_extension(src), ".gcda")
      gcno <- paste0(remove_extension(src), ".gcno")
      if (file.exists(gcno) && file.exists(gcda)) {
        status <- system2("gcov", args = src, stdout = NULL)
        stopifnot(status == 0)
        parse_gcov(paste0(src, ".gcov"))
    }
  })))
  names(res) <- file.path(src_path, names(res))
  res
}

remove_extension <- function(x) {
  rex::re_substitutes(x, rex::rex(".", except_any_of("."), end), "")
}

sources <- function(pkg = ".") {
  pkg <- devtools::as.package(pkg)
  srcdir <- file.path(pkg$path, "src")
  dir(srcdir, rex::rex(".",
                       list("c", except_any_of(".")) %or% "f", end),
      recursive = TRUE,
      full.names = TRUE)
}
