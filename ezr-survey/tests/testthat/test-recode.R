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
  expect_equal(as.character(out), c("<18", "18-24", "18-24", "25+", "25+"))
  expect_error(bin_numeric(1, breaks = c(0, 1, 2), labels = "one"))
})

test_that("bin_numeric keeps its bands in order, not alphabetical", {
  out <- bin_numeric(c(45, 120, 60),
                     breaks = c(40, 70, 100, 150),
                     labels = c("40-70k", "70-100k", "100-150k"))
  expect_s3_class(out, "factor")
  expect_equal(levels(out), c("40-70k", "70-100k", "100-150k"))
  pct <- calc_percentage(data.frame(band = out), band)
  expect_equal(as.character(pct$band), c("40-70k", "100-150k"))
})

test_that("recode_age extracts digits and bands", {
  expect_equal(as.character(recode_age(c("17", "22 years", "31", "47"))),
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

test_that("recode_likert prefers the longest matching level", {
  # "Good" nests inside "Very good": an answer the exact pass misses (here an
  # emoji prefix) must still resolve to the level it names, not the shorter one.
  expect_equal(recode_likert(c("\U0001F642 Very good", "\U0001F610 Good")),
               c(5L, 4L))

  likeability <- c("Very unlikeable", "Unlikeable", "Likeable", "Very likeable")
  expect_equal(
    recode_likert(paste("*", likeability), levels = likeability),
    c(1L, 2L, 3L, 4L)
  )

  likelihood <- c("Very unlikely", "Unlikely", "Likely", "Very likely")
  expect_equal(
    recode_likert(paste("*", likelihood), levels = likelihood),
    c(1L, 2L, 3L, 4L)
  )

  # nested synonyms follow the same longest-first rule
  expect_equal(
    recode_likert(c("* Satisfied", "* Very satisfied"),
                  synonyms = list(Good = "Satisfied",
                                  "Very good" = "Very satisfied")),
    c(4L, 5L)
  )
})

test_that("nps_group classifies 0-10 into groups", {
  expect_equal(nps_group(c(0, 6, 7, 8, 9, 10)), c(-1L, -1L, 0L, 0L, 1L, 1L))
  expect_equal(nps_group(c(3, 8, 10), labels = TRUE),
               c("Detractor", "Passive", "Promoter"))
  expect_true(is.na(nps_group(11)))
})

test_that("drop_items turns matched values into NA (case-insensitive)", {
  expect_equal(drop_items(c("Yes", "No", "Other", "Don't know"),
                          c("other", "Don't know")),
               c("Yes", "No", NA, NA))
  expect_equal(drop_items(c(" a ", "b"), "a"), c(NA, "b"))   # trims
  expect_identical(drop_items(c("a", "b"), character(0)), c("a", "b"))
  expect_identical(drop_items(c("a", "b"), NULL), c("a", "b"))
})

test_that("split_multi widens a packed column, most-chosen first", {
  packed <- tibble::tibble(
    respondent = 1:4,
    motivations = c("Speed; Drivers", "Speed", "", "Betting; Speed")
  )
  out <- split_multi(packed, motivations)
  expect_equal(names(out), c("respondent", "motivations", "motivations_Speed",
                             "motivations_Betting", "motivations_Drivers"))
  expect_equal(out$motivations_Speed, c("Speed", "Speed", "", "Speed"))
  expect_equal(out$motivations_Drivers, c("Drivers", "", "", ""))
})

test_that("split_multi honours an explicit delimiter and prefix", {
  packed <- tibble::tibble(x = c("a/b", "b"))
  out <- split_multi(packed, x, split = "/", prefix = "pick_")
  expect_equal(names(out), c("x", "pick_b", "pick_a"))
})

test_that("split_multi output reproduces the packed percentages", {
  packed <- tibble::tibble(
    respondent = 1:4,
    motivations = c("Speed; Drivers", "Speed", "", "Betting; Speed")
  )
  direct <- calc_percentage_multi(packed, "motivations", id = respondent,
                                 sort = "desc")
  widened <- packed %>%
    split_multi(motivations) %>%
    calc_percentage_multi("motivations_", id = respondent, sort = "desc")
  expect_equal(as.character(widened$option), as.character(direct$option))
  expect_equal(widened$pct, direct$pct)
})

test_that("split_multi treats an undelimited column as one answer each", {
  out <- split_multi(tibble::tibble(x = c("a", "b", "a")), x)
  expect_equal(out$x_a, c("a", "", "a"))
  expect_error(split_multi(tibble::tibble(x = c("", "")), x))
})

test_that("detect_delimiter prefers a semicolon over a comma", {
  expect_equal(detect_delimiter(c("a, b; c", "d")), ";")
  expect_equal(detect_delimiter(c("a, b", "c")), ",")
  expect_equal(detect_delimiter(c("a|b", "c")), "|")
  expect_null(detect_delimiter(c("a", "b", "")))
})

test_that("recode_age reports answers that held no number", {
  expect_message(recode_age(c("young", "old", "31")), "held no number")
  expect_silent(recode_age(c("young", "31"), quiet = TRUE))
  expect_true(is.na(recode_age(c("young", "31"), quiet = TRUE)[[1]]))
})
