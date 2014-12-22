#' @import jsonlite

expression_coverage <- function(x, ..., env = parent.frame()) {
  args <- lazyeval::lazy_dots(...)
  expression_coverage_(x, args)
}
expression_coverage_ <- function(x, args, env = parent.frame()) {

  exprs <- lazyeval::as.lazy_dots(args, env)
  str(exprs)

  `*counts*` <- list()

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
        #message("type: ", typeof(x), " class: ", class(x), " length: ", length(src_ref))
        as.call(Map(trace_expressions, x, src_ref))
      } else if (!is.null(srcref)) {
        `*counts*`[key(srcref)] <<- 0
        bquote(`{`(`*trace*`(.(srcref)), .(as.call(recurse(x)))))
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

  `*trace*` <- function(y) {
    key <- key(y)
    `*counts*`[[key]] <<- `*counts*`[[key]] + 1
  }

  for (file_expressions in x) {
    eval(trace_expressions(file_expressions$expr))
  }

  print(ls())
  for (expr in exprs) {
    lazyeval::lazy_eval(expr, environment())
  }

  `*counts*`
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
