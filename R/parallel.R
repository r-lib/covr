# utility function to replace a symbol in a locked loaded package/namespace
replace_binding <- function(package, name, value) {
  ns <- getNamespace(package)
  unlock <- get('unlockBinding') # to fool r CMD check
  lock <-  get('lockBinding')
  unlock(name, ns)
  assign(name, value, ns)
  lock(name, ns)
}


add_parallel_mcexit_fix_to_package_startup <- function(pkg_name, lib) {
  load_script <- file.path(lib, pkg_name, "R", pkg_name)
  lines <- readLines(file.path(lib, pkg_name, "R", pkg_name))
  lines <- append(lines,
    c('##### added by covr:::add_parallel_mcexit_fix_to_package_startup ###\n',
    sprintf("cat('fixing mcexit\n');covr:::fix_mcexit('%s')", lib)))

  writeLines(text = lines, con = load_script)
}


fix_mcexit <- function(lib) {
  library(parallel)

  # try to detect if already fixed
  f <- parallel:::mcexit
  if (exists('original_mcexit', envir = environment(f))) return(invisible(FALSE))

  ## available from the fixed_mcexit closure
  original_mcexit <- f

  # make parallel:::mcexit compatible with covr
  fixed_mcexit <- function(...) {
    cat('saving trace in "', lib, '"\n')
    covr:::save_trace(lib)
    original_mcexit(...)
  }

  covr:::replace_binding('parallel', 'mcexit', fixed_mcexit)

  invisible(TRUE)
}



