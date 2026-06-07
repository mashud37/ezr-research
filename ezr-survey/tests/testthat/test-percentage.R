test_that("calc_percentage matches a hand-computed table", {
  df <- tibble::tibble(g = c("a", "a", "a", "b", ""))
  out <- calc_percentage(df, g)
  expect_setequal(names(out), c("g", "n", "pct"))
  # blank dropped; a = 3/4, b = 1/4
  expect_equal(out$pct[out$g == "a"], 75)
  expect_equal(out$pct[out$g == "b"], 25)
  expect_equal(sum(out$pct), 100)
})

test_that("calc_percentage groups within `by`", {
  out <- calc_percentage(consumer_survey, satis_return, by = region)
  sums <- out |>
    dplyr::group_by(region) |>
    dplyr::summarise(total = sum(pct), .groups = "drop")
  expect_true(all(abs(sums$total - 100) <= 2))  # rounding tolerance
})

test_that("calc_percentage wide pivots one row per group", {
  out <- calc_percentage(consumer_survey, satis_return, by = region, wide = TRUE)
  expect_equal(nrow(out), dplyr::n_distinct(consumer_survey$region))
  expect_true("region" %in% names(out))
  expect_false("n" %in% names(out))
})

test_that("calc_percentage sort sets factor level order", {
  out <- calc_percentage(consumer_survey, demo_gender, sort = "desc")
  expect_s3_class(out$demo_gender, "factor")
  expect_equal(out$pct, sort(out$pct, decreasing = TRUE))
})

test_that("calc_percentage_multi uses distinct-respondent denominator", {
  df <- tibble::tibble(
    respondent_id = c("r1", "r2", "r3"),
    m_a = c("A", "A", ""),
    m_b = c("B", "", "")
  )
  out <- calc_percentage_multi(df, "m_", id = respondent_id)
  # denominator = 2 respondents who chose anything (r1, r2); r3 chose nothing
  expect_equal(out$pct[out$option == "a"], 100)  # 2 of 2
  expect_equal(out$pct[out$option == "b"], 50)   # 1 of 2
})

test_that("calc_percentage_multi errors on a missing prefix", {
  expect_error(calc_percentage_multi(consumer_survey, "nope_"))
})

test_that("calc_summary returns mean/median/sd", {
  out <- calc_summary(consumer_survey, demo_age)
  expect_setequal(names(out), c("n", "mean", "median", "sd"))
  expect_equal(out$n, sum(!is.na(consumer_survey$demo_age)))
  expect_equal(out$mean, mean(consumer_survey$demo_age, na.rm = TRUE))
})
