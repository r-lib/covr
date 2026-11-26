#' Calculate test coverage for a package
#'
#' This function calculates the test coverage for a development package on the
#' `path`. By default it runs only the package tests, but it can also run
#' vignette and example code.
#'
#' @details
#' This function uses [tools::testInstalledPackage()] to run the
#' code, if you would like to test your package in another way you can set
#' `type = "none"` and pass the code to run as a character vector to the
#' `code` parameter.
#'
#' Coverage is also recorded in other R processes that load the package, such
#' as \pkg{callr} sessions, \pkg{future} or \pkg{parallel} cluster workers, or
#' Shiny apps run by \pkg{shinytest2}. Each process saves its coverage when it
#' exits normally, so the coverage is lost if a process is killed (e.g. with
#' `SIGKILL` or `SIGTERM`) or is still running when the tests finish, and
#' `package_coverage()` warns (with class `covr_unsaved_trace`). Stop these
#' processes gracefully and wait for them to exit, e.g. call `$stop()` on a
#' \pkg{shinytest2} `AppDriver`, which waits longer for the app to exit when
#' run by covr. See `vignette("shiny", package = "covr")` for measuring the
#' coverage of Shiny apps.
#'
#' `path` can also be an installed package, e.g.
#' `system.file(package = "pkg")`, to compute coverage without the package
#' source. The package must have been installed with its tests and source
#' references, e.g. with
#' `remotes::install_github("user/pkg", INSTALL_opts = c("--install-tests",
#' "--with-keep.source"))`. File names are those of the source it was
#' installed from, and compiled code isn't covered.
#'
#' The coverage of Rust code, built by cargo into a static library that is
#' linked into the package, is measured with LLVM's source-based coverage.
#' This needs the llvm tools of the Rust toolchain
#' (`rustup component add llvm-tools`), or for Rust installed by a Linux
#' distribution, those of the LLVM version rustc uses (e.g.
#' `apt-get install llvm-18`); without them `package_coverage()`
#' warns and reports no coverage for the Rust code. covr instruments the
#' crates of the package's cargo workspace by having cargo run rustc through a
#' wrapper (with `RUSTC_WORKSPACE_WRAPPER`) that adds `-C instrument-coverage`,
#' so it works however the package sets `RUSTFLAGS`, and dependencies are
#' built as usual. Vendored crates, including the C code they compile, and
#' code generated in cargo's `target` directory aren't included. The code that
#' macros such as `#[extendr]` and `#[savvy]` generate is counted on the
#' macro's line, so the line isn't covered if parts of the generated code
#' never run, e.g. the handling of arguments that can't be converted. The
#' coverage of Rust code isn't measured on Windows, as rustup's Rust for the
#' `x86_64-pc-windows-gnu` target that Rtools uses has no profiler runtime.
#'
#' #ifdef unix
#' Parallelized code using \pkg{parallel}'s [mcparallel()] needs to
#' use a patched `parallel:::mcexit`. This is done automatically if the
#' package depends on \pkg{parallel}, but can also be explicitly set using the
#' global option `covr.fix_parallel_mcexit` or the environment variable
#' `COVR_FIX_PARALLEL_MCEXIT`.
#' #endif
#'
#' @section Several packages:
#' With several `path`s, e.g. the packages of a monorepo, all the packages are
#' installed and instrumented in the same library, the tests (and other
#' `type`s) of each are run in turn, and `code` is run once with all of them
#' attached. The coverage of each package includes the code that the tests of
#' the others run, e.g. of a package that they import. File names are
#' relative to the directory that contains all the packages, e.g.
#' `pkgA/R/utils.R`. To run the code some other way, e.g. with a test runner
#' or build system, see [instrument_packages()].
#'
#' @param path file path to the package, or to an installed package. Several
#'   paths measure the coverage of several packages together (see below).
#' @param type run the package \sQuote{tests}, \sQuote{vignettes},
#' \sQuote{examples}, \sQuote{all}, or \sQuote{none}. The default is
#' \sQuote{tests}.
#' @param combine_types If `TRUE` (the default) the coverage for all types
#' is simply summed into one coverage object. If `FALSE` separate objects
#' are used for each type of coverage.
#' @param relative_path whether to output the paths as relative or absolute
#'   paths, relative to the package root, or for several packages, to the
#'   directory that contains all of them. If a string, it is interpreted as a
#'   root path and all paths will be relative to that root.
#' @param quiet whether to load and compile the package quietly, useful for
#' debugging errors.
#' @param clean whether to clean temporary output files after running, mainly
#' useful for debugging errors. If coverage fails, or failures are reported as
#' warnings with `allow_failures = TRUE`, `install_path` is kept even when
#' `clean = TRUE`, so the test output can be inspected.
#' @param line_exclusions a named list of files with the lines to exclude from
#' each file.
#' @param function_exclusions a vector of regular expressions matching function
#' names to exclude. Example `print\\\.` to match print methods.
#' @param code A character vector of additional test code to run.
#' @param show_code_output If `TRUE`, the output of `code` is shown on the
#'   console while it runs, e.g. to follow it in the logs of a CI job. The
#'   default, `FALSE`, only saves it to a file in `install_path`, which is shown
#'   if `code` fails.
#' @param ... Additional arguments passed to [tools::testInstalledPackage()].
#'   Use `outDir` to save the output of the tests and examples to a directory
#'   which is kept after coverage finishes; by default it is written to
#'   `install_path`.
#' @param install_path The path the instrumented package will be installed to
#'   and tests run in. By default it is a path in the R sessions temporary
#'   directory. It can sometimes be useful to set this (along with `clean =
#'   FALSE`) to help debug test failures. It is not removed if coverage fails.
#' @param allow_failures If `TRUE`, failures or errors when running tests,
#'   vignettes, examples or `code` are reported as warnings (with class
#'   `covr_warning`) and coverage is still returned. Coverage may be incomplete
#'   in this case, as code which would have run after the failure is not
#'   tracked. The default, `FALSE`, throws an error (with class `covr_error`)
#'   on the first failure. The default can be changed with the
#'   `covr.allow_failures` option, e.g. `options(covr.allow_failures = TRUE)`.
#' @return A [coverage] object. If `combine_types = FALSE` and more than one
#'   `type` is run, a list of class `coverages` with one coverage object for
#'   each type, named by type.
#' @seealso [exclusions()] For details on excluding parts of the
#' package from the coverage calculations.
#' @export
package_coverage <- function(
  path = ".",
  type = c("tests", "vignettes", "examples", "all", "none"),
  combine_types = TRUE,
  relative_path = TRUE,
  quiet = TRUE,
  clean = TRUE,
  line_exclusions = NULL,
  function_exclusions = NULL,
  code = character(),
  install_path = temp_file("R_LIBS"),
  ...,
  allow_failures = getOption("covr.allow_failures", FALSE),
  show_code_output = FALSE
) {
  if (!is.character(path) || length(path) == 0 || anyNA(path)) {
    covr_abort("{.arg path} must be a character vector of package paths.")
  }
  pkgs <- lapply(unname(path), as_package)
  pkg_names <- vcapply(pkgs, `[[`, "package")
  if (anyDuplicated(pkg_names)) {
    covr_abort(
      "{.arg path} has the package {.pkg {unique(pkg_names[duplicated(pkg_names)])}} more than once."
    )
  }
  installed <- vlapply(pkgs, function(pkg) is_installed_package(pkg$path))

  if (missing(type)) {
    type <- "tests"
  }

  type <- parse_type(type)

  if ("tests" %in% type) {
    for (pkg in pkgs[installed]) {
      if (!dir.exists(file.path(pkg$path, "tests"))) {
        covr_abort(c(
          "Can't find tests in the installed package {.pkg {pkg$package}}.",
          i = "Install it with {.code R CMD INSTALL --install-tests}."
        ))
      }
    }
  }

  run_separately <- !isTRUE(combine_types) && length(type) > 1
  if (run_separately) {
    # store the args that were called, evaluated in the caller's frame so
    # `Recall()` doesn't look up local variables in this one
    called_args <- lapply(as.list(match.call())[-1], eval, parent.frame())

    # remove the type
    called_args$type <- NULL
    res <- list()
    for (t in type) {
      res[[t]] <- do.call(Recall, c(called_args, type = t))
      attr(res[[t]], "type") <- t
    }

    attr(res, "package") <- coverage_package(pkgs)
    class(res) <- "coverages"
    return(res)
  }

  if (is.character(relative_path) && length(relative_path) != 1L) {
    covr_abort(c(
      "{.arg relative_path} must be {.code TRUE}, {.code FALSE}, or a single string.",
      x = "It is a character vector of length {length(relative_path)}."
    ))
  }

  for (pkg in pkgs[!installed]) {
    check_source_paths(pkg)
  }

  # tools::testInstalledPackage requires normalized install_path (#517), and
  # `normalizePath()` leaves relative paths that don't exist relative on Unix
  dir.create(install_path)
  install_path <- normalize_path(install_path)
  check_library_path(install_path)

  flags <- getOption("covr.flags")

  if (isTRUE(clean)) {
    # The install directory is only removed on success, so the test output
    # files referenced in failure messages remain available for debugging.
    succeeded <- FALSE
    on.exit(
      {
        for (pkg in pkgs[!installed]) {
          clean_objects(pkg$path)
          clean_gcov(pkg$path)
        }
        clean_parse_data()
        if (succeeded) {
          unlink(install_path, recursive = TRUE, expand = FALSE)
        }
      },
      add = TRUE
    )
  }

  # clean any dlls prior to trying to install
  for (pkg in pkgs[!installed]) {
    clean_objects(pkg$path)
  }

  # Measure the coverage of Rust code, if the packages have any. Each package
  # builds its code in its own directory, but all write their counts to the
  # same one, as a process can load several of them.
  rust <- list()
  for (pkg in pkgs[!installed]) {
    if (length(rust_manifests(pkg$path))) {
      dir <- file.path(install_path, "rust_coverage")
      if (length(pkgs) > 1L) {
        dir <- file.path(dir, pkg$package)
      }
      rust[[pkg$package]] <- rust_coverage_setup(pkg$path, dir)
    }
  }
  rust <- share_rust_profiles(rust)

  # Packages are installed before the packages that depend on them, and only
  # instrumented once all are installed: instrumenting a package loads the
  # packages it imports, which would save their traces if they were
  # instrumented already.
  instrument <- isTRUE(install_instrument())
  for (pkg in sort_by_dependencies(pkgs)) {
    if (is_installed_package(pkg$path)) {
      # `R CMD INSTALL` fails to reinstall an installed package on Windows, and
      # only copies it elsewhere, so copy it directly (#638).
      copy_installed_package(pkg, install_path)
    } else {
      # The package is instrumented and byte-compiled once after it is
      # installed, so there is no point byte-compiling the original code.
      pkg_rust <- rust[[pkg$package]]
      install_package(
        pkg,
        install_path,
        add_rust_flags(flags, pkg_rust),
        quiet,
        env = pkg_rust$build_env,
        byte_compile = !instrument
      )
      if (!is.null(pkg_rust)) {
        rust[[pkg$package]] <- rust_check_build(pkg_rust)
      }
    }
  }
  # The code of installed packages is instrumented when they are loaded
  instrument_library_packages(
    pkgs,
    install_path,
    ahead_of_time = instrument & !installed
  )

  libs <- env_path(install_path, .libPaths())
  # The processes only get the site libraries of this session, not all of
  # `libs`: renv removes the site libraries from the library paths when it
  # activates its sandbox, e.g. when the package imports renv (or vetiver,
  # which embeds it) in an renv project, which would also remove covr and the
  # package (#560).
  site_libs <- r_libs_site()

  # Failures collected when `allow_failures` is TRUE, signaled as warnings
  # after the tests have run.
  failures <- list()

  # Load sys (used to show the output of `code`) before the instrumented
  # package's library is put first in the library paths, so measuring the
  # coverage of sys itself doesn't load the instrumented copy in this process.
  if (isTRUE(show_code_output)) {
    loadNamespace("sys")
  }

  # We need to set the libpaths in the current R session for examples with
  # install or runtime Sexpr blocks, which may implicitly load the package in
  # the current R session.
  withr::with_libpaths(install_path, action = "prefix", {
    withr::with_envvar(
      c(
        R_DEFAULT_PACKAGES = "datasets,utils,grDevices,graphics,stats,methods",
        R_LIBS = libs,
        R_LIBS_USER = r_libs_env_value(libs),
        R_LIBS_SITE = r_libs_env_value(site_libs),
        R_COVR = "true",
        COVR_TRACE_DIR = NA,
        R_TESTS = file.path(R.home("share"), "R", "tests-startup.R"),
        rust_env(rust)
      ),
      {
        withCallingHandlers(
          {
            for (pkg in pkgs) {
              run_package_types(pkg, install_path, type, ...)
            }

            # We always run the commands file (even if empty) to load the
            # packages and initialize all the counters to 0.
            run_commands(
              pkgs,
              install_path,
              code,
              show_output = show_code_output
            )
          },
          message = function(e) {
            if (quiet) invokeRestart("muffleMessage") else e
          },
          warning = function(e) {
            if (quiet) invokeRestart("muffleWarning") else e
          },
          covr_error = function(e) {
            if (isTRUE(allow_failures)) {
              failures[[length(failures) + 1L]] <<- e
              invokeRestart("covr_continue")
            }
          }
        )
      }
    )
  })

  # read tracing files
  coverage <- withCallingHandlers(
    merge_traces(install_path),
    covr_error = function(e) {
      if (isTRUE(allow_failures)) {
        failures[[length(failures) + 1L]] <<- e
        invokeRestart("covr_continue")
      }
    }
  )

  for (failure in failures) {
    warning(structure(
      list(
        message = conditionMessage(failure),
        call = NULL,
        file = failure$file,
        output = failure$output
      ),
      class = c("covr_warning", "warning", "condition")
    ))
  }

  warn_unsaved_traces(
    install_path,
    cli::format_inline("loaded {.pkg {pkg_names}}"),
    "Did a test leave a Shiny app, callr session, or future worker running?"
  )

  # `R CMD INSTALL` copies an installed package rather than building it, so
  # its R code is only available from the srcrefs kept when it was installed,
  # whose file names are in the source it was installed from. Its compiled
  # code isn't instrumented (#638), and the files in its `.covrignore` aren't
  # excluded.
  pkgs <- Map(
    function(pkg, installed) {
      if (installed) {
        pkg["path"] <- list(NULL)
      }
      pkg$ignore <- !installed
      pkg
    },
    pkgs,
    installed
  )
  pkgs <- trace_source_paths(coverage, pkgs)

  res <- NULL
  for (pkg in pkgs[!installed]) {
    pkg_res <- run_gcov(pkg$path, quiet = quiet, clean = clean)
    if (!is.null(rust[[pkg$package]])) {
      objects <- list.files(
        file.path(install_path, pkg$package, "libs"),
        pattern = "[.](so|dll|dylib)$",
        recursive = TRUE,
        full.names = TRUE
      )
      pkg_res <- c(
        pkg_res,
        run_llvm_cov(rust[[pkg$package]], pkg$path, objects, quiet = quiet)
      )
    }
    # Only the files of a package with Rust code can be its dependencies
    if (length(rust_manifests(pkg$path))) {
      pkg_res <- drop_rust_dependencies(
        pkg_res,
        roots = c(pkg$path, getOption("covr.gcov_additional_paths", NULL))
      )
    }
    res <- c(res, scope_compiled(pkg_res, pkg))
  }

  coverage <- coverage_of_packages(
    coverage,
    pkgs,
    root = coverage_root(relative_path, pkgs),
    compiled = res,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions
  )

  if (!clean) {
    attr(coverage, "library") <- install_path
  }

  # Keep the install directory if any failures were reported as warnings, as
  # their messages refer to output files in it.
  succeeded <- length(failures) == 0L
  coverage
}

# Run the vignettes, examples and tests of `pkg` that are in `type`.
run_package_types <- function(pkg, install_path, type, ...) {
  if ("vignettes" %in% type) {
    run_vignettes(pkg, install_path)
  }

  test_installed <- function(
    types,
    outDir = file.path(install_path, pkg$package),
    ...
  ) {
    dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
    outDir <- normalize_path(outDir)
    result <- tools::testInstalledPackage(
      pkg$package,
      outDir = outDir,
      types = types,
      lib.loc = install_path,
      ...
    )
    if (result != 0L) {
      show_failures(outDir)
    }
  }
  if ("examples" %in% type) {
    # testInstalledPackage explicitly sets R_LIBS="" on windows, and does
    # not restore it after, so we need to reset it ourselves.
    withr::with_envvar(c(R_LIBS = Sys.getenv("R_LIBS")), {
      test_installed("examples", ...)
    })
  }
  if ("tests" %in% type) {
    test_installed("tests", ...)
  }
}

parse_type <- function(type) {
  # Each type must match a choice, unlike `match.arg(several.ok = TRUE)`,
  # which only fails if none of them do.
  choices <- c("tests", "vignettes", "examples", "all", "none")
  choices_text <- paste0('"', choices, '"', collapse = ", ")
  type <- vapply(
    type,
    function(x) {
      i <- pmatch(x, choices)
      if (is.na(i)) {
        covr_abort(c(
          "{.arg type} must be one of {choices_text}.",
          x = "{.val {x}} isn't."
        ))
      }
      choices[[i]]
    },
    character(1),
    USE.NAMES = FALSE
  )
  if (identical(type, "all")) {
    type <- c("tests", "vignettes", "examples")
  }

  if (length(type) > 1L) {
    if ("all" %in% type) {
      covr_abort('{.arg type} can\'t combine "all" with other types.')
    }

    if ("none" %in% type) {
      covr_abort('{.arg type} can\'t combine "none" with other types.')
    }
  }
  type
}

# Run vignettes for a package. This is done in a new process as otherwise the
# finalizer is not called to dump the results. The namespace is first
# explicitly loaded to ensure output even if no vignettes exist.
# @param pkg Package object (from as_package) to run
# @param lib the library path to look in
run_vignettes <- function(pkg, lib) {
  outfile <- file.path(lib, paste0(pkg$package, "-Vignette.Rout"))
  failfile <- paste(outfile, "fail", sep = ".")
  cat(
    "tools::buildVignettes(dir = ",
    encodeString(pkg$path, quote = '"'),
    ")\n",
    file = outfile,
    sep = ""
  )
  res <- run_r(outfile, failfile)
  if (res != 0) {
    show_failures(dirname(failfile))
  } else {
    file.rename(failfile, outfile)
  }
}

# The value of R_LIBS_SITE that gives R processes the site libraries `site`.
# An empty R_LIBS_SITE is the default site library, so no site libraries (as in
# renv projects) is "NULL".
r_libs_site <- function(site = .Library.site) {
  site_libs <- env_path(site)
  if (!nzchar(site_libs)) {
    site_libs <- "NULL"
  }
  site_libs
}

# Escape the value of R_LIBS_USER or R_LIBS_SITE so R processes read `x`. R
# expands `%v`, `%V`, `%p` and others in them and reads `%%` as `%` (see
# `?.libPaths`), and on Unix `R_HOME/etc/Renviron` sets them from themselves,
# which removes quotes (#774). A quote is kept in quotes of the other kind; R
# 4.1 doesn't read `\'` as `'`. `tools::testInstalledPackage()` clears R_LIBS
# to run the examples, so they only find the package through these.
r_libs_env_value <- function(x) {
  x <- gsub("%", "%%", x, fixed = TRUE)
  if (!is_windows()) {
    chars <- strsplit(x, "", fixed = TRUE)[[1]]
    chars[chars == "'"] <- "\"'\""
    chars[chars == "\""] <- "'\"'"
    x <- paste(chars, collapse = "")
  }
  x
}

# R can't use a library whose path contains the separator of the libraries in
# R_LIBS, nor `[` or (on Unix) `\`, as `.libPaths()` globs the paths (#774).
check_library_path <- function(path) {
  chars <- c(.Platform$path.sep, "[", if (!is_windows()) "\\")
  found <- chars[vapply(chars, grepl, logical(1), x = path, fixed = TRUE)]
  if (length(found) > 0) {
    covr_abort(c(
      "Can't use {.path {path}} as a library.",
      x = "R can't use libraries whose path contains {.val {found}}.",
      i = "Set {.arg install_path}, or {.envvar TMPDIR} for the default, to a path without them."
    ))
  }
}

# On Unix, `R CMD INSTALL` writes the paths of the R files into `#line`
# directives without escaping them, so R reads wrong file names for paths that
# contain `"` or `\`, and the coverage of their code would be lost or reported
# for files that don't exist (#774).
check_source_paths <- function(pkg) {
  if (is_windows()) {
    return(invisible()) # nocov
  }
  r_dir <- file.path(pkg$path, "R")
  paths <- c(pkg$path, file.path(r_dir, list.files(r_dir, recursive = TRUE)))
  bad <- paths[
    grepl("\"", paths, fixed = TRUE) | grepl("\\", paths, fixed = TRUE)
  ]
  if (length(bad) > 0) {
    covr_abort(c(
      "Can't measure the coverage of {.pkg {pkg$package}}.",
      x = "{.code R CMD INSTALL} records wrong file names for R code whose path contains a double quote or a backslash, such as {.path {bad[[1]]}}.",
      i = "Move the package or rename the file."
    ))
  }
}

# The R front end, to run `R CMD`.
r_binary <- function() {
  name <- "R"
  if (is_windows()) {
    name <- "R.exe" # nocov
  }
  file.path(R.home("bin"), name)
}

# The binary to run R code with. On Windows, `R.exe` starts `Rterm.exe` with
# the same arguments through `cmd.exe`, which expands environment variables
# such as `%PATH%` in them, even in quoted paths (#774), so `Rterm.exe` is run
# directly.
rterm_binary <- function() {
  if (is_windows()) {
    return(file.path(R.home("bin"), "Rterm.exe")) # nocov
  }
  r_binary()
}

# Quote a path for `system2(r_binary(), c("CMD", ...))`. `R CMD` on Windows
# also runs R through `cmd.exe`, which has no escape for `%` in quoted
# arguments, so each `%` is written as `%COVR_PERCENT%`, an environment variable
# that `r_cmd_env()` sets to `%`. `cmd.exe` doesn't expand its value again.
r_cmd_path <- function(path) {
  if (is_windows()) {
    path <- gsub("%", "%COVR_PERCENT%", path, fixed = TRUE) # nocov
  }
  shQuote(path)
}

r_cmd_env <- function() {
  if (is_windows()) {
    return(c(COVR_PERCENT = "%")) # nocov
  }
  character()
}

# Install the package source with the options covr needs. With `quiet`, the
# output is captured to give the reason if the installation fails.
install_package <- function(
  pkg,
  install_path,
  flags,
  quiet,
  env = NULL,
  byte_compile = TRUE
) {
  output <- withr::with_envvar(
    c(
      R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep),
      r_cmd_env(),
      env
    ),
    withr::with_makevars(flags, assignment = "+=", {
      args <- c(
        "--vanilla",
        "CMD",
        "INSTALL",
        "-l",
        r_cmd_path(install_path),
        "--example",
        "--install-tests",
        "--with-keep.source",
        "--with-keep.parse.data",
        "--no-staged-install",
        "--no-multiarch",
        if (!byte_compile) "--no-byte-compile",
        r_cmd_path(pkg$path)
      )

      path <- r_binary()
      if (quiet) {
        suppressWarnings(system2(path, args, stdout = TRUE, stderr = TRUE))
      } else {
        structure(
          character(),
          status = system2(path, args, stdout = "", stderr = "")
        )
      }
    })
  )

  status <- attr(output, "status") %||% 0L
  if (status != 0) {
    covr_abort(
      "Can't install {.pkg {pkg$package}}.",
      output = utils::tail(output, failure_lines())
    )
  }
}

# Copy an installed package to `install_path`, giving the warnings of
# `file.copy()` as the reason if the copy fails.
copy_installed_package <- function(pkg, install_path) {
  reasons <- character()
  copied <- withCallingHandlers(
    file.copy(pkg$path, install_path, recursive = TRUE),
    warning = function(w) {
      reasons <<- c(reasons, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (
    !isTRUE(copied) ||
      !file.exists(file.path(install_path, pkg$package, "DESCRIPTION"))
  ) {
    covr_abort(
      "Can't copy the installed package {.pkg {pkg$package}} to {.path {install_path}}.",
      output = if (length(reasons) > 0) reasons else "`file.copy()` failed."
    )
  }
}

# Run `commands` in a process that attaches the packages `pkgs`. The output is
# saved in a file named after the first one.
run_commands <- function(pkgs, lib, commands, show_output = FALSE) {
  pkg_names <- vcapply(pkgs, `[[`, "package")
  outfile <- file.path(lib, paste0(pkg_names[[1]], "-commands.Rout"))
  failfile <- paste(outfile, "fail", sep = ".")
  writeLines(
    c(
      paste0("library('", pkg_names, "')"),
      commands
    ),
    con = outfile
  )
  res <- run_r(outfile, failfile, show = show_output)
  if (res != 0L) {
    show_failures(dirname(failfile))
  } else {
    file.rename(failfile, outfile)
  }
}

# Run the R script `infile` with `R --file=`, saving its stdout and stderr to
# `outfile`. `R CMD BATCH` can't run scripts with a space in their path (#770).
# Unlike `-f <infile>`, `--file=<infile>` is not read as an environment variable
# by `Rterm.exe` when the path contains `=`, nor globbed by the `R` shell script
# when it contains `*`, `?` or `[` (#774). Returns the exit status.
run_r <- function(infile, outfile, show = FALSE) {
  if (isTRUE(show)) {
    return(run_r_live(infile, outfile))
  }
  # Both streams go to the same file (`2>&1`), so their output stays in order
  system2(
    rterm_binary(),
    c("--vanilla", "--quiet", shQuote(paste0("--file=", infile))),
    stdout = outfile,
    stderr = outfile
  )
}

# Like `run_r()`, but also show stdout and stderr on the console (on stdout and
# stderr respectively) as it runs. They are read from separate pipes, so in
# `outfile` they are in the order they are read, not the order they were
# written.
run_r_live <- function(infile, outfile) {
  out <- file(outfile, "wb")
  on.exit(close(out))
  show <- function(con) {
    function(x) {
      cat(rawToChar(x), file = con)
      writeBin(x, out)
    }
  }
  tryCatch(
    sys::exec_wait(
      rterm_binary(),
      c("--vanilla", "--quiet", paste0("--file=", infile)),
      std_out = show(stdout()),
      std_err = show(stderr())
    ),
    # sys signals an error if the process is killed, e.g. by a segfault; report
    # it as a failure.
    error = function(e) {
      show(stderr())(charToRaw(paste0(conditionMessage(e), "\n")))
      1L
    }
  )
}

# Add hooks to the installed package
# Installed packages have lazy loading code to setup the lazy load database at
# pkg_name/R/pkg_name. This function adds a user level onLoad Hook to the
# package which calls `covr::trace_environment`, so the package environment is
# traced when the package is loaded.
# It also registers a finalizer (with `register_trace()`) that saves the
# tracing information when the namespace is garbage collected or the process
# exits normally. A process that is killed does not save its trace, which
# `package_coverage()` reports. Like the tracing, this runs in an onLoad hook:
# calling covr from the load script itself loads covr while the package is
# still being lazy-loaded, which made tracing ~4x slower when covr measures its
# own coverage (covr is then loaded from an instrumented copy).
# @param pkg_name name of the package to add hooks to
# @param lib the library path to look in
# @param fix_mcexit whether to add the fix for mcparallel:::mcexit
# @param counters_file the file with the counters of a package that was
#   instrumented by `instrument_package()`, which are restored when the package
#   is loaded instead of tracing its namespace.
# @param trace_dir the directory traces are saved in if `COVR_TRACE_DIR` isn't
#   set when the package is loaded, or `NULL` to only save them if it is.
add_hooks <- function(
  pkg_name,
  lib,
  fix_mcexit = FALSE,
  record_tests = isTRUE(getOption("covr.record_tests", FALSE)),
  full_traversal = FALSE,
  branch_coverage = isTRUE(getOption("covr.branch_coverage", FALSE)),
  counters_file = NULL,
  trace_dir = lib
) {
  # Without a `trace_dir` the package is only measured when `COVR_TRACE_DIR`
  # is set when it is loaded. Otherwise it loads as installed, without covr.
  dormant <- is.null(trace_dir)
  active <- 'nzchar(Sys.getenv("COVR_TRACE_DIR"))'
  trace_dir <- paste0(
    "covr:::trace_dir_setting(",
    if (dormant) "NULL" else encodeString(trace_dir, quote = '"'),
    ")"
  )

  load_script <- file.path(lib, pkg_name, "R", pkg_name)
  lines <- readLines(load_script)
  if (!is.null(counters_file)) {
    # Load the instrumented code that `instrument_package()` saved
    db_line <- grep(
      'dbbase <- file.path(info$libname, pkg, "R", pkg)',
      lines,
      fixed = TRUE
    )
    if (length(db_line) != 1L) {
      covr_abort(
        "Can't find where the loader script of {.pkg {pkg_name}} reads the package."
      )
    }
    lines[db_line] <- sub(
      '"R", pkg)',
      if (dormant) {
        paste0('"R", if (', active, ') paste0(pkg, ".covr") else pkg)')
      } else {
        '"R", paste0(pkg, ".covr"))'
      },
      lines[db_line],
      fixed = TRUE
    )
  }
  # The hooks are marked, so `remove_covr_hooks()` can tell them apart from
  # those of the package or the user.
  hook <- function(...) {
    paste0(
      "setHook(packageEvent(pkg, \"onLoad\"), structure(function(...) ",
      ...,
      ", covr_hook = TRUE))"
    )
  }
  hooks <- c(
    hook("options(covr.record_tests = ", record_tests, ")"),
    hook("options(covr.full_traversal = ", isTRUE(full_traversal), ")"),
    hook("options(covr.branch_coverage = ", isTRUE(branch_coverage), ")"),
    if (is.null(counters_file)) {
      hook(
        "covr:::trace_environment(ns, scope = ",
        encodeString(pkg_name, quote = '"'),
        ")"
      )
    } else {
      hook(
        "covr:::restore_counters(ns, file.path(info$libname, pkg, \"R\", \"",
        basename(counters_file),
        "\"))"
      )
    },
    hook("covr:::register_trace(ns, ", trace_dir, ")")
  )
  if (dormant) {
    hooks <- c(paste0("if (", active, ") {"), hooks, "}")
  }
  # The hooks of an earlier load of the package in this process are left when
  # it is unloaded, so they are removed first: otherwise they would trace it
  # again, or trace a dormant one. With base R only, as a dormant package loads
  # without covr.
  remove_hooks <- paste0(
    "setHook(packageEvent(pkg, \"onLoad\"), Filter(function(hook) ",
    "!isTRUE(attr(hook, \"covr_hook\")), getHook(packageEvent(pkg, ",
    "\"onLoad\"))), \"replace\")"
  )
  lines <- append(lines, c(remove_hooks, hooks), length(lines) - 1L)

  if (fix_mcexit) {
    lines <- append(
      lines,
      paste0(if (dormant) paste0("if (", active, ") "), "covr:::fix_mcexit()")
    )
  }

  writeLines(text = lines, con = load_script)
}
