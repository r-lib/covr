#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

int rust_sign(int x);

SEXP sign_wrapper(SEXP x) {
  return Rf_ScalarInteger(rust_sign(Rf_asInteger(x)));
}

static const R_CallMethodDef CallEntries[] = {
  {"sign_wrapper", (DL_FUNC) &sign_wrapper, 1},
  {NULL, NULL, 0}
};

void R_init_TestRust(DllInfo *dll) {
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
