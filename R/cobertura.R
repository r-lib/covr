#' Create a Cobertura XML file
#' @param cov the coverage object returned from \code{\link{package_coverage}}
#' @param filename the name of the Cobertura XML file
#' @author Willem Ligtenberg
#' @export
to_cobertura <- function(cov, filename = 'cobertura.xml'){
  xmlDocument = XML::newXMLDoc()
  
  df <- tally_coverage(cov, by = "line")
  
  top <- XML::newXMLNode(name = "coverage", 
      attrs = c(
          "line-rate" = as.character(percent_coverage(df, by = "line")/100),
          "branch-rate" = "0",
          version = sessionInfo()$otherPkgs$covr$Version,
          timestamp = as.character(Sys.time())),
      parent = xmlDocument)
  
  # Add sources
  sources <- XML::newXMLNode(
      name = "sources", 
      parent = top)
  sourceFiles <- unique(covr::display_name(cov))
  for(f in sourceFiles){
    source <- XML::newXMLNode(
        name = "source", 
        text = f,
        parent = sources)
  }
  
  # Add packages
  packages <- XML::newXMLNode(
      name = "packages", 
      parent = top)
  
  packageName <- attr(x, "package")$package
  if(length(packageName) > 1){
    stop("We have covr results for more than one package? We do not support that for now.")
  }
  package <- XML::newXMLNode(
      name = "package", 
      attrs = c(
          name = packageName,
          "line-rate" = as.character(percent_coverage(df, by = "line")/100),
          "branch-rate" = "0",
          complexity = "0"),
      parent = packages)
  
  classes <- XML::newXMLNode(
      name = "classes", 
      parent = package)
  
  # Add classes (for which we will use files for now)
  for(f in sourceFiles){
    cl <- XML::newXMLNode(
        name = "class", 
        attrs = c(
            name = basename(f),
            filename = f,
            "line-rate" = as.character(percent_coverage(df[df$filename == f, ], by = "line")/100),
            "branch-rate" = "0",
            complexity = "0"),
        parent = classes)
    # Add methods
    ms <- XML::newXMLNode(
        name = "methods", 
        parent = cl)
    for(fname in unique(df$functions)){
      fun <- XML::newXMLNode(
          name = "method", 
          attrs = c(
              name = fname,
              signature = "NA",
              "line-rate" = as.character(percent_coverage(df[df$functions == fname, ], by = "line")/100),
              "branch-rate" = "0"),
          parent = ms)
      # Add lines
      ls <- XML::newXMLNode(
          name = "lines", 
          parent = fun)
      for(i in seq_len(nrow(df[df$functions == fname, ]))){
        line <- df[df$functions == fname, ][i, ]
        l <- XML::newXMLNode(
            name = "line", 
            attrs = c(
                number = as.character(line$line),
                hits = as.character(line$value),
                branch = "false"),
            parent = ls)
      }
    }
    # Add lines
    ls2 <- XML::newXMLNode(
        name = "lines", 
        parent = cl)
    for(i in seq_len(nrow(df))){
      line <- df[i, ]
      l <- XML::newXMLNode(
          name = "line", 
          attrs = c(
              number = as.character(line$line),
              hits = as.character(line$value),
              branch = "false"),
          parent = ls2)
    }
  }
  
  
  # This workaround was suggested by Duncan:
  # http://r.789695.n4.nabble.com/saveXML-prefix-argument-td4678407.html
  
  cat(XML::saveXML(xmlDocument, encoding = "UTF-8", indent = TRUE, prefix = cobertura_dtd()),
      file = filename)
}


#' Generate cobertura DTD
#' @return String that contains the cobertura DTD
#' @author Willem Ligtenberg
cobertura_dtd <- function(){
  return('<?xml version="1.0" encoding="UTF-8" ?>
          
          <!-- Internal DTD -->
          <!DOCTYPE coverage [
          <!-- Portions (C) International Organization for Standardization 1986:
          Permission to copy in any form is granted for use with
          conforming SGML systems and applications as defined in
          ISO 8879, provided this notice is included in all copies.
          -->
          
          <!ELEMENT coverage (sources?,packages)>
          <!ATTLIST coverage line-rate   CDATA #REQUIRED>
          <!ATTLIST coverage branch-rate CDATA #REQUIRED>
          <!ATTLIST coverage version     CDATA #REQUIRED>
          <!ATTLIST coverage timestamp   CDATA #REQUIRED>
          
          <!ELEMENT sources (source*)>
          
          <!ELEMENT source (#PCDATA)>
          
          <!ELEMENT packages (package*)>
          
          <!ELEMENT package (classes)>
          <!ATTLIST package name        CDATA #REQUIRED>
          <!ATTLIST package line-rate   CDATA #REQUIRED>
          <!ATTLIST package branch-rate CDATA #REQUIRED>
          <!ATTLIST package complexity  CDATA #REQUIRED>
          
          <!ELEMENT classes (class*)>
          
          <!ELEMENT class (methods,lines)>
          <!ATTLIST class name        CDATA #REQUIRED>
          <!ATTLIST class filename    CDATA #REQUIRED>
          <!ATTLIST class line-rate   CDATA #REQUIRED>
          <!ATTLIST class branch-rate CDATA #REQUIRED>
          <!ATTLIST class complexity  CDATA #REQUIRED>
          
          <!ELEMENT methods (method*)>
          
          <!ELEMENT method (lines)>
          <!ATTLIST method name        CDATA #REQUIRED>
          <!ATTLIST method signature   CDATA #REQUIRED>
          <!ATTLIST method line-rate   CDATA #REQUIRED>
          <!ATTLIST method branch-rate CDATA #REQUIRED>
          
          <!ELEMENT lines (line*)>
          
          <!ELEMENT line (conditions*)>
          <!ATTLIST line number CDATA #REQUIRED>
          <!ATTLIST line hits   CDATA #REQUIRED>
          <!ATTLIST line branch CDATA "false">
          <!ATTLIST line condition-coverage CDATA "100%">
          
          <!ELEMENT conditions (condition*)>
          
          <!ELEMENT condition EMPTY>
          <!ATTLIST condition number CDATA #REQUIRED>
          <!ATTLIST condition type CDATA #REQUIRED>
          <!ATTLIST condition coverage CDATA #REQUIRED>
          ]>')
}
