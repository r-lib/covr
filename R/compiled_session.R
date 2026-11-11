# Coverage of the compiled code of a package loaded with pkgload::load_all(),
# measured in the current session by environment_coverage(), with_coverage()
# and file_coverage() (#605).
#
# The DLL load_all() built isn't instrumented, so an instrumented copy of the
# package is built in the session's temporary directory. Only the files that
# changed since the last build are copied and recompiled, and cargo only
# recompiles the Rust crates that changed in the copy's `target` directory.
# While the code runs, the namespace uses the instrumented DLL instead of its
# own, and unloading the instrumented DLL afterwards makes libgcov write its
# counts, which gcov then reads. The counts of Rust code are written before
# the DLL is unloaded, and read with llvm-cov (#749). The paths of the copy
# are then mapped back to the package.

# Starts measuring the compiled code of `env`, or returns `NULL` if `env`
# isn't the namespace of a package loaded by load_all() with compiled code. If
# gcov is missing or turned off, and the package has no Rust code that can be
# measured, this returns `NULL` unless `required`.
start_compiled_coverage <- function(env, required = FALSE) {
  if (!is.environment(env) || !isNamespace(env)) {
    return(NULL)
  }
  package <- getNamespaceName(env)
  if (!isNamespaceLoaded("pkgload") || !pkgload::is_dev_package(package)) {
    return(NULL)
  }
  # The DLLs loaded by `useDynLib()`, which can be named differently than the
  # package, e.g. data.table's `data_table`
  dlls <- names(env[[".__NAMESPACE__."]][["DLLs"]])
  if (!length(dlls)) {
    if (required) {
      covr_abort("Can't find compiled code loaded by {.pkg {package}}.")
    }
    return(NULL)
  }

  path <- normalize_path(getNamespaceInfo(env, "path"))
  build <- file.path(
    temp_dir(),
    "covr_compiled",
    paste0(package, "-", substr(digest::digest(path), 1, 8))
  )

  # Rust code is only instrumented if the tools to measure it are found, so
  # that build is kept apart, as make doesn't relink the DLL when only that
  # changes.
  rust_code <- length(rust_manifests(path)) > 0
  rust <- if (rust_code) {
    rust_coverage_setup(path, paste0(build, "-rust-llvm"))
  }
  if (!is.null(rust)) {
    build <- paste0(build, "-rust")
  }
  gcov <- has_gcov(required && is.null(rust))
  if (!gcov && is.null(rust)) {
    return(NULL)
  }

  dll_dir <- with_build_tools({
    if (!is.null(rust)) {
      rust <- add_llvm_profile_writer(rust)
    }
    build_instrumented_copy(path, build, rust)
  })
  if (!is.null(rust)) {
    rust <- rust_check_build(rust)
  }
  if (!gcov && is.null(rust)) {
    unlink(dll_dir, recursive = TRUE)
    return(NULL)
  }

  instrumented <- file.path(dll_dir, paste0(dlls, .Platform$dynlib.ext))
  file.copy(file.path(build, "src", basename(instrumented)), dll_dir)
  built <- file.exists(instrumented)
  if (!any(built)) {
    unlink(dll_dir, recursive = TRUE)
    if (required) {
      covr_abort(
        "Can't find the DLLs {.val {dlls}} in the build of {.pkg {package}}."
      )
    }
    return(NULL)
  }

  state <- new.env(parent = emptyenv())
  state$env <- env
  state$package <- package
  state$path <- path
  state$build <- build
  state$dll_dir <- dll_dir
  state$gcov <- gcov
  state$rust <- rust
  state$rust_code <- rust_code
  state$dlls <- character()
  state$original <- character()
  state$instrumented <- character()
  state$swapped <- TRUE
  if (!is.null(rust)) {
    unlink(list.files(rust$profiles, full.names = TRUE))
  }
  # Record each swapped DLL, so a failure restores the ones already swapped.
  # The Rust profiler runtime reads where to write its counts when the DLL is
  # loaded.
  tryCatch(
    withr::with_envvar(
      rust$env,
      for (i in which(built)) {
        original <- getNamespaceInfo(env, "DLLs")[[dlls[[i]]]][["path"]]
        swap_namespace_dll(env, dlls[[i]], original, instrumented[[i]])
        state$dlls <- c(state$dlls, dlls[[i]])
        state$original <- c(state$original, original)
        state$instrumented <- c(state$instrumented, instrumented[[i]])
      }
    ),
    error = function(e) {
      stop_compiled_coverage(state)
      stop(e)
    }
  )
  state
}

# gcov is looked up with the build tools on the `PATH`, as Rtools' gcov isn't
# on it by default on Windows. `options(covr.gcov = "")` turns it off.
has_gcov <- function(required) {
  gcov_path <- getOption("covr.gcov", find_gcov())
  if (!is.na(gcov_path)) {
    return(nzchar(gcov_path))
  }
  if (required) {
    covr_abort(c(
      "Can't find gcov.",
      i = "Set its path with {.code options(covr.gcov = )}."
    ))
  }
  FALSE
}

# Restores the namespace's own DLL. Unloading the instrumented DLL writes its
# counts to the `.gcda` files of the copy, and those of its Rust code are
# written just before.
stop_compiled_coverage <- function(state) {
  if (is.null(state) || !isTRUE(state$swapped)) {
    return(invisible())
  }
  state$swapped <- FALSE
  for (i in seq_along(state$dlls)) {
    swap_namespace_dll(
      state$env,
      state$dlls[[i]],
      state$instrumented[[i]],
      state$original[[i]]
    )
  }
  unlink(state$dll_dir, recursive = TRUE)
  invisible()
}

# Adds the compiled code coverage measured since start_compiled_coverage() to
# `coverage`.
add_compiled_coverage <- function(coverage, state) {
  if (is.null(state)) {
    return(coverage)
  }
  stop_compiled_coverage(state)

  res <- if (state$gcov) {
    with_build_tools(run_gcov(state$build, quiet = TRUE, clean = TRUE))
  }
  unlink(gcov_counts(state$build))
  if (!is.null(state$rust)) {
    objects <- file.path(state$build, "src", basename(state$instrumented))
    res <- c(res, run_llvm_cov(state$rust, state$build, objects))
    unlink(list.files(state$rust$profiles, full.names = TRUE))
  }
  if (state$rust_code) {
    res <- drop_rust_dependencies(
      res,
      roots = c(state$build, getOption("covr.gcov_additional_paths", NULL))
    )
  }
  res <- relocate_line_coverages(res, state$build, state$path)

  # Append rather than assign by name: a header has an entry for every object
  # that includes it, and these are added up later.
  attrs <- attributes(coverage)
  coverage <- c(unclass(coverage), res)
  attrs$names <- names(coverage)
  attributes(coverage) <- attrs
  coverage
}

with_build_tools <- function(code) {
  pkgbuild::with_build_tools(code, required = FALSE)
}

gcov_counts <- function(path) {
  list.files(
    file.path(path, "src"),
    pattern = rex::rex(".gcda", end),
    full.names = TRUE,
    recursive = TRUE
  )
}

# Updates the instrumented copy of the package at `path` in `build` and
# compiles it, with the instrumentation of Rust code set up by
# rust_coverage_setup() in `rust`. Returns an empty directory to copy its DLLs
# to before loading them, so they can be rebuilt while they are loaded on
# Windows.
build_instrumented_copy <- function(path, build, rust = NULL) {
  changed <- sync_package_copy(path, build)

  # Objects aren't rebuilt when a header they include changes, so rebuild
  # everything if anything other than a source file changed. cargo rebuilds
  # the Rust code it needs to itself.
  build_inputs <- grepl("^(src|inst/include)/", changed) |
    changed == "DESCRIPTION"
  if (any(build_inputs & !is_compiled_source(changed))) {
    unlink(build_outputs(build))
  }
  unlink(gcov_counts(build))

  # Checking that the DLL is up to date takes a while for some packages, so
  # skip it if the last build succeeded and only files that can't affect it
  # changed since.
  built <- paste0(build, ".built")
  affects_dll <- !grepl("^(R|tests|man|vignettes)/", changed)
  if (file.exists(built) && !any(affects_dll)) {
    return(temp_dir_create("covr_dll"))
  }
  unlink(built)
  withr::with_makevars(
    add_rust_flags(getOption("covr.flags"), rust),
    assignment = "+=",
    withr::with_envvar(
      rust$build_env,
      pkgbuild::compile_dll(build, quiet = TRUE)
    )
  )
  file.create(built)

  temp_dir_create("covr_dll")
}

temp_dir_create <- function(pattern) {
  dir <- temp_file(pattern)
  dir.create(dir)
  dir
}

is_compiled_source <- function(x) {
  grepl("[.](c|cc|cpp|cxx|c[+][+]|f|f90|f95|m|mm|rs)$", x, ignore.case = TRUE)
}

is_compiled_file <- function(x) {
  is_compiled_source(x) | grepl("[.](h|hh|hpp|hxx)$", x, ignore.case = TRUE)
}

# Files written by building the package, which aren't copied. In packages with
# Rust code (`rust`), the files in the directories of its dependencies and
# cargo's build output aren't: cargo rebuilds what it needs, but not the
# libraries its build scripts wrote, and vendored crates can include
# libraries.
is_build_output <- function(x, rust = FALSE) {
  output <- grepl("^src/", x) &
    (grepl(
      rex::rex(
        ".",
        or("o", "so", "dll", "dylib", "sl", "a", "mod", "gcda", "gcno", "gcov"),
        end
      ),
      x
    ) |
      grepl(rex::rex(".gcov.json.gz", end), x) |
      grepl("(^|/)symbols[.]rds$", x))
  if (rust) {
    output <- output & !in_rust_dependency_dir(x)
  }
  output
}

build_outputs <- function(build) {
  files <- file.path(
    "src",
    list.files(file.path(build, "src"), all.files = TRUE, recursive = TRUE)
  )
  rust <- length(rust_manifests(build)) > 0
  file.path(build, files[is_build_output(files, rust)])
}

# The files of the package at `path` that would be in its source tarball,
# relative to `path`: hidden top-level files and those matching
# `.Rbuildignore` are left out, as are build outputs in `src/` and cache
# directories, e.g. cargo's `target` directories, as the copy is built on its
# own.
package_copy_files <- function(path) {
  ignore <- c("^[.]", read_rbuildignore(path))
  rust <- length(rust_manifests(path)) > 0
  ignored <- function(x) {
    Reduce(
      `|`,
      lapply(ignore, grepl, x = x, perl = TRUE, ignore.case = TRUE),
      is_build_output(x, rust)
    )
  }

  list_dir <- function(dir) {
    entries <- list.files(
      file.path(path, dir),
      all.files = TRUE,
      no.. = TRUE
    )
    if (nzchar(dir)) {
      entries <- file.path(dir, entries)
    }
    entries <- entries[!ignored(entries)]
    is_dir <- dir.exists(file.path(path, entries))
    is_cache <- is_dir & file.exists(file.path(path, entries, "CACHEDIR.TAG"))
    c(entries[!is_dir], unlist(lapply(entries[is_dir & !is_cache], list_dir)))
  }
  list_dir("")
}

read_rbuildignore <- function(path) {
  file <- file.path(path, ".Rbuildignore")
  if (!file.exists(file)) {
    return(character())
  }
  patterns <- trimws(readLines(file, warn = FALSE))
  patterns[nzchar(patterns) & !grepl("^#", patterns)]
}

# Makes `build` a copy of the package at `path`, copying only the files that
# are missing or changed, so that only changed sources are recompiled. Copies
# get the current time, so they are always newer than their objects. Files
# copied by a previous call that are no longer in the package are removed,
# but not the files the build creates. Returns the changed files.
sync_package_copy <- function(path, build) {
  files <- package_copy_files(path)
  manifest <- paste0(build, ".rds")
  if (file.exists(manifest)) {
    unlink(file.path(build, setdiff(readRDS(manifest), files)))
  }
  dir.create(build, recursive = TRUE, showWarnings = FALSE)
  saveRDS(files, manifest)

  from <- file.path(path, files)
  to <- file.path(build, files)
  from_info <- file.info(from)
  to_info <- file.info(to)
  changed <- is.na(to_info$size) |
    from_info$size != to_info$size |
    from_info$mtime > to_info$mtime

  for (dir in unique(dirname(to[changed]))) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  file.copy(from[changed], to[changed], overwrite = TRUE)
  files[changed]
}

# Replaces the DLL `name` at `from` with the one at `to` in the namespace
# `env`: its native routine objects and DLL info, and string lookups such as
# `.Call("fun", PACKAGE = "name")`, which find the only DLL of that name.
swap_namespace_dll <- function(env, name, from, to) {
  bindings <- dll_bindings(env, name)
  # Run finalizers that may call into the old DLL while it is still loaded
  gc()
  # Rust code's counts aren't written when unloading a DLL that stays loaded
  write_llvm_profile(from)
  dyn.unload(from)
  dll <- tryCatch(
    load_namespace_dll(env, to),
    error = function(e) {
      # Put the old DLL back, so the namespace keeps working
      use_namespace_dll(env, name, bindings, load_namespace_dll(env, from))
      stop(e)
    }
  )
  use_namespace_dll(env, name, bindings, dll)
}

# Loads a DLL of the namespace `env`. Loading runs its `R_init_<name>()`,
# which can assign to the namespace (e.g. Rcpp's `.rcpp_cache`), so the
# bindings that are locked once the namespace is loaded are unlocked meanwhile.
load_namespace_dll <- function(env, path) {
  unlock <- get("unlockBinding") # to fool R CMD check
  lock <- get("lockBinding")
  bindings <- ls(env, all.names = TRUE)
  locked <- bindings[vlapply(bindings, bindingIsLocked, env = env)]
  for (binding in locked) {
    unlock(binding, env)
  }
  on.exit(
    for (binding in locked) {
      lock(binding, env)
    }
  )
  dyn.load(path)
}

# Points the `bindings` of the DLL `name` in the namespace `env` at `dll`
use_namespace_dll <- function(env, name, bindings, dll) {
  package <- getNamespaceName(env)
  routines <- getDLLRegisteredRoutines(dll)
  for (binding in bindings) {
    old <- get(binding, envir = env, inherits = FALSE)
    new <- if (inherits(old, "DLLInfo")) {
      dll
    } else {
      native_routine(old, dll, routines)
    }
    replace_binding(package, binding, new)
  }
  dlls <- getNamespaceInfo(env, "DLLs")
  dlls[[name]] <- dll
  setNamespaceInfo(env, "DLLs", dlls)
  invisible(dll)
}

# The bindings in the namespace `env` of the native routines that
# `useDynLib()` assigned from the loaded DLL `name`, and of the DLL object of
# `useDynLib(x = name)`. The namespace's bindings are inspected rather than
# its NAMESPACE file, as parsing it would evaluate its `if ()` directives.
dll_bindings <- function(env, name) {
  dll <- getNamespaceInfo(env, "DLLs")[[name]]
  is_dll_binding <- function(binding) {
    if (bindingIsActive(binding, env) || is_unforced_promise(env, binding)) {
      return(FALSE)
    }
    x <- get(binding, envir = env, inherits = FALSE)
    if (inherits(x, "DLLInfo")) {
      return(identical(x[["name"]], name))
    }
    if (!inherits(x, "NativeSymbolInfo")) {
      return(FALSE)
    }
    # R < 4.1 doesn't record the DLL of routines that aren't registered
    if (!is.null(x$dll)) {
      return(identical(x$dll[["name"]], name))
    }
    !is.null(tryCatch(
      getNativeSymbolInfo(x$name, dll),
      error = function(e) NULL
    ))
  }
  bindings <- ls(env, all.names = TRUE)
  bindings[vlapply(bindings, is_dll_binding)]
}

native_routine <- function(old, dll, routines) {
  types <- c(
    CallRoutine = ".Call",
    CRoutine = ".C",
    FortranRoutine = ".Fortran",
    ExternalRoutine = ".External"
  )
  type <- types[intersect(class(old), names(types))]
  if (length(type)) {
    routine <- routines[[type[[1]]]][[old$name]]
    if (!is.null(routine)) {
      return(routine)
    }
  }
  getNativeSymbolInfo(old$name, dll)
}

# Maps the source files of compiled code coverage measured in the copy `from`
# to the package at `to`.
relocate_line_coverages <- function(x, from, to) {
  prefix <- paste0(from, "/")
  for (i in seq_along(x)) {
    srcfile <- attr(x[[i]]$srcref, "srcfile")
    if (startsWith(srcfile$filename, prefix)) {
      srcfile$filename <- file.path(
        to,
        substring(srcfile$filename, nchar(prefix) + 1)
      )
    }
  }
  names(x) <- vcapply(x, function(x) key(x$srcref))
  x
}

# Loads the package containing the compiled `files` with pkgload::load_all()
# for file_coverage(), returning its namespace.
load_compiled_package <- function(files) {
  if (!is_installed("pkgload")) {
    covr_abort(
      "{.fn file_coverage} requires {.pkg pkgload} for compiled code."
    )
  }
  roots <- unique(lapply(dirname(files), package_root))
  if (length(roots) != 1 || is.null(roots[[1]])) {
    covr_abort(c(
      "Compiled {.arg source_files} must be in a single package.",
      i = "Can't find one package for {.file {files}}."
    ))
  }
  pkgload::load_all(roots[[1]], quiet = TRUE)$env
}
