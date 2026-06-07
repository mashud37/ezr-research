test_that("an MCQ grades right and wrong answers", {
  x <- draw_exercise(topic = "percentage", type = "mcq", seed = 1)
  expect_s3_class(x, "ezrlearning_exercise")
  expect_equal(x$type, "mcq")
  expect_true(check_answer(x, x$answer)$correct)
  wrong <- setdiff(LETTERS[seq_along(x$options)], x$answer)[1]
  expect_false(check_answer(x, wrong)$correct)
})

test_that("a code exercise grades a matching result", {
  x <- draw_exercise(topic = "nps", type = "code", seed = 2)
  expect_equal(x$type, "code")
  # the reference solution code must grade correct
  expect_true(check_answer(x, x$solution_code)$correct)
  # a wrong value is incorrect
  expect_false(check_answer(x, 12345)$correct)
})

test_that("answer accepts letter, number and option text for MCQs", {
  x <- draw_exercise(topic = "reshape", type = "mcq", seed = 5)
  i <- match(x$answer, LETTERS)
  expect_true(check_answer(x, i)$correct)
  expect_true(check_answer(x, x$options[[i]])$correct)
})

test_that("reveal and hint run without error", {
  x <- draw_exercise(topic = "nps", seed = 1)
  expect_output(print(x))
  expect_invisible(reveal(x))
  expect_invisible(hint(x))
})

test_that("a code error is reported, not thrown", {
  x <- draw_exercise(topic = "nps", type = "code", seed = 2)
  r <- check_answer(x, "this_is_not_valid_code(")
  expect_false(r$correct)
  expect_match(r$message, "error")
})
