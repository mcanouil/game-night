library(chromote)
library(callr)

social <- function(input, output, rmd_params, chrome_path, delay = 1) {
  callr::r(
    func = function(input, output, rmd_params, chrome_path, delay) {
      output_file <- file.path("ads", sub("\\.png$", ".pdf", basename(output)))

      web_browser <- suppressMessages(try(chromote::ChromoteSession$new(), silent = TRUE))

      if (
        inherits(web_browser, "try-error") &&
        missing(chrome_path) &&
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
        params = rmd_params
      )

      # file.copy(
      #   from = xaringan_poster,
      #   to = file.path("ads", sub("\\.png$", ".html", basename(output))),
      #   overwrite = TRUE
      # )

      web_browser$Page$navigate(xaringan_poster, wait_ = FALSE)
      on.exit(web_browser$close(), add = TRUE)
      web_browser$Page$loadEventFired()

      web_browser$screenshot(
        filename = output,
        selector = "div.remark-slide-scaler",
        scale = 2
      )

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

      slide_size <- ({
        r <- web_browser$Runtime$evaluate('slideshow.getRatio()')$result$value
        r <- lapply(strsplit(r, ":"), as.integer)
        width <- r[[1]][1]
        height <- r[[1]][2]
        page_width <- 8/width * width
        list(
          width = as.integer(908 * width / height),
          height = 681L,
          page = list(width = page_width, height = page_width * height / width)
        )
      })

      expected_slides <- as.integer(
        web_browser$Runtime$evaluate("slideshow.getSlideCount()")$result$value
      )

      max_slides <- expected_slides * 4

      web_browser$Browser$setWindowBounds(1, bounds = list(
        width = slide_size$width,
        height = slide_size$height
      ))

      web_browser$Emulation$setEmulatedMedia("print")
      web_browser$Runtime$evaluate(paste0(
        "let style = document.createElement('style')\n",
        "style.innerText = '@media print { ",
        ".remark-slide-container:not(.remark-visible){ display:none; }",
        "}'\n",
        "document.head.appendChild(style)"
      ))

      idx_slide <- current_slide()
      last_hash <- ""
      idx_part <- 0L
      pdf_files <- c()
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

        pdf_file_promise <- web_browser$Page$printToPDF(
          landscape = TRUE,
          printBackground = TRUE,
          paperWidth = 12,
          paperHeight = 9,
          marginTop = 0,
          marginRight = 0,
          marginBottom = 0,
          marginLeft = 0,
          pageRanges = "1",
          preferCSSPageSize = TRUE,
          wait_ = FALSE
        )$then(function(value) {
          filename <- tempfile(fileext = ".pdf")
          writeBin(jsonlite::base64_dec(value$data), filename)
          filename
        })
        pdf_files <- c(pdf_files, web_browser$wait_for(pdf_file_promise))
      }

      pdftools::pdf_combine(pdf_files, output = output_file)
      unlink(pdf_files)

      invisible(output_file)
    },
    args = list(
      input = input,
      output = output,
      rmd_params = rmd_params,
      delay = delay
    )
  )
}
