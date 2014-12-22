#' @import jsonlite
NULL

expression_coverage <- function(x, ..., env = parent.frame()) {
  args <- lazyeval::lazy_dots(...)
  expression_coverage_(x, args)
}

trace_expressions <- function (x, srcref = NULL) {
  recurse <- function(y) {
    lapply(y, trace_expressions)
  }

  if (is.atomic(x) || is.name(x)) {
    x
  }
  else if (is.call(x)) {
    src_ref <- attr(x, "srcref")
    if (!is.null(src_ref)) {
      message("type: ", typeof(x), " class: ", class(x), " length: ", length(src_ref))
      as.call(Map(trace_expressions, x, src_ref))
    } else if (!is.null(srcref)) {
      key <- key(srcref)
      covr::new_counter(key)
      bquote(`{`(covr::count(.(key)), .(as.call(recurse(x)))))
    } else {
      as.call(recurse(x))
    }
  }
  else if (is.function(x)) {
    formals(x) <- trace_expressions(formals(x))
    body(x) <- trace_expressions(body(x))
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

new_counter <- function(key) {
  .counters[[key]] <- 0
}
count <- function(key) {
  .counters[[key]] <- .counters[[key]] + 1
}

clear_counters <- function() {
  rm(envir = .counters, list=ls(envir = .counters))
}
environment_coverage <- function(env, ...) {
  clear_counters()

  exprs <- as.list(substitute(list(...))[-1])

  old_env <- as.environment(as.list(env, all.names = TRUE))

  on.exit({
    for(n in ls(old_env, all.names=TRUE)) {
      assign(n, get(n, old_env), env)
    }
  })

  for(name in ls(env, all.names=TRUE)) {
    obj <- get(name, env)
    if (is.function(obj)) {
      val = trace_expressions(obj)
      message("name: ", name)
      assign(name, eval(val, env), env)
    }
  }

  for (expr in exprs) {
    eval(expr, envir=env)
  }

  res <- as.list(.counters)
  clear_counters()
  res
}

key <- function(x) {
  file <- attr(x, "srcfile")$filename %||% "<default>"
  paste(sep = ":", file, paste0(collapse = ":", c(x)))
}

get_srcfile <- function(filename) {
  lines <- readLines(filename)
  source_file <- srcfilecopy(filename, lines, file.info(filename)[1, "mtime"], isFile = TRUE)
  source_file$expr <- parse(text = lines, srcfile = source_file, keep.source = TRUE)
  source_file$content <- paste0(collapse = "\n", lines)

  #try(source_file$expr <- parse(text=source_file$content, srcfile=source_file, keep.source = TRUE))

   #This needs to be done twice to avoid
     #https://bugs.r-project.org/bugzilla/show_bug.cgi?id=16041
  #try(source_file$expr <- parse(text=source_file$content, srcfile=source_file, keep.source = TRUE))

  source_file$parsed <- getParseData(source_file)

  source_file
}

package_coverage <- function(path = ".") {
  source_files <- dir(file.path(path, "R"), pattern = "\\.[Rr]$", full.names = TRUE)

  test_files <- dir(file.path(path, "tests", "testthat"), recursive = TRUE, pattern = "\\.[Rr]$", full.names = TRUE)

  source_parsed <- lapply(source_files, get_srcfile)

  test_parsed <- lapply(test_files, function(x) parse(x))

  expression_coverage_(source_parsed, test_parsed)
}
#jsonlite::toJSON(na="null",
  #list("service_job_id" = 123324,
    #"service_name" = "travis-ci",
    #"source_files" =
      #list("name" = "test",
        #"source" = "a <- 1",
        #"coverage" = c(NA, 2, 3)
        #)
    #)
  #)

make_function <- function (args, body, env = parent.frame()) {
    args <- as.pairlist(args)
    stopifnot(is.language(body))
    eval(call("function", args, body), env)
}

change_enclosing_environment <- function(f, env) {
  make_function(formals(f), body(f), env)
}
