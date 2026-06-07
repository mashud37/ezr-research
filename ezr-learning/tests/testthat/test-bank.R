test_that("the bank exposes a catalogue and topics", {
  b <- exercise_bank()
  expect_s3_class(b, "tbl_df")
  expect_gt(nrow(b), 12)
  expect_true(all(c("id", "chapter", "topic", "type", "difficulty") %in% names(b)))
  expect_true(all(b$type %in% c("mcq", "code")))
  expect_s3_class(list_topics(), "tbl_df")
})

test_that("draws are reproducible by seed and vary across seeds", {
  a1 <- draw_exercise(topic = "nps", seed = 42)
  a2 <- draw_exercise(topic = "nps", seed = 42)
  expect_identical(a1$prompt, a2$prompt)
  expect_identical(a1$answer, a2$answer)
  b <- draw_exercise(topic = "nps", seed = 7)
  expect_false(identical(a1$prompt, b$prompt) && identical(a1$data, b$data))
  expect_equal(a1$seed, 42)
})

test_that("filters scope the draw and bad filters error", {
  x <- draw_exercise(type = "mcq", seed = 3)
  expect_equal(x$type, "mcq")
  y <- draw_exercise(chapter = 6, seed = 3)
  expect_equal(y$chapter, 6)
  expect_error(draw_exercise(topic = "not_a_topic"), "No exercises match")
})

test_that("every generator instantiates and self-grades", {
  ids <- exercise_bank()$id
  for (gid in ids) {
    meta <- get(gid, envir = ezrlearning:::.generator_registry)$meta
    # skip generators whose optional ezr backend package is not installed
    if (!ezrlearning:::generator_available(meta)) next
    x <- draw_exercise(topic = meta$topic, type = meta$type, seed = 11)
    expect_s3_class(x, "ezrlearning_exercise")
    if (x$type == "mcq") {
      expect_true(check_answer(x, x$answer)$correct, info = gid)
    } else if (!is.null(x$solution_value) || !is.null(x$check)) {
      expect_true(check_answer(x, x$solution_code)$correct, info = gid)
    }
  }
})
