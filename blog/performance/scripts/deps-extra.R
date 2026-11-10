# Download the CRAN source tarballs of benchmark packages into <bench>/src and
# install their dependencies (including Suggests, so their tests can run) into
# the R 4.6.2 deps library. The bench directory is COVR_BENCH (default
# ~/covr-bench). Tarballs already in <bench>/src are kept.
# Usage: Rscript --no-init-file deps-extra.R <pkg>...
pkgs <- commandArgs(trailingOnly = TRUE)
bin <- sprintf("https://p3m.dev/cran/latest/bin/linux/manylinux_2_28-%s/%s", R.version$arch, substr(getRversion(), 1, 3))
options(
  repos = c(CRAN = bin),
  HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)),
  Ncpus = 8L
)
bench <- Sys.getenv("COVR_BENCH", path.expand("~/covr-bench"))
lib <- file.path(bench, "lib", "4.6.2", "deps")
src <- file.path(bench, "src")
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
dir.create(src, recursive = TRUE, showWarnings = FALSE)
.libPaths(lib)
have <- Sys.glob(file.path(src, paste0(pkgs, "_*.tar.gz")))
todo <- setdiff(pkgs, sub("_.*", "", basename(have)))
if (length(todo)) {
  download.packages(todo, destdir = src, repos = c(CRAN = "https://cloud.r-project.org"), type = "source")
}
tarballs <- unlist(lapply(pkgs, function(p) Sys.glob(file.path(src, paste0(p, "_*.tar.gz")))))
deps <- unique(unlist(lapply(tarballs, function(t) {
  pkg <- sub("_.*", "", basename(t))
  ex <- tempfile()
  untar(t, files = file.path(pkg, "DESCRIPTION"), exdir = ex)
  d <- read.dcf(file.path(ex, pkg, "DESCRIPTION"))
  x <- unlist(strsplit(d[, intersect(c("Depends", "Imports", "LinkingTo", "Suggests"), colnames(d))], ","))
  x <- trimws(sub("\\(.*", "", x))
  x[nzchar(x)]
})))
deps <- setdiff(deps, c("R", "covr", rownames(installed.packages(priority = "base"))))
deps <- setdiff(deps, rownames(installed.packages(lib.loc = lib)))
cat("installing:", deps, "\n")
if (length(deps)) {
  install.packages(deps, lib = lib, dependencies = c("Depends", "Imports", "LinkingTo"))
}
unlink(file.path(lib, "covr"), recursive = TRUE)
cat("tarballs:", basename(tarballs), "\n")
cat("missing:", setdiff(deps, rownames(installed.packages(lib.loc = lib))), "\n")
