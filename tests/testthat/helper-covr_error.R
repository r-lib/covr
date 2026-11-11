covr_error_for <- function(lines, prompt = TRUE, frame = parent.frame()) {
  td <- withr::local_tempdir(.local_envir = frame)
  writeLines(
    c(if (prompt) c("header", ">"), lines),
    file.path(td, "x.Rout.fail")
  )
  err <- tryCatch(show_failures(td), covr_error = function(e) e)
  err$file <- "x.Rout.fail"
  err
}
