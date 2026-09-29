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
  expect_setequal(names(country_region),
                  c("country", "iso2", "iso3", "region", "subregion"))
  expect_gt(nrow(country_region), 150)
  expect_false(any(duplicated(country_region$country)))
})

test_that("every country carries its ISO 3166-1 codes", {
  codes <- country_region[country_region$country %in%
                            c("Germany", "United States", "Japan"), ]
  expect_equal(codes$iso2[order(codes$country)], c("DE", "JP", "US"))
  expect_equal(codes$iso3[order(codes$country)], c("DEU", "JPN", "USA"))
  # Kosovo has no code of its own; everything else does
  expect_equal(country_region$country[is.na(country_region$iso2)], "Kosovo")
  # Namibia's code is the two letters "NA", not a missing value
  expect_identical(country_region$iso2[country_region$country == "Namibia"],
                   "NA")
})

test_that("the misspelled countries were corrected", {
  expect_true(all(c("Isle of Man", "American Samoa", "Kazakhstan", "Bermuda")
                  %in% country_region$country))
  expect_false(any(c("Ise of Man", "America Samoa", "Kazakstan")
                   %in% country_region$country))
  expect_equal(recode_region(c("Isle of Man", "Bermuda")),
               c("Europe", "North America"))
})

test_that("the spellings people actually type resolve", {
  expect_equal(
    recode_region(c("USA", "U.S.", "Usa", "usa", "United States of America")),
    rep("North America", 5)
  )
  expect_equal(recode_region(c("UK", "England", "Scotland", "Great Britain")),
               rep("Europe", 4))
  expect_equal(recode_region(c("Deutschland", "Holland", "Brasil", "Espana")),
               c("Europe", "Europe", "South America", "Europe"))
})

test_that("ISO 3166-1 alpha-2 and alpha-3 codes resolve", {
  expect_equal(recode_region(c("US", "GBR", "DEU", "JPN", "BRA")),
               c("North America", "Europe", "Europe", "Asia", "South America"))
  expect_equal(recode_region(c("FR", "CA", "AU")),
               c("Europe", "North America", "Oceania"))
})

test_that("a code that is also an English word needs its capitals", {
  # "NO" is Norway; "no" is somebody answering a different question
  expect_equal(recode_region("NO"), "Europe")
  expect_true(is.na(recode_region("no", quiet = TRUE)))
  expect_true(is.na(recode_region("it", quiet = TRUE)))
  expect_equal(recode_region("IT"), "Europe")
  # an unambiguous code is read either way
  expect_equal(recode_region(c("Uk", "us")), c("Europe", "North America"))
})

test_that("a leading 'the' and stray punctuation do not matter", {
  expect_equal(recode_region(c("The Netherlands", "U.K.", "U S A")),
               c("Europe", "Europe", "North America"))
})
