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
  expect_error(ai_report_sections(list(data.frame(answer = "Yes", pct = 100))))
})

test_that("ai_summarise sends the built prompt to the chat it is given", {
  seen <- NULL
  stub <- list(chat = function(msg) {
    seen <<- msg
    "- Yes leads on 70%."
  })
  df <- data.frame(answer = c("Yes", "No"), pct = c(70, 30))
  out <- ai_summarise(df, chat = stub, title = "Agreement",
                      context = ai_context(n = 500))

  expect_equal(out, "- Yes leads on 70%.")
  expect_match(seen, "Agreement", fixed = TRUE)
  expect_match(seen, "n = 500", fixed = TRUE)
  expect_match(seen, "| Yes | 70 |", fixed = TRUE)
})

test_that("ai_report_sections summarises every named section", {
  stub <- list(chat = function(msg) "ok")
  out <- ai_report_sections(
    list(
      gender = data.frame(answer = c("Female", "Male"), pct = c(55, 45)),
      nps = list(data = data.frame(nps = 32), template = "exec_summary")
    ),
    chat = stub
  )
  expect_named(out, c("gender", "nps"))
  expect_equal(out$gender, "ok")
})
