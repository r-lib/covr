# annotate_coverage shows missed lines with context

    Code
      annotate_coverage(cov)
    Output
      source.R
         3 |    1 |     'positive'
         4 |      |   } else {
         5 |  !!0 |     'other'
         6 |      |   }
         7 |      | }
        ...
        15 |    1 |   e <- 5
        16 |    1 |   if (x) {
        17 |  !!0 |     'never'
        18 |      |   }
        19 |    1 |   a + b

# annotate_coverage supports context = 0 and Inf

    Code
      annotate_coverage(cov, context = 0)
    Output
      source.R
         5 |  !!0 |     'other'
        ...
        17 |  !!0 |     'never'

---

    Code
      annotate_coverage(cov, context = Inf)
    Output
      source.R
         1 |      | f <- function(x) {
         2 |    1 |   if (x > 0) {
         3 |    1 |     'positive'
         4 |      |   } else {
         5 |  !!0 |     'other'
         6 |      |   }
         7 |      | }
         8 |      | 
         9 |      | # a comment
        10 |      | g <- function(x) {
        11 |    1 |   a <- 1
        12 |    1 |   b <- 2
        13 |    1 |   c <- 3
        14 |    1 |   d <- 4
        15 |    1 |   e <- 5
        16 |    1 |   if (x) {
        17 |  !!0 |     'never'
        18 |      |   }
        19 |    1 |   a + b
        20 |      | }

# annotate_coverage filters by files

    Code
      annotate_coverage(cov, files = "no_such_file.R")
    Output
      No missed lines.

# annotate_coverage accepts custom lines

    Code
      annotate_coverage(cov, lines = lines, context = 1)
    Output
      source.R
         2 |    1 |   if (x > 0) {
         3 |    1 |     'positive'
         4 |      |   } else {
        ...
        10 |      | g <- function(x) {
        11 |    1 |   a <- 1
        12 |    1 |   b <- 2

# annotate_coverage reads sources that were not traced from the package

    Code
      annotate_coverage(cov, lines = lines, context = 0)
    Output
      other.R
        2 |      | b <- 2

---

    Code
      annotate_coverage(cov, lines = lines)
    Condition
      Error:
      ! Can't find the source of 'missing.R'.

# annotate_coverage ignores lines beyond the end of the source

    Code
      annotate_coverage(cov, lines = lines)
    Output
      No missed lines.

# annotate_coverage reports when nothing is missed

    Code
      annotate_coverage(cov)
    Output
      No missed lines.

# annotate_coverage shows missed branches

    Code
      annotate_coverage(cov)
    Output
      source.R
        1 |      | f <- function(x, y) {
        2 |    1 |   if (x) {  <- not taken: FALSE
        3 |    1 |     'yes'
        4 |      |   }
        5 |  !!0 |   switch(y, a = 1, b = 2)  <- not taken: b, <no match>
        6 |      | }
        7 |      | h <- function(x) {
        8 |  !!0 |   if (x) 1 else 2
        9 |      | }

---

    Code
      annotate_coverage(cov, lines = data.frame(filename = unique(tally_coverage(cov,
        by = "branch")$filename), line = 3), context = 0)
    Output
      source.R
        3 |    1 |     'yes'

# annotate_coverage stops at max_lines with a summary line

    Code
      annotate_coverage(cov, context = 0, max_lines = 2)
    Output
      source.R
         3 |  !!0 |     'never'
        ...
         9 |  !!0 |     'never'
      ... 3 more lines in 1 file not shown; narrow with `files` or `lines`, or raise `max_lines`.

# annotate_coverage checks max_lines and context

    Code
      annotate_coverage(cov, max_lines = "a")
    Condition
      Error:
      ! `max_lines` must be a single number.
    Code
      annotate_coverage(cov, context = NA)
    Condition
      Error:
      ! `context` must be a single number.

