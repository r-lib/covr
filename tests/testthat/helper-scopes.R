# Clear the traces and the traced scopes now and when the test ends
local_clean_traces <- function(env = parent.frame()) {
  clean <- function() {
    clear_counters()
    rm(list = ls(the$scopes, all.names = TRUE), envir = the$scopes)
  }
  clean()
  withr::defer(clean(), envir = env)
}
