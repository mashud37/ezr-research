# Documentation completeness guard: every exported function must have a
# \value section, at least one example, and be assigned to a family (\concept),
# so the help and pkgdown reference stay complete as the package grows.

rd_sections <- function() {
  db <- tryCatch(tools::Rd_db("ezrsurvey"), error = function(e) NULL)
  skip_if(is.null(db), "Rd database not available (package not installed).")
  db
}

exported_function_topics <- function(db) {
  ns <- asNamespace("ezrsurvey")
  exports <- getNamespaceExports("ezrsurvey")
  is_fun <- vapply(exports, function(x) is.function(get0(x, envir = ns)),
                   logical(1))
  funs <- exports[is_fun]
  # Re-exported operators (e.g. %>%) are documented elsewhere.
  setdiff(funs, c("%>%"))
}

rd_tag_values <- function(rd, tag) {
  tags <- vapply(rd, function(x) attr(x, "Rd_tag"), character(1))
  rd[tags == tag]
}

topic_for <- function(db, fn) {
  for (nm in names(db)) {
    aliases <- unlist(lapply(rd_tag_values(db[[nm]], "\\alias"),
                             function(a) trimws(paste(unlist(a), collapse = ""))))
    if (fn %in% aliases) return(db[[nm]])
  }
  NULL
}

test_that("every exported function documents @return, @examples and @family", {
  db <- rd_sections()
  funs <- exported_function_topics(db)
  expect_gt(length(funs), 40)

  missing_value <- character(0)
  missing_examples <- character(0)
  missing_family <- character(0)

  for (fn in funs) {
    rd <- topic_for(db, fn)
    if (is.null(rd)) next
    tags <- vapply(rd, function(x) attr(x, "Rd_tag"), character(1))
    if (!"\\value" %in% tags) missing_value <- c(missing_value, fn)
    if (!"\\examples" %in% tags) missing_examples <- c(missing_examples, fn)
    if (!"\\concept" %in% tags) missing_family <- c(missing_family, fn)
  }

  expect_identical(missing_value, character(0),
                   info = paste("missing @return:",
                                paste(missing_value, collapse = ", ")))
  expect_identical(missing_examples, character(0),
                   info = paste("missing @examples:",
                                paste(missing_examples, collapse = ", ")))
  expect_identical(missing_family, character(0),
                   info = paste("missing @family:",
                                paste(missing_family, collapse = ", ")))
})
