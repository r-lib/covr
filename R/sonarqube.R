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
to_sonarqube <- function(cov, filename = "sonarqube.xml", path_prefix = NULL) {
  loadNamespace("xml2")

  # Compiled code has no functions, and isn't reported.
  df <- tally_coverage(cov, by = "line")
  lines <- collapse_lines(df[!is.na(df$functions), , drop = FALSE])

  d <- xml2::xml_new_document()

  top <- xml2::xml_add_child(d, "coverage", version = "1")

  files <- unique(lines$filename)

  for (f in files) {
    path <- as.character(f)
    if (!is.null(path_prefix)) {
      path <- file.path(path_prefix, path)
    }
    file <- xml2::xml_add_child(top, "file", path = path)

    for (i in which(lines$filename == f)) {
      line <- lines[i, ]
      xml2::xml_add_child(
        file,
        "lineToCover",
        lineNumber = as.character(line$line),
        covered = tolower(as.character(line$value > 0))
      )
    }
  }

  xml2::write_xml(d, file = filename)

  invisible(d)
}
