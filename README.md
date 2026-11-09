# covr <img src="man/figures/logo.png" align="right" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/r-lib/covr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-lib/covr/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/r-lib/covr/branch/master/graph/badge.svg)](https://app.codecov.io/gh/r-lib/covr?branch=master)
[![CRAN version](https://www.r-pkg.org/badges/version/covr)](https://cran.r-project.org/package=covr)
<!-- badges: end -->

Track test coverage for your R package and view reports locally or (optionally)
upload the results to [codecov](https://about.codecov.io/) or [coveralls](https://coveralls.io/).

# Installation #

```r
install.packages("covr")

# For devel version
devtools::install_github("r-lib/covr")
```

The easiest way to setup covr on [Github Actions](https://github.com/r-lib/actions/tree/v2-branch/examples#test-coverage-workflow) 
is with [usethis](https://github.com/r-lib/usethis).

```r
usethis::use_github_action("test-coverage")
```

This workflow uploads to Codecov. To use [Coveralls](https://coveralls.io/)
instead, replace the `codecov/codecov-action` step with the official
[Coveralls action](https://github.com/coverallsapp/github-action), which
uploads the `cobertura.xml` file the workflow already creates. No Coveralls
token is needed, the action authenticates with the built-in `GITHUB_TOKEN`.

```yaml
      - uses: coverallsapp/github-action@v2
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          file: ./cobertura.xml
          format: cobertura
          # Fail if error if not on PR
          fail-on-error: ${{ github.event_name != 'pull_request' }}
```

If the package is in a subdirectory of the repository, also set `base-path` to
that directory so Coveralls can find the source files.

## Coverage badge without a coverage service ##

If you only want a coverage badge for your README, and not the history and pull
request checks of Codecov or Coveralls, `to_badge()` writes one as an SVG file
locally. For example, to update a badge in a `badges` branch on every push to
GitHub, replace the coverage steps of the test-coverage workflow with these,
and give the workflow `permissions: contents: write`.

```yaml
      - name: Test coverage
        run: |
          cov <- covr::package_coverage(quiet = FALSE)
          print(cov)
          covr::to_badge(cov, "coverage.svg")
        shell: Rscript {0}

      - name: Publish coverage badge
        if: github.event_name == 'push'
        run: |
          mkdir "$RUNNER_TEMP/badges"
          cp coverage.svg "$RUNNER_TEMP/badges"
          cd "$RUNNER_TEMP/badges"
          git init -b badges
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add coverage.svg
          git commit -m "Update coverage badge"
          git push --force "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" badges
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Then link to the badge in your README:

```md
![Test coverage](https://raw.githubusercontent.com/OWNER/REPO/badges/coverage.svg)
```

The same approach works on other forges, such as Codeberg or GitLab, or you can
commit the badge to the repository when you update your README.

# Usage #

For local development a coverage report can be used to inspect coverage for
each line in your package. *Note* requires the
[htmltools](https://github.com/rstudio/htmltools) package to be installed.
`report_html()` creates the same report to include in an R Markdown or Quarto
document.

```r
library(covr)

# If run with no arguments implicitly calls `package_coverage()`
report()
```

covr also defines an [RStudio Addin](https://rstudio.github.io/rstudioaddins/),
which runs `report()` on the active project. This can be used via the Addin
menu or by binding the action to a
[shortcut](https://rstudio.github.io/rstudioaddins/#keyboard-shorcuts), e.g.
*Ctrl-Shift-C*.

## Interactively ##
```r
# If run with the working directory within the package source.
package_coverage()

# or a package in another directory
cov <- package_coverage("/dir/lintr")

# view results as a data.frame
as.data.frame(cov)

# zero_coverage() shows only uncovered lines.
# If run within RStudio, `zero_coverage()` will open a marker pane with the
# uncovered lines.
zero_coverage(cov)

# or the functions which were never run
zero_coverage(cov, by = "function")
```

# Exclusions #

`covr` supports a few of different ways of excluding some or all of a file.

## .covrignore file ##

A `.covrignore` file located in your package's root directory can be used to
exclude files or directories.

The lines in the `.covrignore` file are interpreted as a list of file globs to
ignore. It uses the globbing rules in `Sys.glob()`. Any directories listed will
ignore all the files in the directory. Paths are relative to the package root
and refer to the source files being measured (e.g. files in `R/` or `src/`),
not to test files. For example, to ignore a single file, all files matching a
wildcard, and every file in a directory:

```
R/deprecated.R
R/zzz*.R
src/vendor
```

Alternative locations for the file can be set by the environment variable
`COVR_COVRIGNORE` or the R option `covr.covrignore`.

The `.covrignore` file should be added to your `.RBuildignore` file unless you
want to distribute it with your package. If so it can be added to
`inst/.covrignore` instead.


## Function Exclusions ##
The `function_exclusions` argument to `package_coverage()` can be used to
exclude functions by name. This argument takes a vector of regular expressions
matching functions to exclude.

```r
# exclude print functions
package_coverage(function_exclusions = "print\\.")

# exclude `.onLoad` function
package_coverage(function_exclusions = "\\.onLoad")
```

## Line Exclusions ##
The `line_exclusions` argument to `package_coverage()` can be used to exclude some or
all of a file.  This argument takes a list of filenames or named ranges to
exclude.

```r
# exclude whole file of R/test.R
package_coverage(line_exclusions = "R/test.R")

# exclude lines 1 to 10 and 15 from R/test.R
package_coverage(line_exclusions = list("R/test.R" = c(1:10, 15)))

# exclude lines 1 to 10 from R/test.R, all of R/test2.R
package_coverage(line_exclusions = list("R/test.R" = c(1, 10), "R/test2.R"))
```

## Exclusion Comments ##

In addition you can exclude lines from the coverage by putting special comments
in your source code.

This can be done per line.
```r
f1 <- function(x) {
  x + 1 # nocov
}
```

Or by specifying a range with a start and end.
```r
f2 <- function(x) { # nocov start
  x + 2
} # nocov end
```

The patterns used can be specified by setting the global options
`covr.exclude_pattern`, `covr.exclude_start`, `covr.exclude_end`.

NB: The same pattern applies to exclusions in the `src` folder, so skipped lines in, e.g., C code (where comments can start with `//`) should look like `// # nocov`.

# FAQ #
## Should I add covr to my package's Suggests? ##
It isn't required, as covr is usually only used in CI rather than by your
package's code. It is useful though: `devtools::install()` and `pak::pak()`
will then install covr for local development, and it helps us see which
packages use covr. `usethis::use_coverage()` adds it for you.

## Will covr work with testthat, RUnit, etc... ##
Covr should be compatible with any testing package, it uses
`tools::testInstalledPackage()` to run your packages tests.

## Why are tests using `skip_on_cran()` not counted in my coverage? ##
`package_coverage()` runs your tests non-interactively in a separate R
process, so testthat assumes it is running on CRAN unless the `NOT_CRAN`
environment variable is `"true"`. Tests that call `skip_on_cran()` are then
skipped, and the code they exercise is reported as uncovered. To include
them, set the variable before computing coverage:

```r
Sys.setenv(NOT_CRAN = "true")
package_coverage()
```

`devtools::test_coverage()` sets `NOT_CRAN` for you.

## Can covr measure the coverage of a Shiny app? ##
Yes, including tests that run the app with shinytest2. Use
`package_coverage()` for an app in a package, and `shiny_app_coverage()` for
other apps. The vignette
[vignettes/shiny.Rmd](https://github.com/r-lib/covr/blob/main/vignettes/shiny.Rmd)
describes both.

```r
vignette("shiny", package = "covr")
```

## Will covr work with alternative compilers? ##

Covr is known to work with clang versions `3.5+` and gcc version `4.2+`.

If the appropriate gcov version is not on your path you can set the appropriate
location with the `covr.gcov` options. If you set this path to "" it will turn
_off_ coverage of compiled code.
```r
options(covr.gcov = "path/to/gcov")
```

## Can covr measure the coverage of Rust code? ##
Yes. `package_coverage()` measures the coverage of the Rust code in `src/`,
e.g. of packages using [extendr](https://extendr.github.io/) or
[savvy](https://yutannihilation.github.io/savvy/guide/), with LLVM's
source-based coverage. This needs the llvm tools of your Rust toolchain:

```sh
rustup component add llvm-tools
```

If Rust is installed by your Linux distribution (e.g. with
`apt-get install cargo rustc`), install the LLVM version that rustc uses
instead, e.g. `apt-get install llvm-18` if `rustc -vV` shows
`LLVM version: 18.1.3`.

Without the tools covr warns and reports no coverage for the Rust code. Set
`options(covr.llvm_cov = "")` to turn off the coverage of Rust code.

On GitHub Actions, add a step that installs the tools before computing
coverage, e.g. in the `test-coverage.yaml` workflow from
`usethis::use_github_action("test-coverage")`, after `setup-r-dependencies`:

```yaml
      - name: Install Rust's llvm-tools
        run: rustup component add llvm-tools
```

Exclusions work in Rust files too, e.g. `// # nocov` at the end of a line.
Code generated by macros such as `#[extendr]` or `#[savvy]` counts on the
macro's line, which is only covered if all of that code runs, e.g. including
the errors for arguments that can't be converted.

This isn't supported on Windows, as rustup's Rust for the GNU ABI that Rtools
uses (`x86_64-pc-windows-gnu`) doesn't include the profiler runtime that
writes the coverage counts.

## How does covr work? ##
`covr` tracks test coverage by modifying a package's code to add tracking calls
to each call.

The vignette
[vignettes/how_it_works.Rmd](https://github.com/r-lib/covr/blob/master/vignettes/how_it_works.Rmd)
contains a detailed explanation of the technique and the rationale behind it.

You can view the vignette from within `R` using

```r
vignette("how_it_works", package = "covr")
```

## Why can't covr run during R CMD check ##
Because covr modifies the package code it is possible there are unknown edge
cases where that modification affects the output. In addition when tracking
coverage for compiled code covr compiles the package without optimization,
which _can_ modify behavior (usually due to package bugs which are masked with
higher optimization levels).

# Alternative Coverage Tools #
- <https://github.com/MangoTheCat/testCoverage> (no longer supported)
- [**R-coverage**](https://web.archive.org/web/20160611114452/http://r2d2.quartzbio.com/posts/r-coverage-docker.html) (no longer supported)

## Code of Conduct

Please note that the covr project is released with a [Contributor Code of Conduct](https://github.com/r-lib/covr/blob/main/CODE_OF_CONDUCT.md). By contributing to this project, you agree to abide by its terms.
