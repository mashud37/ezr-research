test_that("generation_scheme returns ordered bands", {
  s <- generation_scheme("pew")
  expect_true(all(c("label", "from", "to") %in% names(s)))
  expect_equal(s$label[s$from == 1981], "Millennial")
})

test_that("recode_generation maps birth years to cohorts", {
  out <- recode_generation(c(1935, 1950, 1968, 1990, 2001, 2015),
                           input = "year")
  expect_equal(out, c("Silent", "Baby Boomer", "Gen X", "Millennial",
                      "Gen Z", "Gen Alpha"))
  expect_true(is.na(recode_generation(1900, input = "year")))
})

test_that("recode_generation maps ages using a reference year", {
  # born 1990 / 2001 at reference year 2026
  out <- recode_generation(c(36, 25), input = "age", year = 2026)
  expect_equal(out, c("Millennial", "Gen Z"))
})

test_that("recode_generation salvages text and respects current_year option", {
  withr::defer(reset_ezrsurvey_options())
  ezrsurvey_options(current_year = 2026)
  expect_equal(recode_generation(c("36 years")), "Millennial")
})

test_that("recode_generation accepts a custom scheme", {
  sch <- tibble::tibble(label = c("Young", "Old"), from = c(2000, 1900))
  expect_equal(recode_generation(c(2005, 1950), input = "year", scheme = sch),
               c("Young", "Old"))
})
