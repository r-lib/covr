.onLoad <- function(libname, pkgname) {
  log <- Sys.getenv("TESTINSTRUMENT_LOG")
  if (nzchar(log)) {
    cat(Sys.getpid(), "\n", file = log, append = TRUE)
  }
  assign("made", make_made(), envir = asNamespace(pkgname))
}

f <- function(x) {
  if (x > 0) {
    "positive"
  } else {
    "other"
  }
}

is_compiled <- function(fun) {
  is.function(fun) && typeof(.Internal(bodyCode(fun))) == "bytecode"
}

g <- function(n) {
  while (n > 0) {
    n <- n - 1
  }
  if (n == 0) "zero" else "other"
}

make_made <- function() {
  eval(parse(text = "function(x) {\n  x + 1\n}", keep.source = TRUE)[[1L]])
}
