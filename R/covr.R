#' @import jsonlite
NULL

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

#' @export
new_counter <- function(key) {
  .counters[[key]] <- 0
}

#' @export
count <- function(key) {
  .counters[[key]] <- .counters[[key]] + 1
}

#' @export
clear_counters <- function() {
  rm(envir = .counters, list=ls(envir = .counters))
}

environment_coverage <- function(env, ..., enc = parent.frame()) {
  exprs <- as.list(substitute(list(...))[-1])
  environment_coverage_(env, exprs, enc = enc)
}

environment_coverage_ <- function(env, exprs, enc = parent.frame()) {
  clear_counters()

  old_env <- as.environment(as.list(env, all.names = TRUE))

  on.exit({
    for(n in ls(old_env, all.names=TRUE)) {
      assign(n, get(n, old_env), env)
    }
  })

  for(name in ls(env, all.names=TRUE)) {
    obj <- get(name, env)
    if (is.function(obj)) {
      val <- trace_expressions(obj)
      assign(name, eval(val, env), env)
    }
  }

  for (expr in exprs) {
    eval(expr, enc)
  }

  res <- as.list(.counters)
  clear_counters()
  res
}

key <- function(x) {
  file <- attr(x, "srcfile")$filename %||% "<default>"
  paste(sep = ":", file, paste0(collapse = ":", c(x)))
}

#' @export
package_coverage <- function(path = ".", relative_path = FALSE) {
  library(testthat)
  devtools::load_all(path)

  env <- devtools::ns_env(path)

  testing_dir <- file.path(path, "tests", "testthat")

  res <- environment_coverage(devtools::ns_env(path),
    testthat::test_dir(path = testing_dir, env = env),
    enc = environment())

  if (relative_path) {
    names(res) <- rex::re_substitutes(names(res), rex::rex(normalizePath(path), "/"), "")
  }
  res
}

per_line <- function(x) {
    re <-
      rex::rex(
        capture(name = "filename", something), ":",
        capture(name = "first_line", something), ":",
        capture(name = "first_byte", something), ":",
        capture(name = "last_line", something), ":",
        capture(name = "last_byte", something), ":",
        capture(name = "first_column", something), ":",
        capture(name = "last_column", something), ":",
        capture(name = "first_parsed", something), ":",
        capture(name = "last_parsed", something))
  df <- rex::re_matches(names(x),re)

  df[] <- lapply(df, type.convert, as.is = TRUE)
  df$value <- unlist(x)

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

to_coveralls <- function(x, service_job_id = Sys.getenv("TRAVIS_JOB_ID"), service_name = "travis-ci") {
  coverages <- per_line(x)

  names <- names(coverages)

  sources <- lapply(names(coverages), function(x) { readChar(x, file.info(x)$size) })

  res <- mapply(function(name, source, coverage) { list("name" = jsonlite::unbox(name), "source" = jsonlite::unbox(source), "coverage" = coverage) }, names, sources, coverages, SIMPLIFY = FALSE, USE.NAMES = FALSE)

  jsonlite::toJSON(na = "null", list(
    "service_job_id" = jsonlite::unbox(service_job_id),
    "service_name" = jsonlite::unbox(service_name),
    "source_files" = res))
}

#' @export
coveralls <- function(path = ".") {
  coveralls_url <- "https://coveralls.io/api/v1/jobs"
  coverage <- to_coveralls(package_coverage(path, relative_path = TRUE))

  name <- tempfile()
  con <- file(name)
  writeChar(con = con, coverage, eos = NULL)
  close(con)
  httr::content(httr::POST(coveralls_url, body = list(json_file = httr::upload_file(name))))
}
