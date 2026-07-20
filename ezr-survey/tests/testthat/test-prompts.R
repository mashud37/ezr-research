test_that("built-in prompt templates are registered", {
  p <- list_prompts()
  expect_s3_class(p, "tbl_df")
  expect_true(all(c("key_findings", "exec_summary", "drivers_barriers",
                    "slide_title", "slide_bullets", "thematic_analysis",
                    "segment_comparison", "methodology", "full_report")
                  %in% p$name))
})

test_that("get_prompt returns a usable spec", {
  spec <- get_prompt("key_findings")
  expect_true(all(c("system", "instruction", "description",
                    "output_contract") %in% names(spec)))
  expect_error(get_prompt("nope"))
})

test_that("register_prompt adds a template, with and without a contract", {
  register_prompt("test_tmpl", system = "S", instruction = "I",
                  description = "D")
  expect_true("test_tmpl" %in% list_prompts()$name)
  expect_equal(get_prompt("test_tmpl")$system, "S")
  expect_null(get_prompt("test_tmpl")$output_contract)

  register_prompt("test_tmpl2", system = "S", instruction = "I",
                  description = "D", output_contract = "One line only.")
  txt <- build_prompt("test_tmpl2", tibble::tibble(x = 1))
  expect_match(txt, "Required output format: One line only.", fixed = TRUE)
})

test_that("format_table_for_llm emits a markdown pipe table", {
  df <- tibble::tibble(answer = c("Yes", "No"), n = c(7L, 3L),
                       pct = c(70, 30))
  txt <- format_table_for_llm(df)
  lines <- strsplit(txt, "\n")[[1]]
  expect_equal(lines[[1]], "| answer | n | pct |")
  expect_match(lines[[2]], "^\\| --- \\| ---: \\| ---: \\|$")
  expect_equal(lines[[3]], "| Yes | 7 | 70 |")
})

test_that("format_table_for_llm truncates and notes omitted rows", {
  df <- tibble::tibble(x = 1:100)
  txt <- format_table_for_llm(df, max_rows = 10)
  expect_match(txt, "90 more rows omitted")
  expect_length(grep("^\\| [0-9]+ \\|$", strsplit(txt, "\n")[[1]]), 10)
})

test_that("build_prompt includes instruction, extras, contract and data", {
  df <- calc_percentage(podracing_survey, demo_gender)
  txt <- build_prompt("key_findings", df,
                      instructions = "focus on the gap", title = "Gender")
  expect_match(txt, "bullet points")
  expect_match(txt, "focus on the gap")
  expect_match(txt, "Gender")
  expect_match(txt, "demo_gender")
  expect_match(txt, "Required output format:")
})

test_that("ai_context derives n and precision from data", {
  ctx <- ai_context(podracing_survey, question = "Q1?",
                    fieldwork = "May 2026")
  expect_s3_class(ctx, "ezrsurvey_ai_context")
  expect_equal(ctx$n, nrow(podracing_survey))
  expect_output(print(ctx), "Sample size")

  block <- format_context_for_llm(ctx)
  expect_match(block, "Survey context:")
  expect_match(block, "n = 1000")
  expect_match(block, "Question asked: Q1\\?")
  expect_match(block, "Fieldwork: May 2026")
})

test_that("build_prompt renders context blocks and plain-string context", {
  df <- tibble::tibble(x = 1)
  ctx <- ai_context(n = 500, base = "All respondents")
  txt <- build_prompt("key_findings", df, context = ctx)
  expect_match(txt, "n = 500")
  expect_match(txt, "Base: All respondents")

  txt2 <- build_prompt("key_findings", df, context = "Wave 3 of 4.")
  expect_match(txt2, "Wave 3 of 4.", fixed = TRUE)
})
