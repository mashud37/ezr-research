test_that("nice_max rounds up to the next multiple", {
  expect_equal(nice_max(63, 25), 75)
  expect_equal(nice_max(80, 25), 100)
  expect_equal(nice_max(75, 25), 75)   # exact multiple stays put
  expect_equal(nice_max(c(8, 17), 5), 20)
  expect_equal(nice_max(40, 25, pad = 10), 60)
})

test_that("nice_max handles empty / NA input", {
  expect_true(is.na(nice_max(numeric(0))))
  expect_true(is.na(nice_max(c(NA, NA))))
  expect_equal(nice_max(c(NA, 30), 25), 50)
})

test_that("nice_max validates arguments", {
  expect_error(nice_max("a"))
  expect_error(nice_max(10, unit = -1))
})

test_that("label_pct formats numbers as percentages", {
  expect_equal(label_pct()(c(0, 33.4, 100)), c("0%", "33%", "100%"))
  expect_equal(label_pct(1)(33.45), "33.5%")
})

test_that("scale_y_pct returns a ggplot scale", {
  expect_s3_class(scale_y_pct(c(10, 40)), "ScaleContinuousPosition")
})
