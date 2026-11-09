#include <R.h>
#include <Rinternals.h>
#include <stdlib.h>

/* The counts of the traces live in blocks that are never moved or freed, so
 * instrumented code can hold an external pointer to its count and
 * `covr_count()` only has to increment it. A key keeps its count for the life
 * of the process, also after `clear_counters()`, so an instrumented function
 * always counts into its own trace. External pointers are NULL after they are
 * unserialized, so a function sent to another process doesn't count there,
 * rather than counting into another trace. */
#define BLOCK_SIZE 4096

static double **blocks = NULL;
static int n_blocks = 0;
static int n_keys = 0;
static SEXP keys = NULL; // a preserved STRSXP, for reading the counts back

static double *count_at(int i) {
  return &blocks[i / BLOCK_SIZE][i % BLOCK_SIZE];
}

// Add a count for `key` and return an external pointer to it.
// `register_count()` in R makes sure each key is only added once.
SEXP covr_counter_add(SEXP key) {
  if (n_keys == n_blocks * BLOCK_SIZE) {
    double **new_blocks =
        (double **)realloc(blocks, (size_t)(n_blocks + 1) * sizeof(double *));
    if (new_blocks == NULL) {
      Rf_error("can't allocate memory for the counts");
    }
    blocks = new_blocks;
    blocks[n_blocks] = (double *)calloc(BLOCK_SIZE, sizeof(double));
    if (blocks[n_blocks] == NULL) {
      Rf_error("can't allocate memory for the counts");
    }
    SEXP new_keys = PROTECT(Rf_allocVector(STRSXP, (n_blocks + 1) * BLOCK_SIZE));
    for (int i = 0; i < n_keys; ++i) {
      SET_STRING_ELT(new_keys, i, STRING_ELT(keys, i));
    }
    R_PreserveObject(new_keys);
    if (keys != NULL) {
      R_ReleaseObject(keys);
    }
    keys = new_keys;
    UNPROTECT(1);
    ++n_blocks;
  }
  SET_STRING_ELT(keys, n_keys, STRING_ELT(key, 0));
  double *count = count_at(n_keys++);
  *count = 0;
  return R_MakeExternalPtr(count, R_NilValue, R_NilValue);
}

// Called by instrumented code for every evaluated expression.
SEXP covr_count(SEXP ptr) {
  double *count = (double *)R_ExternalPtrAddr(ptr);
  if (count != NULL) {
    (*count)++;
  }
  return R_NilValue;
}

// A named numeric vector of the non-zero counts (named by key), which are reset.
SEXP covr_counter_take(void) {
  int n = 0;
  for (int i = 0; i < n_keys; ++i) {
    if (*count_at(i) != 0) {
      ++n;
    }
  }
  SEXP res = PROTECT(Rf_allocVector(REALSXP, n));
  SEXP nms = PROTECT(Rf_allocVector(STRSXP, n));
  for (int i = 0, j = 0; i < n_keys; ++i) {
    double *count = count_at(i);
    if (*count != 0) {
      REAL(res)[j] = *count;
      SET_STRING_ELT(nms, j, STRING_ELT(keys, i));
      *count = 0;
      ++j;
    }
  }
  Rf_setAttrib(res, R_NamesSymbol, nms);
  UNPROTECT(2);
  return res;
}

// Discard the counts, keeping the keys and their counts' addresses.
SEXP covr_counter_reset(void) {
  for (int i = 0; i < n_keys; ++i) {
    *count_at(i) = 0;
  }
  return R_NilValue;
}
