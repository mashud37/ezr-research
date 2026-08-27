gender_scheme <- function() {
  c(variable = "demo_gender",
    "Male" = 0.49, "Female" = 0.50, "Non-binary" = 0.01)
}

test_that("the scheme can be set, read and cleared", {
  on.exit(clear_weights(), add = TRUE)
  expect_false(has_weights())
  suppressMessages(set_weights(gender_scheme()))
  expect_true(has_weights())
  sp <- get_weights()
  expect_named(sp, "demo_gender")
  expect_equal(sum(sp$demo_gender), 1)              # normalised
  clear_weights()
  expect_false(has_weights())
})

test_that("single-variable weights are exact post-stratification", {
  on.exit(clear_weights(), add = TRUE)
  suppressMessages(set_weights(gender_scheme()))
  p <- calc_percentage(podracing_survey, demo_gender)
  expect_true("wpct" %in% names(p))
  # weighted margin reproduces the targets (to rounding)
  got <- stats::setNames(p$wpct, as.character(p$demo_gender))
  expect_equal(unname(got[["Male"]]), 49)
  expect_equal(unname(got[["Female"]]), 50)
  expect_equal(unname(got[["Non-binary"]]), 1)
})

test_that("weight_vector is normalised to mean 1", {
  w <- weight_vector(podracing_survey, gender_scheme())
  expect_length(w, nrow(podracing_survey))
  expect_equal(mean(w), 1, tolerance = 1e-8)
  expect_true(all(w > 0))
})

test_that("multi-variable raking matches every margin", {
  on.exit(clear_weights(), add = TRUE)
  suppressMessages(set_weights(
    gender_scheme(),
    c(variable = "region", "North America" = 0.30, "Europe" = 0.30,
      "Asia" = 0.20, "Latin America" = 0.10, "Oceania" = 0.10)
  ))
  g <- calc_percentage(podracing_survey, demo_gender)
  r <- calc_percentage(podracing_survey, region)
  expect_equal(sort(g$wpct), c(1, 49, 50))
  expect_equal(sort(r$wpct), c(10, 10, 20, 30, 30))
})

test_that("weights = FALSE forces unweighted; TRUE needs a scheme", {
  on.exit(clear_weights(), add = TRUE)
  suppressMessages(set_weights(gender_scheme()))
  p <- calc_percentage(podracing_survey, satis_return, weights = FALSE)
  expect_false("wpct" %in% names(p))
  clear_weights()
  expect_error(calc_percentage(podracing_survey, satis_return, weights = TRUE),
               "no weighting scheme")
})

test_that("an ad-hoc scheme weights a single call without setting state", {
  expect_false(has_weights())
  p <- calc_percentage(podracing_survey, demo_gender, weights = gender_scheme())
  expect_true("wpct" %in% names(p))
  expect_false(has_weights())     # nothing stored
})

test_that("a category with no target is an error", {
  expect_error(
    weight_vector(podracing_survey, c(variable = "demo_gender", "Male" = 1)),
    "no weight target"
  )
})

test_that("calc_nps and calc_summary replace with weighted values", {
  on.exit(clear_weights(), add = TRUE)
  base_nps_mean <- calc_summary(podracing_survey, nps_value)$mean
  base_mean <- calc_summary(podracing_survey, demo_age)$mean
  suppressMessages(set_weights(gender_scheme()))
  w_nps <- calc_nps(podracing_survey, nps_value)
  w_nps_mean <- calc_summary(podracing_survey, nps_value)$mean
  w_sum <- calc_summary(podracing_survey, demo_age)
  expect_equal(names(w_nps), c("n", "nps"))          # no extra column
  expect_equal(names(w_sum), c("n", "mean", "median", "sd"))
  # weighting moves the (unrounded) means; the headline NPS may round the same
  expect_false(isTRUE(all.equal(w_nps_mean, base_nps_mean)))
  expect_false(isTRUE(all.equal(w_sum$mean, base_mean)))
  expect_equal(w_nps$n, 1000L)                       # base stays unweighted
})

test_that("crosstab defaults to weighted cells", {
  on.exit(clear_weights(), add = TRUE)
  base <- crosstab(podracing_survey, region, demo_gender, cell = "row_pct")
  suppressMessages(set_weights(gender_scheme()))
  wtd <- crosstab(podracing_survey, region, demo_gender, cell = "row_pct")
  expect_equal(dim(base), dim(wtd))
  expect_false(isTRUE(all.equal(base, wtd)))
  # non-binary is downweighted to ~1% overall, so its row share stays small
  # (na.rm: a region may have no non-binary respondents at all)
  expect_true(all(wtd[["Non-binary"]] <= 4, na.rm = TRUE))
})

test_that("the named-list spec form is equivalent to the vector form", {
  a <- weight_vector(podracing_survey, gender_scheme())
  b <- weight_vector(podracing_survey,
                     list(demo_gender = c("Male" = 0.49, "Female" = 0.50,
                                          "Non-binary" = 0.01)))
  expect_equal(a, b)
})

test_that("weights are computed once and reused for the same data and scheme", {
  clear_weights_cache()
  spec <- ezrsurvey:::parse_weight_spec(gender_scheme())
  a <- ezrsurvey:::compute_weights(podracing_survey, spec)
  expect_length(ls(ezrsurvey:::.ezrsurvey_weight_cache), 1)
  b <- ezrsurvey:::compute_weights(podracing_survey, spec)
  expect_equal(a, b)
  expect_length(ls(ezrsurvey:::.ezrsurvey_weight_cache), 1)
})

test_that("changing the weighting column invalidates the cached weights", {
  clear_weights_cache()
  spec <- ezrsurvey:::parse_weight_spec(gender_scheme())
  a <- ezrsurvey:::compute_weights(podracing_survey, spec)

  edited <- podracing_survey
  edited$demo_gender[1:200] <- "Female"
  b <- ezrsurvey:::compute_weights(edited, spec)
  expect_false(isTRUE(all.equal(a, b)))
  expect_equal(b, ezrsurvey:::rake_weights(edited, spec, 50L, 1e-6))
})

test_that("clear_weights_cache empties the cache", {
  ezrsurvey:::compute_weights(podracing_survey,
                              ezrsurvey:::parse_weight_spec(gender_scheme()))
  expect_gt(length(ls(ezrsurvey:::.ezrsurvey_weight_cache)), 0)
  clear_weights_cache()
  expect_length(ls(ezrsurvey:::.ezrsurvey_weight_cache), 0)
})
