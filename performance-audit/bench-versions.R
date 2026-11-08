# Time package_coverage() of one package with the covr version installed
# first in R_LIBS, as covr's subprocesses load the installed covr.
#
# Usage:
#   R_LIBS=$bench/lib/<R>/covr-<ver>:$bench/lib/<R>/deps \
#     <Rscript> --no-init-file performance-audit/bench-versions.R \
#     <pkg_tarball> <label> <out.rds>
#
# The tests are run with `type = "none"` and `code`, the same way for every
# covr version, with failures allowed, since some benchmark packages have test
# failures with current dependencies. Besides the total, it records where the
# main process spent its time (Rprof, sampled every 20 ms; the tests run in a
# subprocess, which shows up as the time in run_commands()) and the time of
# the post-processing functions on the result.

args <- commandArgs(trailingOnly = TRUE)
tarball <- normalizePath(args[[1]])
label <- args[[2]]
out <- args[[3]]

now <- function() proc.time()[["elapsed"]]
timed <- function(expr) {
  t0 <- now()
  r <- tryCatch(
    {
      force(expr)
      TRUE
    },
    error = function(e) {
      message("error: ", conditionMessage(e))
      FALSE
    }
  )
  if (r) now() - t0 else NA_real_
}
vmhwm <- function() {
  x <- grep("^VmHWM", readLines("/proc/self/status"), value = TRUE)
  as.numeric(gsub("[^0-9]", "", x)) / 1024
}

pkg <- sub("_.*", "", basename(tarball))
src_dir <- tempfile("src")
dir.create(src_dir)
untar(tarball, exdir = src_dir)
src <- file.path(src_dir, pkg)

test_code <- sprintf(
  "Sys.setenv(NOT_CRAN = 'true'); testthat::test_dir(system.file('tests/testthat', package = '%s'), package = '%s', load_package = 'installed', reporter = 'silent', stop_on_failure = FALSE, stop_on_warning = FALSE)",
  pkg,
  pkg
)

invisible(suppressPackageStartupMessages(loadNamespace("covr")))
covr_version <- as.character(packageVersion("covr"))

# Wall-clock time spent in covr's main process steps, measured with trace()
# rather than Rprof(), which only samples CPU time and so misses the time spent
# waiting for R CMD INSTALL and the test process. Old covr versions install
# with utils::install.packages() rather than install_package().
phase_time <- new.env()
phase_depth <- new.env()
.phase_start <- function(name) {
  depth <- phase_depth[[name]] %||% 0
  if (depth == 0) {
    assign(paste0(name, "_t0"), proc.time()[["elapsed"]], phase_depth)
  }
  phase_depth[[name]] <- depth + 1
}
.phase_end <- function(name) {
  phase_depth[[name]] <- phase_depth[[name]] - 1
  if (phase_depth[[name]] == 0) {
    t <- proc.time()[["elapsed"]] - phase_depth[[paste0(name, "_t0")]]
    phase_time[[name]] <- (phase_time[[name]] %||% 0) + t
  }
}
`%||%` <- function(x, y) if (is.null(x)) y else x
phases <- list(
  install = list("install_package", "covr"),
  install = list("install.packages", "utils"),
  # covr 3.6.5 runs R CMD INSTALL inline in package_coverage()
  install = list("with_makevars", "withr"),
  run_code = list("run_commands", "covr"),
  merge = list("merge_coverage", "covr"),
  gcov = list("run_gcov", "covr"),
  exclude = list("exclude", "covr")
)
traced <- list()
for (i in seq_along(phases)) {
  fn <- phases[[i]][[1]]
  ns <- asNamespace(phases[[i]][[2]])
  if (!exists(fn, envir = ns, inherits = FALSE)) {
    next
  }
  name <- names(phases)[[i]]
  suppressMessages(trace(
    fn,
    tracer = bquote(.phase_start(.(name))),
    exit = bquote(.phase_end(.(name))),
    where = ns,
    print = FALSE
  ))
  traced[[length(traced) + 1L]] <- phases[[i]]
}

cov <- NULL
total <- timed(
  cov <- covr::package_coverage(
    src,
    type = "none",
    code = test_code,
    quiet = TRUE,
    clean = FALSE
  )
)
for (x in traced) {
  suppressMessages(untrace(x[[1]], where = asNamespace(x[[2]])))
}

fn_time <- function(name) phase_time[[name]] %||% 0

res <- list(
  label = label,
  covr = covr_version,
  r = paste(R.version$major, R.version$minor, sep = "."),
  pkg = pkg,
  total = total,
  # Main process phases (wall clock).
  install = fn_time("install"),
  run_code = fn_time("run_code"),
  merge = fn_time("merge"),
  gcov_in_run = fn_time("gcov"),
  exclude = fn_time("exclude"),
  main_mem_mb = vmhwm()
)

if (!is.null(cov)) {
  res$n_traces <- length(cov)
  res$percent <- tryCatch(covr::percent_coverage(cov), error = function(e) NA)
  res$percent_coverage <- timed(covr::percent_coverage(cov))
  res$tally_coverage <- timed(covr::tally_coverage(cov))
  # report() takes minutes for large packages, so the driver only times it in
  # the first repetition.
  if (!identical(Sys.getenv("COVR_BENCH_REPORT"), "false")) {
    res$report <- timed(covr::report(
      cov,
      file = tempfile(fileext = ".html"),
      browse = FALSE
    ))
  }
  if (length(list.files(src, pattern = "[.]gcda$", recursive = TRUE)) > 0) {
    res$gcov <- timed(covr:::run_gcov(src, quiet = TRUE, clean = FALSE))
  }
}
res$main_mem_after_post_mb <- vmhwm()

saveRDS(res, out)
str(res)
