test_that("ezrmodel_options reads, sets and resets", {
  withr::defer(reset_ezrmodel_options())
  opts <- ezrmodel_options()
  expect_true(all(c("na_answers", "seed", "scale") %in% names(opts)))
  ezrmodel_options(seed = 42)
  expect_equal(ezrmodel_options()$seed, 42)
  reset_ezrmodel_options()
  expect_null(ezrmodel_options()$seed)
})

test_that("ezrmodel_options validates input", {
  expect_error(ezrmodel_options(99))
  expect_warning(ezrmodel_options(not_real = 1))
  reset_ezrmodel_options()
})

test_that("seed option makes kmeans reproducible", {
  withr::defer(reset_ezrmodel_options())
  ezrmodel_options(seed = 7)
  a <- cluster(ecommerce, k = 3, vars = c(recency_days, frequency, monetary))
  b <- cluster(ecommerce, k = 3, vars = c(recency_days, frequency, monetary))
  expect_equal(a$assignments, b$assignments)
})

test_that("profile round-trips through YAML", {
  skip_if_not_installed("yaml")
  withr::defer(reset_ezrmodel_options())
  dir <- withr::local_tempdir()
  path <- file.path(dir, ".ezrmodel.yml")
  yaml::write_yaml(list(seed = 99), path)
  expect_true(load_ezrmodel_profile(path))
  expect_equal(ezrmodel_default("seed"), 99)
})

test_that("use_ezrmodel_profile writes a template", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "ezrmodel.yml")
  out <- use_ezrmodel_profile(path)
  expect_true(file.exists(out))
  expect_error(use_ezrmodel_profile(path))
})

test_that("na_blank honours the na_answers option", {
  expect_equal(na_blank(c("a", "", "Prefer not to answer", "b")),
               c("a", NA, NA, "b"))
})

test_that("ensure_numeric salvages embedded numbers", {
  expect_equal(ensure_numeric(c("8 - very likely", "10", "x"), quiet = TRUE),
               c(8, 10, NA))
})
