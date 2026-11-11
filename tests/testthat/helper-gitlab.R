# The fixture is copied, as gitlab() writes the report into the package
local_gitlab_package <- function(frame = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = frame)
  file.copy(test_path("TestS4"), dir, recursive = TRUE)
  file.path(dir, "TestS4")
}
