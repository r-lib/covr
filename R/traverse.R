# Replacements for functions nested inside lists and environments, e.g.
# `fns <- list(a = function() ...)` or functions created inside `local()`
# (#113). Only used when `options(covr.full_traversal = TRUE)`, as walking
# every object can be slow for packages with large data.
#
# `existing` holds the replacements already found by the other methods, so
# functions they trace (e.g. R6 or RC methods) are not traced twice.
#
# Objects are tracked by address, because tracing modifies a particular
# closure in place and lists or environments can be shared or cyclic.
replacements_nested <- function(env, existing = list()) {
  seen <- new.env(hash = TRUE, parent = emptyenv())
  # The name of the first function found for each srcref.
  names_by_src <- new.env(hash = TRUE, parent = emptyenv())
  state <- new.env(parent = emptyenv())
  state$replacements <- list()
  state$queue <- list()

  # Returns `TRUE` the first time `x` is seen.
  claim <- function(x) {
    key <- address(x)
    if (exists(key, envir = seen, inherits = FALSE)) {
      return(FALSE)
    }
    assign(key, TRUE, envir = seen)
    TRUE
  }

  # Copies of a function, e.g. from serializing a lazy loaded package, are
  # separate closures that each need tracing. They share counters, so they
  # use the name of the first copy found rather than the last.
  src_name <- function(fun, name) {
    ref <- attr(fun, "srcref", exact = TRUE)
    if (is.null(ref)) {
      return(name)
    }
    key <- key(ref)
    if (exists(key, envir = names_by_src, inherits = FALSE)) {
      return(get(key, envir = names_by_src, inherits = FALSE))
    }
    assign(key, name, envir = names_by_src)
    name
  }

  claim(env)
  for (r in existing) {
    claim(r$target_value)
    src_name(r$target_value, as.character(r$name))
  }

  # Objects are walked breadth first, so functions are named after the
  # shortest path to them, e.g. `GeomRect$draw_panel` rather than
  # `GeomBar$super$super$draw_panel`.
  enqueue <- function(x, name, holder) {
    state$queue[[length(state$queue) + 1L]] <- list(x, name, holder)
  }

  # Queue the environments a function was created in, e.g. those of nested
  # `local()` calls, up to the environment being traced.
  enqueue_enclosures <- function(fun, name) {
    e <- environment(fun)
    while (!identical(e, env) && !skip_env(e)) {
      enqueue(e, name, NULL)
      e <- parent.env(e)
    }
  }

  visit <- function(x, name, holder) {
    if (is.function(x)) {
      if (!is.primitive(x) && is_defined_in(x, env) && claim(x)) {
        state$replacements[[length(state$replacements) + 1L]] <-
          replacement(src_name(x, name), holder, x)
        enqueue_enclosures(x, name)
      }
    } else if (is.environment(x)) {
      if (!skip_env(x) && claim(x)) {
        for (nm in ls(x, all.names = TRUE)) {
          # Evaluating a promise, e.g. an unused argument of a function
          # factory, would change when the code being measured runs.
          if (bindingIsActive(nm, x) || is_unforced_promise(x, nm)) {
            next
          }
          # Bindings can hold the missing argument.
          value <- tryCatch(
            get(nm, envir = x, inherits = FALSE),
            error = function(e) NULL
          )
          enqueue(value, paste0(name, "$", nm), x)
        }
      }
    } else if (is.list(x) && !is.data.frame(x) && claim(x)) {
      # `.subset2()` and `attr()` avoid class methods, e.g. `[[` on a
      # `package_version()` returns another version object.
      nms <- attr(x, "names", exact = TRUE)
      for (i in seq_along(x)) {
        elt <- if (is.null(nms) || !nzchar(nms[[i]])) {
          paste0("[[", i, "]]")
        } else {
          paste0("$", nms[[i]])
        }
        enqueue(.subset2(x, i), paste0(name, elt), x)
      }
    }
  }

  nms <- grep("^\\.__", ls(env, all.names = TRUE), value = TRUE, invert = TRUE)
  for (nm in nms) {
    if (bindingIsActive(nm, env)) {
      next
    }
    x <- get(nm, envir = env, inherits = FALSE)
    if (is.function(x)) {
      # Top level functions are already traced by `replacement()`, so only
      # look inside the environments they were created in.
      if (!is.primitive(x) && is_defined_in(x, env)) {
        enqueue_enclosures(x, nm)
      }
    } else {
      enqueue(x, nm, env)
    }
  }

  i <- 0L
  while (i < length(state$queue)) {
    i <- i + 1L
    item <- state$queue[[i]]
    state$queue[i] <- list(NULL)
    visit(item[[1]], item[[2]], item[[3]])
  }

  state$replacements
}

address <- function(x) {
  .Call(covr_address, x)
}

is_unforced_promise <- function(env, name) {
  .Call(covr_is_unforced_promise, env, name)
}

# Never walk namespaces (including other packages and the lazydata
# environment reached through `.__NAMESPACE__.`), attached packages, or the
# global, base and empty environments.
skip_env <- function(e) {
  isNamespace(e) ||
    identical(e, globalenv()) ||
    identical(e, baseenv()) ||
    identical(e, emptyenv()) ||
    grepl("^package:", environmentName(e))
}

# Whether `fun` was created by code evaluated in `env`, rather than in
# another package, by following its enclosing environments.
is_defined_in <- function(fun, env) {
  e <- environment(fun)
  while (!identical(e, emptyenv())) {
    if (identical(e, env)) {
      return(TRUE)
    }
    if (isNamespace(e)) {
      return(FALSE)
    }
    e <- parent.env(e)
  }
  FALSE
}
