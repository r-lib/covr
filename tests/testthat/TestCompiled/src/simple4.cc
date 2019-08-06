#define USE_RINTERNALS
#include <R.h>
#include <Rdefines.h>
#include <R_ext/Error.h>
#include "simple-header.h"

extern "C" SEXP simple4_(SEXP x) {
  return simple2_<int, INTSXP>(x);
}
