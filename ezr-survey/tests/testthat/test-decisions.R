test_that("band presets have the required shape", {
  for (b in list(bands_rating_3(), bands_rating_5(), bands_nps())) {
    expect_true(all(c("from", "to", "label", "colour") %in% names(b)))
    expect_true(all(b$to > b$from))
  }
})

test_that("annotate_bands adds layers to a plot", {
  base <- ggplot2::ggplot(podracing_survey, ggplot2::aes(demo_age, nps_value)) +
    ggplot2::geom_point()
  p <- annotate_bands(base, bands_rating_3(), axis = "x", at = 10)
  expect_s3_class(p, "ggplot")
  expect_gt(length(p$layers), length(base$layers))
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("annotate_bands validates the band spec", {
  base <- ggplot2::ggplot(podracing_survey, ggplot2::aes(demo_age, nps_value)) +
    ggplot2::geom_point()
  expect_error(annotate_bands(base, data.frame(x = 1), at = 1))
})

test_that("mark_value adds a reference line", {
  base <- ggplot2::ggplot(podracing_survey, ggplot2::aes(demo_age, nps_value)) +
    ggplot2::geom_point()
  p <- mark_value(base, 5, axis = "x")
  expect_gt(length(p$layers), length(base$layers))
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("band lookup colours a value by the band it sits in", {
  b <- bands_rating_3()   # BAD 1-3 (red), OK 3-4 (amber), GOOD 4-5 (green)
  expect_equal(band_label(c(1.2, 2.4, 2.9), b), rep("BAD", 3))
  expect_equal(band_label(3, b), "OK")
  expect_equal(band_label(c(4, 5), b), c("GOOD", "GOOD"))
  # a mid-2 rating is red, never the amber of the neighbouring band
  expect_equal(band_colour(2.4, b), b$colour[b$label == "BAD"])
  # out-of-range values clamp to the end bands instead of returning NA
  expect_equal(band_label(0, b), "BAD")
  expect_equal(band_label(99, b), "GOOD")
})

test_that("the rating palette agrees with the 3-band thresholds", {
  b <- bands_rating_3()
  bad <- b$colour[b$label == "BAD"]
  ok <- b$colour[b$label == "OK"]
  # 1 and 2 both sit in BAD, so both must carry the BAD colour -- a 2 shaded
  # amber is the miscolouring this guards against
  expect_equal(unname(pal_rating[["1"]]), bad)
  expect_equal(unname(pal_rating[["2"]]), bad)
  expect_equal(unname(pal_rating[["3"]]), ok)
  # 4 and 5 are both good greens (two shades, distinct from bad and ok)
  expect_false(unname(pal_rating[["4"]]) %in% c(bad, ok))
  expect_false(unname(pal_rating[["5"]]) %in% c(bad, ok))
})

test_that("band presets can be clipped to the axis a chart shows", {
  full <- bands_rating_3()
  expect_equal(full$from[[1]], 1)

  clipped <- bands_rating_3(from = 2)
  expect_equal(clipped$from[[1]], 2)
  expect_equal(nrow(clipped), nrow(full))
  expect_equal(clipped$to, full$to)

  # a band entirely outside the range drops out
  expect_equal(nrow(bands_rating_3(from = 4)), 1)
  expect_equal(nrow(bands_rating_3(to = 3)), 1)
})

test_that("bands_nps_score covers the -100..100 score axis", {
  b <- bands_nps_score()
  expect_equal(min(b$from), -100)
  expect_equal(max(b$to), 100)
  expect_true(all(c("label", "from", "to", "colour") %in% names(b)))
  # bands_nps() is the 0-10 answer scale and is a different thing
  expect_equal(max(bands_nps()$to), 10.5)
})

test_that("rescale_bands moves a preset onto another scale", {
  wide <- rescale_bands(bands_rating_3(), to = c(0, 100))
  expect_equal(min(wide$from), 0)
  expect_equal(max(wide$to), 100)
  # BAD covers 1-3 of 1-5, which is half the scale, so half of 0-100 too
  expect_equal(wide$to[[1]], 50)
  expect_equal(wide$label, bands_rating_3()$label)
  expect_equal(wide$colour, bands_rating_3()$colour)

  seven <- rescale_bands(bands_rating_3(), to = c(1, 7))
  expect_equal(min(seven$from), 1)
  expect_equal(max(seven$to), 7)

  # the scale the bands are written on can be stated when it is not their span
  stated <- rescale_bands(bands_rating_3(), to = c(0, 10), from = c(0, 5))
  expect_equal(stated$from[[1]], 2)
})

test_that("rescale_bands rejects a scale it cannot use", {
  expect_error(rescale_bands(bands_rating_3(), to = 100), "two numbers")
  expect_error(rescale_bands(bands_rating_3(), to = c(0, NA)), "two numbers")
  expect_error(
    rescale_bands(bands_rating_3(), to = c(0, 100), from = c(2, 2)),
    "no range"
  )
})
