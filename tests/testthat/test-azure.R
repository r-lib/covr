test_that("azure_pipelines calls package_coverage and to_cobertura", {

  tf <- tempfile()
  on.exit(unlink(tf))

  azure(test_path("TestS4"), filename = tf)

  expect_true(file.exists(tf))
})
