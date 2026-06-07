test_that("ezrsurvey_options reads and sets, reset restores", {
  withr::defer(reset_ezrsurvey_options())
  opts <- ezrsurvey_options()
  expect_true(all(c("pct_axis_unit", "pct_axis_max", "na_answers",
                    "generation_scheme") %in% names(opts)))
  expect_equal(opts$pct_axis_unit, 25)

  ezrsurvey_options(pct_axis_max = 100)
  expect_equal(ezrsurvey_options()$pct_axis_max, 100)
  expect_equal(ezrsurvey_default("pct_axis_max"), 100)

  reset_ezrsurvey_options()
  expect_null(ezrsurvey_options()$pct_axis_max)
})

test_that("ezrsurvey_options validates input", {
  expect_error(ezrsurvey_options(99))
  expect_warning(ezrsurvey_options(not_a_real_option = 1))
  reset_ezrsurvey_options()
})

test_that("na_blank honours the na_answers option", {
  withr::defer(reset_ezrsurvey_options())
  ezrsurvey_options(na_answers = c("Prefer not to answer", "Don't know"))
  expect_equal(na_blank(c("Yes", "Don't know", "No")), c("Yes", NA, "No"))
})

test_that("plot_bars honours the pct_axis_max option", {
  withr::defer(reset_ezrsurvey_options())
  ezrsurvey_options(pct_axis_max = 100)
  p <- calc_percentage(consumer_survey, demo_gender) |> plot_bars()
  expect_equal(ggplot2::layer_scales(p)$y$get_limits(), c(0, 100))
})

test_that("profile round-trips through YAML", {
  skip_if_not_installed("yaml")
  withr::defer(reset_ezrsurvey_options())
  dir <- withr::local_tempdir()
  path <- file.path(dir, ".ezrsurvey.yml")
  yaml::write_yaml(list(pct_axis_max = 80, generation_scheme = "pew"), path)

  expect_true(load_ezrsurvey_profile(path))
  expect_equal(ezrsurvey_default("pct_axis_max"), 80)
})

test_that("use_ezrsurvey_profile writes a template", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "ezrsurvey.yml")
  out <- use_ezrsurvey_profile(path)
  expect_equal(out, path)
  expect_true(file.exists(path))
  expect_error(use_ezrsurvey_profile(path))   # no overwrite by default
})

test_that("edit_ezrsurvey_profile creates the file and returns its path", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "edit.yml")
  out <- edit_ezrsurvey_profile(path)          # non-interactive: just messages
  expect_equal(out, path)
  expect_true(file.exists(path))
})

test_that("save_ezrsurvey_profile persists changed options", {
  skip_if_not_installed("yaml")
  withr::defer(reset_ezrsurvey_options())
  dir <- withr::local_tempdir()
  path <- file.path(dir, "save.yml")
  ezrsurvey_options(pct_axis_max = 80)
  save_ezrsurvey_profile(path, include_orders = FALSE)

  reset_ezrsurvey_options()
  expect_null(ezrsurvey_default("pct_axis_max"))
  load_ezrsurvey_profile(path)
  expect_equal(ezrsurvey_default("pct_axis_max"), 80)
})
