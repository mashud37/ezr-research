test_that("book_chapters maps chapters to topics and urls", {
  ch <- book_chapters()
  expect_s3_class(ch, "tbl_df")
  expect_equal(nrow(ch), 8L)
  expect_true(all(c("chapter", "title", "topics", "url") %in% names(ch)))
  expect_true(all(grepl("^https?://", ch$url)))
  # chapter 2 should advertise the nps topic
  expect_match(ch$topics[ch$chapter == 2], "nps")
})

test_that("open_book returns a url and rejects bad chapters", {
  expect_message(u <- open_book(2), "Book")
  expect_match(u, "the-ezr-way")
  expect_error(open_book(99), "No such chapter")
})
