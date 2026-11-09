test_that("one-line functions are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function(x) x + 1

  expect_equal(
    as.character(body(trace_calls(fun))[[3]][[2]][[2]]),
    c(":::", "covr", "covr_count")
  )

  fun <- function() 1

  expect_equal(
    as.character(body(trace_calls(fun))[[3]][[2]][[2]]),
    c(":::", "covr", "covr_count")
  )

  expect_equal(body(trace_calls(fun))[[3]][[3]], body(fun))
})
test_that("one-line functions with no calls are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function(x) x

  expect_equal(
    as.character(body(trace_calls(fun))[[3]][[2]][[2]]),
    c(":::", "covr", "covr_count")
  )

  expect_equal(body(trace_calls(fun))[[3]][[3]], body(fun))
})
test_that("one-line functions with braces are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function(x) {
    x + 1
  }

  expect_equal(
    as.character(body(trace_calls(fun))[[2]][[3]][[2]][[2]]),
    c(":::", "covr", "covr_count")
  )

  expect_equal(body(trace_calls(fun))[[2]][[3]][[3]], body(fun)[[2]])
})

test_that("one-line functions with no calls and braces are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function() {
    1
  }

  e2 <- body(trace_calls(fun))[[2]][[3]]
  expect_true(
    length(e2) > 1 &&
      identical(as.character(e2[[2]][[2]]), c(":::", "covr", "covr_count"))
  )

  fun <- function(x) {
    x
  }

  e2 <- body(trace_calls(fun))[[2]][[3]]

  # the second expr should be a block
  expect_true(
    length(e2) > 1 &&
      identical(as.character(e2[[2]][[2]]), c(":::", "covr", "covr_count"))
  )
})


test_that("last evaled expression is traced", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function() {
    x <- 1
    x
  }

  body <- body(trace_calls(fun))

  expect_equal(length(body), 3)

  # last expression: the implicit return expression
  e3 <- body[[3]][[3]]
  expect_true(
    length(e3) > 1 &&
      identical(as.character(e3[[2]][[2]]), c(":::", "covr", "covr_count"))
  )
})

test_that("functions with NULL bodies are traced correctly", {
  old <- options(keep.source = TRUE)
  on.exit(options(old))

  fun <- function() NULL

  expect_null(trace_calls(fun)())
})

test_that("functions with curly curly syntax are traced correctly", {
  my_capture <- function(x) {
    rlang::expr({{ x }})
  }
  expect_equal(my_capture(5 == 1), rlang::quo(5 == 1))

  # behavior not changed by covr
  my_capture2 <- trace_calls(my_capture)
  expect_equal(my_capture2(5 == 1), rlang::quo(5 == 1))

  # outer code traced traced with ({  })
  expect_equal(as.character(body(my_capture2)[[2]][[1]]), "if")
  expect_equal(as.character(body(my_capture2)[[2]][[3]][[1]]), "{")
  expect_equal(
    as.character(body(my_capture2)[[2]][[3]][[2]][[2]]),
    c(":::", "covr", "covr_count")
  )

  # no trace in the internal {{  }}
  expect_equal(as.character(body(my_capture2)[[2]][[3]][[3]][[2]][[1]]), "{")
  expect_equal(
    as.character(body(my_capture2)[[2]][[3]][[3]][[2]][[2]][[1]]),
    "{"
  )
})


test_that("functions that rely on implicit invisibility work the same", {
  f <- function(x) {
    x <- 1
  }

  f2 <- trace_calls(f)

  expect_equal(withVisible(f2(1)), withVisible(f(1)))

  f3 <- function(x) {
    x + 1
  }

  f4 <- trace_calls(f3)

  expect_equal(withVisible(f3(1)), withVisible(f4(1)))
})


test_that("functions that use S3 dispatch work", {
  cov <- code_coverage(
    source_code = '
foo <- function(x) {
  UseMethod("foo")
}

foo.bar <- function(x) { x[[1]] + 1 }

bar <- function(x) {
  structure(list(x), class = "bar")
}
',
    test_code = '
stopifnot(foo(bar(1)) == 2)
'
  )
  expect_equal(percent_coverage(cov), 100)
})

test_that("the C counter counts, survives retracing and resets", {
  skip_on_cran()
  clear_counters()
  withr::defer(clear_counters())
  env <- new.env()
  env$f <- function(x) {
    x + 1
  }
  original <- env$f
  env$f <- trace_calls(original)
  expect_true(is_traced(env$f))
  env$f(1)
  env$f(1)
  sync_counts()
  value <- function() {
    unlist(lapply(as.list(.counters), `[[`, "value"))
  }
  expect_equal(unname(value()), rep(2, length(value())))

  # Tracing again keeps the count of each trace (#641)
  keys <- names(value())
  ptrs <- mget(keys, envir = .count_ptrs)
  env$g <- trace_calls(original)
  expect_identical(mget(keys, envir = .count_ptrs), ptrs)
  expect_equal(unname(value()[keys]), rep(2, length(keys)))

  # A function serialized and unserialized, as when it's sent to another
  # process, runs but doesn't count
  h <- unserialize(serialize(env$f, NULL))
  expect_equal(h(1), 2)
  sync_counts()
  expect_equal(unname(value()[keys]), rep(2, length(keys)))

  env$f(1)
  zero_counters()
  sync_counts()
  expect_equal(unname(value()), rep(0, length(value())))

  # After clearing, a key keeps its count, so a function instrumented before
  # still counts into its own trace once it is traced again
  env$f(1)
  clear_counters()
  expect_length(.Call(covr_counter_take), 0L)
  expect_length(ls(.counters), 0)
  env$g <- trace_calls(original)
  expect_identical(mget(keys, envir = .count_ptrs), ptrs)
  env$f(1)
  sync_counts()
  expect_equal(unname(value()[keys]), rep(1, length(keys)))
})

test_that("a `.Call` where the traced function lives doesn't mask the counter", {
  skip_on_cran()
  clear_counters()
  withr::defer(clear_counters())
  env <- new.env()
  env$.Call <- function(...) stop("the local `.Call` was called")
  env$f <- eval(
    parse(text = "function(x) {\n  x + 1\n}", keep.source = TRUE)[[1]],
    env
  )
  f <- trace_calls(env$f)
  expect_equal(f(1), 2)
  sync_counts()
  expect_equal(unname(unlist(eapply(.counters, `[[`, "value"))), 1)
})

test_that("primitive functions are not traced", {
  expect_identical(trace_calls(sum), sum)
})

test_that("is_traced() is FALSE for primitives and non-functions", {
  expect_identical(is_traced(sum), FALSE)
  expect_identical(is_traced(1), FALSE)
})

test_that("trace_calls reports objects it cannot trace and returns them unchanged", {
  env <- globalenv()
  expect_snapshot(res <- trace_calls(env))
  expect_identical(res, env)
})
