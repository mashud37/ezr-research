test_that("plot_nps builds and reports a score", {
  p <- plot_nps(consumer_survey, nps_value)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))
  expect_match(p$labels$title, "Net Promoter Score of:")
})

test_that("plot_nps tolerates worded scores", {
  df <- tibble::tibble(v = c("10", "9 - promoter", "3 detractor", "8", "7"))
  expect_no_error(ggplot2::ggplot_build(plot_nps(df, v)))
})

test_that("sample_comments pulls from multiple columns with trimmings", {
  out <- sample_comments(consumer_survey, nps_com, show_com,
                         n = 3, by_column = TRUE)
  expect_true(all(c("source", "comment", "length") %in% names(out)))
  expect_setequal(unique(out$source), c("nps_com", "show_com"))
  expect_true(all(out$length > 30))
  expect_true(all(nchar(out$comment) <= 400))
})

test_that("sample_comments exclude filter drops matching comments", {
  out <- sample_comments(consumer_survey, nps_com, show_com,
                         n = 50, by_column = FALSE, exclude = c("production"))
  expect_false(any(grepl("production", tolower(out$comment))))
})

test_that("sample_comments_diverse returns n scored, distinct comments", {
  out <- sample_comments_diverse(consumer_survey, nps_com, show_com,
                                 n = 5, seed = 1)
  expect_lte(nrow(out), 5)
  expect_true("info" %in% names(out))
  expect_equal(anyDuplicated(out$comment), 0)
})

test_that("sample_comments_diverse is reproducible with a seed", {
  a <- sample_comments_diverse(consumer_survey, nps_com, show_com, n = 5, seed = 42)
  b <- sample_comments_diverse(consumer_survey, nps_com, show_com, n = 5, seed = 42)
  expect_equal(a$comment, b$comment)
})

test_that("sample_comments_diverse restores the RNG state", {
  set.seed(123)
  before <- .Random.seed
  invisible(sample_comments_diverse(consumer_survey, nps_com, n = 3, seed = 7))
  expect_equal(.Random.seed, before)
})

test_that("entropy method also works", {
  out <- sample_comments_diverse(consumer_survey, nps_com, show_com,
                                 n = 4, method = "entropy", seed = 2)
  expect_lte(nrow(out), 4)
})

test_that("stopwords argument accepts custom vectors and FALSE", {
  expect_silent(sample_comments_diverse(consumer_survey, nps_com, show_com,
                                        n = 3, stopwords = c("the", "and"),
                                        seed = 3))
  expect_silent(sample_comments_diverse(consumer_survey, nps_com, show_com,
                                        n = 3, stopwords = FALSE, seed = 3))
})

test_that("resolve_stopwords honours FALSE, vectors, and a default set", {
  expect_equal(resolve_stopwords(FALSE), character(0))
  expect_equal(resolve_stopwords(c("A", "B")), c("a", "b"))
  expect_gt(length(resolve_stopwords(NULL)), 10)   # stopwords pkg or fallback
})
