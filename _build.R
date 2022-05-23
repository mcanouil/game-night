source("assets/create_game_night.R")

rscripts <- sort(
  x = list.files(path = "R", pattern = "^20.*\\.R$", full.names = TRUE),
  decreasing = TRUE
)

invisible(lapply(rscripts, source, encoding = "UTF-8"))
