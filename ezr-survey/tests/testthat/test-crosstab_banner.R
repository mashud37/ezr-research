test_that("crosstab_banner returns a wide master table with Overall first", {
  b <- crosstab_banner(podracing_survey, rows = satis_return, cols = region)
  expect_s3_class(b, "tbl_df")
  expect_equal(names(b)[1:3], c("variable", "item", "Overall"))
  expect_true(all(b$variable == "satis_return"))
})

test_that("each banner column sums to ~100 within a categorical block", {
  b <- crosstab_banner(podracing_survey, rows = satis_return, cols = region)
  num <- b[setdiff(names(b), c("variable", "item"))]
  expect_true(all(abs(colSums(num, na.rm = TRUE) - 100) <= 2))
})

test_that("empty categorical cells are 0, not NA", {
  b <- crosstab_banner(podracing_survey, rows = demo_gender, cols = region,
                       cell = "count")
  num <- b[setdiff(names(b), c("variable", "item"))]
  expect_false(anyNA(num))
})

test_that("numeric questions become a statistics block", {
  b <- crosstab_banner(podracing_survey, rows = nps_value, cols = demo_gender)
  expect_setequal(b$item, c("mean", "median", "sd", "p25", "p75"))
  expect_true(all(b$Overall >= 0 & b$Overall <= 10))
})

test_that("stats argument selects which statistics appear", {
  b <- crosstab_banner(podracing_survey, rows = nps_value, cols = demo_gender,
                       stats = c("mean", "sd"))
  expect_setequal(b$item, c("mean", "sd"))
})

test_that("rows may mix categorical and numeric questions", {
  b <- crosstab_banner(podracing_survey, rows = c(satis_return, nps_value),
                       cols = region)
  expect_setequal(unique(b$variable), c("satis_return", "nps_value"))
})

test_that("cell = 'diff' keeps Overall and shows point differences", {
  raw <- crosstab_banner(podracing_survey, rows = satis_return, cols = region)
  d <- crosstab_banner(podracing_survey, rows = satis_return, cols = region,
                       cell = "diff")
  expect_equal(d$Overall, raw$Overall)
  expect_equal(d$Asia, raw$Asia - raw$Overall)
})

test_that("long = TRUE returns the tidy five-column form", {
  lb <- crosstab_banner(podracing_survey, rows = satis_return, cols = region,
                        long = TRUE)
  expect_setequal(names(lb),
                  c("variable", "item", "group", "group_item", "value"))
  expect_true("Overall" %in% lb$group)
})

test_that("total = FALSE drops the Overall column", {
  b <- crosstab_banner(podracing_survey, rows = satis_return, cols = region,
                       total = FALSE)
  expect_false("Overall" %in% names(b))
})

test_that("a variable is never crossed with itself", {
  lb <- crosstab_banner(podracing_survey, rows = demo_gender,
                        cols = c(demo_gender, region), long = TRUE)
  expect_false("demo_gender" %in% lb$group)
})

test_that("weighting runs and stays a tibble", {
  b <- crosstab_banner(
    podracing_survey, rows = satis_return, cols = demo_gender,
    weights = c(variable = "demo_gender", Male = 0.49, Female = 0.50,
                "Non-binary" = 0.01)
  )
  expect_s3_class(b, "tbl_df")
})

test_that("flextable = TRUE renders a two-row banner header", {
  skip_if_not_installed("flextable")
  ft <- crosstab_banner(podracing_survey, rows = satis_return,
                        cols = c(demo_gender, region), flextable = TRUE)
  expect_s3_class(ft, "flextable")
  expect_equal(flextable::nrow_part(ft, "header"), 2)
})

test_that("banner spanners record each column's grouping variable", {
  b <- crosstab_banner(podracing_survey, rows = satis_return,
                       cols = c(demo_gender, region))
  sp <- attr(b, "banner_spanners")
  expect_true(all(c("col", "group", "label") %in% names(sp)))
  expect_true(all(c("Overall", "demo_gender", "region") %in% sp$group))
})

test_that("data only crosses every eligible variable and skips id / free-text", {
  b <- suppressMessages(crosstab_banner(podracing_survey))
  expect_s3_class(b, "tbl_df")
  expect_equal(names(b)[1:3], c("variable", "item", "Overall"))
  expect_false("respondent_id" %in% b$variable)
  expect_false("nps_com" %in% b$variable)
  sp <- attr(b, "banner_spanners")
  expect_false("respondent_id" %in% sp$group)
  expect_true(ncol(b) > 10)
})

test_that("one side may be auto while the other is named", {
  b <- suppressMessages(crosstab_banner(podracing_survey, rows = satis_return))
  expect_setequal(unique(b$variable), "satis_return")
  expect_true(ncol(b) > 3)
})

test_that("max_levels bounds which categorical variables are auto-selected", {
  b <- suppressMessages(crosstab_banner(podracing_survey, max_levels = 5))
  sp <- attr(b, "banner_spanners")
  expect_false("demo_edu" %in% sp$group)   # 7 levels, above the cap
  expect_true("demo_gender" %in% sp$group)  # 3 levels, within the cap
})

test_that("a multi-select block is one stub question with a question-level base", {
  b <- crosstab_banner(podracing_survey, rows = starts_with("motivations_"),
                       cols = region)
  expect_setequal(unique(b$variable), "motivations")
  expect_gt(nrow(b), 1)
  expect_true(all(b$Overall >= 0 & b$Overall <= 100))
})

test_that("auto banner folds motivations_ into one multi-select stub", {
  b <- suppressMessages(crosstab_banner(podracing_survey))
  expect_true("motivations" %in% b$variable)
  expect_false("motivations_speed" %in% b$variable)
})

test_that("mean on a categorical question errors clearly", {
  expect_error(
    crosstab_banner(podracing_survey, rows = demo_gender, cols = region,
                    cell = "mean"),
    "numeric"
  )
})

test_that("a checkpointed banner resumes and matches an uninterrupted run", {
  d <- podracing_survey[, c("satis_return", "demo_gender", "region")]
  want <- crosstab_banner(d)

  ck <- withr::local_tempfile(fileext = ".rds")
  original <- ezrsurvey:::banner_block_cat
  calls <- 0
  # Stop part-way through, the way a real interruption would.
  local_mocked_bindings(
    banner_block_cat = function(...) {
      calls <<- calls + 1
      if (calls == 2) stop("interrupted")
      original(...)
    }
  )
  expect_error(crosstab_banner(d, checkpoint = ck), "interrupted")
  expect_true(file.exists(ck))
  expect_length(readRDS(ck)$finished, 1)

  # Re-running the identical call picks up where it stopped.
  got <- crosstab_banner(d, checkpoint = ck)
  expect_equal(got, want)
})

test_that("a checkpoint from different data is discarded, not reused", {
  d <- podracing_survey[, c("satis_return", "demo_gender")]
  ck <- withr::local_tempfile(fileext = ".rds")
  crosstab_banner(d, checkpoint = ck)

  d2 <- d
  d2$satis_return[1:100] <- "Very likely"
  expect_equal(crosstab_banner(d2, checkpoint = ck), crosstab_banner(d2))
})

test_that("a corrupt checkpoint does not stop the run", {
  d <- podracing_survey[, c("satis_return", "demo_gender")]
  ck <- withr::local_tempfile(fileext = ".rds")
  writeLines("not an rds file", ck)
  expect_equal(crosstab_banner(d, checkpoint = ck), crosstab_banner(d))
})

test_that("checkpoint accepts TRUE and rejects nonsense", {
  d <- podracing_survey[1:80, c("satis_return", "demo_gender", "region")]
  fp <- banner_fingerprint(d, "a", "b", "pct", NULL, TRUE, TRUE, NULL, 0)

  expect_null(banner_checkpoint_path(NULL, fp))
  expect_null(banner_checkpoint_path(FALSE, fp))
  expect_equal(banner_checkpoint_path("my.rds", fp), "my.rds")

  managed <- banner_checkpoint_path(TRUE, fp)
  expect_true(startsWith(basename(managed), "banner-"))
  # the name carries the fingerprint, so a different run cannot collide with it
  other <- banner_checkpoint_path(TRUE, banner_fingerprint(d, "z", "b", "pct",
                                                           NULL, TRUE, TRUE,
                                                           NULL, 0))
  expect_false(identical(managed, other))

  expect_error(banner_checkpoint_path(1, fp), "must be TRUE, FALSE")
})

test_that("confirmation is off in scripts and validates its argument", {
  expect_false(confirm_on("auto"))
  expect_true(confirm_on(TRUE))
  expect_false(confirm_on(FALSE))
  expect_error(confirm_on("yes"), "must be TRUE, FALSE")

  # with no prompt to show, the run simply goes ahead
  expect_true(confirm_selection("title", "line", setting = FALSE))

  expect_equal(confirm_lines("Skipped", character(0)), "Skipped: none")
  expect_match(confirm_lines("Questions", c("a", "b"))[[1]],
               "Questions (2): a, b", fixed = TRUE)

  # even forced on, readline() cannot block a script: it reads an empty answer,
  # which is a yes
  d <- podracing_survey[1:80, c("satis_return", "demo_gender", "region")]
  expect_s3_class(suppressMessages(crosstab_banner(d, confirm = TRUE)),
                  "data.frame")
})

test_that("declining the selection computes nothing", {
  d <- podracing_survey[1:80, c("satis_return", "demo_gender", "region")]
  out <- testthat::with_mocked_bindings(
    suppressMessages(crosstab_banner(d, confirm = TRUE)),
    readline = function(...) "n", .package = "base")
  expect_null(out)

  # a named selection is the user's own choice, so it is never questioned
  named <- testthat::with_mocked_bindings(
    crosstab_banner(d, rows = satis_return, cols = demo_gender,
                    confirm = TRUE),
    readline = function(...) "n", .package = "base")
  expect_s3_class(named, "data.frame")
})
