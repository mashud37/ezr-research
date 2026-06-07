test_that("calc_nps equals %promoters - %detractors", {
  df <- tibble::tibble(v = c(rep(10, 5), rep(8, 3), rep(3, 2)))
  # 5 promoters (50%), 3 passive, 2 detractors (20%) => NPS 30
  expect_equal(calc_nps(df, v)$nps, 30)
  expect_equal(calc_nps(df, v)$n, 10)
})

test_that("calc_nps groups by `by`", {
  out <- calc_nps(consumer_survey, nps_value, by = region)
  expect_equal(nrow(out), dplyr::n_distinct(consumer_survey$region))
  expect_true(all(out$nps >= -100 & out$nps <= 100))
})

test_that("ipm_model returns expected columns", {
  skip_if_not_installed("rwa")
  m <- ipm_model(consumer_survey, nps_value, "ratings_")
  expect_true(all(c("feature", "importance", "performance", "perf_class") %in%
                    names(m)))
  expect_equal(nrow(m), 5)                       # five ratings_ features
  expect_s3_class(m$perf_class, "factor")
  expect_true(all(m$performance >= 1 & m$performance <= 5))
})

test_that("ipm_model errors on a missing prefix", {
  expect_error(ipm_model(consumer_survey, nps_value, "nope_"))
})
