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

# Run the tests the way package_coverage(type = "tests") does (R/covr.R),
# minus instrumenting: tools::testInstalledPackage() under the same
# environment variables, so the same tests run and skip.
env <- c(
  R_DEFAULT_PACKAGES = "datasets,utils,grDevices,graphics,stats,methods",
  R_LIBS = libs,
  R_LIBS_USER = libs,
  R_COVR = "true",
  R_TESTS = file.path(R.home("share"), "R", "tests-startup.R"),
  NOT_CRAN = "true"
)
out_dir <- tempfile("out")
dir.create(out_dir)
t1 <- now()
status <- withr::with_envvar(env, tools::testInstalledPackage(pkg, lib.loc = lib, outDir = out_dir, types = "tests"))
run_code <- now() - t1
res <- list(label = "plain", pkg = pkg, total = install + run_code, install = install,
  run_code = run_code, merge = 0, tests_failed = status != 0L)
saveRDS(res, out)
cat(sprintf("plain %s: %.1f s (install %.1f, tests %.1f)\n", pkg, res$total, install, run_code))
