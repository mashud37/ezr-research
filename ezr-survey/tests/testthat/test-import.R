test_that("read_folder stacks CSVs and tags the source file", {
  dir <- withr::local_tempdir()
  readr::write_csv(tibble::tibble(id = 1:2, x = c("a", "b")),
                   file.path(dir, "one.csv"))
  readr::write_csv(tibble::tibble(id = 3:4, x = c("c", "d")),
                   file.path(dir, "two.csv"))

  out <- read_folder(dir)
  expect_equal(nrow(out), 4)
  expect_true("file" %in% names(out))
  expect_setequal(unique(out$file), c("one.csv", "two.csv"))
  expect_type(out$id, "character")          # all_character default
})

test_that("read_folder errors helpfully", {
  expect_error(read_folder(file.path(tempdir(), "does-not-exist")))
})

test_that("select_prefix keeps id plus prefixed columns", {
  out <- select_prefix(consumer_survey, "demo_", keep = "respondent_id")
  expect_equal(names(out)[1], "respondent_id")
  expect_true(all(grepl("^demo_", names(out)[-1])))
})

test_that("parse_filename splits metadata and drops the extension", {
  df <- tibble::tibble(file = "viewer_CDL_acme_NA_2026.csv")
  out <- parse_filename(df, into = c("type", "game", "brand", "locale", "year"))
  expect_equal(out$type, "viewer")
  expect_equal(out$year, "2026")
  expect_true("file" %in% names(out))       # kept by default
})
