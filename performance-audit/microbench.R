# Microbenchmarks behind the recommendations in performance-audit.md.
#
# Usage (R_LIBS must start with the covr main library):
#   R_LIBS=$bench/lib/4.6.2/covr-main:$bench/lib/4.6.2/deps \
#     /opt/R/4.6.2/bin/Rscript --no-init-file performance-audit/microbench.R \
#     [<trace_file>]
#
# Each timing is the median of 5 runs of a byte-compiled loop of 1e6
# iterations, reported per iteration after subtracting an empty loop.

invisible(suppressPackageStartupMessages(loadNamespace("covr")))
args <- commandArgs(trailingOnly = TRUE)
n <- 1e6

per_iter <- function(f, reps = 5) {
  f <- compiler::cmpfun(f)
  f(10) # warm up
  times <- vapply(
    seq_len(reps),
    function(i) system.time(f(n))[["elapsed"]],
    numeric(1)
  )
  median(times) / n * 1e9 # ns
}

empty <- per_iter(function(n) {
  for (i in seq_len(n)) {
    NULL
  }
})
report <- function(label, f) {
  ns <- per_iter(f) - empty
  cat(sprintf("%-62s %8.0f ns\n", label, ns))
  invisible(ns)
}

cat(sprintf(
  "R %s, empty loop %.0f ns/iteration (subtracted)\n\n",
  getRversion(),
  empty
))

# A counter like the ones trace_calls() creates.
key <- "bench.R:1:1:1:10:1:10:1:1"
counters <- covr:::.counters
counters[[key]] <- list(value = 0)
current_test <- covr:::.current_test
current_test$record <- FALSE

x <- 1
report("cheap base R op: x + 1", function(n) {
  for (i in seq_len(n)) {
    x + 1
  }
})
report("covr:::count(key) (what instrumented code calls)", function(n) {
  for (i in seq_len(n)) {
    covr:::count(key)
  }
})
count_fn <- covr:::count
report("count(key), closure inlined in the call (no `:::`)", function(n) {
  for (i in seq_len(n)) {
    count_fn(key)
  }
})
report("`:::`(covr, count) lookup alone", function(n) {
  for (i in seq_len(n)) {
    covr:::count
  }
})
report(
  ".counters[[key]]$value <- .counters[[key]]$value + 1L alone",
  function(n) {
    for (i in seq_len(n)) {
      counters[[key]]$value <- counters[[key]]$value + 1L
    }
  }
)
report("isTRUE(.current_test$record) alone", function(n) {
  ct <- covr:::.current_test
  for (i in seq_len(n)) {
    isTRUE(ct$record)
  }
})

# Alternatives: a counter environment per trace, and an integer vector.
cnt <- new.env(parent = emptyenv())
cnt$value <- 0L
count_env <- function(e) e$value <- e$value + 1L
report(
  "alt: count_env(e): e$value <- e$value + 1L, inlined closure",
  function(n) {
    for (i in seq_len(n)) {
      count_env(cnt)
    }
  }
)
store <- new.env(parent = emptyenv())
store$counts <- integer(1000)
count_idx <- function(i) store$counts[i] <- store$counts[i] + 1L
report(
  "alt: count_idx(i): integer vector in an env, inlined closure",
  function(n) {
    for (i in seq_len(n)) {
      count_idx(7L)
    }
  }
)
report("alt: inline `e$value <- e$value + 1L` (no call)", function(n) {
  for (i in seq_len(n)) {
    cnt$value <- cnt$value + 1L
  }
})
# The counter environment embedded in the call as a constant, so instrumented
# code needs neither a function call nor a variable lookup.
inline_const <- eval(bquote(function(n) {
  for (i in seq_len(n)) {
    `$<-`(.(cnt), "value", .(cnt)$value + 1L)
  }
}))
report("alt: `$<-`(<env constant>, \"value\", <env>$value + 1L)", inline_const)

# count() without the record_tests check, which could be decided when the code
# is instrumented instead of on every count.
count_no_check <- function(key) {
  .counters[[key]]$value <- .counters[[key]]$value + 1L
}
environment(count_no_check) <- asNamespace("covr")
count_no_check <- compiler::cmpfun(count_no_check)
report(
  "alt: count() without the isTRUE(.current_test$record) check",
  function(n) {
    for (i in seq_len(n)) {
      count_no_check(key)
    }
  }
)

# A C counter: .Call() with the native symbol and the index of the counter in
# a C array, both embedded in the call as constants. The index is a constant
# that is never modified, unlike a count stored in the call itself.
c_file <- tempfile(fileext = ".c")
writeLines(
  c(
    "#include <Rinternals.h>",
    "static int counts[1000];",
    "SEXP covr_bench_count(SEXP i) { counts[INTEGER(i)[0]]++; return R_NilValue; }",
    "SEXP covr_bench_get(SEXP i) { return ScalarInteger(counts[INTEGER(i)[0]]); }"
  ),
  c_file
)
so <- sub("[.]c$", .Platform$dynlib.ext, c_file)
system2(
  file.path(R.home("bin"), "R"),
  c("CMD", "SHLIB", "-o", so, c_file),
  stdout = FALSE,
  stderr = FALSE
)
dll <- dyn.load(so)
sym <- getNativeSymbolInfo("covr_bench_count", dll)$address
inline_c <- eval(bquote(function(n) {
  for (i in seq_len(n)) {
    .Call(.(sym), 7L)
  }
}))
report("alt: .Call(<native symbol>, <index constant>) C counter", inline_c)
cat(sprintf(
  "  (C counter after the runs: %d, expected %d)\n",
  .Call(getNativeSymbolInfo("covr_bench_get", dll), 7L),
  as.integer(5 * n + 10)
))

# Overhead of instrumentation on a realistic function, per evaluated counter.
src <- tempfile(fileext = ".R")
writeLines(
  c(
    "f <- function(x) {",
    "  y <- x * 2",
    "  if (y > 10) {",
    "    y <- y - 1",
    "  }",
    "  y + 1",
    "}"
  ),
  src
)
env <- new.env()
sys.source(src, envir = env, keep.source = TRUE)
f_plain <- env$f
covr:::clear_counters()
f_traced <- covr:::trace_calls(f_plain, "f")
f_traced <- compiler::cmpfun(f_traced)
f_plain <- compiler::cmpfun(f_plain)
t_plain <- report("f(3) uninstrumented (4 statements evaluated)", function(n) {
  for (i in seq_len(n)) {
    f_plain(3)
  }
})
t_traced <- report("f(3) instrumented by trace_calls()", function(n) {
  for (i in seq_len(n)) {
    f_traced(3)
  }
})
covr:::zero_counters()
f_traced(3)
counts <- sum(unlist(eapply(covr:::.counters, function(x) x$value)))
cat(sprintf(
  "  -> %d counts per call, %.0f ns overhead per count (%.1fx slower)\n\n",
  as.integer(counts),
  (t_traced - t_plain) / counts,
  t_traced / t_plain
))

# Trace file serialization.
if (length(args) >= 1) {
  trace <- readRDS(args[[1]])
  cat(sprintf(
    "trace file %s: %d traces, %.1f MB on disk\n",
    basename(args[[1]]),
    length(trace),
    file.size(args[[1]]) / 1e6
  ))
  time <- function(label, expr) {
    expr <- substitute(expr)
    env <- parent.frame()
    t <- median(vapply(
      1:3,
      function(i) system.time(eval(expr, env))[["elapsed"]],
      numeric(1)
    ))
    cat(sprintf("%-62s %8.3f s\n", label, t))
  }
  tmp <- tempfile()
  time(
    "portable_srcfiles() (save_trace's srcfile copy)",
    covr:::portable_srcfiles(trace)
  )
  time("saveRDS() gzip (default)", saveRDS(trace, tmp))
  cat(sprintf("  size %.1f MB\n", file.size(tmp) / 1e6))
  time("saveRDS(compress = FALSE)", saveRDS(trace, tmp, compress = FALSE))
  cat(sprintf("  size %.1f MB\n", file.size(tmp) / 1e6))
  time("readRDS()", readRDS(args[[1]]))
  srcfile_bytes <- length(serialize(trace, NULL))
  counts_only <- lapply(trace, function(x) x$value)
  cat(sprintf(
    "serialized: %.1f MB; counts alone: %.3f MB\n",
    srcfile_bytes / 1e6,
    length(serialize(counts_only, NULL)) / 1e6
  ))
}
