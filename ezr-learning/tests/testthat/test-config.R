test_that("options read, set and reset", {
  on.exit(reset_ezrlearning_options(), add = TRUE)
  expect_equal(ezrlearning_options()$difficulty, "easy")
  old <- ezrlearning_options(difficulty = "hard")
  expect_equal(ezrlearning_options()$difficulty, "hard")
  reset_ezrlearning_options()
  expect_equal(ezrlearning_options()$difficulty, "easy")
})

test_that("unknown options warn", {
  on.exit(reset_ezrlearning_options(), add = TRUE)
  expect_warning(ezrlearning_options(nonsense = 1), "Unknown")
})
