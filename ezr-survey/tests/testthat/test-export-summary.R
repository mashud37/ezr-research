test_that("export_summary_xlsx writes one sheet per variable", {
  skip_if_not_installed("openxlsx2")
  dir <- withr::local_tempdir()
  p <- file.path(dir, "s.xlsx")
  out <- export_summary_xlsx(podracing_survey, demo_gender, satis_return,
                             nps_value, path = p)
  expect_equal(out, p)
  expect_true(file.exists(p))
  wb <- openxlsx2::wb_load(p)
  expect_setequal(openxlsx2::wb_get_sheet_names(wb),
                  c("demo_gender", "satis_return", "nps_value"))
})

test_that("export_summary_xlsx works without charts and with tidyselect", {
  skip_if_not_installed("openxlsx2")
  dir <- withr::local_tempdir()
  p <- file.path(dir, "r.xlsx")
  export_summary_xlsx(podracing_survey, starts_with("ratings_"),
                      chart = FALSE, path = p)
  wb <- openxlsx2::wb_load(p)
  expect_equal(length(openxlsx2::wb_get_sheet_names(wb)), 6)
})

test_that("export_summary_xlsx honours the session default dataset", {
  skip_if_not_installed("openxlsx2")
  withr::defer(clear_dataset())
  use_dataset(podracing_survey)
  dir <- withr::local_tempdir()
  p <- file.path(dir, "d.xlsx")
  export_summary_xlsx(demo_gender, path = p)
  expect_true(file.exists(p))
})

test_that("with no variables it writes every question, multi-select as one sheet", {
  skip_if_not_installed("openxlsx2")
  dir <- withr::local_tempdir()
  p <- file.path(dir, "all.xlsx")
  suppressMessages(export_summary_xlsx(podracing_survey, path = p))
  sheets <- openxlsx2::wb_get_sheet_names(openxlsx2::wb_load(p))
  expect_true("motivations" %in% sheets)
  expect_false(any(grepl("motivations_", sheets)))
  expect_false("respondent_id" %in% sheets)
})

test_that("named_zip_tool_missing spots a zip tool that is not installed", {
  withr::local_envvar(c(R_ZIPCMD = "definitely-not-a-zip-tool"))
  expect_true(named_zip_tool_missing())
})

test_that("named_zip_tool_missing passes a zip tool that is installed", {
  real <- unname(Sys.which("R"))
  skip_if(!nzchar(real), "no known-good executable to point R_ZIPCMD at")
  withr::local_envvar(c(R_ZIPCMD = real))
  expect_false(named_zip_tool_missing())
})

test_that("export_summary_xlsx writes when R_ZIPCMD names a missing tool", {
  skip_if_not_installed("openxlsx2")
  withr::local_envvar(c(R_ZIPCMD = "definitely-not-a-zip-tool"))
  dir <- withr::local_tempdir()
  p <- file.path(dir, "nozip.xlsx")
  export_summary_xlsx(podracing_survey, demo_gender, path = p)
  expect_true(file.exists(p))
  expect_setequal(openxlsx2::wb_get_sheet_names(openxlsx2::wb_load(p)),
                  "demo_gender")
})

test_that("saving a workbook leaves the openxlsx2 zip option as it found it", {
  skip_if_not_installed("openxlsx2")
  withr::local_envvar(c(R_ZIPCMD = "definitely-not-a-zip-tool"))
  withr::local_options(openxlsx2.no_utils_zip = NULL)
  dir <- withr::local_tempdir()
  export_summary_xlsx(podracing_survey, demo_gender,
                      path = file.path(dir, "opt.xlsx"))
  expect_null(getOption("openxlsx2.no_utils_zip"))
})
