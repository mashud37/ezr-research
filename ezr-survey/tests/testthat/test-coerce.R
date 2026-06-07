test_that("ensure_numeric salvages embedded numbers", {
  expect_equal(ensure_numeric(c("25 years", "31", "forty"), quiet = TRUE),
               c(25, 31, NA))
  expect_equal(ensure_numeric(c("8 - very likely", "10", "3.5/5"), quiet = TRUE),
               c(8, 10, 3.5))
  expect_equal(ensure_numeric(c("-2 pts", "x"), quiet = TRUE), c(-2, NA))
})

test_that("ensure_numeric leaves numeric input untouched and silent", {
  expect_identical(ensure_numeric(c(1, 2, 3)), c(1, 2, 3))
  expect_silent(ensure_numeric(c(1L, 2L)))
})

test_that("ensure_numeric messages when it coerces, and quiet suppresses it", {
  expect_message(ensure_numeric(c("25 years", "x"), name = "age"),
                 "Auto-converted 'age' to numeric")
  expect_silent(ensure_numeric(c("25 years"), quiet = TRUE))
})

test_that("nps_group tolerates worded numeric answers", {
  expect_equal(nps_group(c("9 - very likely", "3 (unlikely)", "8")),
               c(1L, -1L, 0L))
})

test_that("calc_nps auto-coerces a text score column", {
  df <- tibble::tibble(score = c("10", "9 - promoter", "3 detractor", "8"))
  out <- suppressMessages(calc_nps(df, score))
  # 2 promoters (50%), 1 detractor (25%) -> NPS 25
  expect_equal(out$nps, 25)
  expect_equal(out$n, 4)
})

test_that("calc_summary auto-coerces a text numeric column", {
  df <- tibble::tibble(age = c("25 years", "35", "45 yo"))
  out <- suppressMessages(calc_summary(df, age))
  expect_equal(out$mean, 35)
  expect_equal(out$n, 3)
})
