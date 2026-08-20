# Smoke tests: confirm each plot wrapper returns a ggplot that actually builds.

test_that("plot_bars builds", {
  p <- calc_percentage(podracing_survey, demo_gender, sort = "desc") %>% plot_bars()
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("plot_bars flips and adds an average line", {
  p <- calc_percentage(podracing_survey, demo_edu) %>%
    plot_bars(flip = TRUE, avg_line = TRUE)
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("auto_bar_layout chooses orientation, order and wrap", {
  few_short <- auto_bar_layout(c("M", "F", "X"), 3, "auto", FALSE,
                               "auto", NULL, NULL)
  expect_equal(few_short$orientation, "cols")
  expect_equal(few_short$sort, "desc")            # largest on the left

  long_label <- auto_bar_layout("A rather long category label", 1, "auto",
                                FALSE, "auto", NULL, NULL)
  expect_equal(long_label$orientation, "bars")
  expect_equal(long_label$sort, "asc")            # largest on top after flip

  many <- auto_bar_layout(letters[1:9], 9, "auto", FALSE, "auto", NULL, NULL)
  expect_equal(many$orientation, "bars")

  ordinal <- auto_bar_layout(c("Low", "Mid", "High"), 3, "auto", TRUE,
                             "auto", NULL, NULL)
  expect_equal(ordinal$sort, "none")              # ordinal scale left alone

  # text size steps down as bars multiply, floored at bar_size_min
  big <- auto_bar_layout(letters[1:25], 25, "bars", FALSE, "auto", NULL, NULL)
  expect_equal(big$size, ezrsurvey_default("bar_size_min"))
})

test_that("plot_bars auto-orders bars and wraps long labels", {
  # few short labels -> vertical cols, largest share on the left (first level)
  g <- calc_percentage(podracing_survey, demo_gender)
  lv_g <- levels(ggplot2::ggplot_build(plot_bars(g))$plot$data$demo_gender)
  top_g <- as.character(g$demo_gender[which.max(g$pct)])
  expect_equal(gsub("\n", " ", lv_g[1]), top_g)

  # many long labels -> horizontal bars, largest share on top (last level)
  fd <- calc_percentage(podracing_survey, fav_driver)
  lv_d <- levels(ggplot2::ggplot_build(plot_bars(fd))$plot$data$fav_driver)
  top_d <- as.character(fd$fav_driver[which.max(fd$pct)])
  expect_equal(gsub("\n", " ", lv_d[length(lv_d)]), top_d)

  # forcing narrow columns wraps the long driver names
  lv_w <- levels(ggplot2::ggplot_build(
    plot_bars(fd, orientation = "cols"))$plot$data$fav_driver)
  expect_true(any(grepl("\n", lv_w)))
})

test_that("plot_bars keeps a registered ordinal scale in order", {
  withr::defer(remove_order("edu_isced_t"))
  register_order("edu_isced_t",
                 c("Primary or less", "Lower secondary", "Upper secondary",
                   "Short-cycle tertiary", "Bachelor or equivalent",
                   "Master or equivalent", "Doctoral or equivalent"),
                 vars = "demo_edu")
  tbl <- calc_percentage(podracing_survey, demo_edu)
  expect_true(is.ordered(tbl$demo_edu))
  lv <- levels(ggplot2::ggplot_build(
    plot_bars(tbl, orientation = "bars"))$plot$data$demo_edu)
  expect_equal(gsub("\n", " ", lv[1]), "Primary or less")  # not re-sorted
})

test_that("plot_nps_gauge builds for both scales", {
  expect_no_error(ggplot2::ggplot_build(plot_nps_gauge(42)))
  expect_no_error(ggplot2::ggplot_build(plot_nps_gauge(3.8, scale = "rating")))
})

test_that("plot_gauges stacks scores and infers scales", {
  p <- plot_gauges(c("Net Promoter Score" = 23, "Average quality rating" = 3.4))
  expect_no_error(ggplot2::ggplot_build(p))
  # explicit scales and a single gauge also build
  expect_no_error(ggplot2::ggplot_build(
    plot_gauges(c("Recommendation" = 5, "Quality" = 4.2),
                scales = c("nps", "rating"))
  ))
  expect_error(plot_gauges(c(10, 20)), "named")
})

test_that("plot_ipm builds", {
  skip_if_not_installed("rwa")
  m <- ipm_model(podracing_survey, nps_value, "ratings_")
  expect_no_error(ggplot2::ggplot_build(plot_ipm(m)))
})

test_that("themes and palette scales return the right objects", {
  expect_s3_class(theme_ezrsurvey(), "theme")
  expect_s3_class(theme_ezrsurvey_xy(transparent = TRUE), "theme")
  expect_s3_class(scale_fill_rating(), "Scale")
  expect_s3_class(scale_fill_nps(), "Scale")
})
