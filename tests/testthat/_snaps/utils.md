# read_description errors if there is no DESCRIPTION file

    Code
      read_description("no-such-dir/DESCRIPTION")
    Condition
      Error:
      ! Can't find a DESCRIPTION file at 'no-such-dir/DESCRIPTION'.

