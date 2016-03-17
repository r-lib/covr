context("shine")
cov <- package_coverage("TestS4", type = "all", combine_types = FALSE)

test_that("it works with coverage objects", {
  with_mock(`shiny::runApp` = function(...) list(...),
    res <- shine(cov$tests),
    data <- environment(res[[1]]$server)$data,
    test_S4 <- data$full[["R/TestS4.R"]],

    expect_equal(test_S4$line, 1:38),

    expect_equal(test_S4$coverage,
      c("", "", "", "", "", "", "5", "2", "", "3", "", "", "", "", "", "",
      "", "", "", "", "", "", "", "", "1", "", "", "", "",
      "", "1", "", "", "", "", "", "1", "")),

    expect_equal(data$file_stats,
      x <- data.frame(
        Coverage = "<div class=\"coverage-box coverage-high\">100.00</div>",
        File = "<a href=\"#\">R/TestS4.R</a>",
        Lines = 38L,
        Relevant = 6L,
        Covered = 6L,
        Missed = 0L,
        `Hits / Line` = "2",
        row.names = "R/TestS4.R",
        stringsAsFactors = FALSE,
        check.names = FALSE))
    )
})

test_that("it works with coverages objects", {
  with_mock(`shiny::runApp` = function(...) list(...),
    res <- shine(cov),
    data <- environment(res[[1]]$server)$data,

    # Test coverage
    test_S4_test <- data$tests$full[["R/TestS4.R"]],
    expect_equal(test_S4_test$line, 1:38),

    expect_equal(test_S4_test$coverage,
      c("", "", "", "", "", "", "5", "2", "", "3", "", "", "", "", "", "",
      "", "", "", "", "", "", "", "", "1", "", "", "", "",
      "", "1", "", "", "", "", "", "1", "")),

    expect_equal(data$tests$file_stats,
      x <- data.frame(
        Coverage = "<div class=\"coverage-box coverage-high\">100.00</div>",
        File = "<a href=\"#\">R/TestS4.R</a>",
        Lines = 38L,
        Relevant = 6L,
        Covered = 6L,
        Missed = 0L,
        `Hits / Line` = "2",
        row.names = "R/TestS4.R",
        stringsAsFactors = FALSE,
        check.names = FALSE)),

    # Vignette coverage
    test_S4_vignette <- data$vignettes$full[["R/TestS4.R"]],
    expect_equal(test_S4_vignette$line, 1:38),

    expect_equal(test_S4_vignette$coverage,
      c("", "", "", "", "", "", "0", "0", "", "0", "", "", "", "", "", "",
        "", "", "", "", "", "", "", "", "0", "", "", "", "", "", "0", "", "",
        "", "", "", "0", "")),

    expect_equal(data$vignettes$file_stats,
      x <- data.frame(
        Coverage = "<div class=\"coverage-box coverage-low\">0.00</div>",
        File = "<a href=\"#\">R/TestS4.R</a>",
        Lines = 38L,
        Relevant = 6L,
        Covered = 0L,
        Missed = 6L,
        `Hits / Line` = "0",
        row.names = "R/TestS4.R",
        stringsAsFactors = FALSE,
        check.names = FALSE))
    )
})
