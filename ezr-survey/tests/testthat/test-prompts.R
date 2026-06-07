test_that("built-in prompt templates are registered", {
  p <- list_prompts()
  expect_s3_class(p, "tbl_df")
  expect_true(all(c("key_findings", "exec_summary", "drivers_barriers",
                    "slide_title") %in% p$name))
})

test_that("get_prompt returns a usable spec", {
  spec <- get_prompt("key_findings")
  expect_true(all(c("system", "instruction", "description") %in% names(spec)))
  expect_error(get_prompt("nope"))
})

test_that("register_prompt adds a template", {
  register_prompt("test_tmpl", system = "S", instruction = "I",
                  description = "D")
  expect_true("test_tmpl" %in% list_prompts()$name)
  expect_equal(get_prompt("test_tmpl")$system, "S")
})

test_that("format_table_for_llm truncates and notes omitted rows", {
  df <- tibble::tibble(x = 1:100)
  txt <- format_table_for_llm(df, max_rows = 10)
  expect_match(txt, "more rows omitted")
})

test_that("build_prompt includes instruction, extras and data", {
  df <- calc_percentage(consumer_survey, demo_gender)
  txt <- build_prompt("key_findings", df,
                      instructions = "focus on the gap", title = "Gender")
  expect_match(txt, "concise bullet points")
  expect_match(txt, "focus on the gap")
  expect_match(txt, "Gender")
  expect_match(txt, "demo_gender")
})
