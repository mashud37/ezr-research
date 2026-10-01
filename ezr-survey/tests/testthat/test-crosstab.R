test_that("crosstab counts by default, one row per x", {
  ct <- crosstab(podracing_survey, demo_gender, region)
  expect_s3_class(ct, "tbl_df")
  expect_equal(names(ct)[1], "demo_gender")
  expect_equal(nrow(ct), dplyr::n_distinct(na_blank(podracing_survey$demo_gender),
                                           na.rm = TRUE))
})

test_that("crosstab row percentages sum to ~100 per row", {
  ct <- crosstab(podracing_survey, region, demo_gender, cell = "row_pct")
  num <- ct[vapply(ct, is.numeric, logical(1))]
  expect_true(all(abs(rowSums(num, na.rm = TRUE) - 100) <= 2))
})

test_that("crosstab aggregates a value column", {
  ct <- crosstab(podracing_survey, region, demo_gender, value = nps_value,
                 fn = mean)
  num <- ct[vapply(ct, is.numeric, logical(1))]
  expect_true(all(unlist(num) >= 0 & unlist(num) <= 10, na.rm = TRUE))
})

test_that("crosstab long form returns x, y, value", {
  ct <- crosstab(podracing_survey, demo_gender, region, wide = FALSE)
  expect_setequal(names(ct), c("demo_gender", "region", "value"))
})

test_that("default_by option groups calc_percentage when by is omitted", {
  withr::defer(reset_ezrsurvey_options())
  ezrsurvey_options(default_by = "region")
  out <- calc_percentage(podracing_survey, demo_gender)
  expect_true("region" %in% names(out))
})

test_that("calc_percentage_batch stacks several questions", {
  out <- calc_percentage_batch(podracing_survey, demo_gender, demo_job)
  expect_true(all(c("variable", "answer", "n", "pct") %in% names(out)))
  expect_setequal(unique(out$variable), c("demo_gender", "demo_job"))
})

test_that("crosstab copes with questions called value or n", {
  d <- data.frame(
    value = c("Low", "High", "High", "Low", "High"),
    n = c("A", "A", "B", "B", "B")
  )
  ct <- crosstab(d, value, n)
  expect_equal(names(ct), c("value", "A", "B"))
  expect_equal(ct$value, c("High", "Low"))
  expect_equal(ct$A, c(1, 1))
  expect_equal(ct$B, c(2, 1))

  flipped <- crosstab(d, n, value, cell = "row_pct")
  expect_equal(names(flipped), c("n", "High", "Low"))
  expect_equal(flipped$High, c(50, 67))

  long <- crosstab(d, n, n, wide = FALSE)
  expect_equal(long$value, c(2, 3))
  expect_error(crosstab(d, value, n, wide = FALSE), "Rename that column")
})

test_that("crosstab keeps a factor's own answer order", {
  d <- data.frame(
    agree = factor(c("Disagree", "Agree", "Strongly agree", "Agree"),
                   levels = c("Strongly disagree", "Disagree", "Agree",
                              "Strongly agree")),
    group = factor(c("Old", "Young", "Old", "Young"),
                   levels = c("Young", "Old"))
  )
  ct <- crosstab(d, agree, group)
  expect_equal(as.character(ct$agree), c("Disagree", "Agree", "Strongly agree"))
  expect_equal(names(ct), c("agree", "Young", "Old"))
})
