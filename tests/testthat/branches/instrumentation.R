f_if <- function(x) {
  if (x) {
    1
  } else {
    2
  }
}

f_if_no_else <- function(x) {
  if (x) 1
  NULL
}

f_braceless <- function(x) if (x) "a" else if (!x) "b"

f_assign <- function(x) {
  y <- if (x > 1) "big" else "small"
  y
}

f_switch <- function(x) {
  switch(x, a = , b = "ab", c = {
    "c"
  }, "other")
}

f_switch_no_default <- function(x) switch(x, a = 1, b = 2)

f_switch_numeric <- function(i) switch(i, "one", "two")

f_switch_dots <- function(x, ...) switch(x, ...)

f_loops <- function(n) {
  for (i in seq_len(n)) if (i > 2) break
  while (n > 0) n <- n - 1
  repeat break
}

f_nested <- function(x) lapply(x, function(y) if (y) 1 else 0)

f_and <- function(x, y) if (x && y) 1
