invisible(loadNamespace("covr"))
n <- 1e6
per_iter <- function(f, reps = 7) {
  f <- compiler::cmpfun(f); f(10)
  median(vapply(seq_len(reps), function(i) system.time(f(n))[["elapsed"]], 0)) / n * 1e9
}
empty <- per_iter(function(n) for (i in seq_len(n)) NULL)
rep <- function(label, f) cat(sprintf("%-60s %5.0f ns\n", label, per_iter(f) - empty))
options(keep.source = TRUE)
fn <- eval(parse(text = "function(x) {\n  x + 1\n}")[[1]])
ptr <- body(covr:::trace_calls(fn, "fn"))[[2]][[3]][[2]][[3]]
# A namespace-like environment holding the routine, like an instrumented package's namespace
pkgns <- new.env(parent = globalenv())
pkgns$.__covr_count__ <- covr:::covr_count
mkin <- function(e, env) { f <- eval(bquote(function(n) for (i in seq_len(n)) .(e))); environment(f) <- env; f }
rep("covr:::covr_count lookup (#734 now)", mkin(as.call(list(.Call, quote(covr:::covr_count), ptr)), globalenv()))
rep("namespace binding, function defined in the namespace", mkin(as.call(list(.Call, quote(.__covr_count__), ptr)), pkgns))
inner <- new.env(parent = new.env(parent = pkgns)) # a closure two levels below the namespace
rep("namespace binding, closure two environments down", mkin(as.call(list(.Call, quote(.__covr_count__), ptr)), inner))
rep("routine object embedded (no lookup)", mkin(as.call(list(.Call, covr:::covr_count, ptr)), globalenv()))
