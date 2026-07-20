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
  out <- select_prefix(podracing_survey, "demo_", keep = "respondent_id")
  expect_equal(names(out)[1], "respondent_id")
  expect_true(all(grepl("^demo_", names(out)[-1])))
})

test_that("select_suffix keeps id plus suffixed columns", {
  out <- select_suffix(podracing_survey, "_com", keep = "respondent_id")
  expect_equal(names(out)[1], "respondent_id")
  expect_true(all(grepl("_com$", names(out)[-1])))
  expect_setequal(names(out)[-1], c("nps_com", "show_com"))
})

test_that("parse_filename splits metadata and drops the extension", {
  df <- tibble::tibble(file = "podracing_wave1_NA_2026.csv")
  out <- parse_filename(df, into = c("survey", "wave", "locale", "year"))
  expect_equal(out$survey, "podracing")
  expect_equal(out$year, "2026")
  expect_true("file" %in% names(out))       # kept by default
})
