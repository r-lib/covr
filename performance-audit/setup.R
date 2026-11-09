# Set up the libraries used by the covr performance benchmarks.
#
# Run once per R version, e.g.
#   Rscript --no-init-file performance-audit/setup.R /tmp/covr-bench
#   /opt/R/4.4.3/bin/Rscript --no-init-file performance-audit/setup.R /tmp/covr-bench
#
# Creates, under <bench>:
#   src/                 tarballs of the covr versions and benchmark packages
#   lib/<R>/deps         dependencies of all covr versions, testthat and the
#                        benchmark packages (P3M binaries where available)
#   lib/<R>/covr-<ver>   one library per covr version, holding only covr
#
# The covr versions are installed from the CRAN archive; "main" is installed
# from the committed HEAD of this repository (`git archive HEAD`).

args <- commandArgs(trailingOnly = TRUE)
bench <- if (length(args) >= 1) args[[1]] else "/tmp/covr-bench"
repo <- normalizePath(if (length(args) >= 2) args[[2]] else ".")

rver <- paste(R.version$major, R.version$minor, sep = ".")
options(
  repos = c(
    CRAN = sprintf(
      "https://p3m.dev/cran/latest/bin/linux/manylinux_2_28-%s/%s",
      R.version$arch,
      substr(getRversion(), 1, 3)
    )
  ),
  HTTPUserAgent = sprintf(
    "R/%s R (%s)",
    getRversion(),
    paste(getRversion(), R.version$platform, R.version$arch, R.version$os)
  ),
  Ncpus = 8L
)

src <- file.path(bench, "src")
deps_lib <- file.path(bench, "lib", rver, "deps")
dir.create(src, recursive = TRUE, showWarnings = FALSE)
dir.create(deps_lib, recursive = TRUE, showWarnings = FALSE)

covr_versions <- c("3.5.1", "3.6.0", "3.6.4", "3.6.5")
bench_pkgs <- c(
  forcats = "1.0.1",
  checkmate = "2.3.4",
  Luminescence = "0.9.25"
)

cran_download <- function(pkg, version) {
  file <- file.path(src, sprintf("%s_%s.tar.gz", pkg, version))
  if (file.exists(file)) {
    return(file)
  }
  urls <- c(
    sprintf("https://cran.r-project.org/src/contrib/%s", basename(file)),
    sprintf(
      "https://cran.r-project.org/src/contrib/Archive/%s/%s",
      pkg,
      basename(file)
    )
  )
  for (url in urls) {
    ok <- tryCatch(
      download.file(url, file, quiet = TRUE, mode = "wb") == 0,
      error = function(e) FALSE,
      warning = function(w) FALSE
    )
    if (ok) {
      return(file)
    }
  }
  unlink(file)
  stop("Can't download ", basename(file))
}

read_desc <- function(x) {
  if (dir.exists(x)) {
    return(read.dcf(file.path(x, "DESCRIPTION")))
  }
  pkg <- sub("_.*", "", basename(x))
  exdir <- tempfile()
  untar(x, files = file.path(pkg, "DESCRIPTION"), exdir = exdir)
  read.dcf(file.path(exdir, pkg, "DESCRIPTION"))
}

deps_of <- function(x, fields) {
  desc <- read_desc(x)
  deps <- unlist(lapply(intersect(fields, colnames(desc)), function(f) {
    strsplit(desc[, f], ",")[[1]]
  }))
  deps <- trimws(sub("\\(.*", "", deps))
  deps <- deps[nzchar(deps)]
  setdiff(deps, c("R", rownames(installed.packages(priority = "base"))))
}

covr_tarballs <- vapply(
  covr_versions,
  cran_download,
  character(1),
  pkg = "covr"
)
pkg_tarballs <- mapply(cran_download, names(bench_pkgs), bench_pkgs)

main_dir <- file.path(src, "covr-main")
unlink(main_dir, recursive = TRUE)
dir.create(main_dir)
system2(
  "sh",
  c(
    "-c",
    shQuote(sprintf("cd %s && git archive HEAD | tar -x -C %s", repo, main_dir))
  )
)

needed <- unique(c(
  "testthat",
  "htmltools",
  "DT",
  "profvis",
  unlist(lapply(
    c(covr_tarballs, main_dir),
    deps_of,
    c("Depends", "Imports", "LinkingTo")
  )),
  # covr's own Suggests, for measuring covr's coverage of itself
  deps_of(main_dir, "Suggests"),
  unlist(lapply(
    pkg_tarballs,
    deps_of,
    c("Depends", "Imports", "LinkingTo", "Suggests")
  ))
))

.libPaths(deps_lib)
missing <- setdiff(needed, rownames(installed.packages(lib.loc = deps_lib)))
if (length(missing) > 0) {
  install.packages(
    missing,
    lib = deps_lib,
    dependencies = c("Depends", "Imports", "LinkingTo")
  )
}
# Packages such as devtools depend on covr, so the deps library gets the CRAN
# covr too. Remove it, so covr only comes from the per-version libraries and
# can never shadow the version under test.
unlink(file.path(deps_lib, "covr"), recursive = TRUE)
still_missing <- setdiff(
  needed,
  rownames(installed.packages(lib.loc = deps_lib))
)
if (length(still_missing) > 0) {
  message(
    "Not installed (unavailable): ",
    paste(still_missing, collapse = ", ")
  )
}

install_covr <- function(version, path) {
  lib <- file.path(bench, "lib", rver, paste0("covr-", version))
  unlink(lib, recursive = TRUE)
  dir.create(lib, recursive = TRUE)
  status <- system2(
    file.path(R.home("bin"), "R"),
    c("CMD", "INSTALL", "--no-test-load", "-l", shQuote(lib), shQuote(path)),
    env = paste0("R_LIBS=", deps_lib),
    stdout = FALSE,
    stderr = FALSE
  )
  message(
    "covr ",
    version,
    " on R ",
    rver,
    ": ",
    if (status == 0) "ok" else "FAILED"
  )
}

for (v in covr_versions) {
  install_covr(v, covr_tarballs[[v]])
}
install_covr("main", main_dir)
