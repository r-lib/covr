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

local_branch <- function(dir = ".") {
  in_dir(dir,
    branch <- system_output("git", c("rev-parse", "--abbrev-ref", "HEAD"))
  )
  trim(branch)
}

current_commit <- function(dir = ".") {
  in_dir(dir,
    commit <- system_output("git", c("rev-parse", "HEAD"))
  )
  trim(commit)
}

test_directory <- function(path) {
  if(file.exists(file.path(path, "tests"))) {
    file.path(path, "tests")
  } else if (file.exists(file.path(path, "inst", "tests"))) {
    file.path(path, "inst", "tests")
  } else {
    stop("No testing directory found", call. = FALSE)
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

traced_files <- function(x) {
  res <- list()
  for (i in seq_along(x)) {
    src_file <- attr(x[[i]]$srcref, "srcfile")
    address <- address(src_file)
    if (is.null(res[[address]])) {
      lines <- getSrcLines(src_file, 1, Inf)
      matches <- rex::re_matches(lines,
        rex::rex(start, any_spaces, "#line", spaces,
          capture(name = "line_number", digit), spaces,
          quotes, capture(name = "filename", anything), quotes))

      matches <- na.omit(matches)

      filename_match <- which(matches$filename == src_file$filename)

      if (length(filename_match) == 1) {
        start <- as.numeric(rownames(matches)[filename_match]) + 1
        end <- if (!is.na(rownames(matches)[filename_match + 1])) {
          as.numeric(rownames(matches)[filename_match + 1]) - 1
        } else {
          length(lines)
        }
      } else {
        start <- 1
        end <- length(lines)
      }
      src_file$file_lines <- lines[seq(start, end)]

      res[[address]] <- src_file
    }
  }
  res
}

# TODO: use C code to get the address directly
address <- function(x) {
  rex::re_matches(capture.output(str(x)),
             rex::rex(capture(name = "address", "0x", anything),
                      boundary))$address
}

per_line <- function(coverage) {

  files <- traced_files(coverage)

  blank_lines <- lapply(files, function(file) {
    which(rex::re_matches(file$file_lines, rex::rex(start, any_spaces, maybe("#", anything), end)))
    })

  file_lengths <- lapply(files, function(file) {
    length(file$file_lines)
  })

  res <- lapply(file_lengths,
    function(x) {
      rep(NA_real_, length.out = x)
    })

  for (i in seq_along(coverage)) {
    x <- coverage[[i]]
    file_address <- address(attr(x$srcref, "srcfile"))
    value <- x$value
    for (line in seq(x$srcref[1], x$srcref[3])) {
      # if it is not a blank line
      if (!line %in% blank_lines[[file_address]]) {

      # if current coverage is na or coverage is less than current coverage
        if (is.na(res[[file_address]][line]) || value < res[[file_address]][line]) {
          res[[file_address]][line] <- value
        }
      }
    }
  }
  structure(
    Map(function(file, coverage) {
      structure(list(file=file, coverage=coverage), class = "line_coverage")
    },
    files, res),
    class = "line_coverages")
}
