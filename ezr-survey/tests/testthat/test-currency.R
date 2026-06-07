test_that("convert_currency uses the USD base correctly", {
  # 100 USD -> EUR at 0.92 per USD
  expect_equal(convert_currency(100, "USD", "EUR"), 92)
  # round trip
  expect_equal(convert_currency(convert_currency(100, "USD", "EUR"),
                                "EUR", "USD"), 100)
  # same currency is identity
  expect_equal(convert_currency(250, "GBP", "GBP"), 250)
})

test_that("convert_currency is vectorised and case-insensitive", {
  out <- convert_currency(c(100, 100), from = c("eur", "gbp"), to = "USD")
  expect_equal(round(out), c(109, 127))
})

test_that("convert_currency salvages text amounts", {
  expect_equal(convert_currency("$100", "USD", "EUR"), 92)
})

test_that("unknown currencies warn and return NA", {
  expect_warning(res <- convert_currency(100, "ZZZ", "USD"))
  expect_true(is.na(res))
})

test_that("custom rates override the snapshot", {
  out <- convert_currency(100, "EUR", "USD", rates = c(USD = 1, EUR = 0.5))
  expect_equal(out, 200)
})

test_that("add_currency works with a per-row column and a constant", {
  df <- tibble::tibble(spend = c(100, 200, 50),
                       currency = c("EUR", "GBP", "JPY"))
  out <- add_currency(df, spend, from = currency, to = "USD")
  expect_true("spend_usd" %in% names(out))
  expect_equal(round(out$spend_usd), c(109, 253, 0))   # 50 JPY ~ 0.33 USD -> 0

  out2 <- add_currency(df, spend, from = "EUR", to = "USD", into = "usd")
  expect_equal(round(out2$usd[1]), 109)
})

test_that("cross-rates convert via the USD base", {
  # 100 EUR -> USD (/.92) -> CNY (*7.2)
  expect_equal(convert_currency(100, "EUR", "CNY"), 100 / 0.92 * 7.2)
})

test_that("currency aliases resolve to ISO codes", {
  expect_equal(convert_currency(100, "EUR", "RMB"),
               convert_currency(100, "EUR", "CNY"))
  expect_equal(normalize_currency(c("rmb", "yen", "USD")),
               c("CNY", "JPY", "USD"))
})

test_that("list_currencies returns codes including majors", {
  cc <- list_currencies()
  expect_true(all(c("USD", "EUR", "GBP", "JPY") %in% cc))
})
