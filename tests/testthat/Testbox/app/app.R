options(box.path = file.path(getwd()))
rm(list = ls(box:::loaded_mods), envir = box:::loaded_mods)

box::use(
  app/modules/module,
  app/modules/moduleR6
)
