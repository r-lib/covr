#define USE_RINTERNALS
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Error.h>
#include <R_ext/Rdynload.h>
#include <Rdefines.h>
#include <stdlib.h>  // for NULL
#include <stdint.h> // for uint64_t

// Mirror the exact structures of SEXPREC from R internals
struct proxy_sxpinfo_struct {
    uint64_t bits;  // guaranteed to be 64 bits
};

struct proxy_closxp_struct {
    struct SEXPREC *formals;
    struct SEXPREC *body;
    struct SEXPREC *env;
};

struct proxy_sexprec {
    struct proxy_sxpinfo_struct sxpinfo;
    struct SEXPREC *attrib;
    struct SEXPREC *gengc_next_node, *gengc_prev_node;
    union {
        struct proxy_closxp_struct closxp;
        // We could add other union members if needed
    } u;
};

typedef struct proxy_sexprec* proxy_sexp;

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
  // Rather than using memcpy() with a hard coded byte offset,
  // we mirror the R internals SEXPREC struct defs here, to hopefully match the alignment
  // behavior of R (e.g., on windows).

  // Duplicate attributes is still not "non-API", thankfully.
  DUPLICATE_ATTRIB(old_fun, new_fun);

  proxy_sexp old = (proxy_sexp) old_fun;
  proxy_sexp new = (proxy_sexp) new_fun;

  struct proxy_closxp_struct tmp = old->u.closxp;
  old->u.closxp = new->u.closxp;
  new->u.closxp = tmp;

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
