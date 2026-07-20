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

test_that("scaffold_report substitutes author and reference doc", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "r.qmd")
  ref <- file.path(dir, "brand.pptx")
  file.create(ref)
  scaffold_report("pptx", path = path, title = "T", author = "A. Analyst",
                  reference_doc = ref)
  txt <- paste(readLines(path), collapse = "\n")
  expect_match(txt, "A. Analyst", fixed = TRUE)
  expect_match(txt, "reference-doc:")
  expect_no_match(txt, "\\{\\{[A-Z_]+\\}\\}")

  # pptx falls back to the bundled 16:9 template ...
  path2 <- file.path(dir, "r2.qmd")
  scaffold_report("pptx", path = path2, title = "T")
  txt2 <- paste(readLines(path2), collapse = "\n")
  expect_match(txt2, "reference-doc: .*ezrsurvey-16x9[.]pptx")

  # ... docx keeps the commented hint
  path3 <- file.path(dir, "r3.qmd")
  scaffold_report("docx", path = path3, title = "T")
  txt3 <- paste(readLines(path3), collapse = "\n")
  expect_match(txt3, "# reference-doc:")
})

test_that("bundled templates use the magrittr pipe and params", {
  tpl_dir <- system.file("templates", package = "ezrsurvey")
  for (f in list.files(tpl_dir, pattern = "^report-.*\\.qmd$",
                       full.names = TRUE)) {
    txt <- paste(readLines(f, encoding = "UTF-8"), collapse = "\n")
    expect_no_match(txt, "\\|>", info = f)
    expect_match(txt, "params:", info = f)
  }
})

test_that("list_report_templates lists the bundled formats", {
  fmts <- list_report_templates()
  expect_true(all(c("pptx", "html", "pdf", "docx") %in% fmts))
})

test_that("report_layouts describes the default template", {
  skip_if_not_installed("officer")
  layouts <- report_layouts()
  expect_s3_class(layouts, "tbl_df")
  expect_true(all(c("layout", "master", "has_title", "n_body") %in%
                    names(layouts)))
  expect_true("Title and Content" %in% layouts$layout)
})

test_that("select_layout picks sensible layouts by placeholder types", {
  skip_if_not_installed("officer")
  doc <- officer::read_pptx()
  expect_equal(select_layout(doc, "content")$layout, "Title and Content")
  expect_equal(select_layout(doc, "title")$layout, "Title Slide")
  two <- select_layout(doc, "two_content")
  expect_true(is.null(two) || two$layout == "Two Content")
})

test_that("report_add_slide validates explicit layouts and guards titles", {
  skip_if_not_installed("officer")
  doc <- report_new("pptx")
  expect_error(report_add_slide(doc, layout = "No Such Layout"),
               "report_layouts")
  # A layout without a title placeholder warns once instead of erroring
  expect_warning(
    doc <- report_add_slide(doc, title = "Hi", layout = "Blank"),
    "no title placeholder"
  )
  expect_s3_class(doc, "rpptx")
})

test_that("report_deck builds a pptx file", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "deck.pptx")
  p <- calc_percentage(podracing_survey, demo_gender) %>% plot_bars()
  tbl <- calc_nps(podracing_survey, nps_value)
  out <- report_deck(list("Gender" = p, "NPS" = tbl), path = path,
                     title = "Overview")
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 0)
})

test_that("report_deck with a stub chat writes AI bullets", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "deck-ai.pptx")
  calls <- 0L
  fake_chat <- list(chat = function(msg) {
    calls <<- calls + 1L
    "- First takeaway\n- Second takeaway\n- Third takeaway"
  })
  p <- calc_percentage(podracing_survey, demo_gender) %>% plot_bars()
  out <- report_deck(list("Gender" = p), path = path, ai = TRUE,
                     chat = fake_chat)
  expect_true(file.exists(out))
  expect_equal(calls, 1L)
})

test_that("report_deck survives a failing chat", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "deck-fail.pptx")
  broken_chat <- list(chat = function(msg) stop("provider down"))
  p <- calc_percentage(podracing_survey, demo_gender) %>% plot_bars()
  expect_message(
    out <- report_deck(list("Gender" = p), path = path, ai = TRUE,
                       chat = broken_chat),
    "provider down"
  )
  expect_true(file.exists(out))
})

test_that("parse_markdown_bullets strips markers and blanks", {
  expect_equal(
    parse_markdown_bullets("- a\n* b\n\n1. c\n2) d"),
    c("a", "b", "c", "d")
  )
})

test_that("report builders add plots and tables to a docx", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "doc.docx")
  p <- calc_percentage(podracing_survey, demo_edu) %>% plot_bars(flip = TRUE)
  doc <- report_new("docx") %>%
    report_add_slide("Education", heading_level = 1) %>%
    report_add_plot(p) %>%
    report_add_table(calc_percentage(podracing_survey, demo_edu))
  out <- report_save(doc, path)
  expect_true(file.exists(out))
})

test_that("the default deck is 16:9 with the bundled template", {
  skip_if_not_installed("officer")
  doc <- report_new("pptx")
  size <- officer::slide_size(doc)
  expect_equal(size$width, 40 / 3, tolerance = 1e-6)
  expect_equal(size$height, 7.5)
  layouts <- report_layouts()
  expect_true(all(c("Title Slide", "Title and Content", "Two Content",
                    "Content with Caption") %in% layouts$layout))
  # the decorative title rule must not count as a content placeholder
  tac <- layouts[layouts$layout == "Title and Content", ]
  expect_equal(tac$n_body, 1L)
})

test_that("content slides carry a slide-number field, title slides do not", {
  skip_if_not_installed("officer")
  skip_if_not_installed("xml2")
  dir <- withr::local_tempdir()
  doc <- report_new("pptx")
  doc <- report_add_slide(doc, "One")
  doc <- report_add_slide(doc, "Two")
  path <- file.path(dir, "numbered.pptx")
  print(doc, target = path)
  ex <- file.path(dir, "x")
  utils::unzip(path, exdir = ex)
  for (i in 1:2) {
    slide <- paste(readLines(file.path(ex, "ppt", "slides",
                                       sprintf("slide%d.xml", i)),
                             warn = FALSE), collapse = "")
    expect_match(slide, "slidenum")
  }

  doc2 <- report_new("pptx", slide_numbers = FALSE)
  doc2 <- report_add_slide(doc2, "One")
  path2 <- file.path(dir, "plain.pptx")
  print(doc2, target = path2)
  ex2 <- file.path(dir, "x2")
  utils::unzip(path2, exdir = ex2)
  slide <- paste(readLines(file.path(ex2, "ppt", "slides", "slide1.xml"),
                           warn = FALSE), collapse = "")
  expect_no_match(slide, "slidenum")
})

test_that("bars are drawn to a constant thickness whatever the bar count", {
  # width is a fraction of a category slot, so holding thickness constant means
  # width / n_items must be the same for a 3-bar and an 8-bar chart.
  w3 <- consistent_bar_width(3)
  w8 <- consistent_bar_width(8)
  expect_equal(w3 / 3, w8 / 8)
  expect_lt(w3, w8)
  # a very dense chart caps rather than overflowing its slot
  expect_lte(consistent_bar_width(40), 0.9)
  expect_equal(consistent_bar_width(6), 0.66)
})

test_that("report_deck builds a multi-chart deck", {
  skip_if_not_installed("officer")
  dir <- withr::local_tempdir()
  items <- list(
    "Gender" = calc_percentage(podracing_survey, demo_gender) %>% plot_bars(),
    "Job" = calc_percentage(podracing_survey, demo_job) %>% plot_bars()
  )
  out <- report_deck(items, path = file.path(dir, "deck.pptx"))
  expect_true(file.exists(out))
})

test_that("example_report copies the worked example", {
  dir <- withr::local_tempdir()
  dest <- file.path(dir, "example")
  paths <- suppressMessages(example_report(dest))
  expect_true(all(file.exists(paths)))
  expect_true(any(grepl("podracing-report[.]qmd$", paths)))
  expect_true(any(grepl("podracing-deck[.]R$", paths)))
  expect_error(suppressMessages(example_report(dest)), "overwrite")
  expect_silent(suppressMessages(example_report(dest, overwrite = TRUE)))
})
