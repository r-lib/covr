set_makevars <- function(envs, path = file.path("~", ".R", "Makevars")) {
  if (length(envs) == 0) {
    return()
  }
  stopifnot(is.named(envs))

  old <- NULL
  if (file.exists(path)) {
    lines <- readLines(path)
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

  if (!identical(old, lines)) {
    file.rename(path, backup_name(path))
    writeLines(con = path, lines)
  }

  old
}

reset_makevars <- function(path = file.path("~", ".R", "Makevars")) {

  if (file.exists(backup_name(path))) {
    file.rename(backup_name(path), path)
  }
}

backup_name <- function(file) {
  paste0(file, ".bak")
}
