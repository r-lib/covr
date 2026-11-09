# An executable shell script called `name` in `dir` running `lines`
fake_tool <- function(dir, name, lines) {
  path <- file.path(dir, name)
  writeLines(c("#!/bin/sh", lines), path)
  Sys.chmod(path, "755")
  path
}
