test_that("correlations returns a matrix and a target ranking", {
  cc <- correlations(nps_drivers, nps)
  expect_s3_class(cc, "ezrmodel_cor")
  expect_true(is.matrix(cc$matrix))
  expect_true(all(c("variable", "correlation") %in% names(cc$target_cor)))
  # sorted by absolute correlation
  expect_equal(abs(cc$target_cor$correlation),
               sort(abs(cc$target_cor$correlation), decreasing = TRUE))
})

test_that("correlations without a target gives the full matrix", {
  cc <- correlations(nps_drivers, select = c(value, quality, service))
  expect_null(cc$target_cor)
  expect_equal(dim(cc$matrix), c(3L, 3L))
  expect_s3_class(tidy(cc), "tbl_df")
})

test_that("correlations print and plot work", {
  cc <- correlations(nps_drivers, nps)
  expect_output(print(cc), "Correlations with 'nps'")
  expect_s3_class(plot(cc), "ggplot")
})
