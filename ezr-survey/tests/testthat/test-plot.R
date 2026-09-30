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

test_that("each gauge bar carries the breaks of its own scale", {
  g <- ezrsurvey:::gauge_layout(c("Net Promoter Score" = 23, "Quality" = 3.4),
                                c("nps", "rating"), 0.5)
  # the first gauge is drawn on top, so its ticks sit at the higher y
  top <- g$ticks[g$ticks$y > 1, ]
  bottom <- g$ticks[g$ticks$y < 1, ]
  expect_equal(top$label, c("-100", "0", "30", "70", "100"))
  expect_equal(bottom$label, c("1", "3", "4", "5"))
  # both scales are normalised onto the same bar, so both span it end to end
  expect_equal(range(top$x), c(0, 1))
  expect_equal(range(bottom$x), c(0, 1))
})

test_that("a band too narrow for its name is left to its numbers", {
  # the NPS scale gives EXCELLENT a 30-point band, a fifteenth of the bar
  expect_false(ezrsurvey:::band_fits(0.15, "EXCELLENT"))
  expect_true(ezrsurvey:::band_fits(0.50, "NEEDS WORK"))
  g <- ezrsurvey:::gauge_layout(c("Net Promoter Score" = 23), "nps", 0.5)
  expect_equal(g$rects$label[!g$rects$wide], "EXCELLENT")
})

test_that("each NPS callout is centred over the bars it describes", {
  p <- plot_nps(podracing_survey, nps_value)
  # annotate() keeps the text in aes_params and the position in the layer's data
  callout_x <- function(word) {
    for (layer in p$layers) {
      text <- layer$aes_params$label
      if (!is.null(text) && grepl(word, text)) return(layer$data$x[[1]])
    }
    NA_real_
  }
  # scores 0-10 are drawn at 1-11, so detractors occupy 1-7, passives 8-9 and
  # promoters 10-11; each callout belongs at the midpoint of its own block
  expect_equal(callout_x("DETRACTOR"), 4)
  expect_equal(callout_x("PASSIVE"), 8.5)
  expect_equal(callout_x("PROMOTER"), 10.5)
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

test_that("plot_rating_grid builds a whole question block in one call", {
  p <- plot_rating_grid(podracing_survey, "ratings_")
  expect_s3_class(p, "ggplot")
  # the block prefix is stripped from the feature labels
  expect_false(any(grepl("^ratings_", as.character(p$data[[1]]))))
})

test_that("plot_rating_grid reports answers that are not on the scale", {
  d <- podracing_survey
  d$fit_a <- "Fits the community"
  expect_message(
    plot_rating_grid(d, "fit_",
                     levels = c("Does not fit", "Fits the commnity")),
    "not on the"
  )
})

test_that("plot_rating_grid errors when no column matches the prefix", {
  expect_error(plot_rating_grid(podracing_survey, "nothing_"), "start with")
})

test_that("plot_stacked_rating names the argument the caller forgot", {
  d <- data.frame(feature = "a", level = "Good", pct = 100)
  expect_error(plot_stacked_rating(d), "needs `feature` and `level`")
  expect_error(plot_stacked_rating(d, feature), "needs `feature` and `level`")
  expect_no_error(ggplot2::ggplot_build(plot_stacked_rating(d, feature, level)))
})

test_that("plot_quotes_tree says which column it is missing", {
  skip_if_not_installed("treemapify")
  raw <- data.frame(comment = c("a quote", "another quote"),
                    stringsAsFactors = FALSE)
  # `length` is a base function, so without a guard this fails much later as a
  # ggplot aesthetic error rather than here
  expect_error(plot_quotes_tree(raw, comment), "needs a `length` column")
  expect_error(plot_quotes_tree(raw, no_such_col), "needs a `no_such_col`")
  quotes <- sample_comments(podracing_survey, nps_com, n = 4)
  expect_no_error(ggplot2::ggplot_build(plot_quotes_tree(quotes)))
})

test_that("plot_rating_grid reports two answers landing on one rank", {
  d <- data.frame(
    rate_a = c("Agree", "Disagree", "Neither agree nor disagree"),
    rate_b = c("Strongly agree", "Agree", "Neither agree nor disagree"),
    stringsAsFactors = FALSE
  )
  # recode_likert() falls back to substring matching, so without the check
  # "Neither agree nor disagree" quietly becomes "Disagree"
  expect_message(
    plot_rating_grid(d, "rate_",
                     levels = c("Strongly disagree", "Disagree",
                                "Agree", "Strongly agree")),
    "both came out as"
  )
  # naming the level it was missing settles it
  expect_no_message(
    plot_rating_grid(d, "rate_",
                     levels = c("Strongly disagree", "Disagree",
                                "Neither agree nor disagree",
                                "Agree", "Strongly agree"))
  )
})

test_that("plot_ipm draws on the scale its bands describe", {
  skip_if_not_installed("rwa")
  model <- ipm_model(podracing_survey, nps_value, "ratings_")

  # Performance on 0-100, with bands moved to match: every point must be
  # inside the panel, not clipped away by a hardcoded 1-5 axis.
  wide <- model
  wide$performance <- (wide$performance - 1) / 4 * 100
  p <- plot_ipm(wide, bands = rescale_bands(bands_rating_3(), to = c(0, 100)))
  rng <- ggplot2::ggplot_build(p)$layout$panel_params[[1]]$x.range
  expect_lte(rng[[1]], min(wide$performance))
  expect_gte(rng[[2]], max(wide$performance))

  # The default 1-5 bands cannot hold those values, and saying so beats
  # returning an empty chart.
  expect_message(plot_ipm(wide), "fall outside")

  # The ordinary 1-5 case is unchanged. The panel carries ggplot's usual 5%
  # expansion either side, so the scale's own limits are what to check.
  plain <- ggplot2::ggplot_build(plot_ipm(model))
  expect_equal(plain$layout$panel_scales_x[[1]]$get_limits(), c(1, 5))
})
