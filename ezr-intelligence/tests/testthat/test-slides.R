test_that("parse_markdown_bullets strips markers and blanks", {
  expect_equal(
    parse_markdown_bullets("- a\n* b\n\n1. c\n2) d"),
    c("a", "b", "c", "d")
  )
})

test_that("ai_slide_text returns a title and bullets from a stub chat", {
  stub <- list(chat = function(msg) {
    if (grepl("Write one slide title", msg, fixed = TRUE)) {
      "Women outnumber men in the sample"
    } else {
      "- Women lead on 55%\n- Men trail on 45%"
    }
  })
  df <- data.frame(answer = c("Female", "Male"), pct = c(55, 45))
  out <- ai_slide_text(df, title = "Gender", chat = stub)

  expect_equal(out$title, "Women outnumber men in the sample")
  expect_length(out$bullets, 2)
})

test_that("ai_slide_text skips the title call when want_title is FALSE", {
  calls <- 0
  stub <- list(chat = function(msg) {
    calls <<- calls + 1
    "- one bullet"
  })
  ai_slide_text(data.frame(x = 1), chat = stub, want_title = FALSE)
  expect_equal(calls, 1)
})

test_that("ai_slide_text degrades to NULL when the model call fails", {
  broken <- list(chat = function(msg) stop("provider down"))
  expect_message(
    out <- ai_slide_text(data.frame(x = 1), title = "X", chat = broken),
    "provider down"
  )
  expect_null(out$bullets)
  expect_null(out$title)
})

test_that("ai_slide_text rejects an object that cannot chat", {
  expect_error(ai_slide_text(data.frame(x = 1), chat = list(a = 1)),
               "must be an ai_chat")
})
