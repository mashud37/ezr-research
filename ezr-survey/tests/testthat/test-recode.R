test_that("na_blank converts blanks and non-answers", {
  expect_equal(
    na_blank(c("Yes", "", "Prefer not to answer", "No")),
    c("Yes", NA, NA, "No")
  )
  expect_equal(na_blank(c("a", "n/a"), also = "n/a"), c("a", NA))
  expect_equal(na_blank(c(" x ")), "x")
})

test_that("bin_numeric assigns left-closed bands", {
  out <- bin_numeric(c(15, 18, 24, 25, 41),
                     breaks = c(0, 18, 25, Inf),
                     labels = c("<18", "18-24", "25+"))
  expect_equal(out, c("<18", "18-24", "18-24", "25+", "25+"))
  expect_error(bin_numeric(1, breaks = c(0, 1, 2), labels = "one"))
})

test_that("recode_age extracts digits and bands", {
  expect_equal(recode_age(c("17", "22 years", "31", "47")),
               c("17 or younger", "22 to 25", "30 to 34", "35+"))
})

test_that("recode_likert maps wordings and synonyms to integers", {
  expect_equal(recode_likert(c("Very bad", "Ok", "Good", "Very good")),
               c(1L, 3L, 4L, 5L))
  expect_true(is.na(recode_likert("not on the scale")))
  expect_equal(
    recode_likert(c("Dissatisfied", "Satisfied"),
                  synonyms = list(Bad = "Dissatisfied", Good = "Satisfied")),
    c(2L, 4L)
  )
  # substring fallback handles "4 - Good" style prefixes
  expect_equal(recode_likert("4 - Good"), 4L)
})

test_that("nps_group classifies 0-10 into groups", {
  expect_equal(nps_group(c(0, 6, 7, 8, 9, 10)), c(-1L, -1L, 0L, 0L, 1L, 1L))
  expect_equal(nps_group(c(3, 8, 10), labels = TRUE),
               c("Detractor", "Passive", "Promoter"))
  expect_true(is.na(nps_group(11)))
})
