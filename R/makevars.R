set_makevars <- function(envs) {
  if (length(envs) == 0) {
    return()
  }
  stopifnot(is.named(envs))

  makevars <- file.path("~", ".R", "Makevars")
  old <- NULL
  if (file.exists(makevars)) {
    lines <- readLines(makevars)
    old <- lines
    for (env in names(envs)) {
      loc <- grep(rex::rex(start, any_spaces, env, any_spaces, "="), lines)
      if (length(loc) == 0) {
        lines <- append(lines, paste(sep = "=", env, envs[env]))
      } else if(length(loc) == 1) {
        lines[loc] <- paste(sep = "=", env, envs[env])
      } else {
        stop("Multiple results for ", env, " found, something is wrong.", .call = FALSE)
      }
    }
  } else {
    lines <- paste(names(envs), envs, sep = "=")
  }

  dir.create(file.path("~", ".R"), showWarnings = FALSE, recursive = TRUE)
  writeLines(con = makevars, lines)

  old
}
reset_makevars <- function(lines) {
  makevars <- file.path("~", ".R", "Makevars")

  if (is.null(lines)) {
    unlink(makevars)
  } else {
    writeLines(con = makevars, lines)
  }
}
