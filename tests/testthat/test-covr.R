test_that("function_coverage", {

  withr::with_options(c(keep.source = TRUE), {
      f <- function(x) {
        x + 1
      }
      expect_equal(as.numeric(function_coverage("f", env = environment(f))[[1]]$value), 0)

      expect_equal(as.numeric(function_coverage("f", env = environment(f), f(1))[[1]]$value), 1)

      expect_equal(as.numeric(function_coverage("f", env = environment(f), f(1), f(1))[[1]]$value), 2)
    })
})

test_that("function_coverage identity function", {

  withr::with_options(c(keep.source = TRUE), {
    fun <- function(x) {
      x
    }

    cov_num <- function(...) {
      as.numeric(function_coverage("fun", env = environment(fun), ...)[[1]]$value)
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
      vdapply(function_coverage("fun", env = environment(fun), ...), "[[", "value")
    }

    expect_equal(as.numeric(cov_fun()), c(0L, 0L))
    expect_equal(as.numeric(cov_fun(fun())), c(1L, 1L))
  })
})

test_that("duplicated first_line", {
  withr::with_options(c(keep.source = TRUE), {

    fun <- function() {
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
    expect_error(show_failures(td), "eleifend conubia pellentesque viverra.", fixed = TRUE, class = "covr_error")
  })
})
