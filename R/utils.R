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

trim <- function(x) {
  rex::re_substitutes(x, rex::rex(list(start,spaces) %or% list(spaces, end)),  "")
}

local_branch <- function() {
  suppressWarnings(
    branch <- system2("git", "rev-parse --abbrev-ref HEAD", stderr = TRUE, stdout = TRUE)
  )
  if (!is.null(attr(branch, "status"))) {
    stop(branch, call. = FALSE)
  }
  trim(branch)
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

source_dir <- function(path, pattern = rex::rex(".", one_of("R", "r"), end), env,
                       chdir = TRUE, quiet = FALSE) {
  files <- normalizePath(list.files(path, pattern, full.names = TRUE))
  lapply(files, source_from_dir, path = path, env = env, chdir = chdir, quiet = quiet)
}

source_from_dir <- function(file, path, env, chdir = TRUE, quiet = FALSE) {
  if (chdir) {
    old <- setwd(path)
    on.exit(setwd(old))
  }
  if (isTRUE(quiet)) {
    capture.output(sys.source(file, env))
    invisible()
  } else {
    sys.source(file, env)
  }
}

example_code <- function(file) {
  parsed_rd <- tools::parse_Rd(file)

  example_locs <- vapply(parsed_rd,
    function(x) attr(x, "Rd_tag") == "\\examples",
    logical(1)
  )

  unlist(parsed_rd[example_locs])
}

duplicate <- function(x) {
  .Call(duplicate_, x)
}

to_title <- function(x) {
  rex::re_substitutes(x,
                      rex::rex(boundary, capture(any)),
                      "\\U\\1",
                      global = TRUE)
}
