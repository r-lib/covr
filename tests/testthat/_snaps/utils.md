# it throws error if no package

    Code
      as_package("arst11234")
    Condition
      Error:
      ! `path` must be an existing directory.
      x 'arst11234' doesn't exist.

# as_package() errors if the path isn't in a package

    Code
      as_package(dir)
    Condition
      Error:
      ! Can't find a package in '<dir>'.

# read_description errors if there is no DESCRIPTION file

    Code
      read_description("no-such-dir/DESCRIPTION")
    Condition
      Error:
      ! Can't find a DESCRIPTION file at 'no-such-dir/DESCRIPTION'.

# logical_setting() warns about and ignores invalid values

    Code
      expect_true(setting())
    Condition
      Warning:
      Ignoring invalid value "maybe" of environment variable `COVR_TEST_SETTING`.
      i Use `TRUE`, `FALSE`, or a string that is one of "true", "t", "yes", "1", "false", "f", "no" or "0", in any case.

---

    Code
      expect_false(setting(FALSE))
    Condition
      Warning:
      Ignoring invalid value "maybe" of environment variable `COVR_TEST_SETTING`.
      i Use `TRUE`, `FALSE`, or a string that is one of "true", "t", "yes", "1", "false", "f", "no" or "0", in any case.

---

    Code
      expect_false(setting())
    Condition
      Warning:
      Ignoring invalid value TRUE and FALSE of option `covr.test_setting`.
      i Use `TRUE`, `FALSE`, or a string that is one of "true", "t", "yes", "1", "false", "f", "no" or "0", in any case.

