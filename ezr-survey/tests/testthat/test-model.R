test_that("calc_nps equals %promoters - %detractors", {
  df <- tibble::tibble(v = c(rep(10, 5), rep(8, 3), rep(3, 2)))
  # 5 promoters (50%), 3 passive, 2 detractors (20%) => NPS 30
  expect_equal(calc_nps(df, v)$nps, 30)
  expect_equal(calc_nps(df, v)$n, 10)
})

test_that("calc_nps groups by `by`", {
  out <- calc_nps(podracing_survey, nps_value, by = region)
  expect_equal(nrow(out), dplyr::n_distinct(podracing_survey$region))
  expect_true(all(out$nps >= -100 & out$nps <= 100))
})

test_that("calc_nps reports the three group counts and shares", {
  df <- tibble::tibble(v = c(rep(10, 5), rep(8, 3), rep(3, 2)))
  out <- calc_nps(df, v)
  expect_equal(out$promoters, 5L)
  expect_equal(out$passives, 3L)
  expect_equal(out$detractors, 2L)
  expect_equal(out$pct_promoters, 50)
  expect_equal(out$pct_passives, 30)
  expect_equal(out$pct_detractors, 20)
  # the counts account for every valid response, and the shares recover the score
  expect_equal(out$promoters + out$passives + out$detractors, out$n)
  expect_equal(out$pct_promoters - out$pct_detractors, out$nps)
})

test_that("calc_nps counts stay unweighted while shares follow the weights", {
  scheme <- c(variable = "demo_gender",
              "Male" = 0.49, "Female" = 0.50, "Non-binary" = 0.01)
  plain <- calc_nps(podracing_survey, nps_value, weights = FALSE)
  wtd <- calc_nps(podracing_survey, nps_value, weights = scheme)
  # counts are respondents, so weighting cannot change them
  expect_equal(wtd$n, plain$n)
  expect_equal(wtd$promoters, plain$promoters)
  expect_equal(wtd$passives, plain$passives)
  expect_equal(wtd$detractors, plain$detractors)
  # the shares are weighted, so at least one of them moves
  shares <- function(x) c(x$pct_detractors, x$pct_passives, x$pct_promoters)
  expect_false(identical(shares(wtd), shares(plain)))
})

test_that("calc_importance methods all rescale to 100, strongest first", {
  for (method in c("rwa", "forest", "correlation")) {
    skip_if_not_installed(switch(method, rwa = "rwa", forest = "randomForest",
                                 correlation = "stats"))
    set.seed(1)
    out <- calc_importance(podracing_survey, nps_value,
                           dplyr::starts_with("ratings_"), method = method)
    expect_named(out, c("feature", "importance"))
    expect_equal(nrow(out), 6)
    expect_equal(sum(out$importance), 100)
    expect_true(all(out$importance >= 0))
    expect_equal(out$importance, sort(out$importance, decreasing = TRUE))
  }
})

test_that("calc_importance rejects an unknown method", {
  expect_error(calc_importance(podracing_survey, nps_value,
                               dplyr::starts_with("ratings_"),
                               method = "magic"))
})

test_that("ipm_model accepts a non-default importance method", {
  skip_if_not_installed("randomForest")
  set.seed(1)
  m <- ipm_model(podracing_survey, nps_value, "ratings_", method = "forest")
  expect_equal(nrow(m), 6)
  expect_equal(sum(m$importance), 100)
})

test_that("ipm_model returns expected columns", {
  skip_if_not_installed("rwa")
  m <- ipm_model(podracing_survey, nps_value, "ratings_")
  expect_true(all(c("feature", "importance", "performance", "perf_class") %in%
                    names(m)))
  expect_equal(nrow(m), 6)                       # six ratings_ features
  expect_s3_class(m$perf_class, "factor")
  expect_true(all(m$performance >= 1 & m$performance <= 5))
})

test_that("ipm_model errors on a missing prefix", {
  expect_error(ipm_model(podracing_survey, nps_value, "nope_"))
})

test_that("perf_class buckets by integer part, not rounding", {
  skip_if_not_installed("rwa")
  m <- ipm_model(podracing_survey, nps_value, "ratings_")
  expect_equal(as.character(m$perf_class),
               as.character(floor(m$performance)))
  # a mid-band mean stays in its own band (3.57 -> 3, never rounds to 4)
  expect_equal(as.character(cut_perf_band(3.57)), "3")
  expect_equal(as.character(cut_perf_band(3.0)), "3")
  expect_equal(as.character(cut_perf_band(4.99)), "4")
})
