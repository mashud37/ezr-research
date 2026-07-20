test_that("use_dataset / get / has / clear round-trip", {
  withr::defer(clear_dataset())
  expect_false(has_dataset())
  out <- use_dataset(podracing_survey)
  expect_identical(out, podracing_survey)     # returned invisibly for piping
  expect_true(has_dataset())
  expect_equal(nrow(get_dataset()), 1000)
  clear_dataset()
  expect_false(has_dataset())
  expect_error(get_dataset())
})

test_that("analysis helpers use the default dataset when data is omitted", {
  withr::defer(clear_dataset())
  use_dataset(podracing_survey)

  a <- calc_percentage(column = demo_gender)
  b <- calc_percentage(podracing_survey, demo_gender)
  expect_equal(a, b)

  expect_equal(calc_nps(value = nps_value)$nps,
               calc_nps(podracing_survey, nps_value)$nps)
  expect_equal(calc_summary(column = demo_age)$mean,
               calc_summary(podracing_survey, demo_age)$mean)
})

test_that("columns can be passed positionally without data (tidyverse-style)", {
  withr::defer(clear_dataset())
  use_dataset(podracing_survey)

  # bare column, no data and no `column =`
  expect_equal(calc_percentage(demo_gender),
               calc_percentage(podracing_survey, demo_gender))
  expect_equal(calc_summary(demo_age)$mean,
               calc_summary(podracing_survey, demo_age)$mean)
  expect_equal(calc_nps(nps_value)$nps,
               calc_nps(podracing_survey, nps_value)$nps)
  expect_equal(calc_percentage_multi("motivations_", id = respondent_id),
               calc_percentage_multi(podracing_survey, "motivations_",
                                     id = respondent_id))
  # two leading columns shift together
  expect_equal(crosstab(demo_gender, region),
               crosstab(podracing_survey, demo_gender, region))
  # tidyselect through `...`
  expect_equal(diagnose(demo_gender), diagnose(podracing_survey, demo_gender))
  expect_equal(calc_percentage_batch(demo_gender, demo_job),
               calc_percentage_batch(podracing_survey, demo_gender, demo_job))

  # an explicit data frame still wins over the default
  expect_equal(calc_percentage(shopping_survey, demo_gender),
               shopping_survey %>% calc_percentage(demo_gender))
})

test_that("helpers error helpfully when no data and no default", {
  clear_dataset()
  expect_error(calc_percentage(column = demo_gender), "no default dataset")
  expect_error(calc_percentage(demo_gender), "no default dataset")
})

test_that("use_dataset rejects non-data-frames", {
  expect_error(use_dataset(1:10))
})

test_that("open-text comments are globally unique across comment columns", {
  # No non-blank comment may repeat within or across the comment columns.
  com_cols <- grep("_com$|^comment$", names(podracing_survey), value = TRUE)
  expect_true(length(com_cols) > 0)
  vals <- unlist(podracing_survey[com_cols], use.names = FALSE)
  vals <- vals[nzchar(vals)]
  expect_false(anyDuplicated(vals) > 0)

  sv <- unlist(shopping_survey[grep("_com$|^comment$", names(shopping_survey))],
               use.names = FALSE)
  sv <- sv[nzchar(sv)]
  expect_false(anyDuplicated(sv) > 0)
})
