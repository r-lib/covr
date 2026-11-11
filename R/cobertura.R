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
#' @param x the coverage object returned from [package_coverage()]
#' @param file the name of the Cobertura XML file
#' @returns The XML document (an `xml2` document), invisibly, after
#'   writing it to `file`.
#' @export
cobertura <- function(x, file = "cobertura.xml") {
  loadNamespace("xml2")

  df <- tally_coverage(x, by = "line")
  # Methods list the lines of each function, while the totals and the lines of
  # each file count every line once.
  file_lines <- collapse_lines(df)
  percent_overall <- percent_coverage(df, by = "line") / 100
  lines_valid <- nrow(file_lines)
  lines_covered <- sum(file_lines$value > 0)

  # Without branch coverage, `branch_rate()` is always zero.
  has_branches <- !is.null(attr(x, "branches"))
  branches <- tally_coverage(x, by = "branch")
  # The branch rate of the counts `x` of some branches.
  branch_rate <- function(x) {
    if (!has_branches) {
      return("0")
    }
    if (!length(x)) {
      return("1")
    }
    as.character(sum(x > 0) / length(x))
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
    "branch-rate" = branch_rate(branches$value),
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
  source_pth <- attr(x, "package")$path %||% attr(x, "root")
  if (!is.null(source_pth)) {
    xml2::xml_add_child(sources, "source", xml2::xml_cdata(source_pth))
  }

  # Add packages
  packages <- xml2::xml_add_child(top, "packages")
  package <- xml2::xml_add_child(
    packages,
    "package",
    name = attr(x, "package")$package,
    "line-rate" = as.character(percent_overall),
    "branch-rate" = branch_rate(branches$value),
    complexity = "0"
  )

  # Add classes (for which we will use files for now). Packages can have
  # thousands of lines, so the classes are written as text and parsed once,
  # which is much faster than adding each line with xml2.
  classes <- xml2::read_xml(paste0(
    "<classes>",
    paste(
      cobertura_classes(df, file_lines, branches, branch_rate),
      collapse = ""
    ),
    "</classes>"
  ))
  xml2::xml_add_child(package, xml2::xml_root(classes))

  xml2::write_xml(d, file = file)

  invisible(d)
}

# The `<class>` element of each file, as text. `df` has the lines of each
# function, `file_lines` each line once and `branches` the branches;
# `branch_rate()` gives the branch rate of the counts of some branches.
cobertura_classes <- function(df, file_lines, branches, branch_rate) {
  files <- unique(file_lines$filename)
  max_line <- max(0, df$line, branches$line) + 1

  # The `<line>` elements of `lines`, which are in the groups `group`, with
  # the branches on the line in the same group, as `branch_group` gives the
  # group of each branch.
  line_elements <- function(lines, group, branch_group) {
    branch_key <- branch_group * max_line + branches$line
    keys <- unique(branch_key)
    i <- match(group * max_line + lines$line, keys)
    total <- tabulate(match(branch_key, keys), length(keys))[i]
    taken <- tabulate(
      match(branch_key[branches$value > 0], keys),
      length(keys)
    )[i]
    branch <- rep(' branch="false"', length(i))
    has <- !is.na(i)
    branch[has] <- sprintf(
      ' branch="true" condition-coverage="%d%% (%d/%d)"',
      as.integer(floor(100 * taken[has] / total[has])),
      taken[has],
      total[has]
    )
    sprintf(
      '<line number="%s" hits="%s"%s/>',
      as.character(lines$line),
      as.character(lines$value),
      branch
    )
  }
  # Each group's elements of `x`, for the groups `seq_len(n)`.
  by_group <- function(x, group, n) {
    split(x, factor(group, levels = seq_len(n)))
  }
  join_groups <- function(x, group, n) {
    vapply(by_group(x, group, n), paste, character(1), collapse = "")
  }
  line_rates <- function(x, group, n) {
    vapply(
      by_group(x, group, n),
      function(x) as.character(sum(x > 0) / length(x)),
      character(1)
    )
  }
  branch_rates <- function(group, n) {
    vapply(by_group(branches$value, group, n), branch_rate, character(1))
  }

  # Add methods for all lines with functions. Functions are matched within the
  # file, as methods of different classes can share a name, e.g. the
  # `initialize()` methods of R6 classes (#629).
  fun_lines <- df[!is.na(df$functions), , drop = FALSE]
  fun_keys <- paste(fun_lines$filename, fun_lines$functions, sep = "\r")
  method_keys <- unique(fun_keys)
  method <- match(fun_keys, method_keys)
  branch_method <- match(
    paste(branches$filename, branches$functions, sep = "\r"),
    method_keys
  )
  n_methods <- length(method_keys)
  first <- !duplicated(method)
  methods <- sprintf(
    paste0(
      '<method name="%s" signature="" line-rate="%s" branch-rate="%s"',
      ' complexity="0"><lines>%s</lines></method>'
    ),
    xml_escape(fun_lines$functions[first]),
    line_rates(fun_lines$value, method, n_methods),
    branch_rates(branch_method, n_methods),
    join_groups(
      line_elements(fun_lines, method, branch_method),
      method,
      n_methods
    )
  )

  n_files <- length(files)
  file <- match(file_lines$filename, files)
  branch_file <- match(branches$filename, files)
  sprintf(
    paste0(
      '<class name="%s" filename="%s" line-rate="%s" branch-rate="%s"',
      ' complexity="0"><methods>%s</methods><lines>%s</lines></class>'
    ),
    xml_escape(basename(files)),
    xml_escape(files),
    line_rates(file_lines$value, file, n_files),
    branch_rates(branch_file, n_files),
    join_groups(methods, match(fun_lines$filename[first], files), n_files),
    join_groups(line_elements(file_lines, file, branch_file), file, n_files)
  )
}
