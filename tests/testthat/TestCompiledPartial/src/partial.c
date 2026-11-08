#include <R.h>
#include <Rinternals.h>

SEXP partial_(SEXP verbose) {
  if (asLogical(verbose)) Rprintf("reached\n");
  return R_NilValue;
}
