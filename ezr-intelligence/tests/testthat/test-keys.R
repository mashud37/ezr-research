test_that("llm_env_var maps providers to conventional vars", {
  expect_equal(llm_env_var("openai"), "OPENAI_API_KEY")
  expect_equal(llm_env_var("anthropic"), "ANTHROPIC_API_KEY")
  expect_equal(llm_env_var("acme"), "ACME_API_KEY")
})

test_that("get_llm_key falls back to the environment variable", {
  withr::local_envvar(c(OPENAI_API_KEY = "sk-test-123"))
  expect_equal(get_llm_key("openai"), "sk-test-123")
  expect_true(has_llm_key("openai"))
})

test_that("get_llm_key errors (or returns NA) when no key exists", {
  withr::local_envvar(c(ZZZPROVIDER_API_KEY = ""))
  expect_error(get_llm_key("zzzprovider"))
  expect_true(is.na(get_llm_key("zzzprovider", error = FALSE)))
  expect_false(has_llm_key("zzzprovider"))
})
