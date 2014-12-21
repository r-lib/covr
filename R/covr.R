#' @import jsonlite

count <- numeric()

trace_expressions <- function (x, srcref = NULL, ...) {
    recurse <- function(y) {
      lapply(y, trace_expressions, ...)
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
        srcref[9] <- 0
          bquote(`{`(test_print(.(srcref)), .(as.call(recurse(x)))))
      } else {
        as.call(recurse(x))
      }
    }
    else if (is.function(x)) {
      formals(x) <- trace_expressions(formals(x), ...)
      body(x) <- trace_expressions(body(x), ...)
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

test_print <- function(x) {
  if (is.na(count[x[1]])) {
    count[x[1]] <<- 1
  } else {
    count[x[1]] <<- count[x[1]] + 1
  }
}
expr <- function(filename) {
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
