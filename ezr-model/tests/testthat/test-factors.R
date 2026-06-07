items_cols <- function() {
  c("value", "quality", "service", "ease", "support", "trust", "price",
    "innovation")
}

test_that("reliability reports alpha and an item table", {
  skip_if_not_installed("psych")
  r <- reliability(nps_drivers,
                   items = c(value, quality, service, ease, support, trust,
                             price, innovation))
  expect_s3_class(r, "ezrmodel_reliability")
  expect_true(r$alpha > 0 && r$alpha <= 1)
  expect_equal(r$n_items, 8L)
  expect_setequal(r$items$item, items_cols())
  expect_output(print(r), "Cronbach")
  expect_s3_class(tidy(r), "tbl_df")
})

test_that("factors runs EFA with a fixed number of factors", {
  skip_if_not_installed("psych")
  f <- factors(nps_drivers,
               vars = c(value, quality, service, ease, support, trust, price,
                        innovation), n = 2)
  expect_s3_class(f, "ezrmodel_factors")
  expect_equal(f$n, 2L)
  expect_equal(nrow(f$variance), 2L)
  expect_true(all(c("variable") %in% names(f$loadings)))
  expect_s3_class(tidy(f), "tbl_df")
  expect_s3_class(plot(f), "ggplot")
})

test_that("factors augment appends factor scores", {
  skip_if_not_installed("psych")
  f <- factors(nps_drivers,
               vars = c(value, quality, service, ease, support, trust, price,
                        innovation), n = 2, scores = TRUE)
  a <- augment(f)
  expect_true(sum(grepl("^\\.", names(a))) >= 2)
})

test_that("factors chooses a factor count when n is NULL", {
  skip_if_not_installed("psych")
  f <- factors(nps_drivers,
               vars = c(value, quality, service, ease, support, trust, price,
                        innovation))
  expect_true(f$n >= 1L)
})

test_that("sem fits a model when lavaan is available", {
  skip_if_not_installed("lavaan")
  model <- "satisfaction =~ quality + value + service + ease +
                            support + trust + price + innovation"
  s <- sem(nps_drivers, model)
  expect_s3_class(s, "ezrmodel_sem")
  expect_true(all(c("measure", "value") %in% names(s$fit_measures)))
  expect_true(all(c("lhs", "op", "rhs", "estimate") %in% names(s$paths)))
  expect_output(print(s), "equation model")
  expect_s3_class(tidy(s), "tbl_df")
})
