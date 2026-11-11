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

  d <- xml2::xml_new_document()

  top <- xml2::xml_add_child(d, "coverage", version = "1")

  files <- unique(lines$filename)

  for (f in files) {
    path <- as.character(f)
    if (!is.null(path_prefix)) {
      path <- file.path(path_prefix, path)
    }
    file_node <- xml2::xml_add_child(top, "file", path = path)

    file_branches <- if (!is.null(branches)) {
      branches[branches$filename == f, , drop = FALSE]
    }
    for (i in which(lines$filename == f)) {
      line <- lines[i, ]
      attrs <- list(
        lineNumber = as.character(line$line),
        covered = tolower(as.character(line$value > 0))
      )
      b <- match(line$line, file_branches$line)
      if (!is.na(b)) {
        attrs$branchesToCover <- as.character(file_branches$total[[b]])
        attrs$coveredBranches <- as.character(file_branches$taken[[b]])
      }
      do.call(xml2::xml_add_child, c(list(file_node, "lineToCover"), attrs))
    }
  }

  xml2::write_xml(d, file = file)

  invisible(d)
}
