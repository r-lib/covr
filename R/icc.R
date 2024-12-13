parse_icov <- function(lines, package_path = "") {

  source_file <- trim_ws(lines[1L])
  # If the source file does not start with the package path ignore it.
  if (!grepl(rex::rex(start, package_path), source_file)) {
    return(NULL)
  }

  # remove source file lines and empty/white space lines
  lines <- trim_ws(lines[-1L])
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

  show_C_functions <- getOption("covr.showCfunctions", FALSE)
  if (length(idx1) == 0L) {
    m1 <- rex::re_matches(lines, re)
    m1$functions <- rep(NA_character_, nrow(m1))
  } else {
    m1 <- rex::re_matches(lines[-idx1], re)
    if (isTRUE(show_C_functions)) {
      # get function names
      if (length(idx1) == 1L) {
        m1$functions <- rep(r1[idx1], nrow(m1))
      } else {
        stopifnot(idx1[1L] == 1L)
        nums <- c(idx1[2L:length(idx1)]-1L, length(r1)) - idx1
        stopifnot(sum(nums) == nrow(m1))
        m1$functions <- unlist(mapply(rep, r1[idx1], nums,
                                      SIMPLIFY=FALSE, USE.NAMES=FALSE))
      }
    }
  }
  # remove invalid rows if exists
  m1 <- na.omit(m1)
  m1$line <- as.numeric(m1$line)
  m1$coverage <- as.numeric(m1$coverage)
  if (is.null(m1$functions)) {
    m2 <- aggregate(m1$coverage, by = list(line=m1$line), sum)
    names(m2) <- c("line", "coverage")
    m2$functions <- NA_character_
  } else {
    m2 <- aggregate(m1$coverage,
                    by = list(line=m1$line, functions=m1$functions), sum)
    names(m2) <- c("line", "functions", "coverage")
  }
  matches <- m2[order(m2$line), ]

  values <- as.numeric(matches$coverage > 0L)
  functions <- matches$functions

  line_coverages(source_file, matches, values, functions)
}

run_icov <- function(path, quiet = TRUE,
                     icov_path = getOption("covr.icov", ""),
                     icov_args = getOption("covr.icov_args", NULL)) {

  src_path <- normalize_path(file.path(path, "src"))
  if (!file.exists(src_path)) {
     return()
  }

  if (!nzchar(icov_path)) {
    warning("icc codecov not available")
    return()
  }

  icov_profmerge <- getOption("covr.icov_prof", "")
  if (!nzchar(icov_profmerge)) {
    warning("icc profmerge not available")
    return()
  }

  icov_inputs <- list.files(path, pattern = rex::rex(".dyn", end),
                            recursive = TRUE, full.names = TRUE)
  if (length(icov_inputs) == 0L) {
    warning("no icc .dyn files are generated")
    return()
  }

  system_check(icov_profmerge,
        args = c("-prof_dir", src_path),
        quiet = quiet, echo = !quiet)

  withr::with_dir(src_path, {
  system_check(icov_path,
        args = c("-prj", "tmp", "-spi", file.path(src_path, "pgopti.spi"),
                 "-dpi", file.path(src_path, "pgopti.dpi"),
                 "-include-nonexec",
                 "-txtbcvrg", "bcovg.log"),
        quiet = quiet, echo = !quiet)
  })

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

# check if icc is used
uses_icc <- function() {
  compiler <- tryCatch(
    {
      system2(file.path(R.home("bin"), "R"),
        args = c("--vanilla", "CMD", "config", "CC"),
        stdout = TRUE)
    },
    warning = function(e) NA_character_)
  isTRUE(any(grepl("\\bicc\\b", compiler)))
}
