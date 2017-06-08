#' @export
shiny_coverage <- function(code) {
  requireNamespace("shiny", quietly = TRUE)

  registerShinyDebugHook <<- function(params) {
    replace(replacement(params$name, env = params$where))
  }

  message("Use Ctrl-C to interrupt the process when finished and then run `covr::shiny_results()` to retrieve the results")
  force(code)
}


#' Return results from `shiny_coverage()` run.
#' @export
shiny_results <- function() {
  on.exit(clear_counters())

  structure(as.list(.counters), class = "coverage")
}
