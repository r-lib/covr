# utility function to replace a symbol in a locked loaded package/namespace
replace_binding <- function(package, name, value) {
  ns <- getNamespace(package)
  unlock <- get('unlockBinding') # to fool r CMD check
  lock <-  get('lockBinding')
  unlock(name, ns)
  assign(name, value, ns)
  lock(name, ns)
}


# patch parallel:::mcexit to force it to save the covr trace on exit
fix_mcexit <- function(lib) {
  get_from_ns <- `:::` # trick to fool R CMD check
  mcexit <- get_from_ns('parallel', 'mcexit')

  # directly pach mcexit
  body(mcexit) <- as.call(append(after = 1, as.list(body(mcexit)),
      as.call(list(call(":::", as.symbol("covr"), as.symbol("save_trace")), lib))))

  replace_binding('parallel', 'mcexit', mcexit)
}


uses_parallel <- function(pkg) {
  any(grepl("\\bparallel\\b",
      pkg[c("depends", "imports", "suggests", "enhances", "linkingto")]))
}

on_windows <- function() {
  "windows" %in% tolower(Sys.info()[["sysname"]])
}

# consider in that order: the environment variable COVR_FIX_PARALLEL_MCEXIT,
# the option covr.fix_parallel_mcexit, or auto-detection of the usage of
# parallel by the package (cf uses_parallel()).
should_enable_parallel_mcexit_fix <- function(pkg) {
  isTRUE(!on_windows() &&
    as.logical(Sys.getenv("COVR_FIX_PARALLEL_MCEXIT",
      getOption("covr.fix_parallel_mcexit",
        uses_parallel(pkg)))))
}
