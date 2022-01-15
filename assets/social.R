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

library(callr)
library(rmarkdown)
library(xaringanBuilder)

social <- function(
  input = "assets/poster.Rmd",
  output,
  rmd_params,
  output_yaml = "assets/_output.yaml",
  chrome_path = NULL,
  delay = 1
) {
  message(sprintf("Running %s", basename(output)))

  render_poster <- function(
    input, output,
    rmd_params, output_yaml,
    chrome_path,
    delay = 1
  ) {
    file_name <- file.path(
      dirname(output),
      sub("\\..*", "", basename(output)),
      sub("\\.png", "_%02d.png", basename(output))
    )
    dir.create(
      path = dirname(file_name),
      showWarnings = FALSE,
      recursive = TRUE,
      mode = "0775"
    )

    xaringan_poster <- rmarkdown::render(
      input = input,
      output_dir = tempdir(),
      encoding = "UTF-8",
      params = rmd_params,
      output_yaml = output_yaml
    )
    output_pngs <- sapply(
      X = seq_len(5),
      FUN = function(i) {
        xaringanBuilder::build_png(
          input = xaringan_poster,
          output_file = sprintf(file_name, i),
          slides = i
        )
        sprintf(file_name, i)
      }
    )

    on.exit(unlink(xaringan_poster))

    invisible(output_pngs)
  }
  callr::r(
    func = render_poster,
    args = list(
      input = input,
      output = output,
      rmd_params = rmd_params,
      output_yaml = output_yaml,
      delay = delay
    )
  )
}
