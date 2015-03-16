context("codecov")
test_that("it generates a properly formatted json file", {

  with_mock(
    `httr:::perform` = function(...) list(...),
    `httr::content` = identity,
    `httr:::body_config` = function(...) list(...),

    res <- codecov("TestS4"),
    json <- jsonlite::fromJSON(res[[5]][[1]]),

    expect_equal(json$files$name, "TestS4/R/TestS4.R"),
    expect_equal(json$files$coverage[[1]],
      c(NA, NA, NA, 5, 2, 5, 3, 5, NA, NA, NA, NA, NA, NA, NA, NA, NA,
        NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1)
    ),
    expect_equal(json$uploader, "R")
  )
})
