# ---- construction --------------------------------------------------------

# Internal constructor for the exercise object. Validates by type.
new_exercise <- function(id, type, prompt, chapter = NA_integer_, topic = NA,
                         difficulty = "easy", data = NULL, data_name = "theme_park",
                         options = NULL, answer = NULL, solution_code = NA,
                         solution_value = NULL, check = NULL, hint = NA,
                         explanation = NA, seed = NA, source = "bank") {
  type <- match.arg(type, c("mcq", "code"))
  if (type == "mcq") {
    if (length(options) < 2L) stop("An MCQ needs at least two options.", call. = FALSE)
    if (is.null(answer)) stop("An MCQ needs an `answer`.", call. = FALSE)
    answer <- normalize_letter(answer, options)
  }
  structure(
    list(id = id, type = type, prompt = prompt, chapter = chapter, topic = topic,
         difficulty = difficulty, data = data, data_name = data_name,
         options = options, answer = answer, solution_code = solution_code,
         solution_value = solution_value, check = check, hint = hint,
         explanation = explanation, seed = seed, source = source),
    class = "ezrlearning_exercise"
  )
}

# Internal: turn a letter / number / option text into a canonical option letter.
normalize_letter <- function(answer, options) {
  if (is.numeric(answer)) return(LETTERS[as.integer(answer)])
  a <- toupper(trimws(as.character(answer)))
  if (a %in% LETTERS[seq_along(options)]) return(a)
  m <- match(tolower(trimws(as.character(answer))), tolower(options))
  if (!is.na(m)) return(LETTERS[m])
  a
}

# ---- printing ------------------------------------------------------------

#' @export
print.ezrlearning_exercise <- function(x, ...) {
  tag <- if (x$type == "mcq") "Multiple choice" else "Write the code"
  ch <- if (is.na(x$chapter)) "" else paste0("  [ch. ", x$chapter, ": ", x$topic, "]")
  cat(sprintf("<exercise %s>  %s%s\n", x$id, tag, ch))
  cat("\n"); cat(strwrap(x$prompt, width = 76), sep = "\n"); cat("\n")
  if (!is.null(x$data)) {
    cat("\nData (", x$data_name, ", first rows):\n", sep = "")
    print(utils::head(tibble::as_tibble(x$data), 5))
  }
  if (x$type == "mcq") {
    cat("\n")
    for (i in seq_along(x$options)) {
      cat(sprintf("  %s. %s\n", LETTERS[i], x$options[[i]]))
    }
    cat("\nAnswer with check_answer(x, \"A\").  Stuck? hint(x).\n")
  } else {
    cat("\nWrite ezr code that answers this, then pass it to check_answer():\n")
    cat('  check_answer(x, "calc_nps(theme_park, nps)")   # for example\n')
    cat("Stuck? hint(x).  Give up? reveal(x).\n")
  }
  invisible(x)
}

#' Reveal the solution to an exercise
#'
#' Prints the reference solution: for a code task the model answer code (and the
#' value it produces), for a multiple-choice question the correct option, plus
#' the explanation.
#'
#' @param x An exercise (from [draw_exercise()], [quiz()] or
#'   [generate_exercise()]).
#'
#' @return The exercise, invisibly.
#'
#' @details
#' Use this when you want to study the worked answer rather than be graded.
#' [check_answer()] reveals the solution too when you ask it to; `reveal()` is the
#' shortcut for "just show me".
#'
#' @family exercises
#' @seealso [check_answer()], [hint()].
#' @examples
#' x <- draw_exercise(topic = "nps", seed = 1)
#' reveal(x)
#' @export
reveal <- function(x) {
  stopifnot(inherits(x, "ezrlearning_exercise"))
  cat(sprintf("<solution to %s>\n", x$id))
  if (x$type == "mcq") {
    i <- match(x$answer, LETTERS)
    cat(sprintf("  Correct answer: %s. %s\n", x$answer, x$options[[i]]))
  } else {
    cat("  Solution code:\n    ", x$solution_code, "\n", sep = "")
    if (!is.null(x$solution_value)) {
      cat("  Produces:\n")
      print(x$solution_value)
    }
  }
  if (!is.na(x$explanation)) {
    cat("\n"); cat(strwrap(paste("Why:", x$explanation), width = 76), sep = "\n")
    cat("\n")
  }
  invisible(x)
}

#' Show the hint for an exercise
#'
#' @param x An exercise.
#' @return The exercise, invisibly.
#' @family exercises
#' @seealso [check_answer()], [reveal()].
#' @examples
#' x <- draw_exercise(topic = "nps", seed = 1)
#' hint(x)
#' @export
hint <- function(x) {
  stopifnot(inherits(x, "ezrlearning_exercise"))
  if (is.na(x$hint)) {
    cat("No hint for this one -- give it a try, then reveal(x).\n")
  } else {
    cat(strwrap(paste("Hint:", x$hint), width = 76), sep = "\n"); cat("\n")
  }
  invisible(x)
}

# ---- checking ------------------------------------------------------------

# Internal: build an environment where bare ezr functions and the exercise data
# resolve, so a learner's code string runs as if they had library()'d the family.
ezr_eval_env <- function(data = NULL, data_name = "theme_park") {
  e <- new.env(parent = globalenv())
  for (pkg in c("ezrsurvey", "ezrmodel")) {
    ns <- asNamespace(pkg)
    for (nm in getNamespaceExports(pkg)) {
      if (!exists(nm, envir = e, inherits = FALSE)) {
        assign(nm, get(nm, envir = ns), envir = e)
      }
    }
  }
  if (!is.null(data)) assign(data_name, data, envir = e)
  e
}

# Internal: evaluate learner-supplied code (string or one-sided formula).
eval_user_code <- function(code, env) {
  expr <- if (inherits(code, "formula")) code[[length(code)]] else
    parse(text = code)
  eval(expr, envir = env)
}

# Internal: tolerant equality for scalars, vectors and data frames.
values_equal <- function(a, b, tol = 1e-6) {
  if (is.data.frame(a) && is.data.frame(b)) {
    a <- as.data.frame(a); b <- as.data.frame(b)
    rownames(a) <- NULL; rownames(b) <- NULL
  }
  isTRUE(all.equal(a, b, tolerance = tol, check.attributes = FALSE))
}

new_result <- function(correct, message, id, expected = NULL, got = NULL) {
  structure(list(correct = correct, message = message, id = id,
                 expected = expected, got = got),
            class = "ezrlearning_result")
}

#' Check an answer to an exercise
#'
#' Grades a learner's response. For a multiple-choice question pass the option
#' (a letter, number or the option text). For a code task pass either the value
#' you computed, or your code as a string or one-sided formula -- it is run
#' against the exercise data (with the ezr packages available) and compared to
#' the reference result.
#'
#' @param x An exercise (from [draw_exercise()], [quiz()] or
#'   [generate_exercise()]).
#' @param answer Your response. MCQ: `"B"`, `2`, or the option text. Code: a
#'   value, a code string (e.g. `"calc_nps(theme_park, nps)"`), or a one-sided
#'   formula (`~ calc_nps(theme_park, nps)`).
#' @param reveal If `TRUE`, include the reference solution in the result when you
#'   are wrong. Default `FALSE`.
#'
#' @return An `ezrlearning_result` object (with a `print()` method) carrying
#'   `correct` (logical) and a feedback `message`.
#'
#' @details
#' Code answers are evaluated in a sandbox environment where the ezr family's
#' exported functions and the exercise's `data` (under its usual name, e.g.
#' `theme_park`) are in scope, so you do not have to attach anything. The result
#' is compared to the reference value tolerantly (numeric rounding and row order
#' do not matter). If your code errors, you are told what went wrong rather than
#' the call failing. AI-generated *code* tasks have no computed reference value,
#' so they are self-graded -- `check_answer()` will point you to [reveal()].
#'
#' @family exercises
#' @seealso [reveal()], [hint()], [grade()].
#' @examples
#' x <- draw_exercise(topic = "percentage", type = "mcq", seed = 1)
#' check_answer(x, "A")
#' @export
check_answer <- function(x, answer, reveal = FALSE) {
  stopifnot(inherits(x, "ezrlearning_exercise"))

  if (x$type == "mcq") {
    got <- normalize_letter(answer, x$options)
    correct <- identical(got, x$answer)
    msg <- if (correct) "Correct." else
      paste0("Not quite -- you answered ", got, ".",
             if (reveal) paste0(" Correct: ", x$answer, ".") else
               " Try again, or reveal(x).")
    return(new_result(correct, msg, x$id,
                      expected = if (reveal) x$answer else NULL, got = got))
  }

  # code exercise
  if (!is.null(x$check) && is.function(x$check)) {
    val <- tryCatch(
      if (is.character(answer) || inherits(answer, "formula")) {
        eval_user_code(answer, ezr_eval_env(x$data, x$data_name))
      } else answer,
      error = function(e) structure(conditionMessage(e), class = "ezrl_err"))
    if (inherits(val, "ezrl_err")) {
      return(new_result(FALSE, paste0("Your code raised an error: ", val), x$id))
    }
    ok <- isTRUE(x$check(val, x$data))
    msg <- if (ok) "Correct." else "Not quite -- reveal(x) to see the solution."
    return(new_result(ok, msg, x$id))
  }

  if (is.null(x$solution_value)) {
    return(new_result(NA, paste0(
      "This task is self-graded (no stored answer). Compare your code to the ",
      "solution with reveal(x)."), x$id))
  }

  got <- tryCatch(
    if (is.character(answer) || inherits(answer, "formula")) {
      eval_user_code(answer, ezr_eval_env(x$data, x$data_name))
    } else answer,
    error = function(e) structure(conditionMessage(e), class = "ezrl_err"))
  if (inherits(got, "ezrl_err")) {
    return(new_result(FALSE, paste0("Your code raised an error: ", got), x$id))
  }
  correct <- values_equal(got, x$solution_value)
  msg <- if (correct) "Correct." else
    paste0("Not quite -- your result does not match the expected answer.",
           if (reveal) "" else " Try again, or reveal(x).")
  new_result(correct, msg, x$id,
             expected = if (reveal) x$solution_value else NULL, got = got)
}

#' @export
print.ezrlearning_result <- function(x, ...) {
  mark <- if (isTRUE(x$correct)) "[OK]" else if (isFALSE(x$correct)) "[X]" else "[?]"
  cat(mark, " ", x$message, "\n", sep = "")
  if (!is.null(x$expected)) {
    cat("Expected:\n"); print(x$expected)
  }
  invisible(x)
}
