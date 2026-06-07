# Smoke tests: confirm each plot wrapper returns a ggplot that actually builds.

test_that("plot_bars builds", {
  p <- calc_percentage(consumer_survey, demo_gender, sort = "desc") |> plot_bars()
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("plot_bars flips and adds an average line", {
  p <- calc_percentage(consumer_survey, demo_edu) |>
    plot_bars(flip = TRUE, avg_line = TRUE)
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("plot_nps_gauge builds for both scales", {
  expect_no_error(ggplot2::ggplot_build(plot_nps_gauge(42)))
  expect_no_error(ggplot2::ggplot_build(plot_nps_gauge(3.8, scale = "rating")))
})

test_that("plot_ipm builds", {
  skip_if_not_installed("rwa")
  m <- ipm_model(consumer_survey, nps_value, "ratings_")
  expect_no_error(ggplot2::ggplot_build(plot_ipm(m)))
})

test_that("themes and palette scales return the right objects", {
  expect_s3_class(theme_ezrsurvey(), "theme")
  expect_s3_class(theme_ezrsurvey_xy(transparent = TRUE), "theme")
  expect_s3_class(scale_fill_rating(), "Scale")
  expect_s3_class(scale_fill_nps(), "Scale")
})
