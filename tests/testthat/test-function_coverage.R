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

test_that("function_coverage generates output", {
  env <- new.env()
  withr::with_options(c("keep.source" = TRUE), {
    eval(
      parse(
        text = "fun <- function(x) {
  if (isTRUE(x)) {
    1
  } else {
    2
  }
}"
      ),
      envir = env
    )
  })

  t1 <- function_coverage("fun", env = env)

  expect_equal(length(t1), 3)

  expect_equal(length(exclude(t1)), 3)

  expect_equal(length(exclude(t1, "<text>")), 0)

  expect_equal(length(exclude(t1, list("<text>" = 3))), 2)
})

test_that("function_coverage() finds a function by name without an env", {
  withr::with_options(list(keep.source = TRUE), {
    eval(parse(text = "covr_test_f <- function() { 42L }"), envir = globalenv())
  })
  withr::defer(rm("covr_test_f", envir = globalenv()))

  cov <- function_coverage("covr_test_f", covr_test_f())
  expect_equal(percent_coverage(cov), 100)
  expect_equal(percent_coverage(function_coverage("covr_test_f")), 0)
})
