# used for testing the extraction of srcrefs pertaining to tests, which assumes 
# srcrefs within working directory

if (Sys.getenv("COVR_TEST_NESTED") == "TRUE") {
  test_dir("./nested_tests")

  # keep.source needed to extract test trace
  source("./nested_tests/test-a.R", keep.source = TRUE)  
}

