test_that("se_mean matches sd / sqrt(n)", {
  x <- c(4, 5, 3, 4, 5, 2, 4)
  expect_equal(se_mean(x), stats::sd(x) / sqrt(length(x)))
  expect_true(is.na(se_mean(1)))          # need >= 2 values
  expect_equal(se_mean(c(NA, 4, 4)), 0)
})

test_that("se_prop matches the closed form and accepts percentages", {
  expect_equal(se_prop(0.33, 1184), sqrt(0.33 * 0.67 / 1184))
  expect_equal(se_prop(33, 1184), se_prop(0.33, 1184))  # percent input
  expect_error(se_prop(150, 100))                       # invalid even as a percent
})

test_that("rse and margin_of_error compose", {
  se <- se_prop(0.33, 1184)
  expect_equal(rse(0.33, se), se / 0.33 * 100)
  expect_equal(margin_of_error(se, z = 2), 2 * se)
})

test_that("diagnose returns one tidy row per variable", {
  out <- diagnose(podracing_survey, demo_gender, ratings_atmosphere)
  expect_equal(nrow(out), 2)
  expect_true(all(c("variable", "type", "n", "estimate", "se",
                    "rse", "moe", "precision") %in% names(out)))
  expect_true(all(out$se >= 0, na.rm = TRUE))
})

test_that("diagnose detects numeric vs categorical", {
  num <- diagnose(podracing_survey, nps_value)
  expect_equal(num$type, "mean")
  cat <- diagnose(podracing_survey, demo_gender)
  expect_equal(cat$type, "prop")
})

test_that("diagnose groups by `by`", {
  out <- diagnose(podracing_survey, nps_value, by = region)
  expect_equal(nrow(out), dplyr::n_distinct(podracing_survey$region))
  expect_true("region" %in% names(out))
})

test_that("rse_rating maps RSEs to the five bands", {
  expect_equal(
    rse_rating(c(3, 8, 12, 20, 40)),
    c("high precision", "precise", "satisfactory",
      "use with caution", "likely reliability issues")
  )
  expect_true(is.na(rse_rating(NA_real_)))
})

test_that("diagnose precision uses the rating bands", {
  out <- diagnose(podracing_survey, nps_value)
  expect_true(out$precision %in% c("high precision", "precise", "satisfactory",
                                   "use with caution",
                                   "likely reliability issues"))
})

test_that("precision_summary produces a bulleted assessment object", {
  ps <- precision_summary(podracing_survey)
  expect_s3_class(ps, "ezrsurvey_precision")
  expect_true(is.character(ps$bullets) && length(ps$bullets) >= 3)
  expect_match(ps$bullets[1], "total responses")
  expect_true(ps$rating %in% c("high precision", "precise", "satisfactory",
                               "use with caution", "likely reliability issues"))
  expect_output(print(ps), "Survey precision summary")
})

test_that("precision_summary skips id / free-text columns automatically", {
  ps <- precision_summary(podracing_survey)
  # respondent_id (near-unique) and comment columns should not be assessed
  expect_false("respondent_id" %in% ps$table$variable)
  expect_false("nps_com" %in% ps$table$variable)
})
