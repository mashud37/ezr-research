test_that("model_lm returns tidy coefficients and fit", {
  fit <- model_lm(nps_drivers, nps ~ quality + value + service)
  expect_s3_class(fit, "ezrmodel_fit")
  co <- tidy(fit)
  expect_equal(nrow(co), 4L)                      # intercept + 3
  expect_true(all(c("term", "estimate", "p_value", "signif") %in% names(co)))
  expect_true(!is.null(fit$glance$r_squared))
})

test_that("augment appends fitted and resid", {
  fit <- model_lm(nps_drivers, nps ~ quality + value)
  a <- augment(fit)
  expect_true(all(c(".fitted", ".resid") %in% names(a)))
})

test_that("model_glm fits a binomial model", {
  g <- model_glm(nps_drivers, I(nps >= 9) ~ quality + value, family = binomial())
  expect_s3_class(g, "ezrmodel_fit")
  expect_true(inherits(g$fit, "glm"))
  expect_true(!is.null(g$glance$deviance))
})

test_that("model print and plot work", {
  fit <- model_lm(nps_drivers, nps ~ quality + value)
  expect_output(print(fit), "LM:")
  expect_s3_class(plot(fit), "ggplot")
  expect_no_error(ggplot2::ggplot_build(plot(fit)))
})
