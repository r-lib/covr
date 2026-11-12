# Time the same work as bench-release.R without covr: install the package from
# its source tarball into a fresh library, then run its tests the same way
# (testthat::test_dir() on the installed tests, or each tests/*.R script for
# packages without testthat, or R CMD check-style per-script processes for
# COVR_BENCH_TYPE=tests). Saves the same fields as bench-release.R with
# label "plain", so the summary and plots can read both.
# Usage: R_LIBS=<deps> Rscript --no-init-file bench-plain.R <tarball> <out.rds>
args <- commandArgs(trailingOnly = TRUE)
tarball <- normalizePath(args[[1]])
out <- args[[2]]
pkg <- sub("_.*", "", basename(tarball))
now <- function() proc.time()[["elapsed"]]
lib <- tempfile("lib")
dir.create(lib)
src_dir <- tempfile("src")
dir.create(src_dir)
untar(tarball, exdir = src_dir)
src <- file.path(src_dir, pkg)
rbin <- file.path(R.home("bin"), "R")
libs <- paste(c(lib, .libPaths()), collapse = .Platform$path.sep)
t0 <- now()
st <- system2(rbin, c("CMD", "INSTALL", "--install-tests", "-l", shQuote(lib), shQuote(src)),
  env = paste0("R_LIBS=", libs), stdout = FALSE, stderr = FALSE)
install <- now() - t0
if (st != 0) stop("install failed")

# Run the tests the way covr does (R/covr.R), minus instrumenting, under the
# same environment variables, so the same tests run and skip:
# - type = "tests": tools::testInstalledPackage();
# - otherwise (type = "none" with code): `library(pkg)` and the code, run with
#   R CMD BATCH --vanilla, as covr's run_commands() does.
env <- c(
  R_DEFAULT_PACKAGES = "datasets,utils,grDevices,graphics,stats,methods",
  R_LIBS = libs,
  R_LIBS_USER = libs,
  R_COVR = "true",
  R_TESTS = file.path(R.home("share"), "R", "tests-startup.R"),
  NOT_CRAN = "true"
)
tests <- file.path(lib, pkg, "tests")
out_dir <- tempfile("out")
dir.create(out_dir)
t1 <- now()
if (identical(Sys.getenv("COVR_BENCH_TYPE"), "tests")) {
  withr::with_envvar(env, tools::testInstalledPackage(pkg, lib.loc = lib, outDir = out_dir, types = "tests"))
} else {
  code <- if (dir.exists(file.path(tests, "testthat"))) {
    sprintf("Sys.setenv(NOT_CRAN = 'true'); testthat::test_dir(system.file('tests/testthat', package = '%s'), package = '%s', load_package = 'installed', reporter = 'silent', stop_on_failure = FALSE, stop_on_warning = FALSE)", pkg, pkg)
  } else {
    sprintf("Sys.setenv(NOT_CRAN = 'true'); setwd(system.file('tests', package = '%s')); for (f in sort(list.files(pattern = '[.]R$'))) tryCatch(sys.source(f, envir = new.env(parent = globalenv())), error = function(e) message(f, ': ', conditionMessage(e)))", pkg)
  }
  infile <- file.path(out_dir, "commands.R")
  writeLines(c(sprintf("library('%s')", pkg), code), infile)
  withr::with_envvar(env, system(paste(
    shQuote(file.path(R.home("bin"), "R")), "CMD BATCH --vanilla --no-timing",
    shQuote(infile), shQuote(file.path(out_dir, "commands.Rout"))
  )))
}
run_code <- now() - t1
res <- list(label = "plain", pkg = pkg, total = install + run_code, install = install,
  run_code = run_code, merge = 0)
saveRDS(res, out)
cat(sprintf("plain %s: %.1f s (install %.1f, tests %.1f)\n", pkg, res$total, install, run_code))
