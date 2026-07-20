test_that("parse_ooxml_theme reads srgb colours and fonts", {
  skip_if_not_installed("xml2")
  theme <- parse_ooxml_theme(test_path("fixtures", "theme-srgb.xml"))
  expect_equal(theme$accents[1:3], c("#0B5394", "#E69138", "#6AA84F"))
  expect_length(theme$accents, 6)
  expect_equal(theme$dark, "#1A1A2E")
  expect_equal(theme$light, "#FDFDFD")
  expect_equal(theme$font_major, "Georgia")
  expect_equal(theme$font_minor, "Verdana")
})

test_that("parse_ooxml_theme falls back to sysClr lastClr and skips +mj fonts", {
  skip_if_not_installed("xml2")
  theme <- parse_ooxml_theme(test_path("fixtures", "theme-sysclr.xml"))
  expect_equal(theme$dark, "#000000")
  expect_equal(theme$light, "#FFFFFF")
  expect_equal(theme$accents[[1]], "#4472C4")
  expect_null(theme$font_major)
  expect_equal(theme$font_minor, "Calibri")
})

test_that("use_brand extracts a real pptx template end to end", {
  skip_if_not_installed("xml2")
  skip_if_not_installed("officer")
  skip_if_not_installed("withr")
  withr::defer(clear_brand())

  tmp <- withr::local_tempfile(fileext = ".pptx")
  print(officer::read_pptx(), target = tmp)

  info <- use_brand(tmp, quiet = TRUE)
  expect_s3_class(info, "ezrsurvey_brand")
  expect_length(info$colors, 6)
  expect_true(all(is_hex(info$colors)))
  expect_equal(ezrsurvey_default("brand_color_primary"), info$colors[[1]])
  expect_equal(ezrsurvey_default("brand_template_pptx"),
               normalizePath(tmp, winslash = "/"))
})

test_that("use_brand accepts manual colors and fonts without a template", {
  skip_if_not_installed("withr")
  withr::defer(clear_brand())

  expect_warning(
    use_brand(colors = c("#112233", "oops", "#445566"), quiet = TRUE),
    "invalid hex"
  )
  expect_equal(ezrsurvey_default("brand_color_primary"), "#112233")
  expect_equal(ezrsurvey_default("brand_colors"), c("#112233", "#445566"))

  use_brand(fonts = c(major = "Georgia", minor = "Verdana"), quiet = TRUE)
  expect_equal(ezrsurvey_default("brand_font_major"), "Georgia")
  expect_equal(ezrsurvey_default("brand_font_minor"), "Verdana")
})

test_that("use_brand validates its input", {
  expect_error(use_brand(), "Provide a")
  expect_error(use_brand("nope.txt"), "pptx or")
  expect_error(extract_ooxml_theme("missing-file.pptx"), "does not exist")
})

test_that("brand colours flow into plot_bars and pal_brand", {
  skip_if_not_installed("withr")
  withr::local_options(list(
    ezrsurvey.brand_colors = c("#112233", "#445566"),
    ezrsurvey.brand_color_primary = "#112233"
  ))
  p <- plot_bars(calc_percentage(podracing_survey, demo_gender))
  fills <- ggplot2::ggplot_build(p)$data[[1]]$fill
  expect_true(all(fills == "#112233"))

  expect_equal(pal_brand(), c("#112233", "#445566"))
  expect_equal(pal_brand(1), "#112233")
  expect_length(pal_brand(5), 5)
})

test_that("defaults are unchanged without a brand", {
  skip_if_not_installed("withr")
  withr::local_options(list(
    ezrsurvey.brand_colors = NULL,
    ezrsurvey.brand_color_primary = NULL,
    ezrsurvey.brand_font_minor = NULL
  ))
  p <- plot_bars(calc_percentage(podracing_survey, demo_gender))
  fills <- ggplot2::ggplot_build(p)$data[[1]]$fill
  expect_true(all(fills == pal_neutral))

  expect_equal(pal_brand(), pal_sequential_blue)
  expect_equal(theme_ezrsurvey()$text$family, "sans")
})

test_that("brand fonts are ignored when not installed", {
  skip_if_not_installed("withr")
  skip_if_not_installed("systemfonts")
  withr::local_options(list(
    ezrsurvey.brand_font_minor = "No Such Corporate Font 123"
  ))
  suppressMessages(
    expect_equal(theme_ezrsurvey()$text$family, "sans")
  )
})

test_that("clear_brand resets everything and brand_info prints", {
  skip_if_not_installed("withr")
  withr::defer(clear_brand())
  use_brand(colors = "#112233", quiet = TRUE)
  clear_brand()
  info <- brand_info()
  expect_true(all(vapply(info, is.null, logical(1))))
  expect_output(print(info), "No brand set")
})
