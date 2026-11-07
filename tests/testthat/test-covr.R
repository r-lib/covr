test_that("function_coverage", {
  withr::with_options(c(keep.source = TRUE), {
    f <- function(x) {
      x + 1
    }
    expect_equal(
      as.numeric(function_coverage("f", env = environment(f))[[1]]$value),
      0
    )

    expect_equal(
      as.numeric(function_coverage("f", env = environment(f), f(1))[[1]]$value),
      1
    )

    expect_equal(
      as.numeric(
        function_coverage("f", env = environment(f), f(1), f(1))[[1]]$value
      ),
      2
    )
  })
})

test_that("function_coverage identity function", {
  withr::with_options(c(keep.source = TRUE), {
    fun <- function(x) {
      x
    }

    cov_num <- function(...) {
      as.numeric(
        function_coverage("fun", env = environment(fun), ...)[[1]]$value
      )
    }

    expect_equal(cov_num(), 0)
    expect_equal(cov_num(fun(1)), 1)
  })
})

test_that("function_coverage return last expr", {
  withr::with_options(c(keep.source = TRUE), {
    fun <- function(x = 1) {
      x
      x <- 1
    }

    cov_fun <- function(...) {
      vdapply(
        function_coverage("fun", env = environment(fun), ...),
        "[[",
        "value"
      )
    }

    expect_equal(as.numeric(cov_fun()), c(0L, 0L))
    expect_equal(as.numeric(cov_fun(fun())), c(1L, 1L))
  })
})

test_that("duplicated first_line", {
  withr::with_options(c(keep.source = TRUE), {
    fun <- function() {
      # fmt: skip
      res <- lapply(1:2, function(x) { x + 1 }) # nolint
    }
    cov <- function_coverage("fun", env = environment(fun))
    first_lines <- as.data.frame(cov)$first_line
    expect_equal(length(first_lines), 2)
    expect_equal(first_lines[1], first_lines[2])
  })
})

test_that("trace calls handles all possibilities", {
  expr <- expression(y <- x * 10)

  expect_equal(trace_calls(expr), expr)

  expect_equal(trace_calls(list(expr)), list(expr))
})

test_that("show_failures shows as much text as it can from the end", {
  withr::with_options(c(warning.length = 300), {
    td <- tempfile()
    dir.create(td)

    out <- file.path(td, "test.Rout.fail")
    on.exit(unlink(td, recursive = TRUE))
    writeLines(
      "Lorem ipsum dolor sit amet, at erat praesent est mi ultrices. Eget in platea ac auctor et eu et venenatis. Tellus volutpat pellentesque. Dis nulla sem dignissim venenatis. Consequat montes maecenas congue donec ac himenaeos sed sed tempus. Ipsum risus lacus? Malesuada lectus, lacus egestas et lacus, in in ut sed. Tempus ligula dignissim a elementum semper maecenas eu. Enim pellentesque turpis at et ligula in est ut. Accumsan quis fermentum convallis proin ligula primis ut, curabitur. Sociosqu, fringilla, eu lacus eleifend conubia pellentesque viverra.",
      out
    )

    # Expect the error to contain the end of the file
    expect_error(
      show_failures(td),
      "eleifend conubia pellentesque viverra.",
      fixed = TRUE,
      class = "covr_error"
    )
  })
})

test_that("clean_coverage_tests works with degenerated objects", {
  obj <- list(
    a = list(tests = new.env()),
    tests = structure(
      list(structure(
        list("a", "b"),
        call_count = 1L
      )),
      names = ""
    ),
    b = list(value = integer(0)),
    c = list(value = NA)
  )

  expect_no_error(
    covr:::clean_coverage_tests(obj)
  )
})

test_that("merge_coverage sums the counts of shared traces", {
  a <- list(t1 = list(value = 1L), t2 = list(value = 2L))
  b <- list(t2 = list(value = 3L), t3 = list(value = 4L), t1 = list(value = 5L))
  merged <- merge_coverage(list(a, b))
  expect_equal(names(merged), c("t1", "t2", "t3"))
  expect_equal(
    vapply(merged, `[[`, integer(1), "value"),
    c(t1 = 6L, t2 = 5L, t3 = 4L)
  )
})

test_that("package_coverage keeps install_path only when coverage fails", {
  install_path <- tempfile("R_LIBS")
  on.exit(unlink(install_path, recursive = TRUE), add = TRUE)
  expect_error(
    package_coverage(test_path("TestFailure"), install_path = install_path),
    class = "covr_error"
  )
  fail_files <- list.files(install_path, pattern = "fail$", recursive = TRUE)
  expect_equal(basename(fail_files), "testthat.Rout.fail")

  install_path <- tempfile("R_LIBS")
  package_coverage(test_path("TestSummary"), install_path = install_path)
  expect_false(dir.exists(install_path))
})

test_that("package_coverage errors on test failures by default", {
  expect_error(
    package_coverage(test_path("TestFailure")),
    "this test fails",
    class = "covr_error"
  )
})

test_that("covr.allow_failures returns coverage despite test failures", {
  withr::local_options(covr.allow_failures = TRUE)
  expect_warning(
    cov <- package_coverage(test_path("TestFailure")),
    "this test fails",
    class = "covr_warning"
  )
  values <- tapply(
    tally_coverage(cov)$value,
    tally_coverage(cov)$functions,
    sum
  )
  expect_gt(values[["covered"]], 0)
  expect_equal(values[["not_covered"]], 0)
})
