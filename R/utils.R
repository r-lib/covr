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
  rex::re_substitutes(x, rex::rex(list(start, spaces) %or% list(spaces, end)),  "")
}

local_branch <- function(dir = ".") {
  withr::with_dir(dir,
    branch <- system_output("git", c("rev-parse", "--abbrev-ref", "HEAD"))
  )
  trim(branch)
}

current_commit <- function(dir = ".") {
  withr::with_dir(dir,
    commit <- system_output("git", c("rev-parse", "HEAD"))
  )
  trim(commit)
}

test_directory <- function(path) {
  if (file.exists(file.path(path, "tests"))) {
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
  lapply(files, source2, path = path, env = env, quiet = quiet)
}

source2 <- function(file, env, path = NULL, quiet = FALSE) {
  if (!is.null(path)) {
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

ex_dot_r <- get(".createExdotR", envir = asNamespace("tools"))

example_code <- function(file) {
  parsed_rd <- tools::parse_Rd(file)

  example_locs <- vapply(parsed_rd,
    function(x) attr(x, "Rd_tag") == "\\examples",
    logical(1)
  )

  unlist(parsed_rd[example_locs])
}

duplicate <- function(x) {
  .Call(covr_duplicate_, x)
}

to_title <- function(x) {
  rex::re_substitutes(x,
                      rex::rex(rex::regex("\\b"), capture(any)),
                      "\\U\\1",
                      global = TRUE)
}

srcfile_lines <- memoise::memoise(function(srcfile) {
  lines <- getSrcLines(srcfile, 1, Inf)
  matches <- rex::re_matches(lines,
    rex::rex(start, any_spaces, "#line", spaces,
      capture(name = "line_number", digit), spaces,
      quotes, capture(name = "filename", anything), quotes))

  matches <- na.omit(matches)

  filename_match <- which(matches$filename == srcfile$filename)

  if (length(filename_match) == 1) {

     # rownames(matches) is the line number of lines
    start <- as.numeric(rownames(matches)[filename_match]) + 1

    # If there is another directive we want to stop at that, otherwise stop at
    # the end
    end <- if (!is.na(rownames(matches)[filename_match + 1])) {
      as.numeric(rownames(matches)[filename_match + 1]) - 1
    } else {
      length(lines)
    }

    # If there are no line directives for the file just use the entire file
  } else {
    start <- 1
    end <- length(lines)
  }

  res <- lines[seq(start, end)]

  # Track blank or comment lines so they can be excluded from the result calculations, but only for R files
  if (rex::re_matches(srcfile$filename, rex::rex(".", one_of("r", "R"), end))) {
    attr(res, "blanks") <- which(rex::re_matches(res, rex::rex(start, any_spaces, maybe("#", anything), end)))
  }
  res
})

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
                      rex::regex("\\b")))$address
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
      structure(list(file = file, coverage = coverage), class = "line_coverage")
    },
    files, res),
    class = "line_coverages")
}

if (getRversion() < "3.2.0") {
  isNamespaceLoaded <- function(x) x %in% loadedNamespaces()
}

is_windows <- function() {
  .Platform$OS.type == "windows"
}

as_package <- function(path) {
  root <- package_root(path)

  if (is.null(root)) {
    stop(sQuote(path), " does not contain a package!", call. = FALSE)
  }

  res <- read_description(file.path(root, "DESCRIPTION"))
  res$path <- root

  res
}

package_root <- function(path) {
  stopifnot(is.character(path))

  has_description <- function(path) {
    file.exists(file.path(path, "DESCRIPTION"))
  }
  is_root <- function(path) {
    identical(path, dirname(path))
  }

  path <- normalizePath(path, mustWork = FALSE)
  while (!is_root(path) && !has_description(path)) {
    path <- dirname(path)
  }

  if (is_root(path)) {
    NULL
  } else {
    path
  }
}

read_description <- function(path) {
  if (!length(path) || !file.exists(path)) {
    stop("DESCRIPTION file not found at ", sQuote(path), call. = FALSE)
  }

  res <- as.list(read.dcf(path)[1, ])
  names(res) <- tolower(names(res))
  res
}

clean_objects <- function(path) {
  files <- list.files(file.path(path, "src"),
                      pattern = rex::rex(".",
                        or("o", "sl", "so", "dylib",
                          "a", "dll", "def"), end),
                      full.names = TRUE)
  unlink(files)

  invisible(files)
}

# This is not actually an S3 method
# From http://stackoverflow.com/a/34639237/2055486
setdiff.data.frame <- function(x, y,
    by = intersect(names(x), names(y)),
    by.x = by, by.y = by) {
  stopifnot(
    is.data.frame(x),
    is.data.frame(y),
    length(by.x) == length(by.y))

  !do.call(paste, c(x[by.x], sep = "\30")) %in% do.call(paste, c(y[by.y], sep = "\30"))
}
