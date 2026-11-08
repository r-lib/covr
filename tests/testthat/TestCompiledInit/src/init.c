#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

SEXP C_sign_of(SEXP x) {
  if (asReal(x) < 0) {
    return ScalarInteger(-1);
  }
  return ScalarInteger(1);
}

static const R_CallMethodDef callMethods[] = {
  {"C_sign_of", (DL_FUNC) &C_sign_of, 1},
  {NULL, NULL, 0}
};

void R_init_TestCompiledInit(DllInfo *dll) {
  R_registerRoutines(dll, NULL, callMethods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  /* Like Rcpp's `.rcpp_cache`, which is assigned whenever the DLL is loaded */
  SEXP ns = PROTECT(R_FindNamespace(mkString("TestCompiledInit")));
  defineVar(install(".loaded"), ScalarLogical(TRUE), ns);
  UNPROTECT(1);
}
