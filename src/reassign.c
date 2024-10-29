#define USE_RINTERNALS
#include <R.h>
#include <R_ext/Error.h>
#include <R_ext/Rdynload.h>
#include <Rdefines.h>
#include <stdlib.h>  // for NULL

SEXP covr_reassign_function(SEXP name, SEXP /* unused */ env, SEXP old_fun, SEXP new_fun) {
  if (TYPEOF(name) != SYMSXP) error("name must be a symbol");
  if (TYPEOF(old_fun) != CLOSXP) error("old_fun must be a function");
  if (TYPEOF(new_fun) != CLOSXP) error("new_fun must be a function");

  SET_FORMALS(old_fun, FORMALS(new_fun));
  SET_BODY(old_fun, BODY(new_fun));
  SET_CLOENV(old_fun, CLOENV(new_fun));
  DUPLICATE_ATTRIB(old_fun, new_fun);

  return R_NilValue;
}

SEXP covr_duplicate_(SEXP x) { return duplicate(x); }

/* .Call calls */
extern SEXP covr_duplicate_(SEXP);
extern SEXP covr_reassign_function(SEXP, SEXP, SEXP, SEXP);

static const R_CallMethodDef CallEntries[] = {
    {"covr_duplicate_", (DL_FUNC)&covr_duplicate_, 1},
    {"covr_reassign_function", (DL_FUNC)&covr_reassign_function, 4},
    {NULL, NULL, 0}};

void R_init_covr(DllInfo *dll) {
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
