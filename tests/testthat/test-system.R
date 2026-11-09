test_that("system_output() returns the output of the command", {
  skip_on_os("windows")

  expect_equal(system_output("echo", c("a b", "$HOME")), "a b $HOME")
})

test_that("system_output() passes environment variables", {
  skip_on_os("windows")

  expect_equal(
    system_output(
      "sh",
      c("-c", "echo $COVR_TEST_VAR"),
      env = c(COVR_TEST_VAR = "x y")
    ),
    "x y"
  )
})

test_that("system_output() errors if the command fails", {
  skip_on_os("windows")

  expect_error(system_output("sh", c("-c", "exit 3")))
  expect_error(system_output(
    "sh",
    c("-c", "echo oops >&2; exit 1"),
    quiet = TRUE
  ))
})

test_that("wrap_command() wraps long commands with continuation markers", {
  withr::local_options(width = 20)

  expect_snapshot(cat(
    wrap_command("gcov --object-directory dir --branch-probabilities file.c"),
    "\n"
  ))
  expect_equal(wrap_command("short"), "short ")
})
