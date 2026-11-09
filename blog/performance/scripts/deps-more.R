options(repos = c(CRAN = sprintf("https://p3m.dev/cran/latest/bin/linux/manylinux_2_28-%s/%s", R.version$arch, substr(getRversion(), 1, 3))),
  HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)), Ncpus = 8L)
lib <- "/tmp/covr-bench/lib/4.6.2/deps"
.libPaths(lib)
tarballs <- Sys.glob(file.path("/tmp/covr-bench/src", c("dplyr_*", "data.table_*", "devtools_*", "lintr_*")))
deps <- unique(unlist(lapply(tarballs, function(t) {
  pkg <- sub("_.*", "", basename(t)); ex <- tempfile(); untar(t, files = file.path(pkg, "DESCRIPTION"), exdir = ex)
  d <- read.dcf(file.path(ex, pkg, "DESCRIPTION"))
  x <- unlist(strsplit(d[, intersect(c("Depends", "Imports", "LinkingTo", "Suggests"), colnames(d))], ","))
  x <- trimws(sub("\\(.*", "", x)); x[nzchar(x)]
})))
deps <- setdiff(deps, c("R", "covr", rownames(installed.packages(priority = "base")), rownames(installed.packages(lib.loc = lib))))
cat("installing:", deps, "\n")
if (length(deps)) install.packages(deps, lib = lib, dependencies = c("Depends", "Imports", "LinkingTo"))
unlink(file.path(lib, "covr"), recursive = TRUE)
cat("missing:", setdiff(deps, rownames(installed.packages(lib.loc = lib))), "\n")
