test_that("reduce_dims (PCA) returns scores, loadings and variance", {
  r <- reduce_dims(ecommerce, vars = c(recency_days, frequency, monetary,
                                       tenure_months, returns))
  expect_s3_class(r, "ezrmodel_reduction")
  expect_equal(nrow(r$variance), 5L)
  expect_equal(r$variance$cumulative[5], 1, tolerance = 1e-6)
  expect_true(all(c("variable") %in% names(r$loadings)))
})

test_that("augment appends component scores", {
  r <- reduce_dims(ecommerce, n = 2,
                   vars = c(recency_days, frequency, monetary))
  a <- augment(r)
  expect_true(all(c(".PC1", ".PC2") %in% names(a)))
})

test_that("reduce print, tidy and plot work", {
  r <- reduce_dims(ecommerce, vars = c(recency_days, frequency, monetary))
  expect_output(print(r), "PCA of")
  expect_s3_class(tidy(r), "tbl_df")
  expect_s3_class(plot(r), "ggplot")
})

test_that("UMAP returns a 2-D embedding", {
  skip_if_not_installed("uwot")
  r <- reduce_dims(ecommerce, method = "umap",
                   vars = c(recency_days, frequency, monetary, tenure_months))
  expect_equal(r$method, "umap")
  expect_equal(ncol(r$scores), 2L)
  expect_true(all(c("UMAP1", "UMAP2") %in% names(r$scores)))
  expect_true(all(c(".UMAP1", ".UMAP2") %in% names(augment(r))))
  expect_output(print(r), "UMAP embedding")
  expect_s3_class(plot(r), "ggplot")
})

test_that("t-SNE returns an embedding of the requested dimension", {
  skip_if_not_installed("Rtsne")
  r <- reduce_dims(ecommerce, method = "tsne", n = 2,
                   vars = c(recency_days, frequency, monetary, tenure_months))
  expect_equal(r$method, "tsne")
  expect_equal(ncol(r$scores), 2L)
  expect_true(all(c("tSNE1", "tSNE2") %in% names(r$scores)))
  expect_s3_class(tidy(r), "tbl_df")
})
