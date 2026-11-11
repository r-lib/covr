#' Create a SonarQube Generic XML file for test coverage according to
#' <https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/test-coverage/generic-test-data>
#' Based on cobertura.R
#'
#' This functionality requires the xml2 package be installed.
#' @param cov the coverage object returned from [package_coverage()]
#' @param filename the name of the SonarQube Generic XML file
#' @param path_prefix SonarQube expects file paths relative to the project's
#'   base directory. By default the paths are relative to the package root
#'   (e.g. `R/foo.R`), which is correct when the package is the root of the
#'   SonarQube project. If the package is in a subdirectory of the project,
#'   set `path_prefix` to that subdirectory (e.g. `"pkg"` gives `pkg/R/foo.R`).
#' @author Talkdesk Inc.
#' @export
sonarqube <- function(cov, filename = "sonarqube.xml", path_prefix = NULL) {
  loadNamespace("xml2")

  # Compiled code has no functions, and isn't reported.
  df <- tally_coverage(cov, by = "line")
  lines <- collapse_lines(df[!is.na(df$functions), , drop = FALSE])

  files <- unique(lines$filename)
  paths <- as.character(files)
  if (!is.null(path_prefix)) {
    paths <- file.path(path_prefix, paths)
  }

  # Packages can have thousands of lines, so the document is written as text
  # and parsed once, which is much faster than adding each line with xml2.
  line_elements <- sprintf(
    '<lineToCover lineNumber="%s" covered="%s"/>',
    as.character(lines$line),
    tolower(as.character(lines$value > 0))
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

  xml2::write_xml(d, file = filename)

  invisible(d)
}
