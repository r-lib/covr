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
  expect_gt(length(e2), 1)
  expect_identical(as.character(e2[[2]][[2]]), c(":::", "covr", "covr_count"))

  fun <- function(x) {
    x
  }

  e2 <- body(trace_calls(fun))[[2]][[3]]

  # the second expr should be a block
  expect_gt(length(e2), 1)
  expect_identical(as.character(e2[[2]][[2]]), c(":::", "covr", "covr_count"))
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
  expect_gt(length(e3), 1)
  expect_identical(as.character(e3[[2]][[2]]), c(":::", "covr", "covr_count"))
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
  env$g <- trace_calls(original)
  expect_equal(unname(value()[keys]), rep(2, length(keys)))

  # A function serialized and unserialized, as when it's saved, counts into
  # the same traces
  h <- unserialize(serialize(env$f, NULL))
  expect_equal(h(1), 2)
  sync_counts()
  expect_equal(unname(value()[keys]), rep(3, length(keys)))

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
  env$f(1)
  sync_counts()
  expect_equal(unname(value()[keys]), rep(1, length(keys)))
})

test_that("the C counter counts keys by their string, ignoring unknown keys", {
  clear_counters()
  withr::defer(clear_counters())
  .Call(covr_counter_reset)
  utf8 <- enc2utf8("R/\u00e9.R:1:1")
  latin1 <- iconv(utf8, "UTF-8", "latin1")
  expect_identical(Encoding(latin1), "latin1")
  register_count(c("a.R:1:1", utf8))
  register_count(c("a.R:1:1", latin1))

  for (key in c("a.R:1:1", "a.R:1:1", utf8, latin1, "unknown.R:1:1")) {
    expect_null(.Call(covr_count, key))
  }
  counts <- .Call(covr_counter_take)
  expect_equal(counts[["a.R:1:1"]], 2)
  expect_equal(counts[[utf8]], 2)
  expect_length(counts, 2L)
})

test_that("is_traced() finds the counter at the start of the body, or anywhere", {
  clear_counters()
  withr::defer(clear_counters())
  src <- srcfilecopy("t.R", c("f <- function(x) {", "  x + 1", "}"))
  f <- eval(parse(text = src$lines, keep.source = TRUE, srcfile = src)[[1]])
  expect_false(is_traced(f))

  traced <- trace_calls(f)
  expect_true(starts_with_count(body(traced)))
  expect_true(is_traced(traced))

  later <- f
  body(later) <- as.call(list(as.name("{"), quote(x), body(traced)[[2]]))
  expect_false(starts_with_count(body(later)))
  expect_true(is_traced(later))

  names_only <- f
  body(names_only) <- quote({
    covr:::covr_count
    x
  })
  expect_false(is_traced(names_only))

  expect_false(starts_with_count(quote(x)))
  expect_false(starts_with_count(quote({
    if (TRUE) x
  })))
})

test_that("the C counter grows to many keys of different encodings", {
  clear_counters()
  withr::defer(clear_counters())
  .Call(covr_counter_reset)
  take <- function() {
    x <- .Call(covr_counter_take)
    setNames(as.numeric(x), enc2utf8(names(x)))
  }
  count <- function(key) .Call(covr_count, key)
  i <- 1:5000
  ascii <- sprintf("f%d.R:%d:1", i, i)
  utf8 <- enc2utf8(sprintf("\u00e9%d.R:%d:1", i, i))
  latin1 <- iconv(utf8, "UTF-8", "latin1")

  for (chunk in split(i, ceiling(i / 997))) {
    register_count(ascii[chunk])
    register_count(utf8[chunk])
    register_count(latin1[chunk])
  }
  expect_length(take(), 0L)

  for (j in i) {
    for (key in rep(ascii[j], j %% 5L + 1L)) {
      count(key)
    }
    for (key in rep(utf8[j], j %% 3L)) {
      count(key)
    }
    for (key in rep(latin1[j], j %% 4L)) {
      count(key)
    }
  }
  count("unregistered.R:1:1")
  got <- take()

  expect_equal(unname(got[ascii]), i %% 5 + 1)
  both <- i %% 3 + i %% 4
  expect_equal(unname(got[utf8[both > 0]]), both[both > 0])
  expect_length(got, 5000L + sum(both > 0))

  # Counts start again from zero for the keys that are still registered
  count(ascii[1])
  expect_equal(take(), setNames(1, ascii[1]))
})

test_that("a `.Call` where the traced functions live doesn't mask the counter", {
  clear_counters()
  withr::defer(clear_counters())
  env <- new.env()
  env$.Call <- function(...) stop("the local `.Call` was called")
  env$f <- eval(
    parse(text = "function(x) {\n  x + 1\n}", keep.source = TRUE)[[1]],
    env
  )
  trace_environment(env)
  withr::defer(reset_traces())
  expect_equal(env$f(1), 2)
  # Tracing again doesn't instrument the traced function again
  trace_environment(env)
  expect_equal(env$f(1), 2)
  sync_counts()
  # The local `.Call` is traced too, but never called
  expect_equal(sort(unname(unlist(eapply(.counters, `[[`, "value")))), c(0, 2))
})

test_that("a `.Call` where a function lives doesn't mask the counters of function_coverage()", {
  env <- new.env()
  env$.Call <- function(...) stop("the local `.Call` was called")
  env$f <- eval(
    parse(text = "function(x) {\n  x + 1\n}", keep.source = TRUE)[[1]],
    env
  )
  cov <- function_coverage("f", env$f(1), env = env)
  expect_equal(as.data.frame(cov)$value, 1)
})

test_that("counters only call `base::.Call` where `.Call` is masked", {
  env <- new.env(parent = baseenv())
  expect_identical(dot_call(env), as.symbol(".Call"))
  # Calls only find functions
  env$.Call <- 1
  expect_identical(dot_call(env), as.symbol(".Call"))
  env$.Call <- function(...) base::.Call(...)
  expect_identical(dot_call(env), quote(base::.Call))
  expect_identical(dot_call(new.env(parent = env)), quote(base::.Call))
})

test_that("instrumented code has no function objects in it", {
  # Code that walks the calls of a function and expects each function in them
  # to have a body and an environment fails on primitives. callr does, to remove
  # the source references of a function it sends to another process.
  clear_counters()
  withr::defer(clear_counters())
  has_function <- function(x) {
    if (is.function(x)) {
      return(TRUE)
    }
    if (!is.call(x)) {
      return(FALSE)
    }
    for (i in seq_along(x)) {
      if (!identical(x[[i]], quote(expr = )) && has_function(x[[i]])) {
        return(TRUE)
      }
    }
    FALSE
  }
  src <- paste(
    "function(x) {",
    "  lapply(x, function(y) {",
    "    if (y) 1 else 2",
    "  })",
    "}",
    sep = "\n"
  )
  f <- eval(parse(text = src, keep.source = TRUE)[[1]], new.env())
  traced <- trace_calls(f)
  expect_true(is_traced(traced))
  expect_false(has_function(body(traced)))
  expect_equal(traced(c(TRUE, FALSE)), list(1, 2))
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

test_that("trace calls handles all possibilities", {
  expr <- expression(y <- x * 10)

  expect_equal(trace_calls(expr), expr)

  expect_equal(trace_calls(list(expr)), list(expr))
})

test_that("if", {
  f <-
    'f <- function(x) {
  if (FALSE)
    FALSE # never covered, used as anchor
  if (x)
    TRUE
  else
    FALSE
}'

  cov <- code_coverage(f, "f(TRUE)")
  expect_equal(zero_coverage(code_coverage(f, "f(TRUE)"))$line, c(3, 7))
  expect_equal(zero_coverage(code_coverage(f, "f(FALSE)"))$line, c(3, 5))
  expect_equal(zero_coverage(code_coverage(f, "f(TRUE);f(FALSE)"))$line, 3)
})

test_that("nested if else", {
  f <-
    'f <- function(x) {
  if (FALSE)
    FALSE # never covered, used as anchor
  else if (x)
    TRUE
  else
    FALSE
}'

  cov <- code_coverage(f, "f(TRUE)")
  expect_equal(zero_coverage(code_coverage(f, "f(TRUE)"))$line, c(3, 7))
  expect_equal(zero_coverage(code_coverage(f, "f(FALSE)"))$line, c(3, 5))
  expect_equal(zero_coverage(code_coverage(f, "f(TRUE);f(FALSE)"))$line, 3)
})

test_that("one-line if in the body of a function without braces (#279)", {
  f <- "f <- function(x) if (x) 1 else 2"

  for (code in c("f(TRUE)", "f(FALSE)")) {
    cov <- code_coverage(f, code)
    expect_equal(percent_coverage(cov, by = "line"), 0)
    expect_equal(percent_coverage(cov, by = "expression"), 75)
  }

  cov <- code_coverage(f, "f(TRUE); f(FALSE)")
  expect_equal(percent_coverage(cov, by = "line"), 100)
  expect_equal(percent_coverage(cov, by = "expression"), 100)
})

test_that("braceless function bodies are covered like braced ones (#279)", {
  braceless <- "f <- function(x) if (x)
  1 else
  2"
  braced <- "f <- function(x) { if (x)
  1 else
  2 }"

  for (code in c("f(TRUE)", "f(FALSE)", "f(TRUE); f(FALSE)")) {
    cov_braceless <- code_coverage(braceless, code)
    cov_braced <- code_coverage(braced, code)
    expect_equal(
      zero_coverage(cov_braceless)$line,
      zero_coverage(cov_braced)$line
    )
    expect_equal(percent_coverage(cov_braceless), percent_coverage(cov_braced))
  }
  expect_equal(zero_coverage(code_coverage(braceless, "f(TRUE)"))$line, 3)
  expect_equal(zero_coverage(code_coverage(braceless, "f(FALSE)"))$line, 2)
  expect_equal(percent_coverage(code_coverage(braceless, "f(TRUE)")), 200 / 3)
})

test_that("if nested in other calls (#279)", {
  f <- 'f <- function(x) {
  y <- if (x)
    "a"
  else
    "b"
  z <- list(if (x) "c" else "d", e = paste(if (x) "f" else "g"))
  lapply(1, function(i) if (x) i else -i)
  (if (x) "h" else "i") -> a
  paste(switch(as.character(x), "TRUE" = "j", "k"))
}'

  res <- as.data.frame(code_coverage(f, "f(FALSE)"))
  expect_equal(res$first_line[res$value == 0], c(3, 6, 6, 7, 8, 9))
  expect_equal(res$first_column[res$value == 0], c(5, 20, 51, 32, 11, 42))
})

test_that("switch", {
  f <-
    'f <- function(x) {
  switch(x,
    a = 1,
    b = 2,
    c = d <- 1
  )
}'

  expect_equal(
    length(zero_coverage(code_coverage(f, "f(\"a\"); f(\"b\")"))$line),
    1
  )
  expect_equal(
    length(zero_coverage(code_coverage(f, "f(\"a\"); f(\"c\")"))$line),
    1
  )
  expect_equal(
    diff(zero_coverage(code_coverage(f, "f(\"a\"); f(\"d\")"))$line),
    1
  )
})

test_that("switch with default value", {
  f <-
    'f <- function(x) {
  switch(x,
    a = 1,
    b = 2,
    c = d <- 1,
    NULL
  )
}'

  expect_equal(
    length(
      zero_coverage(code_coverage(f, "f(\"a\"); f(\"b\"); f(\"c\")"))$line
    ),
    1
  )

  expect_equal(
    length(zero_coverage(code_coverage(f, "f(\"a\"); f(\"c\")"))$line),
    2
  )
})

test_that("switch with drop through", {
  f <-
    'f <- function(x) {
  switch(x,
    a = ,
    b = 2,
    c = d <- 1,
    NULL
  )
}'

  res <- as.data.frame(code_coverage(f, 'f("a");f("b");f("c")'))
  expect_equal(res$first_line, c(2, 4, 5, 6))
  expect_equal(res$value, c(3, 2, 1, 0))
})

test_that("switch with trailing comma", {
  f <-
    'f <- function(x) {
  switch(x,
    a = 1,
    b = 2,
  )
}'

  expect_no_warning(
    res <- as.data.frame(code_coverage(f, 'f("a");f("a");f("b")'))
  )
  expect_equal(res$first_line, c(2, 3, 4))
  expect_equal(res$value, c(3, 2, 1))
})

test_that("switch with drop through and the base pipe (#630)", {
  skip_if(getRversion() < "4.1")
  f <-
    'f <- function(x) {
  x |>
    switch(
      a = ,
      b = 2,
      c = d <- 1,
      NULL
    )
}'

  res <- as.data.frame(code_coverage(f, 'f("a");f("b");f("c")'))
  expect_equal(res$first_line, c(2, 5, 6, 7))
  expect_equal(res$value, c(3, 2, 1, 0))
})

test_that("switch with ellipses", {
  f <-
    'f <- function(x, ...) {
  switch(typeof(x), ...)
}'

  res <- as.data.frame(code_coverage(f, "f(\"a\", character = TRUE)"))
  expect_equal(res$first_line, 2)
  expect_equal(res$value, 1)

  f <-
    'f <- function(x, ...) {
  switch(typeof(x),
    ...,
    character = TRUE)
}'

  res <- as.data.frame(code_coverage(f, "f(\"a\")"))
  expect_equal(res$first_line, c(2, 4))
  expect_equal(res$value, c(1, 1))
})

test_that("conditionals in argument defaults have counters for their branches", {
  f <-
    'f <- function(a,
              x = if (a) "yes" else "no",
              y = list(z = switch(a, b = 1, 2))) {
  c(x, y$z)
}'

  res <- as.data.frame(code_coverage(f, "f(TRUE)"))
  expect_equal(res$first_line, c(2, 2, 2, 3, 3, 3, 4))
  expect_equal(res$value, c(1, 1, 0, 1, 1, 0, 1))
})

test_that("arguments without conditionals are traced as before", {
  f <- function(a, b = 2, c = list(1), ...) a
  expect_identical(formals(trace_calls(f, "f")), formals(f))
})

test_that("while", {
  f <-
    'f <- function(x) {
  while (x > 0)
    x <- x - 1
  while (FALSE)
    FALSE # never covered, used as anchor
  x
}'

  res <- as.data.frame(code_coverage(f, "f(2)"))
  expect_equal(res$first_line, c(2, 3, 4, 5, 6))
  expect_equal(res$value, c(3, 2, 1, 0, 1))
  expect_equal(zero_coverage(code_coverage(f, "f(0)"))$line, c(3, 5))
})

test_that("while nested in other calls", {
  f <- 'f <- function(x) {
  suppressWarnings(while (x > 0) x <- x - 1)
}'

  res <- as.data.frame(code_coverage(f, "f(2)"))
  expect_equal(res$first_column, c(3, 27, 34))
  expect_equal(res$value, c(1, 3, 2))
  res <- as.data.frame(code_coverage(f, "f(0)"))
  expect_equal(res$value, c(1, 1, 0))
})

test_that("for nested in other calls", {
  f <- 'f <- function(x) {
  list(for (i in x) i)
}'

  res <- as.data.frame(code_coverage(f, "f(1:2)"))
  expect_equal(res$first_column, c(3, 12, 21))
  expect_equal(res$value, c(1, 1, 2))
  res <- as.data.frame(code_coverage(f, "f(NULL)"))
  expect_equal(res$value, c(1, 1, 0))
})

test_that("coverage of functions with NULL constructs", {
  f1 <- function() NULL
  f2 <- function() {
    NULL
  }
  f3 <- function() {
    if (FALSE) {
      NULL
    }
  }
  f4 <- function() {
    if (FALSE) {
      NULL
    }
  }

  cv1 <- function_coverage(f1, f1())
  expect_equal(percent_coverage(cv1), 100)
  cv2 <- function_coverage(f2, f2())
  expect_equal(percent_coverage(cv2), 100)
  cv3 <- function_coverage(f3, f3())
  expect_equal(percent_coverage(cv3), 50)
  cv4 <- function_coverage(f4, f4())
  expect_equal(percent_coverage(cv4), 50)
})

test_that("corner-cases are handled as expected", {
  sink_file <- withr::local_tempfile()
  expect_snapshot(
    withr::with_output_sink(sink_file, {
      cov <- file_coverage("corner-cases.R", "corner-cases-test.R")
    }),
    transform = function(x) gsub("'[0-9][0-9: .-]*'", "'<time>'", x)
  )

  expect_equal(as.data.frame(cov), readRDS("corner-cases.Rds"))
})
