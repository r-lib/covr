# Instrument the functions in `branches/instrumentation.R` with
# `trace_calls()`, returning their bodies without srcrefs, so they can be
# saved and compared with `identical()`.
traced_fixture_bodies <- function(
  path = test_path("branches/instrumentation.R")
) {
  lines <- readLines(path)
  srcfile <- srcfilecopy("instrumentation.R", lines)
  exprs <- parse(text = lines, keep.source = TRUE, srcfile = srcfile)
  env <- new.env()
  for (expr in exprs) {
    eval(expr, env)
  }
  on.exit(clear_counters())
  names <- sort(ls(env))
  bodies <- lapply(names, function(name) body(trace_calls(env[[name]], name)))
  setNames(lapply(bodies, function(x) as_r_count(strip_srcrefs(x))), names)
}

# Rewrite `base::.Call(pkg:::covr_count, key)` as `pkg:::count(key)`, the form
# instrumentation had before counting moved to C.
as_r_count <- function(x) {
  if (!is.call(x)) {
    return(x)
  }
  if (
    identical(x[[1]], call("::", as.symbol("base"), as.symbol(".Call"))) &&
      is.call(x[[2]]) &&
      identical(x[[2]][[1]], as.symbol(":::")) &&
      identical(x[[2]][[3]], as.symbol("covr_count"))
  ) {
    return(as.call(list(call(":::", x[[2]][[2]], as.symbol("count")), x[[3]])))
  }
  for (i in seq_along(x)) {
    if (!identical(x[[i]], quote(expr = ))) {
      x[i] <- list(as_r_count(x[[i]]))
    }
  }
  x
}

strip_srcrefs <- function(x) {
  if (inherits(x, "srcref")) {
    return(NULL)
  }
  if (is.call(x)) {
    attributes(x) <- NULL
    for (i in seq_along(x)) {
      if (!identical(x[[i]], quote(expr = ))) {
        x[i] <- list(strip_srcrefs(x[[i]]))
      }
    }
  }
  x
}

# Replace the namespace of each `pkg:::fun` call in `x` with `pkg`, e.g. to
# compare instrumentation from covr with that of this package, which has
# another name when covr measures its own coverage.
set_namespace <- function(x, pkg) {
  if (is.call(x)) {
    if (identical(x[[1]], as.symbol(":::"))) {
      x[[2]] <- as.symbol(pkg)
    }
    for (i in seq_along(x)) {
      if (!identical(x[[i]], quote(expr = ))) {
        x[i] <- list(set_namespace(x[[i]], pkg))
      }
    }
  }
  x
}

# Source `lines` into a new environment with the parse data that covr needs
# to instrument the branches of `if` and `switch()`. Its parent is the global
# environment, so on R < 4.2.0 R CMD check doesn't treat the code as covr's,
# whose conditions of length > 1 abort with `_R_CHECK_LENGTH_1_CONDITION_`.
local_branch_env <- function(lines, frame = parent.frame()) {
  path <- local_r_file(lines, frame = frame)
  env <- new.env(parent = globalenv())
  withr::with_options(
    c(keep.parse.data.pkgs = TRUE),
    sys.source(path, envir = env, keep.source = TRUE)
  )
  env
}

branch_coverage <- function(source_code, test_code) {
  withr::with_options(
    list(covr.branch_coverage = TRUE),
    code_coverage(paste(source_code, collapse = "\n"), test_code)
  )
}
