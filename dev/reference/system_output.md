# Run a system command and capture the output.

This function automatically quotes both the command and each argument so
they are properly protected from shell expansion.

## Usage

``` r
system_output(
  cmd,
  args = character(),
  env = character(),
  quiet = FALSE,
  echo = FALSE,
  ...
)
```

## Arguments

- cmd:

  the command to run.

- args:

  a vector of command arguments.

- env:

  a named character vector of environment variables. Will be quoted

- quiet:

  if `TRUE`, the command output will be echoed.

- echo:

  if `TRUE`, the command to run will be echoed.

- ...:

  additional arguments passed to
  [`base::system()`](https://rdrr.io/r/base/system.html)

## Value

command output if the command succeeds, an error will be thrown if the
command fails.
