test_that("ellmer_constructor errors on an unknown provider", {
  skip_if_not_installed("ellmer")
  expect_error(ellmer_constructor("definitely_not_a_provider"))
  expect_true(is.function(ellmer_constructor("openai")))
})

test_that("ai_chat requires a key for cloud providers", {
  skip_if_not_installed("ellmer")
  withr::local_envvar(c(ZZZPROVIDER_API_KEY = ""))
  # unknown provider fails at the constructor lookup, before any network call
  expect_error(ai_chat("zzzprovider"))
})

test_that("ai_report_sections validates a named list", {
  expect_error(ai_report_sections(list(calc_percentage(consumer_survey,
                                                        demo_gender))))
})
