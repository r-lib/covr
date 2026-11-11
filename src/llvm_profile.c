#include <R.h>
#include <Rinternals.h>

#ifndef _WIN32
#include <dlfcn.h>
#ifndef RTLD_NOLOAD
#define RTLD_NOLOAD 0
#endif
#endif

// Writes the counts of the Rust code in the loaded DLL at `path`, by calling
// the `covr_llvm_profile_write()` that covr links into the DLLs it builds (see
// `add_llvm_profile_writer()`). This is looked up with `dlsym()`, as R doesn't
// look up the symbols of DLLs that turn off dynamic lookup, as most do.
// Returns whether the counts were written.
SEXP covr_write_llvm_profile(SEXP path) {
#ifdef _WIN32
  return ScalarLogical(FALSE);
#else
  void *handle = dlopen(CHAR(STRING_ELT(path, 0)), RTLD_LAZY | RTLD_NOLOAD);
  if (handle == NULL) {
    return ScalarLogical(FALSE);
  }
  int (*write_profile)(void);
  *(void **)(&write_profile) = dlsym(handle, "covr_llvm_profile_write");
  int written = write_profile != NULL && write_profile() == 0;
  dlclose(handle);
  return ScalarLogical(written);
#endif
}
