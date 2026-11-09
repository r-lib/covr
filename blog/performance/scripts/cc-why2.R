invisible(loadNamespace("covr"))
n <- 1e6
per_iter <- function(f, reps = 5) {
  f <- compiler::cmpfun(f); f(10)
  median(vapply(seq_len(reps), function(i) system.time(f(n))[["elapsed"]], 0)) / n * 1e9
}
empty <- per_iter(function(n) for (i in seq_len(n)) NULL)
rep <- function(label, f) cat(sprintf("%-62s %5.0f ns\n", label, per_iter(f) - empty))
options(keep.source = TRUE)
fn <- eval(parse(text = "function(x) {\n  x + 1\n}")[[1]])
ptr <- body(covr:::trace_calls(fn, "fn"))[[2]][[3]][[2]][[3]]
sym <- covr:::covr_count
pkgns <- new.env(parent = globalenv()); pkgns$.__covr_count__ <- sym; pkgns$.__addr__ <- sym$address
in_env <- function(e, env) { f <- eval(bquote(function(n) for (i in seq_len(n)) .(e))); environment(f) <- env; f }
rep("embedded NativeSymbolInfo constant", in_env(as.call(list(.Call, sym, ptr)), globalenv()))
rep("NativeSymbolInfo bound in the function's namespace-like env", in_env(as.call(list(.Call, quote(.__covr_count__), ptr)), pkgns))
rep("address (extptr) bound in the namespace-like env", in_env(as.call(list(.Call, quote(.__addr__), ptr)), pkgns))
