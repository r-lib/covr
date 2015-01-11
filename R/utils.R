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

sources <- function(pkg = ".") {
  pkg <- devtools::as.package(pkg)
  srcdir <- file.path(pkg$path, "src")
  dir(srcdir, rex::rex(".", list("c", except_any_of(".")) %or% "f", end), recursive = TRUE, full.names = TRUE)
}

test_directory <- function(path) {
  dir <- file.path(path, "inst", "tests")
  if (!file.exists(dir)) {
    dir <- file.path(path, "tests")
  }
  dir
}

set_makevars <- function(envs) {
  if (length(envs) == 0) {
    return()
  }
  stopifnot(is.named(envs))

  makevars <- file.path("~", ".R", "Makevars")
  old <- NULL
  if (file.exists(makevars)) {
    lines <- readLines(makevars)
    old <- lines
    for (env in names(envs)) {
      loc <- grep(rex::rex(start, any_spaces, env, any_spaces, "="), lines)
      if (length(loc) == 0) {
        lines <- append(lines, paste(sep = "=", env, envs[env]))
      } else if(length(loc) == 1) {
        lines[loc] <- paste(sep = "=", env, envs[env])
      } else {
        stop("Multiple results for ", env, " found, something is wrong.", .call = FALSE)
      }
    }
  } else {
    lines <- paste(names(envs), envs, sep = "=")
  }

  dir.create(file.path("~", ".R"), showWarnings = FALSE, recursive = TRUE)
  writeLines(con = makevars, lines)

  old
}
reset_makevars <- function(lines) {
  makevars <- file.path("~", ".R", "Makevars")

  if (is.null(lines)) {
    unlink(makevars)
  } else {
    writeLines(con = makevars, lines)
  }
}
