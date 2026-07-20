test_that("cluster (kmeans) returns assignments, profile, diagnostics", {
  cl <- cluster(ecommerce, k = 4,
                vars = c(recency_days, frequency, monetary, tenure_months))
  expect_s3_class(cl, "ezrmodel_clusters")
  expect_equal(nrow(cl$sizes), 4L)
  expect_equal(sum(cl$sizes$n), sum(cl$ok))
  expect_true(all(c("cluster") %in% names(cl$profile)))
  expect_true(is.finite(cl$diagnostics$within_ss_ratio))
})

test_that("augment appends a .cluster factor", {
  cl <- cluster(ecommerce, k = 3, vars = c(recency_days, frequency, monetary))
  a <- augment(cl)
  expect_true(".cluster" %in% names(a))
  expect_s3_class(a$.cluster, "factor")
  expect_equal(nrow(a), sum(cl$ok))
})

test_that("hclust and pam methods work", {
  skip_if_not_installed("cluster")
  ch <- cluster(ecommerce, k = 3, method = "hclust",
                vars = c(recency_days, frequency, monetary))
  expect_equal(nrow(ch$sizes), 3L)
  cp <- cluster(ecommerce, k = 3, method = "pam",
                vars = c(recency_days, frequency, monetary))
  expect_equal(nrow(cp$sizes), 3L)
})

test_that("cluster_profile crosses clusters against a variable", {
  cl <- cluster(ecommerce, k = 3, vars = c(recency_days, frequency, monetary))
  cpf <- cluster_profile(cl, region)
  expect_true("region" %in% names(cpf))
  expect_gt(ncol(cpf), 1)
})

test_that("cluster print and plot work", {
  cl <- cluster(ecommerce, k = 3, vars = c(recency_days, frequency, monetary))
  expect_output(print(cl), "clustering  k = 3")
  expect_s3_class(plot(cl), "ggplot")
})

test_that("personas clusters cleanly: silhouette, recovered k, ground truth", {
  skip_if_not_installed("cluster")
  cl <- cluster(personas, vars = spend_index:browse_minutes)
  expect_equal(cl$k, 5L)                                # silhouette finds true k
  expect_gt(cl$diagnostics$avg_silhouette, 0.5)        # strong structure

  # every method agrees at k = 5
  for (m in c("kmeans", "hclust", "pam")) {
    cm <- cluster(personas, k = 5, method = m,
                  vars = spend_index:browse_minutes)
    expect_gt(cm$diagnostics$avg_silhouette, 0.5)
  }

  # recovered clusters line up with the ground-truth personas
  cp <- cluster_profile(cl, persona)
  shares <- apply(as.matrix(cp[, setdiff(names(cp), "persona")]), 1, max)
  expect_true(all(shares > 80))
})
