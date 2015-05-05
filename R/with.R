#' Execute code in temporarily altered environment.
#'
#' \itemize{
#'   \item \code{in_dir}: working directory
#'   \item \code{with_collate}: collation order
#'   \item \code{with_envvar}: environmental variables
#'   \item \code{with_libpaths}: library paths, replacing current libpaths
#'   \item \code{with_lib}: library paths, prepending to current libpaths
#'   \item \code{with_locale}: any locale setting
#'   \item \code{with_options}: options
#'   \item \code{with_path}: PATH environment variable
#'   \item \code{with_par}: graphics parameters
#' }
#'
#' @param new values for setting
#' @param code code to execute in that environment
#'
#' @name with_something
NULL

with_something <- function(set) {
  fun <- substitute(set)
  # this deparse/parse silliness is really the simplest way to ensure the
  # returned functions srcref will show the new value of set
  eval(parse(
      text = deparse(
        substitute(
          function(new, code) {
            old <- set(new)
            on.exit(set(old))
            force(code)
          },
          list(set = fun))
        )))
}
is.named <- function(x) {
  !is.null(names(x)) && all(names(x) != "")
}

# env ------------------------------------------------------------------------

set_envvar <- function(envs, action = "replace") {
  if (length(envs) == 0) return()

  stopifnot(is.named(envs))
  stopifnot(is.character(action), length(action) == 1)
  action <- match.arg(action, c("replace", "prefix", "suffix"))

  # if there are duplicated entries keep only the last one
  envs <- envs[!duplicated(names(envs), fromLast = TRUE)]

  old <- Sys.getenv(names(envs), names = TRUE, unset = NA)
  set <- !is.na(envs)

  both_set <- set & !is.na(old)
  if (any(both_set)) {
    if (action == "prefix") {
      envs[both_set] <- paste(envs[both_set], old[both_set])
    } else if (action == "suffix") {
      envs[both_set] <- paste(old[both_set], envs[both_set])
    }
  }

  if (any(set))  do.call("Sys.setenv", as.list(envs[set]))
  if (any(!set)) Sys.unsetenv(names(envs)[!set])

  invisible(old)
}
#' @rdname with_something
#' @param action (for \code{with_envvar} only): should new values
#'    \code{"replace"}, \code{"suffix"}, \code{"prefix"} existing environmental
#'    variables with the same name.
#' @details if \code{NA} is used as a value with \code{with_envvar} those
#' environment variables will be unset.  If there are any duplicated variable
#' names only the last one is used.
with_envvar <- function(new, code, action = "replace") {
  old <- set_envvar(new, action)
  on.exit(set_envvar(old, "replace"))
  force(code)
}

# locale ---------------------------------------------------------------------

set_locale <- function(cats) {
  stopifnot(is.named(cats), is.character(cats))

  old <- vapply(names(cats), Sys.getlocale, character(1))

  mapply(Sys.setlocale, names(cats), cats)
  invisible(old)
}

#' @rdname with_something
with_locale <- with_something(set_locale)

# collate --------------------------------------------------------------------

set_collate <- function(locale) set_locale(c(LC_COLLATE = locale))[[1]]
#' @rdname with_something
with_collate <- with_something(set_collate)

# working directory ----------------------------------------------------------

#' @rdname with_something
in_dir <- with_something(setwd)

# libpaths -------------------------------------------------------------------

set_libpaths <- function(paths) {
  libpath <- normalizePath(paths, mustWork = TRUE)

  old <- .libPaths() # nolint
  .libPaths(libpath) # nolint
  invisible(old)
}

#' @rdname with_something
with_libpaths <- with_something(set_libpaths)

# lib ------------------------------------------------------------------------

set_lib <- function(paths) {
  libpath <- normalizePath(paths, mustWork = TRUE)

  old <- .libPaths() # nolint
  .libPaths(c(libpath, .libPaths())) # nolint
  invisible(old)
}

#' @rdname with_something
with_lib <- with_something(set_lib)

# options --------------------------------------------------------------------

set_options <- function(new_options) {
  do.call(options, as.list(new_options))
}

#' @rdname with_something
with_options <- with_something(set_options)

# par ------------------------------------------------------------------------

#' @rdname with_something
with_par <- with_something(par)

# path -----------------------------------------------------------------------

#' @rdname with_something
#' @param add Combine with existing values? Currently for
#'   \code{\link{with_path}} only. If \code{FALSE} all existing
#'   paths are overwritten, which don't you usually want.
with_path <- function(new, code, add = TRUE) {
  if (add) new <- c(get_path(), new)
  old <- set_path(new)
  on.exit(set_path(old))
  force(code)
}

set_makevars <- function(variables,
                         old_path = file.path("~", ".R", "Makevars"),
                         new_path = tempfile()) {
  if (length(variables) == 0) {
    return()
  }
  stopifnot(is.named(variables))

  old <- NULL
  if (file.exists(old_path)) {
    lines <- readLines(old_path)
    old <- lines
    for (var in names(variables)) {
      loc <- grep(paste(c("^[[:space:]]*", var, "[[:space:]]*", "="), collapse = ""), lines)
      if (length(loc) == 0) {
        lines <- append(lines, paste(sep = "=", var, variables[var]))
      } else if(length(loc) == 1) {
        lines[loc] <- paste(sep = "=", var, variables[var])
      } else {
        stop("Multiple results for ", var, " found, something is wrong.", .call = FALSE)
      }
    }
  } else {
    lines <- paste(names(variables), variables, sep = "=")
  }

  if (!identical(old, lines)) {
    writeLines(con = new_path, lines)
  }

  old
}

#' @rdname with_something
#' @param path location of existing makevars to modify.
#' @details If no existing makevars file exists or the fields in \code{new} do
#' not exist in the existing \code{Makevars} file then the fields are added to
#' the new file.  Existing fields which are not included in \code{new} are
#' appended unchanged.  Fields which exist in \code{Makevars} and in \code{new}
#' are modified to use the value in \code{new}.
with_makevars <- function(new, code, path = file.path("~", ".R", "Makevars")) {
  makevars_file <- tempfile()
  on.exit(unlink(makevars_file))
  with_envvar(c(R_MAKEVARS_USER = makevars_file), {
      set_makevars(new, path, makevars_file)
      force(code)
    })
}
