# package_coverage requires 'all' and 'none' to be the only type

    Code
      package_coverage("TestPrint", type = c("all", "tests"))
    Condition
      Error:
      ! `type` can't combine "all" with other types.
    Code
      package_coverage("TestPrint", type = c("none", "tests"))
    Condition
      Error:
      ! `type` can't combine "none" with other types.

