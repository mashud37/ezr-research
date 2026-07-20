test_that("compare_values computes current - previous", {
  a <- data.frame(feature = c("price", "quality"), performance = c(3.0, 4.0))
  b <- data.frame(feature = c("price", "quality"), performance = c(2.5, 4.5))
  out <- compare_values(current = b, previous = a)
  expect_setequal(names(out), c("feature", "previous", "current", "difference"))
  expect_equal(out$difference, c(-0.5, 0.5))
})

test_that("compare_values works on percentage tables", {
  a <- calc_percentage(dplyr::filter(podracing_survey, region == "Europe"),
                       demo_gender)
  b <- calc_percentage(dplyr::filter(podracing_survey, region == "North America"),
                       demo_gender)
  out <- compare_values(b, a, by = "demo_gender", value = "pct")
  expect_true("difference" %in% names(out))
})

test_that("compare_values errors on missing columns", {
  a <- data.frame(feature = "x", performance = 1)
  b <- data.frame(feature = "x", score = 1)
  expect_error(compare_values(b, a))
})

test_that("plot_diff builds a diverging chart", {
  a <- data.frame(feature = c("price", "quality", "service"),
                  performance = c(3.1, 4.2, 3.5))
  b <- data.frame(feature = c("price", "quality", "service"),
                  performance = c(2.8, 4.4, 3.9))
  p <- compare_values(b, a) %>% plot_diff()
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("export_xlsx writes one tab per table", {
  skip_if_not_installed("writexl")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "out.xlsx")
  out <- export_xlsx(
    gender = calc_percentage(podracing_survey, demo_gender),
    calc_percentage(podracing_survey, demo_job),
    path = path
  )
  expect_equal(out, path)
  expect_true(file.exists(path))
})

test_that("sheet names are sanitised and made unique", {
  nm <- sanitize_sheet_names(c("a/b", "a/b",
                               "this is a really long sheet name over limit"))
  expect_true(all(nchar(nm) <= 31))
  expect_equal(anyDuplicated(nm), 0)
  expect_false(any(grepl("/", nm)))
})
