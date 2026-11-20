test_that("base_r_compiled_coverage() measures an out of tree build", {
  skip_on_cran()
  skip_on_os("windows")
  cc <- Sys.which("gcc")
  skip_if(!nzchar(cc), "no gcc")
  gcov <- resolve_gcov()
  skip_if(is.na(gcov) || !nzchar(gcov), "no gcov")
  skip_if(!gcov_json_supported(gcov), "gcov doesn't support JSON")

  root <- withr::local_tempdir()
  source_dir <- file.path(root, "src")
  build_dir <- file.path(root, "build")
  dir.create(file.path(source_dir, "main"), recursive = TRUE)
  dir.create(file.path(source_dir, "tests"))
  dir.create(file.path(build_dir, "main"), recursive = TRUE)
  dir.create(file.path(build_dir, "tests"))

  writeLines(
    c(
      "int used(int x) {",
      "  if (x > 0) {",
      "    return x;",
      "  }",
      "  return -x;",
      "}",
      "int unused(int x) {",
      "  return x + 1;",
      "}",
      "int never_run(void) {",
      "  return 1;",
      "}"
    ),
    file.path(source_dir, "main", "a.c")
  )
  writeLines(
    c("int helper(void) {", "  return 2;", "}"),
    file.path(source_dir, "main", "never.c")
  )
  writeLines(
    c("int in_tests(void) {", "  return 3;", "}"),
    file.path(source_dir, "tests", "t.c")
  )
  writeLines(
    c(
      "int used(int);",
      "int in_tests(void);",
      "int main(void) {",
      "  used(1);",
      "  used(-2);",
      "  in_tests();",
      "  return 0;",
      "}"
    ),
    file.path(source_dir, "main", "main.c")
  )

  compile <- function(file, out) {
    status <- system2(
      cc,
      c(
        "--coverage",
        "-O0",
        "-g",
        "-c",
        file.path(source_dir, file),
        "-o",
        out
      ),
      stdout = FALSE,
      stderr = FALSE
    )
    expect_equal(status, 0L)
  }
  compile("main/a.c", file.path(build_dir, "main", "a.o"))
  compile("main/never.c", file.path(build_dir, "main", "never.o"))
  compile("main/main.c", file.path(build_dir, "main", "main.o"))
  compile("tests/t.c", file.path(build_dir, "tests", "t.o"))
  exe <- file.path(build_dir, "run")
  status <- system2(
    cc,
    c(
      "--coverage",
      "-o",
      exe,
      file.path(build_dir, "main", c("a.o", "main.o")),
      file.path(build_dir, "tests", "t.o")
    ),
    stdout = FALSE,
    stderr = FALSE
  )
  expect_equal(status, 0L)
  expect_error(
    base_r_compiled_coverage(build_dir, source_dir),
    "Can't find any .*gcda.* files"
  )
  expect_equal(system2(exe), 0L)

  cov <- base_r_compiled_coverage(build_dir, source_dir)

  expect_s3_class(cov, "coverage")
  expect_equal(attr(cov, "package")$path, normalize_path(source_dir))
  expect_equal(
    attr(cov, "root"),
    normalize_path(source_dir)
  )

  df <- as.data.frame(cov)
  files <- unique(df$filename)
  expect_setequal(
    to_relative_path(files, normalize_path(source_dir)),
    c("main/a.c", "main/never.c", "main/main.c")
  )
  expect_false(anyDuplicated(names(cov)) > 0)

  value <- function(file, line) {
    rows <- df[
      endsWith(df$filename, file) & df$first_line == line,
      "value"
    ]
    sum(rows)
  }
  # `used()` is called twice, and one of its branches once
  expect_equal(value("main/a.c", 1), 2)
  expect_equal(value("main/a.c", 3), 1)
  expect_equal(value("main/a.c", 5), 1)
  # functions that never ran
  expect_equal(value("main/a.c", 8), 0)
  expect_equal(value("main/a.c", 11), 0)
  # objects that were never run count as not covered
  expect_equal(value("main/never.c", 2), 0)

  # Several processes of one run merge into the counts of the earlier ones
  expect_equal(system2(exe), 0L)
  merged <- as.data.frame(base_r_compiled_coverage(build_dir, source_dir))
  expect_equal(
    merged[merged$first_line == 1 & endsWith(merged$filename, "a.c"), "value"],
    4
  )

  # Nothing is written in the build or the source tree
  expect_length(
    list.files(
      c(build_dir, source_dir),
      pattern = "[.]gcov",
      recursive = TRUE
    ),
    0
  )
})

test_that("sum_gcov_lines() adds the counts of the same line", {
  lines <- data.frame(
    file = c("b.c", "a.c", "a.c", "a.c"),
    line = c(1L, 2L, 1L, 2L),
    count = c(1, 0, 5, 3)
  )
  expect_equal(
    sum_gcov_lines(lines),
    data.frame(
      file = c("a.c", "a.c", "b.c"),
      line = c(1L, 2L, 1L),
      count = c(5, 3, 1)
    )
  )
  expect_null(sum_gcov_lines(lines[0, ]))
})
