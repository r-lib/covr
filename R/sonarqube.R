#' Create a SonarQube Generic XML file
#'
#' Write coverage in the
#' [generic test data](https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/test-coverage/generic-test-data)
#' XML format read by SonarQube.
#'
#' Every line with coverage is reported as a `lineToCover` with its `lineNumber`
#' and whether it is `covered`, including the lines of compiled code. Each line
#' is reported once: when several functions share a line, it is only covered if
#' all its code was run, as in [report()] and [percent_coverage()].
#'
#' Branches are only reported if they were measured with
#' `options(covr.branch_coverage = TRUE)` (see [covr.branch_coverage]). A line
#' where an `if` or `switch()` starts then also has `branchesToCover`, the
#' number of branches of the `if` and `switch()` calls on the line, and
#' `coveredBranches`, how many of them were taken.
#'
#' This functionality requires the xml2 package be installed.
#' @param x the coverage object returned from [package_coverage()]
#' @param file the name of the SonarQube Generic XML file
#' @param path_prefix SonarQube expects file paths relative to the project's
#'   base directory. By default the paths are relative to the package root
#'   (e.g. `R/foo.R`), which is correct when the package is the root of the
#'   SonarQube project. If the package is in a subdirectory of the project,
#'   set `path_prefix` to that subdirectory (e.g. `"pkg"` gives `pkg/R/foo.R`).
#' @returns The XML document (an `xml2` document), invisibly, after writing it
#'   to `file`.
#' @author Talkdesk Inc.
#' @export
sonarqube <- function(x, file = "sonarqube.xml", path_prefix = NULL) {
  loadNamespace("xml2")

  # Each line, of R and of compiled code, is reported once, as in `lcov()`.
  lines <- collapse_lines(tally_coverage(x, by = "line"))

  # Branches are only reported if they were measured.
  branches <- if (!is.null(attr(x, "branches"))) {
    line_branch_totals(tally_coverage(x, by = "branch"))
  }

  files <- unique(lines$filename)
  paths <- as.character(files)
  if (!is.null(path_prefix)) {
    paths <- file.path(path_prefix, paths)
  }

  # Lines with branches also have the number of branches and how many were
  # taken.
  branch_attrs <- character(nrow(lines))
  if (!is.null(branches)) {
    b <- match(
      paste(lines$filename, lines$line),
      paste(branches$filename, branches$line)
    )
    has <- !is.na(b)
    branch_attrs[has] <- sprintf(
      ' branchesToCover="%d" coveredBranches="%d"',
      branches$total[b[has]],
      branches$taken[b[has]]
    )
  }

  # Packages can have thousands of lines, so the document is written as text
  # and parsed once, which is much faster than adding each line with xml2.
  line_elements <- sprintf(
    '<lineToCover lineNumber="%s" covered="%s"%s/>',
    as.character(lines$line),
    tolower(as.character(lines$value > 0)),
    branch_attrs
  )
  file_lines <- vapply(
    split(line_elements, factor(lines$filename, levels = files)),
    paste,
    character(1),
    collapse = ""
  )
  d <- xml2::read_xml(paste0(
    '<coverage version="1">',
    paste(
      sprintf('<file path="%s">%s</file>', xml_escape(paths), file_lines),
      collapse = ""
    ),
    "</coverage>"
  ))

  xml2::write_xml(d, file = file)

  invisible(d)
}
