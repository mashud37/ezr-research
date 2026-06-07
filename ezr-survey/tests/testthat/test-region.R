test_that("recode_region maps countries to regions", {
  expect_equal(recode_region(c("Germany", "Japan", "Brazil")),
               c("Europe", "Asia", "South America"))
  expect_equal(recode_region("United States"), "North America")
})

test_that("recode_region is case- and whitespace-insensitive", {
  expect_equal(recode_region(c("  germany ", "JAPAN")),
               c("Europe", "Asia"))
})

test_that("recode_subregion returns the finer level", {
  expect_equal(recode_subregion("Germany"), "Western Europe")
  expect_equal(recode_subregion("Japan"), "East Asia")
})

test_that("non-answers and unmatched become NA (with a warning)", {
  expect_true(is.na(recode_region("Prefer not to answer", quiet = TRUE)))
  expect_true(is.na(recode_region("", quiet = TRUE)))
  expect_warning(recode_region(c("Germany", "Atlantis")))
  expect_silent(recode_region(c("Germany", "Atlantis"), quiet = TRUE))
})

test_that("add_region appends region and optionally subregion", {
  df <- tibble::tibble(demo_country = c("Germany", "Japan", "Brazil"))
  out <- add_region(df, demo_country, subregion = TRUE)
  expect_equal(out$region, c("Europe", "Asia", "South America"))
  expect_true("subregion" %in% names(out))
  expect_error(add_region(df, not_a_column))
})

test_that("country_region data ships with the expected shape", {
  expect_s3_class(country_region, "tbl_df")
  expect_setequal(names(country_region), c("country", "region", "subregion"))
  expect_gt(nrow(country_region), 150)
})
