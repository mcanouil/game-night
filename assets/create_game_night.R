# # MIT License
# 
# Copyright (c) 2022 Mickaël Canouil
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# library(callr)
# library(quarto)
# library(webshot2)

create_game_night <- function(
  input = "assets/poster.qmd",
  output,
  rmd_params,
  output_yaml = "assets/_output.yaml",
  chrome_path = NULL,
  delay = 1
) {
  message(sprintf("Running %s", basename(output)))
  if (!all(dir.exists(c("posters", "contents")))) {
    dir.create(c("posters", "contents"), showWarnings = FALSE, mode = "0755")
  }
  callr::r(
    func = function(
      input, output,
      rmd_params, output_yaml,
      chrome_path,
      delay = 1
    ) {
      Sys.setenv(CHROMOTE_CHROME = "/Applications/Brave\ Browser.app/Contents/MacOS/Brave\ Browser")
      on.exit(unlink(sub("\\.qmd$", ".html", input)))
      html_poster <- quarto::quarto_render(
        input = input,
        execute_params = rmd_params,
        quiet = TRUE
      )
      webshot2::webshot(
        url = sub("\\.qmd$", ".html", input),
        file = output,
        vwidth = 1920,
        vheight = 1005
      )

      if (
        !all(file.exists(sprintf("contents/contents-%02d.png", 1:4)))
      ) {
        for (i in 1:4) {
          webshot2::webshot(
            url = sprintf(
              "file:////%s#%s",
              normalizePath(sub("\\.qmd$", ".html", input)),
              i
            ),
            file = sprintf("contents/contents-%02d.png", i),
            vwidth = 1920,
            vheight = 1005
          )
        }
      }
      invisible(output)
    },
    args = list(
      input = input,
      output = output,
      rmd_params = rmd_params,
      output_yaml = output_yaml,
      delay = delay
    )
  )
}
