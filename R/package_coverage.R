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
#' @param path file path to the package, or to an installed package.
#' @param type run the package \sQuote{tests}, \sQuote{vignettes},
#' \sQuote{examples}, \sQuote{all}, or \sQuote{none}. The default is
#' \sQuote{tests}.
#' @param combine_types If `TRUE` (the default) the coverage for all types
#' is simply summed into one coverage object. If `FALSE` separate objects
#' are used for each type of coverage.
#' @param relative_path whether to output the paths as relative or absolute
#'   paths. If a string, it is interpreted as a root path and all paths will be
#'   relative to that root.
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
  pkg <- as_package(path)
  installed <- is_installed_package(pkg$path)

  if (missing(type)) {
    type <- "tests"
  }

  type <- parse_type(type)

  if (
    installed &&
      "tests" %in% type &&
      !dir.exists(file.path(pkg$path, "tests"))
  ) {
    covr_abort(c(
      "Can't find tests in the installed package {.pkg {pkg$package}}.",
      i = "Install it with {.code R CMD INSTALL --install-tests}."
    ))
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

    attr(res, "package") <- pkg
    class(res) <- "coverages"
    return(res)
  }

  if (is.character(relative_path)) {
    if (length(relative_path) != 1L) {
      covr_abort(c(
        "{.arg relative_path} must be {.code TRUE}, {.code FALSE}, or a single string.",
        x = "It is a character vector of length {length(relative_path)}."
      ))
    }
    root <- normalize_path(relative_path)
  } else if (isTRUE(relative_path)) {
    root <- pkg$path
  } else {
    root <- NULL
  }

  # tools::testInstalledPackage requires normalized install_path (#517)
  install_path <- normalize_path(install_path)
  dir.create(install_path)

  flags <- getOption("covr.flags")

  if (isTRUE(clean)) {
    # The install directory is only removed on success, so the test output
    # files referenced in failure messages remain available for debugging.
    succeeded <- FALSE
    on.exit(
      {
        if (!installed) {
          clean_objects(pkg$path)
          clean_gcov(pkg$path)
        }
        clean_parse_data()
        if (succeeded) {
          unlink(install_path, recursive = TRUE)
        }
      },
      add = TRUE
    )
  }

  # clean any dlls prior to trying to install
  if (!installed) {
    clean_objects(pkg$path)
  }

  # Measure the coverage of Rust code, if the package has any
  manifests <- if (!installed) rust_manifests(pkg$path)
  rust <- if (length(manifests)) {
    rust_coverage_setup(pkg$path, install_path)
  }

  full_traversal <- getOption(
    "covr.full_traversal",
    # DESCRIPTION field names are lowercased by `read_description()`
    isTRUE(as.logical(pkg[[tolower("Config/covr/full_traversal")]]))
  )
  counters_file <- NULL
  if (installed) {
    # `R CMD INSTALL` fails to reinstall an installed package on Windows, and
    # only copies it elsewhere, so copy it directly (#638).
    copy_installed_package(pkg, install_path)
  } else {
    # The package is instrumented and byte-compiled once after it is
    # installed, so there is no point byte-compiling the original code.
    instrument <- isTRUE(install_instrument())
    install_package(
      pkg,
      install_path,
      add_rust_flags(flags, rust),
      quiet,
      env = rust$build_env,
      byte_compile = !instrument
    )
    if (instrument) {
      counters_file <- instrument_package(
        pkg,
        install_path,
        full_traversal = full_traversal
      )
    }
    if (!is.null(rust)) {
      rust <- rust_check_build(rust)
    }
  }

  # add hooks to the package startup
  add_hooks(
    pkg$package,
    install_path,
    fix_mcexit = should_enable_parallel_mcexit_fix(pkg),
    full_traversal = full_traversal,
    counters_file = counters_file
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
        R_LIBS_USER = libs,
        R_LIBS_SITE = site_libs,
        R_COVR = "true",
        R_TESTS = file.path(R.home("share"), "R", "tests-startup.R"),
        rust$env
      ),
      {
        withCallingHandlers(
          {
            if ("vignettes" %in% type) {
              type <- type[type != "vignettes"]
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
              type <- type[type != "examples"]
              # testInstalledPackage explicitly sets R_LIBS="" on windows, and does
              # not restore it after, so we need to reset it ourselves.
              withr::with_envvar(c(R_LIBS = Sys.getenv("R_LIBS")), {
                test_installed("examples", ...)
              })
            }
            if ("tests" %in% type) {
              test_installed("tests", ...)
            }

            # We always run the commands file (even if empty) to load the package and
            # initialize all the counters to 0.
            run_commands(
              pkg,
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
    cli::format_inline("loaded {.pkg {pkg$package}}"),
    "Did a test leave a Shiny app, callr session, or future worker running?"
  )

  if (installed) {
    # `R CMD INSTALL` copies an installed package rather than building it, so
    # its R code is only available from the srcrefs kept when it was
    # installed, whose file names are in the source it was installed from.
    # Its compiled code isn't instrumented (#638).
    pkg$path <- installed_source_path(coverage)
    if (is.null(pkg$path)) {
      covr_abort(c(
        "Can't find source references in the installed package {.pkg {pkg$package}}.",
        i = "Install it with {.code R CMD INSTALL --with-keep.source}."
      ))
    }
    if (isTRUE(relative_path)) {
      root <- pkg$path
    }
    res <- NULL
  } else {
    res <- run_gcov(pkg$path, quiet = quiet, clean = clean)
  }

  if (!is.null(rust)) {
    res <- c(
      res,
      run_llvm_cov(rust, pkg$path, install_path, pkg$package, quiet = quiet)
    )
  }
  if (length(manifests)) {
    res <- drop_rust_dependencies(
      res,
      roots = c(pkg$path, getOption("covr.gcov_additional_paths", NULL))
    )
  }

  coverage <- as_coverage(
    c(coverage, res),
    package = pkg,
    root = root
  )

  if (!clean) {
    attr(coverage, "library") <- install_path
  }

  if (getOption("covr.filter_non_package", TRUE)) {
    coverage <- filter_non_package_files(coverage)
  }

  # Exclude generated files from Rcpp and cpp11 to avoid redundant coverage
  # information, and the files in `.covrignore`. Rcpp replaces dots in the
  # package name with underscores in the interfaces header. These paths are in
  # the package, so they are resolved against its root rather than the root
  # used for the output paths, which is `NULL` with `relative_path = FALSE`.
  generated_files <- file.path(
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
  )
  line_exclusions <- c(
    generated_files,
    line_exclusions,
    if (!installed) {
      withr::with_dir(
        pkg$path,
        normalize_path(as.character(parse_covr_ignore()))
      )
    }
  )

  coverage <- exclude(
    coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = root
  )

  # Keep the install directory if any failures were reported as warnings, as
  # their messages refer to output files in it.
  succeeded <- length(failures) == 0L
  coverage
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
    "tools::buildVignettes(dir = '",
    pkg$path,
    "')\n",
    file = outfile,
    sep = ""
  )
  cmd <- paste(
    shQuote(r_binary()),
    "CMD BATCH --vanilla --no-timing",
    shQuote(outfile),
    shQuote(failfile)
  )
  res <- system(cmd)
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

r_binary <- function() {
  name <- "R"
  if (is_windows()) {
    name <- "R.exe" # nocov
  }
  file.path(R.home("bin"), name)
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
    c(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), env),
    withr::with_makevars(flags, assignment = "+=", {
      args <- c(
        "--vanilla",
        "CMD",
        "INSTALL",
        "-l",
        shQuote(install_path),
        "--example",
        "--install-tests",
        "--with-keep.source",
        "--with-keep.parse.data",
        "--no-staged-install",
        "--no-multiarch",
        if (!byte_compile) "--no-byte-compile",
        shQuote(pkg$path)
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

run_commands <- function(pkg, lib, commands, show_output = FALSE) {
  outfile <- file.path(lib, paste0(pkg$package, "-commands.Rout"))
  failfile <- paste(outfile, "fail", sep = ".")
  writeLines(
    c(
      paste0("library('", pkg$package, "')"),
      commands
    ),
    con = outfile
  )
  if (isTRUE(show_output)) {
    res <- run_r_live(outfile, failfile)
  } else {
    cmd <- paste(
      shQuote(r_binary()),
      "CMD BATCH --vanilla --no-timing",
      shQuote(outfile),
      shQuote(failfile)
    )
    res <- system(cmd)
  }
  if (res != 0L) {
    show_failures(dirname(failfile))
  } else {
    file.rename(failfile, outfile)
  }
}

# Run the R script `infile` like `R CMD BATCH` does, but also show its stdout
# and stderr on the console (on stdout and stderr respectively) as it runs.
# Both are saved to `outfile`, in the order they are read. Returns the exit
# status.
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
      r_binary(),
      c("--vanilla", "--quiet", "-f", infile),
      std_out = show(stdout()),
      std_err = show(stderr())
    ),
    # sys signals an error if the process is killed, e.g. by a segfault; report
    # it as a failure, as `R CMD BATCH` does.
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
add_hooks <- function(
  pkg_name,
  lib,
  fix_mcexit = FALSE,
  record_tests = isTRUE(getOption("covr.record_tests", FALSE)),
  full_traversal = FALSE,
  branch_coverage = isTRUE(getOption("covr.branch_coverage", FALSE)),
  counters_file = NULL
) {
  trace_dir <- paste0("Sys.getenv(\"COVERAGE_DIR\", \"", lib, "\")")

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
      '"R", paste0(pkg, ".covr"))',
      lines[db_line],
      fixed = TRUE
    )
  }
  lines <- append(
    lines,
    c(
      paste0(
        "setHook(packageEvent(pkg, \"onLoad\"), function(...) options(covr.record_tests = ",
        record_tests,
        "))"
      ),
      paste0(
        "setHook(packageEvent(pkg, \"onLoad\"), function(...) options(covr.full_traversal = ",
        isTRUE(full_traversal),
        "))"
      ),
      paste0(
        "setHook(packageEvent(pkg, \"onLoad\"), function(...) options(covr.branch_coverage = ",
        isTRUE(branch_coverage),
        "))"
      ),
      if (is.null(counters_file)) {
        "setHook(packageEvent(pkg, \"onLoad\"), function(...) covr:::trace_environment(ns))"
      } else {
        paste0(
          "setHook(packageEvent(pkg, \"onLoad\"), function(...) covr:::restore_counters(ns, file.path(info$libname, pkg, \"R\", \"",
          basename(counters_file),
          "\")))"
        )
      },
      paste0(
        "setHook(packageEvent(pkg, \"onLoad\"), function(...) covr:::register_trace(ns, ",
        trace_dir,
        "))"
      )
    ),
    length(lines) - 1L
  )

  if (fix_mcexit) {
    lines <- append(lines, sprintf("covr:::fix_mcexit('%s')", trace_dir))
  }

  writeLines(text = lines, con = load_script)
}
