# file_coverage() requires compiled files to be in one package

    Code
      file_coverage("foo.c", character())
    Condition
      Error:
      ! Compiled `source_files` must be in a single package.
      i Can't find one package for 'foo.c'.

