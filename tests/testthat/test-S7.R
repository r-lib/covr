test_that("S7 coverage is reported", {
  skip_if_not_installed("S7")
  cov <- as.data.frame(package_coverage(test_path("TestS7")))

  expect_equal(cov$value, c(1, 1, 1, 2, 5, 0, 5, 0, 5, 1, 1, 2, 1, 1, 0))
  expect_snapshot(cov[, c("functions", "first_line", "last_line", "value")])
})

test_that("methods of generics dispatching on multiple arguments are traced", {
  skip_if_not_installed("S7")
  src <- '
foo <- S7::new_generic("foo", c("x", "y"))
S7::method(foo, list(S7::class_numeric, S7::class_character)) <- function(x, y) {
  1
}
S7::method(foo, list(S7::class_character, S7::class_character)) <- function(x, y) {
  2
}
'
  cov <- as.data.frame(code_coverage(src, "foo(1, \"a\")"))

  expect_equal(
    cov$functions,
    c(
      "method(foo, list(class_double, class_character))",
      "method(foo, list(class_character, class_character))"
    )
  )
  expect_equal(cov$value, c(1, 0))
})

test_that("external generic method signatures name every dispatch argument", {
  skip_if_not_installed("S7")
  single <- S7::new_external_generic("pkg", "gen", "x")
  multi <- S7::new_external_generic("pkg", "gen", c("x", "y"))

  expect_equal(
    external_generic_method_signature(single, list(S7::class_character)),
    "method(pkg::gen, class_character)"
  )
  expect_equal(
    external_generic_method_signature(
      multi,
      list(S7::class_character, S7::class_logical)
    ),
    "method(pkg::gen, list(class_character, class_logical))"
  )
})

test_that("constructors share the callbacks of their class reference", {
  skip_if_not_installed("S7")
  Foo <- S7::new_class("Foo", validator = function(self) NULL)
  constructor <- function() NULL
  environment(constructor) <- list2env(
    list(.S7_class_ref = list(class = Foo)),
    parent = emptyenv()
  )

  expect_equal(
    vapply(
      traverse_S7_class(constructor),
      function(r) as.character(r$name),
      ""
    ),
    c("Foo@constructor", "Foo@validator")
  )
})
