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

# this is a unexported function from devtools
set_envvar <- function (envs, action = "replace") {
  if (length(envs) == 0) {
    return()
  }
  stopifnot(is.named(envs))
  stopifnot(is.character(action), length(action) == 1)
  action <- match.arg(action, c("replace", "prefix", "suffix"))
  old <- Sys.getenv(names(envs), names = TRUE, unset = NA)
  set <- !is.na(envs)
  both_set <- set & !is.na(old)
  if (any(both_set)) {
    if (action == "prefix") {
      envs[both_set] <- paste(envs[both_set], old[both_set])
    }
    else if (action == "suffix") {
      envs[both_set] <- paste(old[both_set], envs[both_set])
    }
  }
  if (any(set))
    do.call("Sys.setenv", as.list(envs[set]))
  if (any(!set))
    Sys.unsetenv(names(envs)[!set])
  invisible(old)
}

is.named <- function (x) {
  !is.null(names(x)) && all(names(x) != "")
}

test_directory <- function(path) {
  if(file.exists(file.path(path, "tests"))) {
    file.path(path, "tests")
  } else if (file.exists(file.path(path, "inst", "tests"))) {
    file.path(path, "inst", "tests")
  } else {
    stop("No testing directory found", .call = FALSE)
  }
}

`[.coverage` <- function(x, i, ...) {
  attrs <- attributes(x)
  attrs$names <- attrs$names[i]
  res <- unclass(x)
  res <- res[i]
  attributes(res) <- attrs
  res
}
