options(box.path = file.path(getwd()))
rm(list = ls(box:::loaded_mods), envir = box:::loaded_mods)

library(testthat)

test_dir("tests/testthat")
