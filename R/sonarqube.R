#' Create a SonarQube Generic XML file for test coverage according to
#' https://docs.sonarqube.org/latest/analysis/generic-test/
#' Based on cobertura.R
#'
#' This functionality requires the xml2 package be installed.
#' @param cov the coverage object returned from [package_coverage()]
#' @param filename the name of the SonarQube Generic XML file
#' @author Talkdesk Inc.
#' @export
to_sonarqube <- function(cov, filename = "sonarqube.xml"){

  loadNamespace("xml2")

  df <- tally_coverage(cov, by = "line")

  d <- xml2::xml_new_document()

  top <- xml2::xml_add_child(d, "coverage", version = "1")

  files <- unique(df$filename)

  for (f in files){
    file <- xml2::xml_add_child(top, "file", path = paste(attr(cov, "package")$package, "/", as.character(f), sep=""))

    for (fun_name in unique(na.omit(df[df$filename == f, "functions"]))) {
      fun_lines <- which(df$functions == fun_name)
      for (i in fun_lines){
        line <- df[i, ]
        xml2::xml_add_child(file, "lineToCover", lineNumber = as.character(line$line),
          covered = tolower(as.character(line$value>0)))
      }
    }
  }

  xml2::write_xml(d, file = filename)

  invisible(d)
}
