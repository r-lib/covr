local_shiny_tracing_state <- function(env = parent.frame()) {
  shiny_ns <- asNamespace("shiny")
  parallel_ns <- asNamespace("parallel")
  source_utf8 <- shiny_ns$sourceUTF8
  mcfork <- parallel_ns$mcfork
  mcexit <- parallel_ns$mcexit
  event <- packageEvent("shiny", "onLoad")
  hooks <- getHook(event)

  withr::defer(
    {
      lapply(rev(the$shiny_replacements), reset)
      the$shiny_replacements <- list()
      the$shiny_app_dir <- NULL
      the$shiny_trace_dir <- NULL
      clear_counters()
      the$shiny_trace_registered <- NULL
      replace_binding("shiny", "sourceUTF8", source_utf8)
      replace_binding("parallel", "mcfork", mcfork)
      replace_binding("parallel", "mcexit", mcexit)
      setHook(event, hooks, "replace")
    },
    envir = env
  )
}
