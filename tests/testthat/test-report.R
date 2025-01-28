skip_on_ci <- function() {
  if (!identical(Sys.getenv("CI"), "true")) {
    return(invisible(TRUE))
  }

  skip("On CI")
}

#test_that("it works with coverage objects", {
  #skip_on_cran()
  #skip_on_ci()

  #tmp <- tempfile()
  #set.seed(42)
  #cov <- package_coverage(test_path("TestS4"))
  ## Shiny uses its own seed which is not affected by set.seed, so we need to
  ## set that as well to have reproducibility
  #g <- shiny:::.globals
  #g$ownSeed <- .Random.seed
  #htmlwidgets::setWidgetIdSeed(42)
  #report(cov, file = tmp, browse = FALSE)
  #simplify_link <- function(x) {
    #rex::re_substitutes(x,
      #rex::rex(capture(or("src", "href")), "=", quote, non_quotes, quote), "\\1=\"\">")
  #}
  #expect_equal(simplify_link(readLines(tmp)), simplify_link(readLines("test-report.htm")))
#})
