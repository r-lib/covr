#' @import jsonlite
NULL

rex::register_shortcuts("covr")

#' trace each call with a srcref attribute
#'
#' This function calls itself recursively so it can properly traverse the AST.
#' @param x the call
#' @param srcref argument used to set the srcref of the current call when recursing
#' @seealso \url{http://adv-r.had.co.nz/Expressions.html}
#' @return a modified expression with count calls inserted before each previous
#' call.
trace_calls <- function (x, srcref = NULL) {
  recurse <- function(y) {
    lapply(y, trace_calls)
  }

  if (is.atomic(x) || is.name(x)) {
    x
  }
  else if (is.call(x)) {
    src_ref <- attr(x, "srcref")
    if (!is.null(src_ref)) {
      as.call(Map(trace_calls, x, src_ref))
    } else if (!is.null(srcref)) {
      key <- key(srcref)
      covr::new_counter(key)
      bquote(`{`(covr::count(.(key)), .(as.call(recurse(x)))))
    } else {
      as.call(recurse(x))
    }
  }
  else if (is.function(x)) {
    formals(x) <- trace_calls(formals(x))
    body(x) <- trace_calls(body(x))
    x
  }
  else if (is.pairlist(x)) {
    as.pairlist(recurse(x))
  }
  else if (is.expression(x)) {
    as.expression(recurse(x))
  }
  else if (is.list(x)) {
    recurse(x)
  }
  else {
    stop("Unknown language class: ", paste(class(x), collapse = "/"),
      call. = FALSE)
  }
}

.counters <- new.env()

#' initialize a new counter
#'
#' @param key generated with \code{\link{key}}
#' @export
new_counter <- function(key) {
  .counters[[key]] <- 0
}

#' increment a given counter
#'
#' @inheritParams new_counter
#' @export
count <- function(key) {
  .counters[[key]] <- .counters[[key]] + 1
}

#' clear all previous counters
#'
#' @export
clear_counters <- function() {
  rm(envir = .counters, list=ls(envir = .counters))
}

#' calculate the coverage on an environment after evaluating some expressions.
#'
#' This function uses non_standard evaluation so is best used in interactive
#' sessions.
#' @param env the environment to take function definitions from
#' @param ... one or more expressions to be evaluated.
#' @param enc The enclosing environment from which the expressions should be
#' evaluated
#' @export
environment_coverage <- function(env, ..., enc = parent.frame()) {
  exprs <- dots(...)
  environment_coverage_(env, exprs, enc = enc)
}

#' calculate the coverage on an environment after evaluating some expressions.
#'
#' This function does not use non_standard evaluation so is more appropriate
#' for use in other functions.
#' @inheritParams environment_coverage
#' @param exprs a list of parsed expressions to be evaluated.
#' @export
environment_coverage_ <- function(env, exprs, enc = parent.frame()) {
  clear_counters()

  old_env <- as.environment(as.list(env, all.names = TRUE))

  on.exit({
    for(name in ls(old_env, all.names=TRUE)) {
      obj <- get(name, old_env)
      if (is.function(obj)) {
        assign(name, obj, env)
      }
    }
  })

  for(name in ls(env, all.names=TRUE)) {
    obj <- get(name, env)
    if (is.function(obj)) {
      val <- trace_calls(obj)
      assign(name, eval(val, env), env)
    }
  }

  for (expr in exprs) {
    eval(expr, enc)
  }

  res <- as.list(.counters)
  clear_counters()

  class(res) <- "coverage"

  res
}

#' Generate a key for a  call
#'
#' @param x the call to create a key for
#' @export
key <- function(x) {
  file <- attr(x, "srcfile")$filename %||% "<default>"
  paste(sep = ":", file, paste0(collapse = ":", c(x)))
}

#' Calculate test coverage for a package
#'
#' @param path file path to the package
#' @param ... expressions to run
#' @param relative_path whether to output the paths as relative or absolute
#' paths.
#' @export
package_coverage <- function(path = ".", ..., relative_path = FALSE) {

  if (!file.exists(path)) {
    return(NULL)
  }

  ns_env <- devtools::load_all(path, export_all = FALSE, quiet = TRUE)$env

  env <- new.env(parent = ns_env)

  testing_dir <- file.path(path, "tests")

  res <- environment_coverage_(ns_env,
    c(dots(...),
    if (file.exists(testing_dir)) {
      bquote(testthat::source_dir(path = .(testing_dir), env = .(env)))
    }),
    enc = environment())

  if (relative_path) {
    names(res) <- rex::re_substitutes(names(res), rex::rex(normalizePath(path), "/"), "")
  }
  res
}

per_line <- function(x) {

  df <- as.data.frame(x)

  file_lengths <- tapply(df$last_line, df$filename,
    function(x) {
      max(unlist(x))
    })

  res <- lapply(file_lengths,
    function(x) {
      rep(NA_real_, length.out = x)
    })

  # get the maximum coverage per line
  for (i in seq_len(NROW(df))) {
    for (line in seq(df[i, "first_line"], df[i, "last_line"])) {
      filename <- df[i, "filename"]
      value <- df[i, "value"]
      if (is.na(res[[filename]][line]) || res[[filename]][line] < value) {
        res[[filename]][line] <- value
      }
    }
  }
  res
}
