# Run the tests of a package (see phase-child.R) uninstrumented and
# instrumented by covr main, each with the byte-code JIT on (R's default) and
# off (R_ENABLE_JIT=0), and count how often `if` conditions ran.
#
# Usage (R_LIBS must start with the covr main library):
#   R_LIBS=$bench/lib/4.6.2/covr-main:$bench/lib/4.6.2/deps \
#     /opt/R/4.6.2/bin/Rscript --no-init-file performance-audit/bench-child-variants.R \
#     <pkg_tarball> <reps> <out.rds>

args <- commandArgs(trailingOnly = TRUE)
tarball <- normalizePath(args[[1]])
reps <- as.integer(args[[2]])
out <- args[[3]]

here <- dirname(normalizePath(sub(
  "--file=",
  "",
  grep("--file=", commandArgs(), value = TRUE)
)))
child <- file.path(here, "phase-child.R")
rscript <- file.path(R.home("bin"), "Rscript")
deps <- strsplit(Sys.getenv("R_LIBS"), ":", fixed = TRUE)[[1]]
pkg_name <- sub("_.*", "", basename(tarball))

fresh_source <- function() {
  dir <- tempfile("src")
  dir.create(dir)
  untar(tarball, exdir = dir)
  file.path(dir, pkg_name)
}

plain_lib <- tempfile("plain")
dir.create(plain_lib)
system2(
  file.path(R.home("bin"), "R"),
  c(
    "CMD",
    "INSTALL",
    "--install-tests",
    "-l",
    shQuote(plain_lib),
    shQuote(fresh_source())
  ),
  env = paste0("R_LIBS=", Sys.getenv("R_LIBS")),
  stdout = FALSE,
  stderr = FALSE
)
src <- fresh_source()
pkg <- covr:::as_package(src)
instr_lib <- tempfile("instr")
dir.create(instr_lib)
covr:::install_package(pkg, instr_lib, getOption("covr.flags"), quiet = TRUE)
covr:::add_hooks(pkg$package, instr_lib)

run_child <- function(mode, lib, jit) {
  res_file <- tempfile(fileext = ".rds")
  trace_dir <- tempfile("traces")
  dir.create(trace_dir)
  scratch <- tempfile("scratch")
  dir.create(scratch)
  env <- c(
    paste0("R_LIBS=", paste(c(lib, deps), collapse = ":")),
    paste0("TRACE_SAVE_DIR=", trace_dir),
    paste0("COVERAGE_DIR=", scratch),
    "R_COVR=true",
    if (!jit) "R_ENABLE_JIT=0"
  )
  status <- system2(
    rscript,
    c("--vanilla", shQuote(child), mode, pkg_name, shQuote(res_file)),
    env = env,
    stdout = FALSE,
    stderr = FALSE
  )
  if (status != 0) {
    stop("child failed")
  }
  r <- readRDS(res_file)
  data.frame(
    mode = mode,
    jit = jit,
    load = r$load,
    tests = r$tests,
    n_counts = r$n_counts %||% NA,
    n_if_counts = r$n_if_counts %||% NA,
    n_if_statements = r$n_if_statements %||% NA,
    n_traces = r$n_traces %||% NA,
    covr = r$covr %||% NA
  )
}
`%||%` <- function(x, y) if (is.null(x)) y else x

rows <- list()
for (rep in seq_len(reps)) {
  for (jit in c(TRUE, FALSE)) {
    rows[[length(rows) + 1]] <- cbind(
      rep = rep,
      run_child("plain", plain_lib, jit)
    )
    rows[[length(rows) + 1]] <- cbind(
      rep = rep,
      run_child("instr", instr_lib, jit)
    )
  }
}
res <- do.call(rbind, rows)
res$pkg <- pkg_name
saveRDS(res, out)
print(res)
print(aggregate(cbind(load, tests) ~ mode + jit, res, median))
