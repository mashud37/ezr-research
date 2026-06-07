# ---- assembly ------------------------------------------------------------

#' Assemble a quiz of practice exercises
#'
#' Draws `n` exercises (optionally scoped by topic, chapter, type or difficulty)
#' into a single quiz. Like [draw_exercise()], a quiz is fully reproducible from
#' its `seed`: the same call always yields the same set of questions, which is
#' how [export_worksheet()] can rebuild it exactly.
#'
#' @param n Number of exercises. Default `5`.
#' @param topic,chapter,type,difficulty Filters passed through to the bank (see
#'   [draw_exercise()]). `NULL` means no filter.
#' @param seed Optional integer seed. If `NULL`, one is chosen and stored.
#'
#' @return An `ezrlearning_quiz`: a list of `exercises` plus the `call` used to
#'   build it. Has `print()` methods; grade it with [grade()] or hand it out with
#'   [export_worksheet()].
#'
#' @details
#' Generators are sampled without replacement when there are at least `n` matching
#' templates (so a short quiz spans different topics), with replacement otherwise.
#' Each exercise is instantiated with its own sub-seed drawn from the quiz seed,
#' so the whole quiz is deterministic yet varied. The construction call is stored
#' on the object, letting [export_worksheet()] reconstruct the identical quiz
#' inside a worksheet.
#'
#' @family quiz
#' @seealso [grade()], [export_worksheet()], [draw_exercise()].
#' @examples
#' q <- quiz(3, seed = 1)
#' q
#' @export
quiz <- function(n = 5, topic = NULL, chapter = NULL, type = NULL,
                 difficulty = NULL, seed = NULL) {
  cands <- filter_candidates(topic, chapter, type, difficulty)
  if (length(cands) == 0L) {
    stop("No exercises match those filters. See exercise_bank().", call. = FALSE)
  }
  seed <- seed %||% ezrlearning_default("seed") %||%
    sample.int(.Machine$integer.max, 1)

  exs <- with_seed(seed, {
    k <- length(cands)
    idx <- if (n <= k) sample(k, n) else sample(k, n, replace = TRUE)
    lapply(idx, function(j) {
      g <- cands[[j]]
      sub <- sample.int(.Machine$integer.max, 1)
      e <- with_seed(sub, g$fn(g$meta$difficulty))
      e$seed <- sub
      e
    })
  })

  structure(
    list(exercises = exs, n = length(exs),
         call = list(n = n, topic = topic, chapter = chapter, type = type,
                     difficulty = difficulty, seed = seed)),
    class = "ezrlearning_quiz"
  )
}

#' @export
print.ezrlearning_quiz <- function(x, ...) {
  cat(sprintf("<quiz>  %d questions  (seed %s)\n\n", x$n, x$call$seed))
  for (i in seq_along(x$exercises)) {
    e <- x$exercises[[i]]
    tag <- if (e$type == "mcq") "MCQ " else "code"
    cat(sprintf("%2d. [%s ch.%s/%s] %s\n", i, tag, e$chapter, e$topic,
                substr(e$prompt, 1, 60)))
  }
  cat("\nAnswer with grade(quiz, list(...)) or work through quiz$exercises.\n")
  invisible(x)
}

# ---- grading -------------------------------------------------------------

#' Grade a whole quiz at once
#'
#' Checks a list of answers against a quiz and reports a per-question result and
#' an overall score.
#'
#' @param quiz An `ezrlearning_quiz` from [quiz()].
#' @param answers A list of answers, one per question, in order (or named by
#'   exercise id). Each element is whatever [check_answer()] accepts (a letter for
#'   MCQ, a value / code string for code tasks). Use `NULL` to skip a question.
#'
#' @return An `ezrlearning_grade` object: a per-item table and the `score`
#'   (correct out of those that could be auto-graded). Has a `print()` method.
#'
#' @details
#' Answers are matched to questions by name (exercise id) when the list is named,
#' otherwise by position. Self-graded code tasks (those without a stored answer)
#' are reported as `NA` and left out of the score denominator. The returned table
#' makes it easy to see which topics need another pass.
#'
#' @family quiz
#' @seealso [quiz()], [check_answer()].
#' @examples
#' q <- quiz(3, type = "mcq", seed = 1)
#' # answer every question "A" (some right, some wrong)
#' grade(q, as.list(rep("A", 3)))
#' @export
grade <- function(quiz, answers) {
  stopifnot(inherits(quiz, "ezrlearning_quiz"))
  ids <- vapply(quiz$exercises, `[[`, character(1), "id")
  if (!is.null(names(answers))) {
    answers <- answers[ids]
  }
  res <- lapply(seq_along(quiz$exercises), function(i) {
    e <- quiz$exercises[[i]]
    a <- if (i <= length(answers)) answers[[i]] else NULL
    if (is.null(a)) {
      return(new_result(NA, "Skipped.", e$id))
    }
    check_answer(e, a)
  })
  correct <- vapply(res, function(r) r$correct, logical(1))
  tbl <- tibble::tibble(
    q = seq_along(res),
    id = ids,
    type = vapply(quiz$exercises, `[[`, character(1), "type"),
    topic = vapply(quiz$exercises, `[[`, character(1), "topic"),
    correct = correct
  )
  graded <- !is.na(correct)
  structure(
    list(items = tbl, n_correct = sum(correct, na.rm = TRUE),
         n_graded = sum(graded),
         score = if (any(graded)) mean(correct[graded]) else NA_real_),
    class = "ezrlearning_grade"
  )
}

#' @export
print.ezrlearning_grade <- function(x, ...) {
  d <- x$items
  d$result <- ifelse(is.na(d$correct), "--",
                     ifelse(d$correct, "OK", "X"))
  cat("Quiz results\n")
  print(as.data.frame(d[, c("q", "topic", "type", "result")]), row.names = FALSE)
  if (!is.na(x$score)) {
    cat(sprintf("\nScore: %d / %d  (%.0f%%)\n", x$n_correct, x$n_graded,
                x$score * 100))
  } else {
    cat("\nNo auto-gradable questions answered.\n")
  }
  invisible(x)
}

# ---- worksheet export ----------------------------------------------------

# Internal: deparse an argument value into runnable R source.
fmt_arg <- function(v) {
  if (is.null(v)) return("NULL")
  if (is.character(v)) {
    return(paste0("c(", paste0('"', v, '"', collapse = ", "), ")"))
  }
  paste(deparse(v), collapse = " ")
}

#' Export a quiz as a self-contained worksheet
#'
#' Writes a quiz to an R Markdown worksheet that *rebuilds the identical quiz*
#' from its seed, so every question -- with its exact data -- is live and
#' gradable inside the document. Optionally renders it to HTML.
#'
#' @param quiz An `ezrlearning_quiz` from [quiz()].
#' @param path Output path. If it ends in `.html` and `rmarkdown` is installed,
#'   the worksheet is rendered; otherwise a `.Rmd` is written.
#' @param answer_key Include the worked solutions (via [reveal()]) after each
#'   question. Default `FALSE`.
#' @param title Worksheet title. Default `"ezr practice worksheet"`.
#'
#' @return Invisibly the path written.
#'
#' @details
#' The worksheet's setup chunk calls `quiz()` with the same arguments and seed,
#' so `q$exercises[[i]]` is reconstructed exactly -- learners run
#' `check_answer(q$exercises[[i]], ...)` right in the document. Each question
#' links back to its book chapter. With `answer_key = TRUE` the solutions are
#' included, giving you a teacher's copy. Rendering to HTML needs the suggested
#' `rmarkdown` package; without it (or with a `.Rmd` path) the source is written
#' for you to knit.
#'
#' @family quiz
#' @seealso [quiz()], [grade()].
#' @examples
#' q <- quiz(3, seed = 1)
#' f <- tempfile(fileext = ".Rmd")
#' export_worksheet(q, f)
#' file.exists(f)
#' @export
export_worksheet <- function(quiz, path, answer_key = FALSE,
                             title = "ezr practice worksheet") {
  stopifnot(inherits(quiz, "ezrlearning_quiz"))
  cl <- quiz$call
  setup <- c(
    "```{r setup, include=FALSE}",
    "knitr::opts_chunk$set(echo = TRUE, comment = \"#>\")",
    "library(ezrlearning)",
    sprintf(paste0("q <- quiz(n = %d, topic = %s, chapter = %s, type = %s, ",
                   "difficulty = %s, seed = %s)"),
            cl$n, fmt_arg(cl$topic), fmt_arg(cl$chapter), fmt_arg(cl$type),
            fmt_arg(cl$difficulty), fmt_arg(cl$seed)),
    "```"
  )
  header <- c(
    "---", paste0("title: \"", title, "\""),
    "output: html_document", "---", "", setup, "",
    paste0("*This worksheet rebuilds itself from seed `", cl$seed,
           "`. Answer in the blanks, then knit (or run the chunks) to check.*"),
    ""
  )
  body <- unlist(lapply(seq_along(quiz$exercises), function(i) {
    e <- quiz$exercises[[i]]
    chap <- if (is.na(e$chapter)) "" else
      sprintf(" *(Chapter %s: %s)*", e$chapter, e$topic)
    blank <- if (e$type == "mcq")
      "Your answer (A/B/C/D): **___**" else
      "Your code:\n\n```{r}\n# your_answer <- ...\n```"
    check <- sprintf(
      "```{r}\nq$exercises[[%d]]            # the question\n# check_answer(q$exercises[[%d]], your_answer)\n```",
      i, i)
    out <- c(sprintf("## Question %d%s", i, chap), "", check, "", blank, "")
    if (answer_key) {
      out <- c(out, "**Solution**", "",
               sprintf("```{r}\nreveal(q$exercises[[%d]])\n```", i), "")
    }
    out
  }))

  lines <- c(header, body)
  is_html <- grepl("\\.html?$", path, ignore.case = TRUE)
  rmd_path <- if (is_html) sub("\\.html?$", ".Rmd", path, ignore.case = TRUE) else path
  writeLines(lines, rmd_path)

  if (is_html) {
    if (requireNamespace("rmarkdown", quietly = TRUE)) {
      rmarkdown::render(rmd_path, output_file = basename(path),
                        quiet = TRUE)
      return(invisible(path))
    }
    message("Install 'rmarkdown' to render HTML; wrote the .Rmd instead.")
    return(invisible(rmd_path))
  }
  invisible(rmd_path)
}
