#ifndef _WIN32
#define _GNU_SOURCE // for RTLD_DEFAULT
#include <dlfcn.h>
#endif

#include <R.h>
#include <Rinternals.h>

// Writes the gcov counts of the process, if it runs R that was built with
// `--coverage` (see `instrument_base_r()`). Processes forked by parallel exit
// with `_exit()`, which skips the exit handler that writes them. gcov's
// `__gcov_dump()` writes the counts of the executable and of every shared
// object built with `--coverage`. covr itself isn't, so it is looked up with
// `dlsym()` in the process, where R exports it from its executable or libR.
// Returns whether it was found.
SEXP covr_gcov_dump(void) {
#ifdef _WIN32
  return ScalarLogical(FALSE);
#else
  void (*dump)(void);
  *(void **)(&dump) = dlsym(RTLD_DEFAULT, "__gcov_dump");
  if (dump == NULL) {
    return ScalarLogical(FALSE);
  }
  dump();
  return ScalarLogical(TRUE);
#endif
}
