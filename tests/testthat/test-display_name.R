test_that("display_name() returns the paths relative to the root", {
  cov <- coverage_of_files(
    c("/tmp/pkg/R/a.R", "/tmp/pkg/src/b.c", "/other/c.R"),
    root = "/tmp/pkg"
  )

  expect_equal(
    unname(display_name(cov)),
    c("R/a.R", "src/b.c", "/other/c.R")
  )
  expect_null(display_name(cov[0]))
  expect_snapshot(display_name(list()), error = TRUE)
})

test_that("display_name() keeps paths when there is no root", {
  cov <- coverage_of_files(c("/tmp/pkg/R/a.R", "/other/c.R"))

  expect_equal(unname(display_name(cov)), c("/tmp/pkg/R/a.R", "/other/c.R"))
})

test_that("to_relative_path() only strips a root at the start of the path", {
  expect_equal(
    to_relative_path(
      c(
        "/tmp/pkg/R/a.R",
        "/other/tmp/pkg/R/a.R",
        "/tmp/pkg2/R/a.R",
        "/tmp/pkg",
        NA
      ),
      "/tmp/pkg"
    ),
    c("R/a.R", "/other/tmp/pkg/R/a.R", "/tmp/pkg2/R/a.R", "/tmp/pkg", NA)
  )
  expect_equal(to_relative_path("/tmp/pkg/R/a.R", "/tmp/pkg/"), "R/a.R")
  expect_equal(to_relative_path("/tmp/pkg/R/a.R", "/"), "tmp/pkg/R/a.R")
  expect_equal(to_relative_path("/tmp/a+b/R/a.R", "/tmp/a+b"), "R/a.R")
  expect_equal(to_relative_path("/tmp/aab/R/a.R", "/tmp/a+b"), "/tmp/aab/R/a.R")
  expect_equal(to_relative_path("a/R/a.R", NULL), "a/R/a.R")
})

test_that("path_in_roots() compares whole path components", {
  expect_equal(
    path_in_roots(
      normalize_path(
        c("/tmp/pkg/R/a.R", "/tmp/pkg2/R/a.R", "/other/tmp/pkg/R/a.R", NA)
      ),
      "/tmp/pkg"
    ),
    c(TRUE, FALSE, FALSE, NA)
  )
  expect_equal(
    path_in_roots(
      normalize_path(c("/a/x.c", "/b/y.c", "/c/z.c")),
      c("/a", "/b/")
    ),
    c(TRUE, TRUE, FALSE)
  )
})

test_that("filter_non_package_files() keeps the files in the package", {
  cov <- coverage_of_files(
    normalize_path(c(
      "/tmp/pkg/R/a.R",
      "/tmp/pkg/src/b.c",
      "/other/tmp/pkg/R/a.R",
      "/tmp/pkg2/R/a.R"
    )),
    package_path = "/tmp/pkg"
  )

  filtered <- filter_non_package_files(cov)
  expect_equal(
    unname(vcapply(filtered, function(x) {
      get_source_filename(x$srcref, full.names = TRUE)
    })),
    normalize_path(c("/tmp/pkg/R/a.R", "/tmp/pkg/src/b.c"))
  )
  expect_s3_class(filtered, "coverage")
  expect_equal(attr(filtered, "package"), list(path = "/tmp/pkg"))
})

test_that("covr.gcov_additional_paths keeps the native files in them", {
  files <- normalize_path(c(
    "/tmp/pkg/R/a.R",
    "/ext/lib/x.c",
    "/ext/lib/x.h",
    "/ext/lib/lib.rs",
    "/ext/lib/not-native.R",
    "/ext2/lib/y.c",
    "/elsewhere/z.c"
  ))
  cov <- coverage_of_files(files, package_path = "/tmp/pkg")
  kept <- function() {
    unname(vcapply(filter_non_package_files(cov), function(x) {
      get_source_filename(x$srcref, full.names = TRUE)
    }))
  }

  expect_equal(kept(), files[1])

  withr::local_options(covr.gcov_additional_paths = "/ext")
  expect_equal(kept(), files[1:4])

  withr::local_options(covr.gcov_additional_paths = c("/ext/lib/", "/ext2"))
  expect_equal(kept(), files[c(1:4, 6)])
})
