#' Create a Cobertura XML file
#'
#' This functionality requires the xml2 package be installed.
#' @param cov the coverage object returned from [package_coverage()]
#' @param filename the name of the Cobertura XML file
#' @author Willem Ligtenberg
#' @export
to_cobertura <- function(cov, filename = "cobertura.xml"){

  loadNamespace("xml2")

  df <- tally_coverage(cov, by = "line")
  percent_overall <- percent_coverage(df, by = "line") / 100
  percent_per_file <- tapply(df$value, df$filename, FUN = function(x) (sum(x > 0) / length(x)))
  percent_per_function <- tapply(df$value, df$functions, FUN = function(x) (sum(x > 0) / length(x)))
  lines_valid <- nrow(df)
  lines_covered <- sum(df$value > 0)
                                 
  d <- xml2::xml_new_document()

  top <- xml2::xml_add_child(d,
    "coverage",
    "line-rate" = as.character(percent_overall),
    "branch-rate" = "0", 
    `lines-covered` = as.character(lines_covered),
    `lines-valid` = as.character(lines_valid),
    `branches-covered` = "0",
    `branches-valid` = "0",
    complexity = 0,
    version = as.character(utils::packageVersion("covr")),
    timestamp = as.character(Sys.time()))

  # Add sources
  #sources <- xml2::xml_add_child(top, "sources")
  files <- unique(df$filename)
  #for (f in files){
    #xml2::xml_add_child(sources, "source", f)
  #}

  # Add packages
  packages <- xml2::xml_add_child(top, "packages")
  package <- xml2::xml_add_child(packages, "package",
    name = attr(cov, "package")$package,
    "line-rate" = as.character(percent_overall),
    "branch-rate" = "0",
    complexity = "0")

  classes <- xml2::xml_add_child(package, "classes")

  # Add classes (for which we will use files for now)
  for (f in files){
    class <- xml2::xml_add_child(classes, "class",
      name = basename(f),
      filename = f,
      "line-rate" = as.character(percent_per_file[f]),
      "branch-rate" = "0",
      complexity = "0")

    # Add methods
    methods <- xml2::xml_add_child(class, "methods")

    for (fun_name in unique(df[df$filename == f, "functions"])) {
      fun <- xml2::xml_add_child(methods, "method",
        name = fun_name,
        #signature = "NA",
        "line-rate" = as.character(percent_per_function[fun_name]),
        "branch-rate" = "0")

      # Add lines
      lines <- xml2::xml_add_child(fun, "lines")
      fun_lines <- which(df$functions == fun_name)
      for (i in fun_lines){
        line <- df[i, ]
        xml2::xml_add_child(lines, "line",
          number = as.character(line$line),
          hits = as.character(line$value),
          branch = "false")
      }
    }

    # Add lines for "class"
    class_lines <- xml2::xml_add_child(class, "lines")
    file_lines <- which(df$filename == f)
    for (i in file_lines) {
      line <- df[i, ]
      xml2::xml_add_child(class_lines, "line",
        number = as.character(line$line),
        hits = as.character(line$value),
        branch = "false")
    }
  }

  xml2::write_xml(d, file = filename)

  invisible(d)
}
