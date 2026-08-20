test_that("ai_context derives n and a precision note from data", {
  d <- data.frame(x = 1:1000)
  ctx <- ai_context(d, question = "Q1?", fieldwork = "May 2026")

  expect_s3_class(ctx, "ezrintelligence_context")
  expect_equal(ctx$n, 1000L)
  expect_match(ctx$precision, "margin of error")
  expect_output(print(ctx), "Sample size")
})

test_that("the derived margin of error tracks the sample size", {
  expect_match(ai_context(n = 1000)$precision, "3.1 percentage points")
  expect_match(ai_context(n = 100)$precision, "9.8 percentage points")
  expect_null(ai_context(n = 1)$precision)
})

test_that("an explicit precision note overrides the derived one", {
  ctx <- ai_context(n = 1000, precision = "design effect 1.4")
  expect_equal(ctx$precision, "design effect 1.4")
})

test_that("format_context_for_llm renders every field it is given", {
  ctx <- ai_context(n = 500, question = "Q1?", base = "All respondents",
                    fieldwork = "May 2026", notes = "Wave 3")
  block <- format_context_for_llm(ctx)

  expect_match(block, "Study context:")
  expect_match(block, "n = 500")
  expect_match(block, "Question asked: Q1\\?")
  expect_match(block, "Base: All respondents")
  expect_match(block, "Fieldwork: May 2026")
  expect_match(block, "Notes: Wave 3")
})

test_that("build_prompt renders context objects and plain-string context", {
  df <- tibble::tibble(x = 1)
  txt <- build_prompt("key_findings", df, context = ai_context(n = 500))
  expect_match(txt, "n = 500")

  txt2 <- build_prompt("key_findings", df, context = "Wave 3 of 4.")
  expect_match(txt2, "Wave 3 of 4.", fixed = TRUE)
})
