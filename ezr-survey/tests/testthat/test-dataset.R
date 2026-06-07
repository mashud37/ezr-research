test_that("use_dataset / get / has / clear round-trip", {
  withr::defer(clear_dataset())
  expect_false(has_dataset())
  out <- use_dataset(consumer_survey)
  expect_identical(out, consumer_survey)     # returned invisibly for piping
  expect_true(has_dataset())
  expect_equal(nrow(get_dataset()), 1000)
  clear_dataset()
  expect_false(has_dataset())
  expect_error(get_dataset())
})

test_that("analysis helpers use the default dataset when data is omitted", {
  withr::defer(clear_dataset())
  use_dataset(consumer_survey)

  a <- calc_percentage(column = demo_gender)
  b <- calc_percentage(consumer_survey, demo_gender)
  expect_equal(a, b)

  expect_equal(calc_nps(value = nps_value)$nps,
               calc_nps(consumer_survey, nps_value)$nps)
  expect_equal(calc_summary(column = demo_age)$mean,
               calc_summary(consumer_survey, demo_age)$mean)
})

test_that("helpers error helpfully when no data and no default", {
  clear_dataset()
  expect_error(calc_percentage(column = demo_gender), "no default dataset")
})

test_that("use_dataset rejects non-data-frames", {
  expect_error(use_dataset(1:10))
})
