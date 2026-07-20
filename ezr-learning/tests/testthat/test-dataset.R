test_that("theme_park open text is globally unique (no comment repeats)", {
  vals <- theme_park$comment[nzchar(theme_park$comment)]
  expect_gt(length(vals), 0)
  expect_equal(anyDuplicated(vals), 0L)
})
