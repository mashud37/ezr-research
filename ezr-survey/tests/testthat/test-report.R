test_that("scaffold_report writes a template with the title", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "r.qmd")
  out <- scaffold_report("html", path = path, title = "My Survey")
  expect_equal(out, path)
  expect_true(file.exists(path))
  txt <- paste(readLines(path), collapse = "\n")
  expect_match(txt, "My Survey")
  expect_match(txt, "format:")
  # does not overwrite without permission
  expect_error(scaffold_report("html", path = path))
})

test_that("list_report_templates lists the bundled formats", {
  fmts <- list_report_templates()
  expect_true(all(c("pptx", "html", "pdf", "docx") %in% fmts))
})

test_that("report_deck builds a pptx file", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "deck.pptx")
  p <- calc_percentage(consumer_survey, demo_gender) |> plot_bars()
  tbl <- calc_nps(consumer_survey, nps_value)
  out <- report_deck(list("Gender" = p, "NPS" = tbl), path = path,
                     title = "Overview")
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 0)
})

test_that("report builders add plots and tables to a docx", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "doc.docx")
  p <- calc_percentage(consumer_survey, demo_edu) |> plot_bars(flip = TRUE)
  doc <- report_new("docx") |>
    report_add_slide("Education", heading_level = 1) |>
    report_add_plot(p) |>
    report_add_table(calc_percentage(consumer_survey, demo_edu))
  out <- report_save(doc, path)
  expect_true(file.exists(out))
})
