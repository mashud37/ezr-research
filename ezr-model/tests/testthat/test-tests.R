test_that("test_groups one-sample vs mu", {
  tg <- test_groups(nps_drivers, nps, region, mu = 6)
  expect_s3_class(tg, "ezrmodel_tests")
  expect_setequal(tidy(tg)$group, unique(nps_drivers$region))
  expect_true(all(c("estimate", "p_value", "signif") %in% names(tidy(tg))))
})

test_that("test_groups two-sample vs reference excludes the ref", {
  tg <- test_groups(nps_drivers, nps, region, ref = "Europe")
  expect_false("Europe" %in% tidy(tg)$group)
})

test_that("test_groups validates and supports wilcox", {
  expect_error(test_groups(nps_drivers, nps, region, ref = "Nowhere"))
  tg <- test_groups(nps_drivers, nps, region, mu = 6, method = "wilcox")
  expect_equal(tg$method, "wilcox")
})

test_that("tests print and plot work", {
  tg <- test_groups(nps_drivers, nps, region, mu = 6)
  expect_output(print(tg), "Tests of 'nps'")
  expect_s3_class(plot(tg), "ggplot")
})
