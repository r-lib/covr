invisible(loadNamespace("covr"))
n <- 1e6
per_iter <- function(f, reps = 7) {
  f <- compiler::cmpfun(f); f(10)
  median(vapply(seq_len(reps), function(i) system.time(f(n))[["elapsed"]], 0)) / n * 1e9
}
empty <- per_iter(function(n) for (i in seq_len(n)) NULL)
rep <- function(label, f) cat(sprintf("%-58s %5.0f ns\n", label, per_iter(f) - empty))
options(keep.source = TRUE)
fn <- eval(parse(text = "function(x) {\n  x + 1\n}")[[1]])
traced <- covr:::trace_calls(fn, "fn")
call <- body(traced)[[2]][[3]][[2]]
print(call)
mk <- function(e) eval(bquote(function(n) for (i in seq_len(n)) .(e)))
key <- ls(covr:::.counters)[[1]]
rep("covr:::count(key) (R, #733)", function(n) for (i in seq_len(n)) covr:::count(key))
rep("generated call: .Call(covr:::covr_count, <extptr>)", mk(call))
rep(".Call(<NativeSymbolInfo>, <extptr>) (no :::)", mk(as.call(list(.Call, covr:::covr_count, call[[3]]))))
f_plain <- compiler::cmpfun(fn); f_tr <- compiler::cmpfun(traced)
rep("fn(3) uninstrumented", function(n) for (i in seq_len(n)) f_plain(3))
rep("fn(3) instrumented (1 count)", function(n) for (i in seq_len(n)) f_tr(3))
ns <- asNamespace("covr")
rep(".Call(<covr namespace>$covr_count, <extptr>)", mk(as.call(list(.Call, as.call(list(`$`, ns, as.symbol("covr_count"))), call[[3]]))))
rep(".Call(`$`(<ns>, covr_count) w/ symbol `$`, <extptr>)", mk(as.call(list(.Call, call("$", ns, as.symbol("covr_count")), call[[3]]))))
# Does the embedded-namespace form survive serialization to a new process?
g <- eval(as.call(list(as.symbol("function"), NULL, as.call(list(.Call, as.call(list(`$`, ns, as.symbol("covr_count"))), call[[3]])))))
file <- tempfile(fileext = ".rds"); saveRDS(g, file)
out <- system2(file.path(R.home("bin"), "Rscript"), c("--vanilla", "-e", shQuote(sprintf(
  "g <- readRDS('%s'); r <- tryCatch({g(); 'ok'}, error = function(e) conditionMessage(e)); cat('new process:', r, '| covr loaded:', 'covr' %%in%% loadedNamespaces(), '\\n')", file))),
  stdout = TRUE, stderr = TRUE, env = paste0("R_LIBS=", Sys.getenv("R_LIBS")))
cat(out, sep = "\n")
