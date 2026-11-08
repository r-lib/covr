test_that("f works when called through code with source references", {
  # Like rlang's eval_bare() when rlang is installed with source references,
  # `call_fn()` calls `f()` from code with srcrefs outside the test files.
  call_fn <- eval(parse(text = "function(fn, x) {\n  fn(x)\n}", keep.source = TRUE))
  expect_equal(call_fn(f, 1), 1)
  expect_equal(call_fn(f, 2), 2)
})
