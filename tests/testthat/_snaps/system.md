# system_output() errors if the command fails

    Code
      system_output("sh", c("-c", "exit 3"))
    Condition
      Error:
      ! running command ''sh' '-c' 'exit 3'' had status 3

---

    Code
      system_output("sh", c("-c", "echo oops >&2; exit 1"), quiet = TRUE)
    Condition
      Error:
      ! running command ''sh' '-c' 'echo oops >&2; exit 1'' had status 1

# system_output() errors for a command that can't be run

    Code
      system_output("covr-command-that-does-not-exist", quiet = TRUE)
    Condition
      Error:
      ! running command ''covr-command-that-does-not-exist'' had status 127

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

