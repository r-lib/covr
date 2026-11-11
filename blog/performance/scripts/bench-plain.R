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

tests <- file.path(lib, pkg, "tests")
code <- if (identical(Sys.getenv("COVR_BENCH_TYPE"), "tests")) {
  # Each script in its own R process, as R CMD check does.
  sprintf("for (f in sort(list.files(%s, pattern = '[.]R$', full.names = TRUE))) system2(%s, c('--no-echo', '--no-restore', '-f', shQuote(f)), stdout = FALSE, stderr = FALSE)",
    deparse(tests), deparse(file.path(R.home("bin"), "R")))
} else if (dir.exists(file.path(tests, "testthat"))) {
  sprintf("testthat::test_dir(%s, package = %s, load_package = 'installed', reporter = 'silent', stop_on_failure = FALSE, stop_on_warning = FALSE)",
    deparse(file.path(tests, "testthat")), deparse(pkg))
} else {
  sprintf("setwd(%s); for (f in sort(list.files(pattern = '[.]R$'))) tryCatch(sys.source(f, envir = new.env(parent = globalenv())), error = function(e) message(f, ': ', conditionMessage(e)))",
    deparse(tests))
}
script <- tempfile(fileext = ".R")
writeLines(c("Sys.setenv(NOT_CRAN = 'true')", code), script)
t1 <- now()
system2(file.path(R.home("bin"), "Rscript"), c("--no-init-file", shQuote(script)),
  env = c(paste0("R_LIBS=", libs), "NOT_CRAN=true"), stdout = FALSE, stderr = FALSE)
run_code <- now() - t1
res <- list(label = "plain", pkg = pkg, total = install + run_code, install = install,
  run_code = run_code, merge = 0)
saveRDS(res, out)
cat(sprintf("plain %s: %.1f s (install %.1f, tests %.1f)\n", pkg, res$total, install, run_code))
