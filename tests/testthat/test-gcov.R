context("gcov")
test_that("gcov calls system2 with the proper arguments", {
  with_mock(
    `base::system2` = capture_args,
    `base::setwd` = function(...) invisible(),
    `base::file.exists` = function(..) TRUE,

    system2_args <- return_args(run_gcov("src/test.c")),

    expect_equal(system2_args[[1]], "gcov"),
    expect_equal(system2_args[[2]], "test.c"),

    expect_equal(names(system2_args)[3], "stdout"),
    expect_equal(system2_args[[3]], NULL)
  )
})
