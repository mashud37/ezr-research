test_that("progress is off in non-interactive sessions by default", {
  withr::local_options(list(ezrsurvey.progress = "auto"))
  # Tests never run interactively, so "auto" must resolve to silent -- this is
  # what keeps every expect_silent() in the suite passing.
  expect_false(progress_on())

  run <- progress_start(3, "starting")
  expect_silent(progress_item(run, 1, "first"))
  expect_silent(progress_note("anything"))
  expect_silent(progress_done(run))
})

test_that("progress can be forced on and off", {
  withr::local_options(list(ezrsurvey.progress = TRUE))
  expect_true(progress_on())
  run <- progress_start(2)
  expect_message(progress_item(run, 1, "first"), "\\[1/2\\] first")
  expect_message(progress_plan("Plan", c("a", "b")), "Plan")

  withr::local_options(list(ezrsurvey.progress = FALSE))
  expect_false(progress_on())
  expect_silent(progress_item(progress_start(2), 1, "first"))
})

test_that("a run that starts quiet stays quiet", {
  withr::local_options(list(ezrsurvey.progress = FALSE))
  run <- progress_start(2)
  withr::local_options(list(ezrsurvey.progress = TRUE))
  # Whether to report is settled when the run opens, so a run cannot start
  # reporting half way through.
  expect_silent(progress_item(run, 1, "first"))
})

test_that("format_duration reads in sensible units", {
  expect_equal(format_duration(12), "12s")
  expect_equal(format_duration(300), "5m")
  expect_equal(format_duration(7200), "2h")
  expect_equal(format_duration(NA_real_), "?")
})

test_that("the ETA is empty until there is something to measure", {
  run <- progress_start(10)
  expect_equal(progress_eta(run, 1), "")   # nothing done yet
  run$started <- Sys.time() - 100
  expect_match(progress_eta(run, 5), "left")
})
