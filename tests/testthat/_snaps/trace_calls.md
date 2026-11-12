# trace_calls reports objects it cannot trace and returns them unchanged

    Code
      res <- trace_calls(env)
    Message
      Unknown language class: environment

# corner-cases are handled as expected

    Code
      withr::with_output_sink(sink_file, {
        cov <- file_coverage("corner-cases.R", "corner-cases-test.R")
      })
    Condition
      Warning in `getPackageName()`:
      Created a package name, '<time>', when none found

