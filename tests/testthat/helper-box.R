reset_box_modules <- function() {
  loaded_mods <- loadNamespace("box")$loaded_mods
  rm(list = ls(loaded_mods), envir = loaded_mods)
}

# Coverage of the app of a Testbox* fixture, as a data frame, measured from
# the fixture's directory.
box_coverage <- function(fixture) {
  skip_if_not_installed("box")
  reset_box_modules()
  withr::with_dir(fixture, {
    as.data.frame(file_coverage(
      source_files = "app/app.R",
      test_files = list.files("tests/testthat", full.names = TRUE)
    ))
  })
}
