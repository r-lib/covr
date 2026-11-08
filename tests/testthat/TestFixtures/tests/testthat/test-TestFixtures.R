test_that("fixtures read in setup files are found", {
  expect_equal(first_word(setup_words), "hello")
})

describe("fixtures", {
  describe_words <- readLines(test_path("fixtures", "words.txt"))

  it("are found when read in describe()", {
    expect_equal(last_word(describe_words), "world")
  })

  it("are found when read in it()", {
    it_words <- readLines(test_path("fixtures", "words.txt"))
    expect_equal(word_count(it_words), 3)
  })
})
