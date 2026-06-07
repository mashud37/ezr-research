test_that("drivers returns a consensus over available methods", {
  d <- drivers(nps_drivers, nps, methods = c("cor", "lm"))
  expect_s3_class(d, "ezrmodel_drivers")
  expect_setequal(d$methods, c("cor", "lm"))
  expect_true(all(c("variable", "mean_rank", "score") %in% names(d$consensus)))
  expect_equal(nrow(d$consensus), 8L)            # 8 driver columns
  # consensus is sorted by mean rank
  expect_equal(d$consensus$mean_rank, sort(d$consensus$mean_rank))
})

test_that("drivers tidy/print/plot work", {
  d <- drivers(nps_drivers, nps, methods = "cor")
  expect_s3_class(tidy(d), "tbl_df")
  expect_output(print(d), "Drivers of 'nps'")
  expect_s3_class(plot(d), "ggplot")
})

test_that("drivers errors with too few predictors", {
  df <- tibble::tibble(y = rnorm(50), x = rnorm(50))
  expect_error(drivers(df, y), "at least 2")
})

test_that("optional methods run when installed", {
  skip_if_not_installed("rwa")
  skip_if_not_installed("randomForest")
  skip_if_not_installed("psych")
  d <- drivers(nps_drivers, nps)
  expect_setequal(d$methods, c("cor", "lm", "rwa", "rf", "fa"))
})
