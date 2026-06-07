f8 <- nps ~ value + quality + service + ease + support + trust + price +
  innovation

test_that("stepwise selection returns an lm-backed result", {
  s <- model_select(nps_drivers, f8, method = "stepwise")
  expect_s3_class(s, "ezrmodel_select")
  expect_equal(s$method, "stepwise")
  expect_true(inherits(s$model, "lm"))
  expect_true(length(s$selected) >= 1)
  expect_true("p_value" %in% names(s$coefficients))
  expect_output(print(s), "stepwise regression")
  expect_s3_class(plot(s), "ggplot")
})

test_that("stepwise augment appends fitted and resid", {
  s <- model_select(nps_drivers, f8, method = "stepwise")
  a <- augment(s)
  expect_true(all(c(".fitted", ".resid") %in% names(a)))
})

test_that("lasso selects a subset of predictors", {
  skip_if_not_installed("glmnet")
  s <- model_select(nps_drivers, f8, method = "lasso")
  expect_equal(s$method, "lasso")
  expect_true(all(c("term", "estimate") %in% names(s$coefficients)))
  expect_true(length(s$selected) <= 8)
  expect_true(!is.na(s$glance$lambda))
  a <- augment(s)
  expect_true(".fitted" %in% names(a))
  expect_s3_class(tidy(s), "tbl_df")
})

test_that("ridge keeps all predictors, elastic respects alpha", {
  skip_if_not_installed("glmnet")
  r <- model_select(nps_drivers, f8, method = "ridge")
  expect_equal(r$alpha, 0)
  e <- model_select(nps_drivers, f8, method = "elastic", alpha = 0.3)
  expect_equal(e$alpha, 0.3)
})
