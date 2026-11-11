test_that("azure_pipelines calls package_coverage and cobertura", {
  tf <- tempfile()
  on.exit(unlink(tf))

  expect_snapshot(azure(test_path("TestS4"), filename = tf))

  expect_true(file.exists(tf))
})
