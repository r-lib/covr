invisible(loadNamespace("covr"))
n <- 1e6
per_iter <- function(f, reps = 5) {
  f <- compiler::cmpfun(f)
  f(10)
  median(vapply(seq_len(reps), function(i) system.time(f(n))[["elapsed"]], 0)) / n * 1e9
}
empty <- per_iter(function(n) for (i in seq_len(n)) NULL)
rep <- function(label, f) cat(sprintf("%-60s %6.0f ns\n", label, per_iter(f) - empty))

c_file <- tempfile(fileext = ".c")
writeLines(c(
  "#include <Rinternals.h>",
  "static double counts[1000];",
  "SEXP bench_count(SEXP i) { int j = INTEGER(i)[0]; if (j >= 0 && j < 1000) counts[j]++; return R_NilValue; }"
), c_file)
so <- sub("[.]c$", .Platform$dynlib.ext, c_file)
system2(file.path(R.home("bin"), "R"), c("CMD", "SHLIB", "-o", so, c_file), stdout = FALSE, stderr = FALSE)
dll <- dyn.load(so)
info <- getNativeSymbolInfo("bench_count", dll)
ns <- new.env()
ns$C_count <- info
# A locked environment stands in for covr's namespace, looked up with `$`
# (`:::` measured separately at ~58 ns in the audit).
lockEnvironment(ns, TRUE)

rep("covr:::count(key) (merged PR, no isTRUE)", function(n) {
  key <- "x"
  for (i in seq_len(n)) covr:::count(key)
})
rep(".Call(<extptr constant>, 7L)", eval(bquote(function(n) for (i in seq_len(n)) .Call(.(info$address), 7L))))
rep(".Call(<NativeSymbolInfo constant>, 7L)", eval(bquote(function(n) for (i in seq_len(n)) .Call(.(info), 7L))))
rep(".Call(ns$C_count, 7L) (lookup each call)", function(n) for (i in seq_len(n)) .Call(ns$C_count, 7L))
rep("covr:::count lookup alone", function(n) for (i in seq_len(n)) covr:::count)
rep(".Call(\"bench_count\", 7L, PACKAGE = <dll>)", eval(bquote(function(n) for (i in seq_len(n)) .Call("bench_count", 7L, PACKAGE = .(basename(sub("[.]so$", "", so)))))))

# The wrapper trace_calls() puts around every expression, without any count.
x <- 1
rep("x + 1", function(n) for (i in seq_len(n)) x + 1)
rep("if (TRUE) { NULL; x + 1 }", function(n) for (i in seq_len(n)) if (TRUE) { NULL; x + 1 })
rep("base::.Call(<NativeSymbolInfo constant>, 7L)", eval(bquote(function(n) for (i in seq_len(n)) base::.Call(.(info), 7L))))
rep("<.Call primitive>(<NativeSymbolInfo constant>, 7L)", eval(as.call(list(as.symbol("function"), as.pairlist(alist(n = )), bquote(for (i in seq_len(n)) .(as.call(list(.Call, info, 7L))))))))
rep("base::.Call(ns$C_count, 7L)", function(n) for (i in seq_len(n)) base::.Call(ns$C_count, 7L))
