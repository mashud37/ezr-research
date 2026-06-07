test_that("band presets have the required shape", {
  for (b in list(bands_rating_3(), bands_rating_5(), bands_nps())) {
    expect_true(all(c("from", "to", "label", "colour") %in% names(b)))
    expect_true(all(b$to > b$from))
  }
})

test_that("annotate_bands adds layers to a plot", {
  base <- ggplot2::ggplot(consumer_survey, ggplot2::aes(demo_age, nps_value)) +
    ggplot2::geom_point()
  p <- annotate_bands(base, bands_rating_3(), axis = "x", at = 10)
  expect_s3_class(p, "ggplot")
  expect_gt(length(p$layers), length(base$layers))
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("annotate_bands validates the band spec", {
  base <- ggplot2::ggplot(consumer_survey, ggplot2::aes(demo_age, nps_value)) +
    ggplot2::geom_point()
  expect_error(annotate_bands(base, data.frame(x = 1), at = 1))
})

test_that("mark_value adds a reference line", {
  base <- ggplot2::ggplot(consumer_survey, ggplot2::aes(demo_age, nps_value)) +
    ggplot2::geom_point()
  p <- mark_value(base, 5, axis = "x")
  expect_gt(length(p$layers), length(base$layers))
  expect_no_error(ggplot2::ggplot_build(p))
})
