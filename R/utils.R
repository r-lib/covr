`%||%` <- function(x, y) {
  if (!is.null(x)) {
    x
  } else {
    y
  }
}

dots <- function(...) {
  eval(substitute(alist(...)))
}

test_directory <- function(path) {
  dir <- file.path(path, "inst", "tests")
  if (!file.exists(dir)) {
    dir <- file.path(path, "tests")
  }
  dir
}

