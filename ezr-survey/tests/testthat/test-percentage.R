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
  out <- calc_percentage(podracing_survey, satis_return, by = region)
  sums <- out %>%
    dplyr::group_by(region) %>%
    dplyr::summarise(total = sum(pct), .groups = "drop")
  expect_true(all(abs(sums$total - 100) <= 2))  # rounding tolerance
})

test_that("calc_percentage wide pivots one row per group", {
  out <- calc_percentage(podracing_survey, satis_return, by = region, wide = TRUE)
  expect_equal(nrow(out), dplyr::n_distinct(podracing_survey$region))
  expect_true("region" %in% names(out))
  expect_false("n" %in% names(out))
})

test_that("calc_percentage sort sets factor level order", {
  out <- calc_percentage(podracing_survey, demo_gender, sort = "desc")
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
  expect_error(calc_percentage_multi(podracing_survey, "nope_"))
})

test_that("calc_summary returns mean/median/sd", {
  out <- calc_summary(podracing_survey, demo_age)
  expect_setequal(names(out), c("n", "mean", "median", "sd"))
  expect_equal(out$n, sum(!is.na(podracing_survey$demo_age)))
  expect_equal(out$mean, mean(podracing_survey$demo_age, na.rm = TRUE))
})

test_that("drop removes unwanted answers and re-bases percentages", {
  df <- tibble::tibble(g = c("a", "a", "b", "Other", "Other"))
  full <- calc_percentage(df, g)
  dropped <- calc_percentage(df, g, drop = "Other")
  expect_false("Other" %in% as.character(dropped$g))
  expect_true("Other" %in% as.character(full$g))
  # the kept answers re-base to 100% (a = 2/3, b = 1/3)
  expect_equal(dropped$pct[dropped$g == "a"], 67)
  expect_equal(sum(dropped$pct), 100)
})

test_that("drop works for multi-select and reads the drop_answers option", {
  multi <- calc_percentage_multi(podracing_survey, "motivations_",
                                 id = respondent_id, drop = "Boonta Eve tradition")
  expect_false("Boonta Eve tradition" %in% as.character(multi$option))

  withr::defer(reset_ezrsurvey_options())
  ezrsurvey_options(drop_answers = "Unemployed")
  out <- calc_percentage(podracing_survey, demo_job)
  expect_false("Unemployed" %in% as.character(out$demo_job))
})

test_that("clean_label undoes exporter mangling and strips a prefix", {
  expect_equal(clean_label("Broadcast.quality...audio"),
               "Broadcast quality / audio")
  expect_equal(clean_label("ratings_Camera.work", prefix = "ratings_"),
               "Camera work")
  # a name without the prefix keeps it: only dots are exporter mangling
  expect_equal(clean_label("other_thing", prefix = "ratings_"), "other_thing")
})

test_that("calc_percentage_batch can tidy its variable names", {
  raw <- calc_percentage_batch(podracing_survey, starts_with("ratings_"))
  expect_true(all(startsWith(unique(raw$variable), "ratings_")))

  tidy <- calc_percentage_batch(podracing_survey, starts_with("ratings_"),
                                prefix = "ratings_")
  expect_false(any(startsWith(unique(tidy$variable), "ratings_")))
  # only the labels change, never the numbers
  expect_equal(tidy$pct, raw$pct)
})

test_that("calc_percentage_batch names match ipm_model's, so the two can join", {
  skip_if_not_installed("rwa")
  model <- ipm_model(podracing_survey, nps_value, "ratings_")
  tab <- calc_percentage_batch(podracing_survey, starts_with("ratings_"),
                               prefix = "ratings_")
  expect_true(all(model$feature %in% unique(tab$variable)))
})
