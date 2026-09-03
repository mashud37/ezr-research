test_that("the default output folder is ezrsurvey-outputs, written to flat", {
  dir <- withr::local_tempdir()
  withr::local_dir(dir)
  expect_equal(resolve_output_path(default_output_path("plot", "png")),
               file.path("ezrsurvey-outputs", "plot.png"))
  save_data(calc_percentage(podracing_survey, demo_gender))
  expect_true(file.exists(file.path("ezrsurvey-outputs", "data.csv")))
})

test_that("save_data writes csv and tsv and returns its input", {
  dir <- withr::local_tempdir()
  tab <- calc_percentage(podracing_survey, demo_gender)

  csv <- file.path(dir, "t.csv")
  out <- save_data(tab, csv)
  expect_identical(out, tab)              # returned invisibly for piping
  expect_true(file.exists(csv))
  expect_equal(nrow(readr::read_csv(csv, show_col_types = FALSE)), nrow(tab))

  tsv <- file.path(dir, "t.tsv")
  save_data(tab, tsv)
  expect_true(file.exists(tsv))
})

test_that("save_data writes xlsx, including multi-sheet lists", {
  skip_if_not_installed("writexl")
  dir <- withr::local_tempdir()
  one <- file.path(dir, "one.xlsx")
  save_data(calc_percentage(podracing_survey, demo_gender), one)
  expect_true(file.exists(one))

  many <- file.path(dir, "many.xlsx")
  save_data(list(gender = calc_percentage(podracing_survey, demo_gender),
                 edu = calc_percentage(podracing_survey, demo_edu)), many)
  expect_true(file.exists(many))
})

test_that("save_data rejects unknown extensions", {
  expect_error(save_data(podracing_survey, tempfile(fileext = ".foo")))
})

test_that("save_plot writes png and svg and returns the plot", {
  dir <- withr::local_tempdir()
  p <- plot_bars(calc_percentage(podracing_survey, demo_gender))

  png <- file.path(dir, "p.png")
  out <- save_plot(p, png)
  expect_s3_class(out, "ggplot")
  expect_true(file.exists(png))

  skip_if_not_installed("svglite")
  svg <- file.path(dir, "p.svg")
  save_plot(p, svg)
  expect_true(file.exists(svg))
})

test_that("save_plot rejects non-ggplot input", {
  expect_error(save_plot(podracing_survey, tempfile(fileext = ".png")))
})

test_that("save_output dispatches on object type", {
  dir <- withr::local_tempdir()
  csv <- file.path(dir, "o.csv")
  save_output(calc_percentage(podracing_survey, demo_gender), csv)
  expect_true(file.exists(csv))

  png <- file.path(dir, "o.png")
  save_output(plot_bars(calc_percentage(podracing_survey, demo_gender)), png)
  expect_true(file.exists(png))

  expect_error(save_output(42, csv))
})

test_that("a bare file name lands in the outputs folder", {
  dir <- withr::local_tempdir()
  withr::local_dir(dir)

  expect_equal(resolve_output_path("chart.png"),
               file.path("ezrsurvey-outputs", "chart.png"))
  expect_true(dir.exists("ezrsurvey-outputs"))

  # naming a directory is how the caller overrides the default
  expect_equal(resolve_output_path("./chart.png"), "./chart.png")
  expect_equal(resolve_output_path("charts/chart.png"), "charts/chart.png")
  expect_true(dir.exists("charts"))

  absolute <- file.path(dir, "chart.png")
  expect_equal(resolve_output_path(absolute), absolute)

  withr::local_options(ezrsurvey.output_dir = ".")
  expect_equal(resolve_output_path("chart.png"), "chart.png")
})

test_that("save_plot writes into the outputs folder by default", {
  dir <- withr::local_tempdir()
  withr::local_dir(dir)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) + ggplot2::geom_point()

  save_plot(p, "chart.png", width = 3, height = 2)
  expect_true(file.exists(file.path("ezrsurvey-outputs", "chart.png")))

  save_data(head(mtcars), "cars.csv")
  expect_true(file.exists(file.path("ezrsurvey-outputs", "cars.csv")))
})
