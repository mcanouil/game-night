library(chromote)
library(callr)
library(rmarkdown)

social <- function(input, output, rmd_params, output_yaml = "assets/_output.yaml", chrome_path = NULL, delay = 1) {
  callr::r(
    func = function(input, output, rmd_params, output_yaml, chrome_path, delay) {
      web_browser <- suppressMessages(try(chromote::ChromoteSession$new(), silent = TRUE))

      if (
        inherits(web_browser, "try-error") &&
        is.null(chrome_path) &&
        Sys.info()[["sysname"]] == "Windows"
      ) {
        edge_path <- "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
        if (file.exists(edge_path)) {
          Sys.setenv(CHROMOTE_CHROME = edge_path)
          web_browser <- chromote::ChromoteSession$new()
        } else {
          stop('Please set Sys.setenv(CHROMOTE_CHROME = "Path/To/Chrome")')
        }
      }

      xaringan_poster <- rmarkdown::render(
        input = input,
        output_dir = tempdir(),
        encoding = "UTF-8",
        params = rmd_params,
        output_yaml = output_yaml
      )

      web_browser$Page$navigate(xaringan_poster, wait_ = FALSE)
      on.exit(web_browser$close(), add = TRUE)
      if (Sys.info()[["sysname"]] == "Windows") web_browser$Page$loadEventFired()

      current_slide <- function() {
        x <- web_browser$Runtime$evaluate("slideshow.getCurrentSlideIndex()")$result$value
        as.integer(x) + 1L
      }

      slide_is_continuation <- function() {
        web_browser$Runtime$evaluate(
          "document.querySelector('.remark-visible').matches('.has-continuation')"
        )$result$value
      }

      hash_current_slide <- function() {
        digest::digest(web_browser$Runtime$evaluate(
          "document.querySelector('.remark-visible').innerHTML"
        )$result$value)
      }

      expected_slides <- as.integer(
        web_browser$Runtime$evaluate("slideshow.getSlideCount()")$result$value
      )

      max_slides <- expected_slides * 4

      idx_slide <- current_slide()
      last_hash <- ""
      idx_part <- 0L
      # png_files <- vector("character", max_slides)
      for (i in seq_len(max_slides)) {
        if (i > 1) {
          web_browser$Input$dispatchKeyEvent(
            "rawKeyDown",
            windowsVirtualKeyCode = 39,
            code = "ArrowRight",
            key = "ArrowRight",
            wait_ = TRUE
          )
        }

        if (current_slide() == idx_slide) {
          step <- 0L
          idx_part <- idx_part + 1L
        } else {
          step <- 1L
          idx_part <- 1L
        }
        idx_slide <- current_slide()

        if (slide_is_continuation()) next
        Sys.sleep(delay)

        this_hash <- hash_current_slide()
        if (identical(last_hash, this_hash)) break
        last_hash <- this_hash

        file_name <- file.path(
          dirname(output),
          sub("\\..*", "", basename(output)),
          sub("\\.png", "_%02d.png", basename(output))
        )
        dir.create(path = dirname(file_name), showWarnings = FALSE, recursive = TRUE, mode = "0775")
        web_browser$screenshot(
          filename = sprintf(file_name, i),
          selector = "div.remark-slide-scaler",
          scale = 2
        )
      }
    },
    args = list(
      input = input,
      output = output,
      rmd_params = rmd_params,
      output_yaml = output_yaml,
      chrome_path = chrome_path,
      delay = delay
    )
  )
}
