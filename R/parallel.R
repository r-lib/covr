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


# patch parallel:::mcexit to force it to save the covr trace on exit
fix_mcexit <- function(lib) {
  get_from_ns <- `:::` # trick to fool R CMD check
  mcexit <- get_from_ns('parallel', 'mcexit')

  # directly pach mcexit
  body(mcexit) <- as.call(append(after = 1, as.list(body(mcexit)),
      bquote(covr:::save_trace(.(lib)))))

  replace_binding('parallel', 'mcexit', mcexit)
}



