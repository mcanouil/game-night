Sys.setenv(CHROMOTE_CHROME = "/Applications/Brave\ Browser.app/Contents/MacOS/Brave\ Browser")
for (i in 0:4) {
  webshot2::webshot(
    url = "assets/poster.html",
    file = sprintf("assets/poster-%02d.png", i + 1),
    vwidth = 1920,
    vheight = 1005,
    # selector = paste0("#", i),
    cliprect = NULL,
    expand = NULL,
    delay = 0.2,
    zoom = 1,
    useragent = NULL,
    max_concurrent = getOption("webshot.concurrent", default = 6)
  )
}

library(chromote)
Sys.setenv(CHROMOTE_CHROME = "/Applications/Brave\ Browser.app/Contents/MacOS/Brave\ Browser")
b <- ChromoteSession$new()
b$Page$navigate("assets/poster.html")
b$Browser$setWindowBounds(1, bounds = list(
  width = 1920,
  height = 1005
))
b$screenshot("assets/poster.png")
