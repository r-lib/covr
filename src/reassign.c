#define USE_RINTERNALS
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Error.h>
#include <R_ext/Rdynload.h>
#include <Rdefines.h>
#include <stdlib.h>  // for NULL

SEXP covr_reassign_function(SEXP old_fun, SEXP new_fun) {
  if (TYPEOF(old_fun) != CLOSXP) error("old_fun must be a function");
  if (TYPEOF(new_fun) != CLOSXP) error("new_fun must be a function");

  // The goal is to modify `old_fun` in place, so that all existing references
  // to `old_fun` call the tracing `new_fun` instead.
  // This used to be simply:
  //   SET_FORMALS(old_fun, FORMALS(new_fun));
  //   SET_BODY(old_fun, BODY(new_fun));
  //   SET_CLOENV(old_fun, CLOENV(new_fun));
  // But those functions are now "non-API". So we comply with the letter of the law and
  // swap the fields manually, making some hard assumptions about the underling memory
  // layout in the process. See also: "The Cobra Effect" (https://en.wikipedia.org/wiki/Cobra_effect).

  // Offset and size for closure-specific data within SEXPREC
  const size_t closure_data_offset = 32;  // 8 bytes (sxpinfo) + 24 bytes (3 pointers for attrib, gengc_next_node, gengc_prev_node)
  const size_t closure_data_size = 24;    // 3 pointers for formals, body, env (3 * 8 bytes)

  // Duplicate attributes is still not "non-API", thankfully.
  DUPLICATE_ATTRIB(old_fun, new_fun);

  // Temporary buffer to hold CLOSXP data (the 3 pointers to formals, body, env)
  char temp[closure_data_size];

  memcpy(temp, (char *)old_fun + closure_data_offset, closure_data_size);
  memcpy((char *)old_fun + closure_data_offset, (char *)new_fun + closure_data_offset, closure_data_size);
  memcpy((char *)new_fun + closure_data_offset, temp, closure_data_size);

  return R_NilValue;
}

SEXP covr_duplicate_(SEXP x) { return duplicate(x); }

/* .Call calls */
extern SEXP covr_duplicate_(SEXP);
extern SEXP covr_reassign_function(SEXP, SEXP);

static const R_CallMethodDef CallEntries[] = {
    {"covr_duplicate_", (DL_FUNC)&covr_duplicate_, 1},
    {"covr_reassign_function", (DL_FUNC)&covr_reassign_function, 2},
    {NULL, NULL, 0}};

void R_init_covr(DllInfo *dll) {
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
