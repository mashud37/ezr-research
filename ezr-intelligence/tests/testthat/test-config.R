test_that("ezrintelligence_options reads, sets and restores", {
  expect_equal(ezrintelligence_options()$provider, "openai")

  old <- ezrintelligence_options(provider = "anthropic")
  expect_equal(ezrintelligence_options()$provider, "anthropic")

  options(stats::setNames(list(old$provider), "ezrintelligence.provider"))
  expect_equal(ezrintelligence_options()$provider, "openai")
})

test_that("ezrintelligence_options rejects unnamed and warns on unknown", {
  expect_error(ezrintelligence_options("openai"))
  expect_warning(ezrintelligence_options(not_an_option = 1))
  reset_ezrintelligence_options()
})

test_that("reset_ezrintelligence_options clears every option", {
  withr::local_options(ezrintelligence.max_rows = 5)
  reset_ezrintelligence_options()
  expect_equal(ezrintelligence_options()$max_rows, 50)
})

test_that("ezrintelligence_default errors on an unknown name", {
  expect_error(ezrintelligence_default("nope"))
})

test_that("a profile round-trips through save and load", {
  skip_if_not_installed("yaml")
  path <- withr::local_tempfile(fileext = ".yml")

  withr::with_options(list(ezrintelligence.provider = "anthropic"), {
    save_ezrintelligence_profile(path)
  })
  reset_ezrintelligence_options()
  expect_true(load_ezrintelligence_profile(path))
  expect_equal(ezrintelligence_options()$provider, "anthropic")

  reset_ezrintelligence_options()
})

test_that("use_ezrintelligence_profile writes a commented template", {
  path <- withr::local_tempfile(fileext = ".yml")
  expect_message(use_ezrintelligence_profile(path))
  expect_true(any(grepl("^# provider:", readLines(path))))
  expect_error(use_ezrintelligence_profile(path))
})

test_that("profile paths are listed user-first", {
  paths <- ezrintelligence_profile_paths()
  expect_length(paths, 3)
  expect_match(paths[[3]], "\\.ezrintelligence\\.yml$")
})
