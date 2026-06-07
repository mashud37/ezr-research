test_that("prompt registry lists, gets and registers templates", {
  p <- list_prompts()
  expect_s3_class(p, "tbl_df")
  expect_true(all(c("mcq", "code_task") %in% p$name))
  expect_type(get_prompt("mcq")$system, "character")
  register_prompt("tmp_t", system = "s", instruction = "i", description = "d")
  expect_true("tmp_t" %in% list_prompts()$name)
})

test_that("a parsed MCQ JSON becomes a gradable exercise", {
  j <- list(type = "mcq", prompt = "Which verb computes NPS?",
            options = c("calc_nps()", "calc_percentage()", "crosstab()"),
            answer = "A", explanation = "calc_nps does.", chapter = 2,
            topic = "nps")
  ex <- ezrlearning:::json_to_exercise(j, "nps", "easy")
  expect_s3_class(ex, "ezrlearning_exercise")
  expect_equal(ex$source, "ai")
  expect_true(check_answer(ex, "A")$correct)
  expect_false(check_answer(ex, "B")$correct)
})

test_that("a parsed code JSON is self-graded", {
  j <- list(type = "code", prompt = "Compute NPS.",
            solution_code = "calc_nps(theme_park, nps)", chapter = 2,
            topic = "nps")
  ex <- ezrlearning:::json_to_exercise(j, "nps", "easy")
  expect_equal(ex$type, "code")
  r <- check_answer(ex, "calc_nps(theme_park, nps)")
  expect_true(is.na(r$correct))   # no stored value -> self-graded
})

test_that("AI verbs error clearly without ellmer", {
  skip_if(requireNamespace("ellmer", quietly = TRUE),
          "ellmer is installed; skipping the missing-dependency path.")
  expect_error(generate_exercise("nps"), "ellmer")
})
