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
    levels = c("Less than high school", "High school or equivalent",
               "Some college but no degree", "Associate degree",
               "Bachelor degree", "Masters degree or higher"),
    vars = "demo_edu"
  )
  out <- calc_percentage(consumer_survey, demo_edu)
  expect_s3_class(out$demo_edu, "factor")
  expect_equal(levels(out$demo_edu)[1], "Less than high school")
  # an explicit sort still overrides the registered order
  out2 <- calc_percentage(consumer_survey, demo_edu, sort = "desc")
  expect_equal(out2$pct, sort(out2$pct, decreasing = TRUE))
})

test_that("register_order_presets registers the expected names", {
  withr::defer(for (n in c("likert_bad_good", "likert_agree", "frequency",
                           "likelihood", "education_us")) remove_order(n))
  register_order_presets()
  expect_true(all(c("likert_bad_good", "education_us") %in% list_orders()$name))
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
