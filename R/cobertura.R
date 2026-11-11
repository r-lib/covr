#' Create a Cobertura XML file
#'
#' Create a
#' cobertura-compliant XML report following [this
#' DTD](https://github.com/cobertura/cobertura/blob/master/cobertura/src/site/htdocs/xml/coverage-04.dtd).
#' Because there are _two_ DTDs called `coverage-04.dtd` and some tools do not seem to
#' adhere to either of them, the parser you're using may balk at the file. Please see
#' [this github discussion](https://github.com/cobertura/cobertura/issues/425) for
#' context. Where `covr` doesn't provide a coverage metric (complexity), a zero
#' is reported.
#'
#' Branch rates are only reported if branches were measured with
#' `options(covr.branch_coverage = TRUE)` (see [covr.branch_coverage]),
#' otherwise they are zero. Each line where an `if` or `switch()` starts then
#' has `branch="true"` and a `condition-coverage` such as `"50% (1/2)"`, the
#' percentage and number of the branches of the `if` and `switch()` calls on
#' the line that were taken. The branch rate of code without branches is one.
#'
#' *Note*: This functionality requires the xml2 package be installed.
#'
#' @param cov the coverage object returned from [package_coverage()]
#' @param filename the name of the Cobertura XML file
#' @export
cobertura <- function(cov, filename = "cobertura.xml") {
  loadNamespace("xml2")

  df <- tally_coverage(cov, by = "line")
  # Methods list the lines of each function, while the totals and the lines of
  # each file count every line once.
  file_lines <- collapse_lines(df)
  percent_overall <- percent_coverage(df, by = "line") / 100
  percent_per_file <- tapply(
    file_lines$value,
    file_lines$filename,
    FUN = function(x) {
      (sum(x > 0) / length(x))
    }
  )
  lines_valid <- nrow(file_lines)
  lines_covered <- sum(file_lines$value > 0)

  # Without branch coverage, `branch_rate()` is always zero.
  has_branches <- !is.null(attr(cov, "branches"))
  branches <- tally_coverage(cov, by = "branch")
  branch_rate <- function(x) {
    if (!has_branches) {
      return("0")
    }
    if (!NROW(x)) {
      return("1")
    }
    as.character(sum(x$value > 0) / NROW(x))
  }
  # The attributes of each of `lines`, with the branches from `line_branches`.
  line_attributes <- function(lines, line_branches) {
    lapply(lines, function(line) {
      taken <- line_branches$value[line_branches$line == line] > 0
      if (!length(taken)) {
        return(list(branch = "false"))
      }
      list(
        branch = "true",
        `condition-coverage` = sprintf(
          "%d%% (%d/%d)",
          as.integer(floor(100 * sum(taken) / length(taken))),
          sum(taken),
          length(taken)
        )
      )
    })
  }

  d <- xml2::xml_new_document()

  xml2::xml_add_child(
    d,
    xml2::xml_dtd(
      name = "coverage",
      system_id = "https://raw.githubusercontent.com/cobertura/cobertura/master/cobertura/src/site/htdocs/xml/coverage-04.dtd"
    )
  )
  top <- xml2::xml_add_child(
    d,
    "coverage",
    "line-rate" = as.character(percent_overall),
    "branch-rate" = branch_rate(branches),
    `lines-covered` = as.character(lines_covered),
    `lines-valid` = as.character(lines_valid),
    `branches-covered` = as.character(sum(branches$value > 0)),
    `branches-valid` = as.character(NROW(branches)),
    complexity = 0,
    version = as.character(utils::packageVersion("covr")),
    timestamp = as.character(Sys.time())
  )

  # Add sources
  sources <- xml2::xml_add_child(top, "sources")
  source_pth <- attr(cov, "package")$path %||% attr(cov, "root")
  if (!is.null(source_pth)) {
    xml2::xml_add_child(sources, "source", xml2::xml_cdata(source_pth))
  }

  files <- unique(file_lines$filename)

  # Add packages
  packages <- xml2::xml_add_child(top, "packages")
  package <- xml2::xml_add_child(
    packages,
    "package",
    name = attr(cov, "package")$package,
    "line-rate" = as.character(percent_overall),
    "branch-rate" = branch_rate(branches),
    complexity = "0"
  )

  classes <- xml2::xml_add_child(package, "classes")

  # Add classes (for which we will use files for now)
  for (f in files) {
    file_df <- df[df$filename == f, , drop = FALSE]
    file_branches <- branches[branches$filename == f, , drop = FALSE]
    class <- xml2::xml_add_child(
      classes,
      "class",
      name = basename(f),
      filename = f,
      "line-rate" = as.character(percent_per_file[f]),
      "branch-rate" = branch_rate(file_branches),
      complexity = "0"
    )

    # Add methods for all lines with functions. Functions are matched within
    # the file, as methods of different classes can share a name, e.g. the
    # `initialize()` methods of R6 classes (#629).
    methods <- xml2::xml_add_child(class, "methods")

    for (fun_name in unique(na.omit(file_df$functions))) {
      fun_df <- file_df[file_df$functions %in% fun_name, , drop = FALSE]
      fun_branches <- file_branches[
        file_branches$functions %in% fun_name,
        ,
        drop = FALSE
      ]
      fun <- xml2::xml_add_child(
        methods,
        "method",
        name = fun_name,
        signature = "",
        "line-rate" = as.character(sum(fun_df$value > 0) / nrow(fun_df)),
        "branch-rate" = branch_rate(fun_branches),
        "complexity" = "0"
      )

      # Add lines
      lines <- xml2::xml_add_child(fun, "lines")
      attrs <- line_attributes(fun_df$line, fun_branches)
      for (i in seq_len(nrow(fun_df))) {
        line <- fun_df[i, ]
        do.call(
          xml2::xml_add_child,
          c(
            list(
              lines,
              "line",
              number = as.character(line$line),
              hits = as.character(line$value)
            ),
            attrs[[i]]
          )
        )
      }
    }

    # Add lines for "class"
    class_lines <- xml2::xml_add_child(class, "lines")
    rows <- which(file_lines$filename == f)
    attrs <- line_attributes(file_lines$line[rows], file_branches)
    for (i in seq_along(rows)) {
      line <- file_lines[rows[[i]], ]
      do.call(
        xml2::xml_add_child,
        c(
          list(
            class_lines,
            "line",
            number = as.character(line$line),
            hits = as.character(line$value)
          ),
          attrs[[i]]
        )
      )
    }
  }

  xml2::write_xml(d, file = filename)

  invisible(d)
}
