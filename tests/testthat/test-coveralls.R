context("coveralls")
read_file <- function(file) readChar(file, file.info(file)$size)
test_that("coveralls generates a properly formatted json file", {

  with_mock(
    `httr:::perform` = function(...) list(...),
    `httr::content` = identity,
    `httr::upload_file` = function(file) readChar(file, file.info(file)$size),

    res <- coveralls("TestS4"),
    json <<- jsonlite::fromJSON(res[[5]]$body$json_file),

    expect_equal(nrow(json$source_files), 1),
    expect_equal(json$service_name, "travis-ci"),
    expect_equal(json$source_files$name, "TestS4/R/TestS4.R"),
    expect_equal(json$source_files$source, read_file("TestS4/R/TestS4.R")),
    expect_equal(json$source_files$coverage[[1]],
      c(NA, NA, 5, 2, 5, 3, 5, NA, NA, NA, NA, NA, NA, NA, NA, NA,
        NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1, NA, NA, NA, NA, NA, 1))
    )
})
