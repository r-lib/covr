options(box.path = file.path(getwd()))
# remove box cache
loaded_mods <- loadNamespace("box")$loaded_mods
rm(list = ls(loaded_mods), envir = loaded_mods)

box::use(
  app/modules/moduleR6
)
