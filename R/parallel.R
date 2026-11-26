# utility function to replace a symbol in a locked loaded package/namespace
replace_binding <- function(package, name, value) {
  ns <- getNamespace(package)
  unlock <- get('unlockBinding') # to fool r CMD check
  lock <- get('lockBinding')
  unlock(name, ns)
  assign(name, value, ns)
  lock(name, ns)
}


# Patch parallel's mcexit() so forked workers, which exit without running
# finalizers, save the traces of all the instrumented packages loaded in the
# process (see `register_trace()`) and clear their pending markers, and
# mcfork() so each worker zeroes the counts it inherits, which the parent
# saves. The functions are patched once, by the first instrumented package
# that needs it, so a package's code that runs in the workers of another
# package is saved too. An error, e.g. if the trace directory was removed after
# the package was restored, would keep the worker from exiting. `trace_dir`
# and `scope` are those of the package, which registers them when it is
# loaded.
fix_mcexit <- function(trace_dir, scope) {
  ns <- asNamespace("parallel")
  if (isTRUE(attr(ns$mcexit, "covr_fix"))) {
    return(invisible())
  }
  mcfork <- ns$mcfork
  mcexit <- ns$mcexit
  replace_binding("parallel", "mcfork", function(...) {
    process <- mcfork(...)
    if (inherits(process, "masterProcess")) {
      zero_counters()
    }
    process
  })
  patched <- function(...) {
    try(save_registered_traces(), silent = TRUE)
    mcexit(...)
  }
  attr(patched, "covr_fix") <- TRUE
  replace_binding("parallel", "mcexit", patched)
  invisible()
}

# Patch parallel's mcfork() and mcexit() in the current session, so processes
# forked by mclapply(), mcparallel() etc. save their counts to `trace_dir` when
# they exit. Each child zeroes its counts after forking, so the counts the
# parent had at that point are not counted twice. Returns a function that
# restores the original functions. The children save the traces of `scope`.
trace_forks <- function(trace_dir, scope) {
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
    try(save_trace_and_clear(trace_dir, scope), silent = TRUE)
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
