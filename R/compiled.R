# this does not handle LCOV_EXCL_START ect.
parse_gcov <- function(file, package_path = "") {
  if (!file.exists(file)) {
    return(NULL)
  }

  lines <- readLines(file)
  source_file <- rex::re_matches(lines[1], rex::rex("Source:", capture(name = "source", anything)))$source

  # retrieve full path to the source files
  source_file <- normalize_path(source_file)

  # If the source file does not start with the package path ignore it.
  if (!grepl(rex::rex(start, package_path), source_file)) {
    return(NULL)
  }

  re <- rex::rex(any_spaces,
    capture(name = "coverage", some_of(digit, "-", "#", "=")),
    ":", any_spaces,
    capture(name = "line", digits),
    ":"
  )

  matches <- rex::re_matches(lines, re)
  # gcov lines which have no coverage
  matches$coverage[matches$coverage == "#####"] <- 0 # nolint

  # gcov lines which have parse error, so make untracked
  matches$coverage[matches$coverage == "====="] <- "-"

  coverage_lines <- matches$line != "0" & matches$coverage != "-"
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
    res <- list(srcref = src_ref, value = value, functions = NA_character_)
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

clean_gcov <- function(path) {
  src_dir <- file.path(path, "src")

  gcov_files <- list.files(src_dir,
                    pattern = rex::rex(or(".gcda", ".gcno", ".gcov"), end),
                    full.names = TRUE,
                    recursive = TRUE)

  unlink(gcov_files)
}

run_gcov <- function(path, quiet = TRUE,
                      gcov_path = getOption("covr.gcov", ""),
                      gcov_args = getOption("covr.gcov_args", NULL)) {
  if (!nzchar(gcov_path)) {
    return()
  }

  src_path <- normalize_path(file.path(path, "src"))
  if (!file.exists(src_path)) {
     return()
  }

  gcov_inputs <- list.files(path, pattern = rex::rex(".gcno", end), recursive = TRUE, full.names = TRUE)
  withr::with_dir(src_path, {
    run_gcov <- function(src) {
      system_check(gcov_path,
        args = c(gcov_args, src, "-o", dirname(src[[1]])),
        quiet = quiet, echo = !quiet)
    }
    tapply(gcov_inputs, dirname(gcov_inputs), run_gcov)
    gcov_outputs <- list.files(path, pattern = rex::rex(".gcov", end), recursive = TRUE, full.names = TRUE)
    structure(
      unlist(recursive = FALSE,
        lapply(gcov_outputs, parse_gcov, package_path = path)),
      class = "coverage")
  })
}

## BEGIN Oracle Contribution
# License: GPL-3 with additional permission for MIT under GPL-3 Section 7 as set forth in license documents.
#
# parse icc compiler code coverage output
parse_icov <- function(lines, package_path = "") {

  source_file <- trimws(lines[1L])
  # If the source file does not start with the package path ignore it.
  if (!grepl(rex::rex(start, package_path), source_file)) {
    return(NULL)
  }

  # remove source file lines and empty/white space lines
  lines <- trimws(lines[-1L])
  lines <- lines[lines !=  ""]

  # get line, values, and functions
  r1 <- rex::re_matches(lines, rex::rex("function - ",
          capture(name = "source", anything),
                  "\t", digits, "\t", digits, "\t", digits, anything))$source
  idx1 <- which(!is.na(r1))

  re <- rex::rex(
    capture(name = "instance", digits), "\t",
    capture(name = "line", digits), "\t",
    capture(name = "idcol", digits), "\t", any_spaces,
    capture(name = "coverage", digits))

  showCfunctions <- getOption("covr.showCfunctions", FALSE)
  if (length(idx1) == 0L)
  {
    m1 <- rex::re_matches(lines, re)
    m1$functions <- rep(NA_character_, nrow(m1))
  }
  else
  {
    m1 <- rex::re_matches(lines[-idx1], re)
    if (showCfunctions)
    {
      # get function names
      if (length(idx1) == 1L)
        m1$functions <- rep(r1[idx1], nrow(m1))
      else
      {
        stopifnot(idx1[1L] == 1L)
        nums <- c(idx1[2L:length(idx1)]-1L, length(r1)) - idx1
        stopifnot(sum(nums) == nrow(m1))
        m1$functions <- unlist(mapply(rep, r1[idx1], nums,
                                      SIMPLIFY=FALSE, USE.NAMES=FALSE)) 
      }
    }
  }
  # remove invalid rows if exists
  m1 <- m1[!(is.na(m1[[1L]]) | is.na(m1[[2L]]) |
             is.na(m1[[3L]]) | is.na(m1[[4L]])), ]
  m1$line <- as.numeric(m1$line)
  m1$coverage <- as.numeric(m1$coverage)
  if (is.null(m1$functions))
  {
    m2 <- aggregate(m1$coverage, by = list(line=m1$line), sum)
    names(m2) <- c("line", "coverage")
    m2$functions <- NA_character_
  }
  else
  {
    m2 <- aggregate(m1$coverage,
                    by = list(line=m1$line, functions=m1$functions), sum)
    names(m2) <- c("line", "functions", "coverage")
  }
  matches <- m2[order(m2$line),]

  values <- as.numeric(matches$coverage > 0L)
  functions <- matches$functions

  # create srcfile reference from the source file
  src_file <- srcfilecopy(source_file, readLines(source_file))

  line_lengths <- vapply(src_file$lines[matches$line], nchar, numeric(1))

  if (any(is.na(values))) {
    stop("values could not be coerced to numeric ", matches$coverage)
  }

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

  names(res) <- lapply(res, function(x) covr:::key(x$srcref))

  class(res) <- "line_coverages"
  res
}

run_icov <- function(path, quiet = TRUE,
                     icov_path = getOption("covr.icov", ""),
                     icov_args = getOption("covr.icov_args", NULL)) {
  if (!nzchar(icov_path)) {
    return()
  }

  src_path <- normalize_path(file.path(path, "src"))
  if (!file.exists(src_path)) {
     return()
  }

  icov_inputs <- list.files(path, pattern = rex::rex(".dyn", end),
                            recursive = TRUE, full.names = TRUE)

  icov_profmerge <- getOption("covr.icov_prof", "")
  system_check(icov_profmerge,
        args = c("-prof_dir", src_path),
        quiet = quiet, echo = !quiet)

  wd <- getwd()
  on.exit(setwd(wd))
  setwd(src_path)
  system_check(icov_path,
        args = c("-prj", "tmp", "-spi", file.path(src_path, "pgopti.spi"),
                 "-dpi", file.path(src_path, "pgopti.dpi"),
                 "-include-nonexec", 
                 "-txtbcvrg", "bcovg.log"),
        quiet = quiet, echo = !quiet)
  
  lines <- readLines(file.path(src_path, "bcovg.log"))

  # generate line coverage
  re <- rex::re_matches(lines, rex::rex("Covered Functions in File: \"",
                        capture(name = "source", anything), "\""))$source
  idx1 <- which(!is.na(re))
  idx2 <- c(idx1[2:length(idx1)]-1, length(re))
  srcfilenms <- re[idx1]
  lines[idx1] <- srcfilenms
  icov_outputs <- lapply(seq_along(idx1), function(i) lines[idx1[i]:idx2[i]])

  structure(
      unlist(recursive = FALSE,
        lapply(icov_outputs, parse_icov, package_path = path)),
      class = "coverage")
}
## END Oracle Contribution
