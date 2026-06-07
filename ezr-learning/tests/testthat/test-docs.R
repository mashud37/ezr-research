# Documentation completeness guard: every exported function must have a
# \value section, an example, and a family (\concept).

rd_db <- function() {
  db <- tryCatch(tools::Rd_db("ezrlearning"), error = function(e) NULL)
  skip_if(is.null(db), "Rd database not available (package not installed).")
  db
}

exported_functions <- function() {
  ns <- asNamespace("ezrlearning")
  exports <- getNamespaceExports("ezrlearning")
  is_fun <- vapply(exports, function(x) is.function(get0(x, envir = ns)),
                   logical(1))
  setdiff(exports[is_fun], c("%>%"))
}

tag_of <- function(rd) vapply(rd, function(x) attr(x, "Rd_tag"), character(1))

topic_for <- function(db, fn) {
  for (nm in names(db)) {
    aliases <- unlist(lapply(db[[nm]][tag_of(db[[nm]]) == "\\alias"],
                             function(a) trimws(paste(unlist(a), collapse = ""))))
    if (fn %in% aliases) return(db[[nm]])
  }
  NULL
}

test_that("every exported function documents @return, @examples and @family", {
  db <- rd_db()
  funs <- exported_functions()
  expect_gt(length(funs), 20)

  miss_value <- miss_examples <- miss_family <- character(0)
  for (fn in funs) {
    rd <- topic_for(db, fn)
    if (is.null(rd)) next
    tags <- tag_of(rd)
    if (!"\\value" %in% tags) miss_value <- c(miss_value, fn)
    if (!"\\examples" %in% tags) miss_examples <- c(miss_examples, fn)
    if (!"\\concept" %in% tags) miss_family <- c(miss_family, fn)
  }
  expect_identical(miss_value, character(0),
                   info = paste("missing @return:", paste(miss_value, collapse = ", ")))
  expect_identical(miss_examples, character(0),
                   info = paste("missing @examples:", paste(miss_examples, collapse = ", ")))
  expect_identical(miss_family, character(0),
                   info = paste("missing @family:", paste(miss_family, collapse = ", ")))
})
