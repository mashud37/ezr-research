test_that("crosstab counts by default, one row per x", {
  ct <- crosstab(consumer_survey, demo_gender, region)
  expect_s3_class(ct, "tbl_df")
  expect_equal(names(ct)[1], "demo_gender")
  expect_equal(nrow(ct), dplyr::n_distinct(na_blank(consumer_survey$demo_gender),
                                           na.rm = TRUE))
})

test_that("crosstab row percentages sum to ~100 per row", {
  ct <- crosstab(consumer_survey, region, demo_gender, cell = "row_pct")
  num <- ct[vapply(ct, is.numeric, logical(1))]
  expect_true(all(abs(rowSums(num, na.rm = TRUE) - 100) <= 2))
})

test_that("crosstab aggregates a value column", {
  ct <- crosstab(consumer_survey, region, demo_gender, value = nps_value,
                 fn = mean)
  num <- ct[vapply(ct, is.numeric, logical(1))]
  expect_true(all(unlist(num) >= 0 & unlist(num) <= 10, na.rm = TRUE))
})

test_that("crosstab long form returns x, y, value", {
  ct <- crosstab(consumer_survey, demo_gender, region, wide = FALSE)
  expect_setequal(names(ct), c("demo_gender", "region", "value"))
})

test_that("default_by option groups calc_percentage when by is omitted", {
  withr::defer(reset_ezrsurvey_options())
  ezrsurvey_options(default_by = "region")
  out <- calc_percentage(consumer_survey, demo_gender)
  expect_true("region" %in% names(out))
})

test_that("calc_percentage_batch stacks several questions", {
  out <- calc_percentage_batch(consumer_survey, demo_gender, demo_job)
  expect_true(all(c("variable", "answer", "n", "pct") %in% names(out)))
  expect_setequal(unique(out$variable), c("demo_gender", "demo_job"))
})
