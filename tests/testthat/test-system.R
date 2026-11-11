test_that("run_command() returns the status and the output in lines", {
  skip_on_os("windows")

  res <- run_command("sh", c("-c", "echo a; echo b >&2; echo 'c d'; exit 3"))
  expect_equal(res, list(status = 3L, stdout = c("a", "c d"), stderr = "b"))

  res <- run_command("sh", c("-c", "printf 'x\\r\\ny'"))
  expect_equal(res$stdout, c("x", "y"))
  expect_equal(run_command("sh", c("-c", "true"))$stdout, character())
})

test_that("run_command() doesn't use a shell and passes environment variables", {
  skip_on_os("windows")

  expect_equal(run_command("echo", c("a b", "$HOME"))$stdout, "a b $HOME")
  res <- run_command(
    "sh",
    c("-c", "echo $COVR_TEST_VAR"),
    env = c(COVR_TEST_VAR = "x y")
  )
  expect_equal(res$stdout, "x y")
  expect_equal(Sys.getenv("COVR_TEST_VAR"), "")
})

test_that("run_command() gives status 127 for a command that can't be run", {
  res <- run_command("covr-command-that-does-not-exist")
  expect_equal(res$status, 127L)
  expect_equal(res$stdout, character())
  expect_match(res$stderr, "covr-command-that-does-not-exist")
})

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

  expect_snapshot(system_output("sh", c("-c", "exit 3")), error = TRUE)
  expect_snapshot(
    system_output("sh", c("-c", "echo oops >&2; exit 1"), quiet = TRUE),
    error = TRUE
  )
})

test_that("system_output() shows the command's standard error unless quiet", {
  skip_on_os("windows")

  expect_message(
    system_output("sh", c("-c", "echo oops >&2")),
    "oops"
  )
  expect_no_message(system_output("sh", c("-c", "echo oops >&2"), quiet = TRUE))
})

test_that("system_output() errors for a command that can't be run", {
  expect_snapshot(
    system_output("covr-command-that-does-not-exist", quiet = TRUE),
    error = TRUE
  )
})

test_that("command_line() quotes the command and arguments", {
  skip_on_os("windows")

  expect_equal(command_line("git", c("a b", "c")), "'git' 'a b' 'c'")
  expect_equal(command_line("git"), "'git'")
})

test_that("wrap_command() wraps long commands with continuation markers", {
  withr::local_options(width = 20)

  expect_snapshot(cat(
    wrap_command("gcov --object-directory dir --branch-probabilities file.c"),
    "\n"
  ))
  expect_equal(wrap_command("short"), "short ")
})
