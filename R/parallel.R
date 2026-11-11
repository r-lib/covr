# utility function to replace a symbol in a locked loaded package/namespace
replace_binding <- function(package, name, value) {
  ns <- getNamespace(package)
  unlock <- get('unlockBinding') # to fool r CMD check
  lock <- get('lockBinding')
  unlock(name, ns)
  assign(name, value, ns)
  lock(name, ns)
}


# patch parallel:::mcexit to force it to save the covr trace on exit, and to
# clear the pending marker of the worker, since it doesn't run finalizers
fix_mcexit <- function(trace_dir) {
  get_from_ns <- `:::` # trick to fool R CMD check
  mcexit <- get_from_ns('parallel', 'mcexit')

  trace_dir <- parse(text = trace_dir)[[1]]

  # directly patch mcexit
  body(mcexit) <- as.call(append(
    after = 1,
    as.list(body(mcexit)),
    as.call(list(
      call(":::", as.symbol("covr"), as.symbol("save_trace_and_clear")),
      trace_dir
    ))
  ))

  replace_binding('parallel', 'mcexit', mcexit)
}

# Patch parallel's mcfork() and mcexit() in the current session, so processes
# forked by mclapply(), mcparallel() etc. save their counts to `trace_dir` when
# they exit. Each child zeroes its counts after forking, so the counts the
# parent had at that point are not counted twice. Returns a function that
# restores the original functions.
trace_forks <- function(trace_dir) {
  ns <- asNamespace("parallel")
  mcfork <- ns$mcfork
  mcexit <- ns$mcexit

  replace_binding("parallel", "mcfork", function(...) {
    process <- mcfork(...)
    if (inherits(process, "masterProcess")) {
      zero_counters()
    }
    process
  })
  replace_binding("parallel", "mcexit", function(...) {
    # An error here would keep the child from exiting, e.g. if it outlives
    # `trace_dir`. Forked children don't run finalizers, so this also removes
    # the pending marker of a child that registered its own trace (#277).
    try(save_trace_and_clear(trace_dir), silent = TRUE)
    mcexit(...)
  })

  function() {
    replace_binding("parallel", "mcfork", mcfork)
    replace_binding("parallel", "mcexit", mcexit)
  }
}

uses_parallel <- function(pkg) {
  any(grepl(
    "\\bparallel\\b",
    pkg[c("depends", "imports", "suggests", "enhances", "linkingto")]
  ))
}


# consider in that order: the option covr.fix_parallel_mcexit, the environment
# variable COVR_FIX_PARALLEL_MCEXIT, or auto-detection of the usage of
# parallel by the package (cf uses_parallel()). Without a package, i.e. for
# coverage measured in the current session, it is enabled by default.
should_enable_parallel_mcexit_fix <- function(pkg = NULL) {
  !is_windows() &&
    logical_setting(
      "covr.fix_parallel_mcexit",
      "COVR_FIX_PARALLEL_MCEXIT",
      default = is.null(pkg) || uses_parallel(pkg)
    )
}
