test_that("register / get / list / remove orders", {
  withr::defer(remove_order("edu_t"))
  register_order("edu_t", c("low", "mid", "high"), vars = "demo_edu",
                 prefixes = "edu_")
  expect_equal(get_order("edu_t"), c("low", "mid", "high"))
  lo <- list_orders()
  expect_true("edu_t" %in% lo$name)
  expect_equal(lo$n_levels[lo$name == "edu_t"], 3L)

  remove_order("edu_t")
  expect_false("edu_t" %in% list_orders()$name)
  expect_error(get_order("edu_t"))
})

test_that("order_for matches by exact var then prefix", {
  withr::defer({remove_order("a"); remove_order("b")})
  register_order("a", c("x", "y"), vars = "demo_edu")
  register_order("b", c("p", "q"), prefixes = "rate_")
  expect_equal(order_for("demo_edu"), c("x", "y"))   # exact wins
  expect_equal(order_for("rate_quality"), c("p", "q"))
  expect_null(order_for("unmatched_col"))
})

test_that("apply_order works by name and by var", {
  withr::defer(remove_order("size"))
  register_order("size", c("S", "M", "L"), vars = "tshirt")
  expect_equal(levels(apply_order(c("L", "S"), name = "size")), c("S", "M", "L"))
  expect_equal(levels(apply_order(c("M"), var = "tshirt")), c("S", "M", "L"))
  expect_identical(apply_order(c("a", "b"), var = "nope"), c("a", "b"))
})

test_that("calc_percentage applies a registered order automatically", {
  withr::defer(remove_order("edu_order"))
  register_order(
    "edu_order",
    levels = c("Primary or less", "Lower secondary", "Upper secondary",
               "Short-cycle tertiary", "Bachelor or equivalent",
               "Master or equivalent", "Doctoral or equivalent"),
    vars = "demo_edu"
  )
  out <- calc_percentage(podracing_survey, demo_edu)
  expect_s3_class(out$demo_edu, "factor")
  expect_equal(levels(out$demo_edu)[1], "Primary or less")
  # an explicit sort still overrides the registered order
  out2 <- calc_percentage(podracing_survey, demo_edu, sort = "desc")
  expect_equal(out2$pct, sort(out2$pct, decreasing = TRUE))
})

test_that("register_order_presets registers the expected names", {
  withr::defer(for (n in c("likert_bad_good", "likert_agree", "frequency",
                           "likelihood", "education_isced")) remove_order(n))
  register_order_presets()
  expect_true(all(c("likert_bad_good", "education_isced") %in% list_orders()$name))
})

test_that("orders round-trip through a YAML profile", {
  skip_if_not_installed("yaml")
  withr::defer(remove_order("rt"))
  register_order("rt", c("one", "two"), vars = "x")

  dir <- withr::local_tempdir()
  path <- file.path(dir, "p.yml")
  save_ezrsurvey_profile(path)
  remove_order("rt")
  expect_null(order_for("x"))

  load_ezrsurvey_profile(path)
  expect_equal(order_for("x"), c("one", "two"))
})

test_that("a registered order reaches the rows, not only the levels", {
  # A recency scale whose alphabetical order is nothing like its real one, so
  # a table left in count order is visibly wrong.
  answers <- c(rep("In the past week", 3), rep("In the past month", 5),
               rep("In the past year", 4), rep("Never", 2))
  d <- data.frame(seen = answers, arm = rep(c("a", "b"), length.out = 14),
                  stringsAsFactors = FALSE)
  register_order("seen_order",
                 levels = c("In the past week", "In the past month",
                            "In the past year", "Never"),
                 vars = "seen")
  on.exit(remove_order("seen_order"), add = TRUE)

  out <- calc_percentage(d, seen)
  expect_equal(as.character(out$seen), get_order("seen_order"))

  # A breakdown keeps its groups together and orders inside each one.
  grouped <- calc_percentage(d, seen, by = arm)
  expect_equal(as.character(grouped$arm), rep(c("a", "b"), each = 4))
  expect_equal(as.character(grouped$seen[grouped$arm == "a"]),
               get_order("seen_order"))
})

test_that("a registered order reaches both margins of a crosstab", {
  d <- data.frame(
    seen = rep(c("In the past week", "In the past month", "Never"), each = 4),
    band = rep(c("Under 18", "18-24"), 6),
    stringsAsFactors = FALSE
  )
  register_order("seen_order",
                 levels = c("In the past week", "In the past month", "Never"),
                 vars = "seen")
  register_order("band_order", levels = c("Under 18", "18-24"), vars = "band")
  on.exit({
    remove_order("seen_order")
    remove_order("band_order")
  }, add = TRUE)

  wide <- crosstab(d, seen, band, cell = "col_pct")
  expect_equal(as.character(wide$seen), get_order("seen_order"))
  # "Under 18" sorts after "18-24" as text, so the column order is the test.
  expect_equal(names(wide)[-1], get_order("band_order"))

  # An unregistered margin keeps the order it already had.
  remove_order("band_order")
  expect_equal(as.character(crosstab(d, seen, band, cell = "count")$seen),
               get_order("seen_order"))
})
