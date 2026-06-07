test_that("use_dataset / get / has / clear round-trip", {
  withr::defer(clear_dataset())
  expect_false(has_dataset())
  out <- use_dataset(nps_drivers)
  expect_identical(out, nps_drivers)
  expect_true(has_dataset())
  expect_equal(nrow(get_dataset()), 600)
  clear_dataset()
  expect_false(has_dataset())
  expect_error(get_dataset())
})

test_that("helpers use the default dataset when data is omitted", {
  withr::defer(clear_dataset())
  use_dataset(nps_drivers)
  a <- correlations(target = nps)
  b <- correlations(nps_drivers, nps)
  expect_equal(a$target_cor, b$target_cor)
})

test_that("helpers error without data or default", {
  clear_dataset()
  expect_error(correlations(target = nps), "no default dataset")
})

test_that("use_dataset rejects non-data-frames", {
  expect_error(use_dataset(1:10))
})
