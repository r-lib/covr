test_that("add works", {
  expect_equal(add(1, 2), 3)
  expect_equal(used_helper(add(1, 1)), 4)
})

test_that("skipped test", {
  skip("not run")
  expect_equal(add(1, 1), 3)
})

test_that("quoted code is not instrumented", {
  expect_equal(
    deparse(quote({
      add(1, 2)
    })),
    c("{", "    add(1, 2)", "}")
  )
  expect_snapshot({
    x <- add(1, 2)
    x
  })
})

test_that("files in .covrignore are not instrumented", {
  expect_equal(readLines("fixtures/value.R"), "42")
})
