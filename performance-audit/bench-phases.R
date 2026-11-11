# Phase breakdown of package_coverage() on covr main, compared to installing
# and testing the same package without coverage.
#
# Usage (R_LIBS must start with the covr main library):
#   R_LIBS=$bench/lib/4.6.2/covr-main:$bench/lib/4.6.2/deps \
#     /opt/R/4.6.2/bin/Rscript --no-init-file performance-audit/bench-phases.R \
#     <bench_dir> <pkg_tarball> <reps> <out_dir>
#
# Writes <out_dir>/<pkg>-phases.rds (one row per phase and repetition) and the
# profiles of one extra, untimed, instrumented run to <out_dir>/<pkg>-*.Rprof.

args <- commandArgs(trailingOnly = TRUE)
bench <- args[[1]]
tarball <- normalizePath(args[[2]])
reps <- as.integer(args[[3]])
out_dir <- args[[4]]
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

here <- dirname(normalizePath(sub(
  "--file=",
  "",
  grep("--file=", commandArgs(), value = TRUE)
)))
child <- file.path(here, "phase-child.R")
rscript <- file.path(R.home("bin"), "Rscript")
r <- file.path(R.home("bin"), "R")
libs <- Sys.getenv("R_LIBS")
# The child processes get the instrumented (or plain) library first, then all
# of R_LIBS, which starts with the covr main library.
deps <- strsplit(libs, ":", fixed = TRUE)[[1]]

now <- function() proc.time()[["elapsed"]]
vmhwm <- function() {
  x <- grep("^VmHWM", readLines("/proc/self/status"), value = TRUE)
  as.numeric(gsub("[^0-9]", "", x)) / 1024
}
timed <- function(expr) {
  t0 <- now()
  force(expr)
  now() - t0
}

fresh_source <- function() {
  dir <- tempfile("src")
  dir.create(dir)
  untar(tarball, exdir = dir)
  file.path(dir, list.files(dir))
}

run_child <- function(mode, lib, pkg, profile = NULL, env = character()) {
  out <- tempfile(fileext = ".rds")
  trace_dir <- tempfile("traces")
  dir.create(trace_dir)
  status <- system2(
    rscript,
    c(
      "--vanilla",
      shQuote(child),
      mode,
      pkg,
      shQuote(out),
      if (!is.null(profile)) shQuote(profile)
    ),
    env = c(
      paste0("R_LIBS=", paste(c(lib, deps), collapse = ":")),
      paste0("TRACE_SAVE_DIR=", trace_dir),
      env
    ),
    stdout = FALSE,
    stderr = FALSE
  )
  if (status != 0 || !file.exists(out)) {
    stop("child failed: ", mode, " ", pkg)
  }
  readRDS(out)
}

pkg_name <- sub("_.*", "", basename(tarball))
test_code <- sprintf(
  "Sys.setenv(NOT_CRAN = 'true'); testthat::test_dir(system.file('tests/testthat', package = '%s'), package = '%s', load_package = 'installed', reporter = 'silent', stop_on_failure = FALSE, stop_on_warning = FALSE)",
  pkg_name,
  pkg_name
)

rows <- list()
add <- function(rep, phase, seconds, ...) {
  rows[[length(rows) + 1L]] <<- data.frame(
    pkg = pkg_name,
    r = paste(R.version$major, R.version$minor, sep = "."),
    rep = rep,
    phase = phase,
    seconds = seconds,
    ...
  )
}

for (rep in seq_len(reps)) {
  message(pkg_name, " rep ", rep)

  # Uninstrumented baseline: a normal install, then the same tests.
  src <- fresh_source()
  plain_lib <- tempfile("plain")
  dir.create(plain_lib)
  add(
    rep,
    "baseline: R CMD INSTALL",
    timed(system2(
      r,
      c(
        "CMD",
        "INSTALL",
        "--install-tests",
        "-l",
        shQuote(plain_lib),
        shQuote(src)
      ),
      env = paste0("R_LIBS=", libs),
      stdout = FALSE,
      stderr = FALSE
    ))
  )
  plain <- run_child("plain", plain_lib, pkg_name)
  add(rep, "baseline: load namespace", plain$load)
  add(
    rep,
    "baseline: run tests",
    plain$tests,
    mem_mb = plain$mem_after_tests_mb
  )

  # The phases of package_coverage(), run one by one.
  src <- fresh_source()
  pkg <- covr:::as_package(src)
  instr_lib <- tempfile("instr")
  dir.create(instr_lib)
  add(
    rep,
    "covr: install with coverage flags",
    timed(
      covr:::install_package(
        pkg,
        instr_lib,
        getOption("covr.flags"),
        quiet = TRUE
      )
    )
  )
  covr:::add_hooks(pkg$package, instr_lib)
  scratch <- tempfile("scratch")
  dir.create(scratch)
  instr <- run_child(
    "instr",
    instr_lib,
    pkg_name,
    env = c("R_COVR=true", paste0("COVERAGE_DIR=", scratch))
  )
  add(rep, "covr: load + trace_environment()", instr$load)
  add(
    rep,
    "covr: run tests (counting)",
    instr$tests,
    mem_mb = instr$mem_after_tests_mb
  )
  add(rep, "covr: save_trace()", instr$save, mem_mb = instr$mem_after_save_mb)

  merged <- NULL
  add(
    rep,
    "covr: merge_coverage()",
    timed(
      merged <- covr:::merge_coverage(instr$trace_file)
    )
  )
  gcov <- NULL
  if (length(list.files(src, pattern = "[.]gcda$", recursive = TRUE)) > 0) {
    add(
      rep,
      "covr: run_gcov()",
      timed(
        gcov <- covr:::run_gcov(src, quiet = TRUE, clean = FALSE)
      )
    )
  }
  cov <- NULL
  add(
    rep,
    "covr: as_coverage() + exclude()",
    timed({
      cov <- covr:::as_coverage(c(merged, gcov), package = pkg, root = pkg$path)
      cov <- covr:::filter_non_package_files(cov)
      cov <- covr:::exclude(cov, path = pkg$path)
    })
  )
  add(rep, "post: percent_coverage()", timed(covr::percent_coverage(cov)))
  add(rep, "post: tally_coverage()", timed(covr::tally_coverage(cov)))
  add(
    rep,
    "post: zero_coverage()",
    timed(
      withr::with_options(
        list(covr.rstudio_source_markers = FALSE),
        covr::zero_coverage(cov)
      )
    )
  )
  add(rep, "post: print()", timed(utils::capture.output(print(cov))))
  add(
    rep,
    "post: report()",
    timed(
      covr::report(cov, file = tempfile(fileext = ".html"), browse = FALSE)
    )
  )
  add(
    rep,
    "post: cobertura()",
    timed(
      covr::cobertura(cov, filename = tempfile(fileext = ".xml"))
    )
  )
  add(rep, "post: coverage_to_list()", timed(covr::coverage_to_list(cov)))

  # The whole of package_coverage(), for comparison with the sum of the phases.
  src <- fresh_source()
  add(
    rep,
    "package_coverage() end to end",
    timed(covr::package_coverage(
      src,
      type = "none",
      code = test_code,
      quiet = TRUE
    ))
  )

  meta <- list(
    covr_in_child = instr$covr,
    n_traces = instr$n_traces,
    n_counts = instr$n_counts,
    n_if_counts = instr$n_if_counts,
    n_tests = instr$n_tests,
    trace_bytes = instr$trace_bytes,
    coverage_bytes = as.numeric(object.size(cov)),
    percent = covr::percent_coverage(cov),
    plain_mem_mb = plain$mem_after_tests_mb,
    instr_mem_mb = instr$mem_after_save_mb,
    main_mem_mb = vmhwm()
  )
  # Keep the last coverage object and trace file for profile-post.R and
  # microbench.R.
  saveRDS(cov, file.path(out_dir, paste0(pkg_name, "-coverage.rds")))
  file.copy(
    instr$trace_file,
    file.path(out_dir, paste0(pkg_name, "-trace.rds")),
    overwrite = TRUE
  )
  unlink(c(plain_lib, instr_lib, scratch), recursive = TRUE)
}

# One profiled instrumented run for the recommendations. The timings above come
# from unprofiled runs.
src <- fresh_source()
pkg <- covr:::as_package(src)
instr_lib <- tempfile("instr")
dir.create(instr_lib)
covr:::install_package(pkg, instr_lib, getOption("covr.flags"), quiet = TRUE)
covr:::add_hooks(pkg$package, instr_lib)
scratch <- tempfile("scratch")
dir.create(scratch)
profile <- file.path(out_dir, paste0(pkg_name, "-child.Rprof"))
run_child(
  "instr",
  instr_lib,
  pkg_name,
  profile = profile,
  env = c("R_COVR=true", paste0("COVERAGE_DIR=", scratch))
)

phases <- do.call(
  rbind,
  lapply(rows, function(x) {
    if (is.null(x$mem_mb)) {
      x$mem_mb <- NA_real_
    }
    x
  })
)
saveRDS(
  list(phases = phases, meta = meta),
  file.path(out_dir, paste0(pkg_name, "-phases.rds"))
)
print(aggregate(seconds ~ phase, phases, median))
str(meta)
