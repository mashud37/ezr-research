test_that("a quiz is reproducible and the right length", {
  q1 <- quiz(4, seed = 1)
  q2 <- quiz(4, seed = 1)
  expect_s3_class(q1, "ezrlearning_quiz")
  expect_equal(q1$n, 4L)
  ids <- function(q) vapply(q$exercises, `[[`, character(1), "id")
  expect_identical(ids(q1), ids(q2))
})

test_that("grade scores all-correct and mixed answers", {
  q <- quiz(4, seed = 1)
  right <- lapply(q$exercises, function(e)
    if (e$type == "mcq") e$answer else e$solution_code)
  g <- grade(q, right)
  expect_s3_class(g, "ezrlearning_grade")
  expect_equal(g$score, 1)
  expect_equal(g$n_correct, g$n_graded)

  q2 <- quiz(3, type = "mcq", seed = 2)
  g2 <- grade(q2, as.list(rep("A", 3)))
  expect_true(g2$score >= 0 && g2$score <= 1)
})

test_that("export_worksheet writes a self-contained Rmd", {
  q <- quiz(3, seed = 1)
  f <- tempfile(fileext = ".Rmd")
  p <- export_worksheet(q, f, answer_key = TRUE)
  expect_true(file.exists(p))
  txt <- readLines(p)
  expect_true(any(grepl("library\\(ezrlearning\\)", txt)))
  expect_true(any(grepl("quiz\\(n = 3", txt)))      # rebuilds itself
  expect_true(any(grepl("reveal\\(q\\$exercises", txt)))  # answer key
})
