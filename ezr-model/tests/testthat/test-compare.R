test_that("compare_models tables lm fits best-first by AIC", {
  a <- model_lm(nps_drivers, nps ~ quality + value)
  b <- model_lm(nps_drivers, nps ~ quality + value + service + trust)
  cmp <- compare_models(simple = a, fuller = b)
  expect_s3_class(cmp, "ezrmodel_comparison")
  expect_equal(nrow(cmp$table), 2L)
  expect_true(all(c("model", "n", "df", "r2", "aic", "bic", "rmse") %in%
                    names(cmp$table)))
  # best row is first and flagged
  expect_true(cmp$table$best[1])
  expect_equal(which.min(cmp$table$aic), 1L)
  expect_output(print(cmp), "Model comparison")
  expect_s3_class(plot(cmp), "ggplot")
})

test_that("compare_models accepts raw lm and model_select objects", {
  skip_if_not_installed("glmnet")
  raw <- stats::lm(nps ~ quality + value, data = nps_drivers)
  las <- model_select(nps_drivers,
                      nps ~ value + quality + service + trust, method = "lasso")
  cmp <- compare_models(raw, lasso = las, metric = "rmse")
  expect_equal(nrow(cmp$table), 2L)
  expect_equal(cmp$metric, "rmse")
  expect_s3_class(tidy(cmp), "tbl_df")
})

test_that("compare_models needs at least two models", {
  a <- model_lm(nps_drivers, nps ~ quality)
  expect_error(compare_models(a), "at least two")
})
