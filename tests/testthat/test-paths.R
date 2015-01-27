library(tufterhandout)

test_that("css can be located", {

  tufte_css <- system.file("tufterhandout.css", package = "tufterhandout")

  if(identical(.Platform$OS.type, "windows")){

    i <- grep(' ', tufte_css)
    if (length(i))
      path[i] <- utils::shortPathName(tufte_css[i])
    tufte_css <- gsub('/', '\\\\', tufte_css)

  }

  expect_true(file.exists(tufte_css))

})
