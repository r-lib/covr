first_word <- function(x) {
  sub(" .*", "", x)
}

last_word <- function(x) {
  sub(".* ", "", x)
}

word_count <- function(x) {
  lengths(strsplit(x, " "))
}
