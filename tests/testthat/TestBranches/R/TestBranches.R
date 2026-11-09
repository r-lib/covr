sign_of <- function(x) {
  if (x > 0) {
    "positive"
  } else if (x < 0) {
    "negative"
  } else {
    "zero"
  }
}

describe <- function(x) {
  switch(x, a = , b = "early", z = "late")
}

skipped <- function(x) {
  if (x) 1 else 2 # nocov
}

forked <- function(x) {
  if (x) "yes"
}
