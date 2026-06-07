test_that("model_frame keeps target + numeric predictors, drops text/id", {
  mf <- model_frame(nps_drivers, nps)
  expect_true("nps" %in% names(mf))
  expect_false("respondent_id" %in% names(mf))   # text id dropped
  expect_false("region" %in% names(mf))           # categorical dropped
  expect_true(all(vapply(mf, is.numeric, logical(1))))
  expect_equal(sum(stats::complete.cases(mf)), nrow(mf))
})

test_that("model_frame accepts explicit predictors and coerces text", {
  df <- tibble::tibble(y = 1:5, a = c("1", "2", "3", "4", "5"), b = 6:10)
  mf <- model_frame(df, y, c(a, b))
  expect_equal(mf$a, as.numeric(1:5))
})

test_that("to_matrix returns a numeric matrix with id rownames", {
  m <- to_matrix(ecommerce, c(recency_days, frequency, monetary),
                 id = customer_id)
  expect_true(is.matrix(m))
  expect_equal(dim(m), c(800L, 3L))
  expect_equal(rownames(m)[1], ecommerce$customer_id[1])
})

test_that("presence_matrix builds a 0/1 wide table", {
  df <- tibble::tibble(id = c("a", "b", "c"), tags = c("x,y", "y,z", "x,z,w"))
  pm <- presence_matrix(df, id, tags)
  expect_true(all(c("x", "y", "z", "w") %in% names(pm)))
  expect_true(all(unlist(pm[setdiff(names(pm), "id")]) %in% c(0L, 1L)))
  # min_count drops the rare 'w'
  pm2 <- presence_matrix(df, id, tags, min_count = 2)
  expect_false("w" %in% names(pm2))
})
