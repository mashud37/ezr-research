test_that("tokenize_text returns a tidy term table", {
  tk <- tokenize_text(reviews, text, review_id)
  expect_s3_class(tk, "ezrmodel_tokens")
  expect_true(all(c("review_id", "term") %in% names(tk$tokens)))
  expect_gt(nrow(tk$tokens), 0)
  # stop-words and short tokens are removed
  expect_false("the" %in% tk$tokens$term)
  expect_true(all(nchar(tk$tokens$term) >= 3))
})

test_that("tokenize print, tidy and plot work", {
  tk <- tokenize_text(reviews, text)
  expect_output(print(tk), "Tokens from")
  expect_s3_class(tidy(tk), "tbl_df")
  expect_s3_class(plot(tk), "ggplot")
})

test_that("term_freq counts terms without a grouping", {
  tf <- term_freq(reviews, text)
  expect_s3_class(tf, "ezrmodel_termfreq")
  expect_equal(tf$weight, "count")
  expect_true(all(c("term", "n") %in% names(tf$freq)))
})

test_that("term_freq computes tf-idf by group", {
  tf <- term_freq(reviews, text, by = rating, top = 5)
  expect_equal(tf$weight, "tfidf")
  expect_true(all(c("rating", "term", "tf", "idf", "tfidf") %in% names(tf$freq)))
  # no group keeps more than `top` terms
  per_group <- tapply(tf$freq$term, tf$freq$rating, length)
  expect_true(all(per_group <= 5))
  expect_s3_class(plot(tf), "ggplot")
})

test_that("term_freq rejects tf-idf without a grouping", {
  expect_error(term_freq(reviews, text, weight = "tfidf"), "needs a `by`")
})

test_that("topics fits a model when quanteda + stm are available", {
  skip_if_not_installed("quanteda")
  skip_if_not_installed("stm")
  tm <- topics(reviews, text, review_id, k = 3)
  expect_s3_class(tm, "ezrmodel_topics")
  expect_equal(tm$k, 3)
  expect_true(all(c("topic", "term", "beta") %in% names(tm$beta)))
  expect_true(all(c("document", "topic", "gamma") %in% names(tm$gamma)))
  a <- augment(tm)
  expect_true(all(c(".topic", ".gamma") %in% names(a)))
  expect_s3_class(plot(tm), "ggplot")
})

test_that("summarise_text returns top sentences when lexRankr is available", {
  skip_if_not_installed("lexRankr")
  s <- summarise_text(reviews, text, n = 3)
  expect_s3_class(s, "tbl_df")
  expect_lte(nrow(s), 3)
  expect_true(all(c("sentence", "score") %in% names(s)))
})
