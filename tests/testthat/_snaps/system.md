# wrap_command() wraps long commands with continuation markers

    Code
      cat(wrap_command(
        "gcov --object-directory dir --branch-probabilities file.c"),
      "\n")
    Output
      gcov  \
        --object-directory  \
        dir  \
        --branch-probabilities  \
        file.c  

