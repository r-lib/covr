#' Measure the coverage of installed packages, however their code is run
#'
#' @description
#' `instrument_packages()` instruments packages installed in a library, so
#' that every R process that loads one of them counts the code it runs and
#' saves the counts in a trace directory when it exits. `trace_coverage()`
#' reads the counts saved there into a single [coverage] object, and
#' `uninstrument_packages()` restores the packages. `local_instrumented_packages()`
#' instruments them until the calling function returns.
#'
#' This is the workflow [package_coverage()] uses, split up so that the code
#' can be run by anything: the tests of several packages, a test runner or
#' build system, or a script that starts many R processes. The traces of
#' several packages, and of processes that load more than one of them, are
#' kept apart, so one directory can collect the coverage of a set of packages,
#' e.g. those of a monorepo.
#'
#' @section Requirements:
#' * The packages must be installed with their source references, e.g. with
#'   `R CMD INSTALL --with-keep.source`. File names in the coverage are those
#'   of the source the packages were installed from.
#' * covr must be installed in a library that the R processes use, as the
#'   instrumented packages call it when they are loaded.
#' * Processes must exit normally to save their counts; processes that are
#'   killed lose them, and `trace_coverage()` warns (with class
#'   `covr_unsaved_trace`) about the processes that loaded an instrumented
#'   package but didn't save their counts.
#'
#' The R processes save their counts in the directory in the environment
#' variable `COVR_TRACE_DIR`, or if it is not set, in `trace_dir`. With
#' `trace_dir = NULL` they only save them if `COVR_TRACE_DIR` is set, so
#' packages can be instrumented once, e.g. when they are built, and their
#' coverage measured whenever it is set. Compiled code isn't instrumented.
#'
#' The coverage includes the instrumented packages that no process loaded,
#' with none of their code covered, if they were instrumented with a
#' `trace_dir`, or if `trace_coverage()` is given their `lib`. This needs
#' them to be instrumented when they are installed, which works for most
#' packages (see the value of `instrument_packages()`).
#'
#' The options that change what is measured, such as
#' [covr.branch_coverage] and [covr.record_tests], and
#' `covr.fix_parallel_mcexit` (see [package_coverage()]), are read when
#' the packages are instrumented. Unlike [package_coverage()],
#' `instrument_packages()` doesn't set the environment variable `R_COVR`, so
#' [in_covr()] is `FALSE` in the processes unless they set it.
#'
#' @section Example workflow:
#' ```r
#' lib <- "lib"
#' # Install the packages with their source references, e.g.
#' #   R CMD INSTALL --with-keep.source -l lib pkgA pkgB
#' instrument_packages(c("pkgA", "pkgB"), lib, trace_dir = "traces")
#'
#' # Then run anything that loads them from `lib`, e.g.
#' #   R_LIBS=lib Rscript -e 'testthat::test_dir("pkgA/tests/testthat",
#' #     package = "pkgA", load_package = "installed")'
#'
#' cov <- trace_coverage("traces")
#' lcov(cov, "lcov.info")
#'
#' uninstrument_packages(c("pkgA", "pkgB"), lib)
#' ```
#'
#' @param packages The names of the packages to instrument, installed in
#'   `lib`.
#' @param lib The library the packages are installed in. For
#'   `trace_coverage()`, a library of instrumented packages, whose packages
#'   that no process loaded are included with no coverage, or `NULL`.
#' @param trace_dir The directory the counts are saved in, if the environment
#'   variable `COVR_TRACE_DIR` is not set when an R process loads an
#'   instrumented package. It is created if it doesn't exist. `NULL` to only
#'   save the counts when `COVR_TRACE_DIR` is set. For `trace_coverage()`, the
#'   directories the counts were saved in, e.g. one for each shard of a CI
#'   run; by default `COVR_TRACE_DIR`, or the default `trace_dir` of the first
#'   library in [.libPaths()].
#' @param cores The number of packages to instrument at once, each in its own
#'   R process.
#' @return `instrument_packages()` and `local_instrumented_packages()` return
#'   a logical vector, invisibly, named by package: `TRUE` for a package that
#'   was instrumented when it was installed, and `FALSE` for one that is
#'   instrumented each time it is loaded, e.g. because it stores functions in
#'   `R/sysdata.rda`. `uninstrument_packages()` returns `packages`, invisibly.
#' @seealso [package_coverage()], which runs the tests of one or more packages
#'   and measures their coverage in one call.
#' @family instrumented packages
#' @export
instrument_packages <- function(
  packages,
  lib = .libPaths()[[1]],
  trace_dir = file.path(lib, "covr_traces"),
  cores = getOption("Ncpus", 1L)
) {
  check_packages(packages)
  if (!is_string(lib) || !dir.exists(lib)) {
    covr_abort("Can't find the library {.path {lib}}.")
  }
  if (!is.null(trace_dir) && !is_string(trace_dir)) {
    covr_abort("{.arg trace_dir} must be a single path or {.code NULL}.")
  }
  installed <- file.exists(file.path(lib, packages, "Meta", "package.rds"))
  if (!all(installed)) {
    covr_abort(
      "Can't find {.pkg {packages[!installed]}} in the library {.path {lib}}."
    )
  }
  lib <- normalize_path(lib)
  no_code <- !file.exists(loader(lib, packages))
  if (any(no_code)) {
    covr_abort(
      "{.pkg {packages[no_code]}} {?has/have} no R code to instrument."
    )
  }
  done <- file.exists(loader_original(lib, packages))
  if (any(done)) {
    covr_abort(c(
      "{.pkg {packages[done]}} {?is/are} already instrumented.",
      i = "Use {.fn uninstrument_packages} first."
    ))
  }
  if (!is.null(trace_dir)) {
    dir.create(trace_dir, recursive = TRUE, showWarnings = FALSE)
    if (!dir.exists(trace_dir)) {
      covr_abort("Can't create the trace directory {.path {trace_dir}}.")
    }
    trace_dir <- normalize_path(trace_dir)
  }

  # Restore the packages if one fails
  backed_up <- character()
  done <- FALSE
  on.exit(if (!done) uninstrument_packages(backed_up, lib), add = TRUE)
  for (pkg in packages) {
    if (!file.copy(loader(lib, pkg), loader_original(lib, pkg))) {
      covr_abort("Can't back up the loader script of {.pkg {pkg}}.")
    }
    backed_up <- c(backed_up, pkg)
  }
  pkgs <- lapply(packages, function(pkg) {
    desc <- read_description(file.path(lib, pkg, "DESCRIPTION"))
    desc$path <- file.path(lib, pkg)
    desc
  })
  counters_files <- instrument_library_packages(
    pkgs,
    lib,
    trace_dir,
    ahead_of_time = isTRUE(install_instrument()),
    cores = cores
  )
  # The packages that no process loads are in the coverage, with none of their
  # code covered
  if (!is.null(trace_dir)) {
    for (i in seq_along(packages)) {
      if (is.null(counters_files[[i]])) {
        # The baseline of an earlier instrumentation of the package
        unlink(baseline_trace_file(trace_dir, packages[[i]]), expand = FALSE)
      } else {
        save_baseline_trace(counters_files[[i]], trace_dir, packages[[i]])
      }
    }
  }
  done <- TRUE
  invisible(stats::setNames(!vlapply(counters_files, is.null), packages))
}

# A trace with no counts of the counters `file` of the package `pkg`,
# instrumented after it was installed, in the trace `directory`. There is one
# for each package, which replaces that of an earlier instrumentation of the
# package into the directory, whose code can have changed since.
save_baseline_trace <- function(file, directory, pkg) {
  counters_file <- stage_counters_file(file, directory)
  if (counters_file == file) {
    return(invisible())
  }
  tmp <- temp_file(".covr_tmp_", tmpdir = directory)
  on.exit(unlink(tmp, force = TRUE, expand = FALSE), add = TRUE)
  saveRDS(
    structure(
      list(
        counters_file = counters_file,
        counts = numeric(),
        counters = list()
      ),
      class = "covr_counts"
    ),
    tmp
  )
  file.rename(tmp, baseline_trace_file(directory, pkg))
  invisible()
}

baseline_trace_file <- function(directory, pkg) {
  file.path(directory, paste0("covr_trace_baseline_", pkg))
}

#' @rdname instrument_packages
#' @export
uninstrument_packages <- function(packages, lib = .libPaths()[[1]]) {
  check_packages(packages, empty = TRUE)
  lib <- normalize_path(lib)
  for (pkg in packages) {
    original <- loader_original(lib, pkg)
    if (!file.exists(original)) {
      next
    }
    # The running R may still read the instrumented code of a namespace it has
    # loaded, through promises to read it when it is first used, so these are
    # read before it is removed. Active bindings are left alone, as reading
    # them runs code, and a binding that fails to read doesn't stop the
    # package from being restored.
    if (pkg %in% loadedNamespaces()) {
      ns <- asNamespace(pkg)
      if (
        identical(normalize_path(dirname(getNamespaceInfo(ns, "path"))), lib)
      ) {
        names <- ls(ns, all.names = TRUE)
        for (name in names[!vlapply(names, bindingIsActive, env = ns)]) {
          try(get(name, envir = ns, inherits = FALSE), silent = TRUE)
        }
        keep_counters_file(pkg, instrumented_counters_file(pkg, lib))
      }
    }
    if (!file.copy(original, loader(lib, pkg), overwrite = TRUE)) {
      covr_abort(c(
        "Can't restore the loader script of {.pkg {pkg}}.",
        i = "Its backup is {.path {original}}."
      ))
    }
    unlink(
      c(
        paste0(instrumented_db_base(pkg, lib), c(".rdb", ".rdx")),
        instrumented_counters_file(pkg, lib),
        original
      ),
      expand = FALSE
    )
    remove_covr_hooks(pkg)
  }
  invisible(packages)
}

# The loader script of an instrumented package sets onLoad hooks (see
# `add_hooks()`) that stay in the session that loaded it, and would trace the
# package and restore the deleted counters if it were loaded again after it is
# restored, so they are removed. Other hooks are kept.
remove_covr_hooks <- function(pkg) {
  event <- packageEvent(pkg, "onLoad")
  hooks <- getHook(event)
  covr <- vlapply(hooks, function(hook) isTRUE(attr(hook, "covr_hook")))
  if (any(covr)) {
    setHook(event, hooks[!covr], "replace")
  }
}

# This session saves the trace of the loaded package `pkg` when it exits,
# which refers to the counters `file` it restored (see `process_trace()`), so
# a copy of them is kept until then if they are removed.
keep_counters_file <- function(pkg, file) {
  entry <- get0(scope_id(pkg), envir = the$scopes, inherits = FALSE)
  if (
    is.null(entry$counters_file) ||
      !identical(normalize_path(entry$counters_file), normalize_path(file))
  ) {
    return(invisible())
  }
  copy <- temp_file("covr_counters_", fileext = ".rds")
  if (file.copy(file, copy)) {
    entry$counters_file <- copy
  }
  invisible()
}

#' @rdname instrument_packages
#' @param .local_envir The environment whose exit restores the packages.
#' @export
local_instrumented_packages <- function(
  packages,
  lib = .libPaths()[[1]],
  trace_dir = file.path(lib, "covr_traces"),
  cores = getOption("Ncpus", 1L),
  .local_envir = parent.frame()
) {
  lib <- normalize_path(lib)
  res <- instrument_packages(packages, lib, trace_dir, cores = cores)
  withr::defer(uninstrument_packages(packages, lib), envir = .local_envir)
  invisible(res)
}

#' @rdname instrument_packages
#' @param paths The source directories of the packages, named by package, e.g.
#'   `c(pkgA = "src/pkgA")`. By default they are the directories the packages
#'   were installed from, as recorded in their source references. Give them
#'   if the packages were installed from somewhere else, e.g. a copy of the
#'   source in a sandbox, and the file names of their code are changed to be
#'   in these. Packages without coverage are ignored.
#'
#'   Or a function of the file names (as recorded when the packages were
#'   installed) and the name of their package, which returns the full paths
#'   of the files in the source, e.g. for a build that copied files from other
#'   directories into `R/`.
#' @param relative_path Whether file names are relative to the source
#'   directory of the package, or for several packages, of the directory that
#'   contains all of them, or absolute paths. If a string, file names are
#'   relative to that directory.
#' @inheritParams package_coverage
#' @param packages For `trace_coverage()`, the names of the packages to
#'   include, or `NULL` for all those with traces in `trace_dir` or
#'   instrumented in `lib`.
#' @return `trace_coverage()` returns a [coverage] object with the coverage of
#'   all the instrumented packages whose counts are in `trace_dir`. Files of
#'   the packages that the `.covrignore` file (see [exclusions]) in their source
#'   directory lists are left out. If there are none, it warns (with class
#'   `covr_no_coverage`) and returns a coverage object without any.
#' @export
trace_coverage <- function(
  trace_dir = NULL,
  lib = NULL,
  paths = NULL,
  relative_path = TRUE,
  line_exclusions = NULL,
  function_exclusions = NULL,
  packages = NULL
) {
  trace_dir <- trace_dir %||%
    trace_dir_setting(file.path(.libPaths()[[1]], "covr_traces"))
  if (
    !is.character(trace_dir) ||
      length(trace_dir) == 0 ||
      anyNA(trace_dir) ||
      !all(dir.exists(trace_dir))
  ) {
    covr_abort("Can't find the trace directory {.path {trace_dir}}.")
  }
  if (!is.null(lib) && (!is_string(lib) || !dir.exists(lib))) {
    covr_abort("Can't find the library {.path {lib}}.")
  }
  if (!is.null(packages)) {
    check_packages(packages)
  }
  if (
    !is.null(paths) &&
      !is.function(paths) &&
      (!is.character(paths) ||
        anyNA(paths) ||
        any(!nzchar(paths)) ||
        is.null(names(paths)) ||
        anyNA(names(paths)) ||
        any(!nzchar(names(paths))))
  ) {
    covr_abort(
      "{.arg paths} must be a character vector named by package, or a function."
    )
  }
  dirs <- trace_dir
  # The same directory given twice would count its traces twice
  trace_dir <- unique(sub("(.)/+$", "\\1", normalize_path(trace_dir)))
  traces <- merge_coverage(c(
    list.files(trace_dir, pattern = "^covr_trace_", full.names = TRUE),
    if (!is.null(lib)) instrumented_counters_files(lib, packages)
  ))
  for (dir in trace_dir) {
    warn_unsaved_traces(
      dir,
      "loaded an instrumented package",
      "Did they exit normally?"
    )
  }
  pkg_names <- traced_packages(traces)
  if (!is.null(packages)) {
    pkg_names <- intersect(pkg_names, packages)
    keys <- names(traces) %||% character()
    scoped <- grepl("/", keys, fixed = TRUE)
    traces <- traces[!scoped | sub("/.*$", "", keys) %in% pkg_names]
    # The decisions of branch coverage too
    branches <- traces[["branches"]]
    if (!is.null(branches)) {
      branch_list <- as.list(branches, all.names = TRUE)
      keep <- sub("/.*$", "", names(branch_list)) %in% pkg_names
      traces[["branches"]] <- if (is.environment(branches)) {
        list2env(branch_list[keep], parent = emptyenv())
      } else {
        branches[keep]
      }
    }
  }
  if (length(pkg_names) == 0) {
    covr_warn(
      "Can't find the coverage of any instrumented package in {.path {dirs}}.",
      class = "covr_no_coverage"
    )
    return(as_coverage(list()))
  }
  pkgs <- lapply(pkg_names, function(name) {
    path <- if (is.character(paths) && name %in% names(paths)) paths[[name]]
    list(package = name, path = path, ignore = TRUE)
  })
  pkgs <- trace_source_paths(traces, pkgs, paths = paths)
  coverage_of_packages(
    traces,
    pkgs,
    root = coverage_root(relative_path, pkgs),
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions
  )
}

# The counters of the `packages` (or all the packages) in the library `lib`
# that were instrumented after they were installed.
instrumented_counters_files <- function(lib, packages = NULL) {
  pkgs <- packages %||% list.files(lib)
  files <- instrumented_counters_file(pkgs, lib)
  files[file.exists(files)]
}

check_packages <- function(packages, empty = FALSE) {
  if (
    !is.character(packages) ||
      (!empty && length(packages) == 0) ||
      anyNA(packages)
  ) {
    covr_abort("{.arg packages} must be a character vector of package names.")
  }
  if (anyDuplicated(packages)) {
    covr_abort(
      "{.arg packages} has {.pkg {unique(packages[duplicated(packages)])}} more than once."
    )
  }
}

loader <- function(lib, pkg) {
  file.path(lib, pkg, "R", pkg)
}

# The loader script of the package as it was before it was instrumented.
loader_original <- function(lib, pkg) {
  paste0(loader(lib, pkg), ".covr-orig")
}

# Instrument the packages `pkgs` (from `as_package()`, or their DESCRIPTION
# with `path` set) installed in `lib`: ahead of time if they can be and
# `ahead_of_time` (see `instrument_package()`), and with the hooks that trace
# them when they are loaded and save their traces (see `add_hooks()`). The
# counts are saved in `trace_dir`, unless `COVR_TRACE_DIR` is set. The hooks are
# only added once all are instrumented, as instrumenting a package loads the
# packages it imports, which would save their traces. Returns the counters
# file of each package, or `NULL` for one that is instrumented when it is
# loaded.
#
# Each package is instrumented by its own R process, which are independent, so
# up to `cores` of them run at once, the largest first, so that the last ones
# to start are the quickest.
instrument_library_packages <- function(
  pkgs,
  lib,
  trace_dir = lib,
  ahead_of_time = TRUE,
  cores = getOption("Ncpus", 1L)
) {
  ahead_of_time <- rep_len(ahead_of_time, length(pkgs))
  cores <- suppressWarnings(as.integer(cores))
  if (length(cores) != 1L || is.na(cores) || cores < 1L) {
    cores <- 1L
  }
  full_traversal <- lapply(pkgs, function(pkg) {
    getOption(
      "covr.full_traversal",
      # DESCRIPTION field names are lowercased by `read_description()`
      isTRUE(as.logical(pkg[[tolower("Config/covr/full_traversal")]]))
    )
  })
  todo <- which(ahead_of_time)
  sizes <- vapply(
    pkgs[todo],
    function(pkg) {
      file.size(file.path(lib, pkg$package, "R", paste0(pkg$package, ".rdb")))
    },
    numeric(1)
  )
  todo <- todo[order(sizes, decreasing = TRUE)]
  counters_files <- vector("list", length(pkgs))
  # The jobs that are running, or whose process exited (they have its
  # `status`) but that aren't finished, by package. If an error or an
  # interrupt stops the loop, they're cancelled.
  jobs <- list()
  on.exit(cancel_instrument(jobs), add = TRUE)
  while (length(todo) || length(jobs)) {
    while (length(jobs) < cores && length(todo)) {
      i <- todo[[1]]
      todo <- todo[-1]
      job <- start_instrument(
        pkgs[[i]],
        lib,
        full_traversal = full_traversal[[i]]
      )
      job$index <- i
      jobs[[pkgs[[i]]$package]] <- job
    }
    for (name in names(jobs)) {
      # The status of a process that is still running is `NA`
      status <- process_status(jobs[[name]]$pid, wait = length(jobs) == 1L)
      if (!is.na(status)) {
        jobs[[name]]$status <- status
      }
    }
    exited <- names(jobs)[!vlapply(jobs, function(job) is.null(job$status))]
    if (!length(exited)) {
      Sys.sleep(0.05)
      next
    }
    for (name in exited) {
      job <- jobs[[name]]
      jobs[[name]] <- NULL
      file <- finish_instrument(job, job$status)
      if (!is.null(file)) {
        counters_files[[job$index]] <- file
      }
    }
  }
  # One package with the fix saves the traces of all the instrumented packages
  # in forked workers (see `fix_mcexit()`)
  for (i in seq_along(pkgs)) {
    add_hooks(
      pkgs[[i]]$package,
      lib,
      fix_mcexit = should_enable_parallel_mcexit_fix(pkgs[[i]]),
      full_traversal = full_traversal[[i]],
      counters_file = counters_files[[i]],
      trace_dir = trace_dir
    )
  }
  counters_files
}

# The packages with traces in `traces`, in alphabetical order, whose keys start
# with the name of their package (see `scope_prefix()`). Other scopes, such as
# that of a Shiny app, aren't packages.
traced_packages <- function(traces) {
  keys <- names(traces) %||% character()
  keys <- keys[grepl("/", keys, fixed = TRUE)]
  pkgs <- unique(sub("/.*$", "", keys))
  sort(pkgs[grepl("^[[:alpha:]][[:alnum:].]*$", pkgs)], method = "radix")
}

package_traces <- function(traces, package) {
  keys <- names(traces) %||% character()
  traces[startsWith(keys, paste0(package, "/"))]
}

# Prefix the keys of the compiled traces `x` of the files of `pkg` with its
# name, like those of its R code, as files of different packages can have the
# same name (see `unscope_keys()`).
scope_compiled <- function(x, pkg) {
  if (!length(x)) {
    return(x)
  }
  files <- vcapply(x, function(trace) {
    get_source_filename(trace$srcref, full.names = TRUE)
  })
  inside <- path_in_roots(files, pkg$path)
  names(x)[inside] <- paste0(pkg$package, "/", names(x)[inside])
  x
}

# Set the `path` of the packages in `pkgs` that have none to the directory of
# the source they were installed from, as recorded in the source references of
# their traces. With `paths` (see `trace_coverage()`), the file names of the
# traces are changed: of the packages that have a `path`, from that directory
# to their `path`, or with `paths` if it is a function, after which the `path`
# of each package is the directory that contains its files, or the parent of
# their `R` directory. Only the files in the directory the package was
# installed from are changed: the namespace can have functions with srcrefs
# from other packages, e.g. re-exported functions.
trace_source_paths <- function(traces, pkgs, paths = NULL) {
  # Decisions of branch coverage can have srcfiles of their own
  branches <- as.list(traces[["branches"]])
  lapply(pkgs, function(pkg) {
    if (!is.null(pkg$path) && is.null(paths)) {
      pkg$path <- absolute_path(pkg$path)
      return(pkg)
    }
    pkg_traces <- package_traces(traces, pkg$package)
    srcfile_traces <- c(pkg_traces, package_traces(branches, pkg$package))
    installed_from <- installed_source_path(pkg_traces)
    if (is.null(installed_from) && (is.null(pkg$path) || is.function(paths))) {
      covr_abort(c(
        "Can't find source references in the installed package {.pkg {pkg$package}}.",
        i = "Install it with {.code R CMD INSTALL --with-keep.source}."
      ))
    }
    if (is.function(paths)) {
      mapped <- new.env(parent = emptyenv())
      from <- paste0(installed_from, "/")
      move_srcfiles(srcfile_traces, function(x) {
        inside <- startsWith(x, from) %in% TRUE
        if (any(inside)) {
          x[inside] <- map_paths(paths, x[inside], pkg$package)
          mapped$files <- c(mapped$files, x[inside])
        }
        x
      })
      dir <- common_path(unique(dirname(mapped$files)))
      if (is.null(dir)) {
        covr_abort(
          "The files that {.arg paths} gives for {.pkg {pkg$package}} aren't in one directory."
        )
      }
      pkg$path <- if (basename(dir) == "R") dirname(dir) else dir
      return(pkg)
    }
    if (is.null(pkg$path)) {
      pkg$path <- installed_from
    } else {
      pkg$path <- absolute_path(pkg$path)
      if (!is.null(installed_from)) {
        move_srcfiles(srcfile_traces, move_directory(installed_from, pkg$path))
      }
    }
    pkg
  })
}

# The file names that the function `paths` gives for the `files` of the
# package `package`, as absolute paths.
map_paths <- function(paths, files, package) {
  res <- paths(files, package)
  if (!is.character(res) || length(res) != length(files) || anyNA(res)) {
    covr_abort(c(
      "{.arg paths} must return a file name for each of the files of {.pkg {package}}.",
      x = if (is.character(res) && length(res) == length(files)) {
        "It returned {.code NA} for some of them."
      } else {
        "It returned a {.cls {class(res)}} of length {length(res)} for {length(files)} file name{?s}."
      }
    ))
  }
  absolute_path(res)
}

# A function that changes file names in the directory `from` to be in `to`.
move_directory <- function(from, to) {
  from <- sub("/*$", "/", from)
  to <- sub("/*$", "/", to)
  function(x) {
    inside <- startsWith(x, from) %in% TRUE
    x[inside] <- paste0(to, substring(x[inside], nchar(from) + 1))
    x
  }
}

# Change the file names of the srcrefs of `traces` with `move`, a function of
# the file names. The srcfiles are environments, shared by the traces of a
# file. The srcfiles of an installed package are aliases of one srcfile with
# the lines of all its files, which start with `#line` directives naming them,
# by which `traced_files()` finds the lines of each file, so these are moved
# too.
move_srcfiles <- function(traces, move) {
  moved <- new.env(parent = emptyenv())
  # Each srcfile is only moved once, as many traces share it, and a file can
  # be moved to a name that would be moved again.
  once <- function(env) {
    if (!is.environment(env) || !is.null(moved[[address(env)]])) {
      return(FALSE)
    }
    moved[[address(env)]] <- TRUE
    TRUE
  }
  for (trace in traces) {
    srcfile <- attr(trace$srcref, "srcfile")
    if (!is.environment(srcfile) || !is.character(srcfile$filename)) {
      next
    }
    if (!once(srcfile)) {
      next
    }
    srcfile$filename <- move(srcfile$filename)
    original <- srcfile$original
    if (!once(original)) {
      next
    }
    directives <- regmatches(
      original$lines,
      regexec('^(#line [0-9]+ ")(.*)"$', original$lines)
    )
    found <- lengths(directives) == 3L
    if (any(found)) {
      parts <- do.call(rbind, directives[found])
      original$lines[found] <- paste0(parts[, 2], move(parts[, 3]), "\"")
    }
  }
  invisible()
}

# The directory file names are relative to, as `package_coverage()`'s
# `relative_path` gives it: the package's directory, or the directory that
# contains all the packages.
coverage_root <- function(relative_path, pkgs) {
  if (is.character(relative_path)) {
    if (length(relative_path) != 1L) {
      covr_abort(c(
        "{.arg relative_path} must be {.code TRUE}, {.code FALSE}, or a single string.",
        x = "It is a character vector of length {length(relative_path)}."
      ))
    }
    absolute_path(relative_path)
  } else if (isTRUE(relative_path)) {
    common_path(vcapply(pkgs, `[[`, "path"))
  } else {
    NULL
  }
}

# The deepest directory that contains all the (normalized, absolute) `paths`,
# the path itself for one path, or `NULL` if there is none, e.g. for paths on
# different Windows drives.
common_path <- function(paths) {
  if (length(paths) == 0) {
    return(NULL)
  }
  if (length(paths) == 1L) {
    return(paths)
  }
  parts <- strsplit(paths, "/", fixed = TRUE)
  n <- min(lengths(parts))
  common <- parts[[1]][seq_len(n)]
  for (p in parts[-1]) {
    same <- common == p[seq_len(n)]
    n <- if (all(same)) n else which(!same)[[1]] - 1L
    common <- common[seq_len(n)]
  }
  # Packages on different Windows drives or network shares (`//server/share`)
  # have none
  unc <- any(startsWith(paths, "//"))
  if (length(common) == 0 || (unc && length(common) < 4L)) {
    return(NULL)
  }
  # The root of a file system: `/`, or a Windows drive like `C:/`
  if (length(common) == 1L && grepl("^([A-Za-z]:)?$", common)) {
    return(paste0(common, "/"))
  }
  paste(common, collapse = "/")
}

# The `package` attribute of the coverage of `pkgs`: the package of one, or the
# names and source directories of several.
coverage_package <- function(pkgs) {
  if (length(pkgs) == 1L) {
    pkg <- pkgs[[1]]
    pkg$ignore <- NULL
    return(pkg)
  }
  list(
    package = vcapply(pkgs, `[[`, "package"),
    path = vcapply(pkgs, `[[`, "path")
  )
}

# The coverage object of the `traces` of the packages `pkgs` (lists with their
# `package` name, source `path`, and whether to `ignore` the files in their
# `.covrignore`), and of their compiled code in `compiled`. Only the files of
# the packages are kept (see `filter_non_package_files()`), and the
# exclusions are applied.
coverage_of_packages <- function(
  traces,
  pkgs,
  root,
  compiled = NULL,
  line_exclusions = NULL,
  function_exclusions = NULL
) {
  coverage <- as_coverage(
    c(traces, compiled),
    package = coverage_package(pkgs),
    root = root
  )

  if (getOption("covr.filter_non_package", TRUE)) {
    coverage <- filter_non_package_files(coverage)
  }

  # Exclude generated files from Rcpp and cpp11 to avoid redundant coverage
  # information, and the files in `.covrignore`. Rcpp replaces dots in the
  # package name with underscores in the interfaces header. These paths are in
  # the package, so they are resolved against its root rather than the root
  # used for the output paths, which is `NULL` with `relative_path = FALSE`.
  package_exclusions <- unlist(lapply(unname(pkgs), function(pkg) {
    c(
      file.path(
        pkg$path,
        c(
          "src/RcppExports.cpp",
          "R/RcppExports.R",
          file.path(
            "inst",
            "include",
            paste0(gsub(".", "_", pkg$package, fixed = TRUE), "_RcppExports.h")
          ),
          "src/cpp11.cpp",
          "R/cpp11.R"
        )
      ),
      if (isTRUE(pkg$ignore) && dir.exists(pkg$path)) {
        withr::with_dir(
          pkg$path,
          normalize_path(as.character(parse_covr_ignore()))
        )
      }
    )
  }))

  exclude(
    coverage,
    line_exclusions = c(package_exclusions, line_exclusions),
    function_exclusions = function_exclusions,
    path = root
  )
}

# Order the packages `pkgs` (from `as_package()`) so that each comes after the
# packages in `pkgs` that it depends on, imports or links to, as they must be
# installed first.
sort_by_dependencies <- function(pkgs) {
  pkg_names <- vcapply(pkgs, `[[`, "package")
  deps <- lapply(pkgs, function(pkg) {
    fields <- as.character(unlist(pkg[c("depends", "imports", "linkingto")]))
    deps <- trimws(sub("[ (].*$", "", trimws(unlist(strsplit(fields, ",")))))
    intersect(deps, pkg_names)
  })
  order <- integer()
  while (length(order) < length(pkgs)) {
    installed <- pkg_names[order]
    ready <- setdiff(
      which(vlapply(deps, function(d) all(d %in% installed))),
      order
    )
    # Packages can't depend on each other in a cycle, but keep the rest in
    # their order rather than loop forever
    if (length(ready) == 0) {
      ready <- setdiff(seq_along(pkgs), order)
    }
    order <- c(order, ready[[1]])
  }
  pkgs[order]
}
